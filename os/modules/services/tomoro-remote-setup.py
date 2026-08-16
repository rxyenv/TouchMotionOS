#!/usr/bin/env python3
"""Privileged, console-local Irusu remote pairing endpoint.

The UI deliberately contains no Bluetooth privileges: it asks this service to
scan and pair only through loopback from the local kiosk.
"""
import json
import os
import subprocess
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

STATE_DIR = Path('/data/tomoro')
STATE_FILE = STATE_DIR / 'remote.json'
PORT = int(os.environ.get('TOMORO_REMOTE_PORT', '8754'))


def load_state():
    try:
        return json.loads(STATE_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def save_state(state):
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix('.tmp')
    tmp.write_text(json.dumps(state, separators=(',', ':')))
    os.chmod(tmp, 0o600)
    tmp.replace(STATE_FILE)


def bluetoothctl(*args, timeout=20):
    return subprocess.run(['bluetoothctl', *args], text=True, capture_output=True,
                          timeout=timeout, check=False).stdout


def is_connected(mac):
    if not mac:
        return False
    return 'Connected: yes' in bluetoothctl('info', mac)


def trusted_remote():
    state = load_state()
    mac = state.get('mac')
    if not mac:
        return None
    info = bluetoothctl('info', mac)
    # A record is only valid when BlueZ still knows it as trusted.
    return state if 'Trusted: yes' in info else None


def device_rows():
    bluetoothctl('--timeout', '8', 'scan', 'on', timeout=12)
    rows = []
    for line in bluetoothctl('devices').splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) >= 2 and parts[0] == 'Device':
            rows.append({'mac': parts[1], 'name': parts[2] if len(parts) == 3 else 'Unknown device'})
    return rows


def pair_with_agent(mac):
    # Keep a BlueZ agent alive for the entire classic-Bluetooth pairing
    # exchange. Older HID remotes commonly fail when `bluetoothctl pair` is
    # invoked as a one-shot command with no agent registered.
    commands = f'agent NoInputNoOutput\ndefault-agent\npair {mac}\ntrust {mac}\nconnect {mac}\nquit\n'
    result = subprocess.run(['bluetoothctl'], input=commands, text=True,
                            capture_output=True, timeout=55, check=False)
    return f'{result.stdout}\n{result.stderr}'.strip()


class App:
    @classmethod
    def status(cls):
        remote = trusted_remote()
        return {
            'paired': remote is not None,
            'connected': is_connected(remote.get('mac')) if remote else False,
            'mac': remote.get('mac') if remote else None,
        }

    @classmethod
    def pair(cls, mac):
        old = trusted_remote()
        # Do not remove the old bond until the replacement is fully usable.
        output = pair_with_agent(mac)
        info = bluetoothctl('info', mac)
        if 'Paired: yes' not in info or 'Trusted: yes' not in info:
            bluetoothctl('remove', mac)
            detail = next((line.strip() for line in reversed(output.splitlines())
                           if 'fail' in line.lower() or 'error' in line.lower()), None)
            return False, detail or 'Could not pair remote; previous remote kept'
        save_state({'mac': mac, 'identity': next((x['name'] for x in device_rows() if x['mac'] == mac), 'Irusu remote')})
        if old and old.get('mac') != mac: bluetoothctl('remove', old['mac'])
        return True, None


class Handler(BaseHTTPRequestHandler):
    server_version = 'TomoroRemote/1'

    def log_message(self, fmt, *args):
        # Paths include one-time session codes; do not leak request URLs.
        return

    def local(self):
        return self.client_address[0] in ('127.0.0.1', '::1')

    def json(self, obj, status=HTTPStatus.OK):
        raw = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Content-Length', str(len(raw)))
        self.end_headers(); self.wfile.write(raw)

    def body(self):
        length = int(self.headers.get('Content-Length', '0'))
        return json.loads(self.rfile.read(length) or b'{}')

    def do_GET(self):
        if not self.local(): self.send_error(HTTPStatus.FORBIDDEN); return
        if self.path == '/api/status': self.json(App.status()); return
        self.send_error(HTTPStatus.NOT_FOUND)

    def do_POST(self):
        if not self.local(): self.json({'error': 'Console access only'}, HTTPStatus.FORBIDDEN); return
        try: data = self.body()
        except json.JSONDecodeError: self.json({'error': 'Invalid request'}, HTTPStatus.BAD_REQUEST); return
        if self.path == '/api/local/scan': self.json({'devices': device_rows()}); return
        if self.path == '/api/local/pair':
            mac = data.get('mac', '')
            if not mac or len(mac) != 17: self.json({'error': 'Invalid device'}, HTTPStatus.BAD_REQUEST); return
            paired, error = App.pair(mac)
            self.json({'ok': paired, 'error': error}, HTTPStatus.OK if paired else HTTPStatus.BAD_GATEWAY); return
        self.json({'error': 'Not found'}, HTTPStatus.NOT_FOUND)


if __name__ == '__main__':
    STATE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
    ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
