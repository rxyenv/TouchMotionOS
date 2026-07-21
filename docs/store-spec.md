# Store Backend + Rust IPC Layer — Spec

## Context

TouchMotionOS needs an app store so users can browse and download Unity games from within the launcher. B2B product; devices have credentials but store catalog is universal. MVP scope: browse catalog → download game → launch it. Backend is a temporary vibe-coded implementation to be handed off later.

Current game launch: `Process.start('steam-run', [game.id])` in `home_screen.dart:_launchGame()`. Games are installed as Nix packages. Downloaded games need a different install path since we can't imperatively install Nix packages.

---

## Architecture

```
[Flutter Launcher]
  Store Screen  ──HTTP──▶  [Backend API]  ──redirect──▶  [CDN]
  Library Screen ──socket──▶ [Rust Daemon: tomoro-store]
                              │  downloads + extracts
                              ▼
                         /var/lib/tomoro/games/{id}/
                         /var/lib/tomoro/manifest.json
```

---

## 1. Backend (Python FastAPI — MVP)

Single file server, deploy anywhere (Railway, Fly.io, VPS).

### Endpoints

```
GET  /catalog                → list all games
GET  /catalog/{id}           → game detail
POST /devices/register       → device checks in (stores device_id + last_seen)
```

### Game metadata schema

```json
{
  "id": "tomoro-breakout",
  "name": "Breakout VR",
  "description": "...",
  "cover_url": "https://cdn.../cover.jpg",
  "download_url": "https://cdn.../tomoro-breakout-v1.0.tar.gz",
  "version": "1.0.0",
  "size_bytes": 204800000,
  "binary": "Breakout.x86_64"
}
```

### Storage

SQLite for MVP (single file, no infra). One `games` table, one `devices` table.

### Auth

Device sends `X-Device-ID: <uuid>` header on every request. Backend logs it. No token validation for MVP — add later.

### Files

```
backend/
  main.py          # FastAPI app + all routes
  db.py            # SQLite helpers
  seed.py          # seed catalog with existing games
  requirements.txt
  README.md        # deploy instructions
```

---

## 2. Rust IPC Daemon (`tomoro-store`)

Unix socket daemon at `/run/tomoro/store.sock`. Bridges Flutter ↔ filesystem operations (download, extract, manifest). Rust chosen because: already in repo (`platform/crates/network/`), handles concurrent downloads cleanly, low overhead.

### New crate: `platform/crates/store/`

Follows same pattern as `platform/crates/network/`.

### Socket Protocol (newline-delimited JSON)

**Requests (Flutter → daemon):**

```json
{"cmd": "list"}
{"cmd": "install", "id": "tomoro-breakout"}
{"cmd": "cancel", "id": "tomoro-breakout"}
{"cmd": "launch", "id": "tomoro-breakout"}
```

**Responses/Events (daemon → Flutter, streamed):**

```json
{"type": "list", "games": [{"id": "...", "version": "...", "installed": true}]}
{"type": "progress", "id": "tomoro-breakout", "pct": 42, "bytes_done": 85983232, "bytes_total": 204800000}
{"type": "installed", "id": "tomoro-breakout"}
{"type": "error", "id": "tomoro-breakout", "msg": "download failed: 404"}
{"type": "launched", "id": "tomoro-breakout"}
```

### Download + Install flow

1. Fetch game metadata from backend (`GET /catalog/{id}`)
2. Stream download to `/var/lib/tomoro/games/{id}.tar.gz.part`
3. Send progress events at ~1s intervals
4. On complete: extract to `/var/lib/tomoro/games/{id}/`
5. Update `/var/lib/tomoro/manifest.json`
6. Send `{"type": "installed", ...}`

### Launch flow

Read manifest → `Command::new("steam-run").arg("/var/lib/tomoro/games/{id}/{binary}").spawn()`

### Manifest format

```json
{
  "games": {
    "tomoro-breakout": {
      "version": "1.0.0",
      "binary": "Breakout.x86_64",
      "installed_at": "2026-07-21T10:00:00Z"
    }
  }
}
```

### Key Rust dependencies

```toml
tokio = { features = ["full"] }
serde_json = "1"
reqwest = { features = ["stream"] }
tar = "0.4"
flate2 = "1"
```

---

## 3. Flutter Launcher Changes

### New screens

- `launcher/lib/screens/store_screen.dart` — grid of available games from backend
- `launcher/lib/screens/library_screen.dart` — installed games (replaces current home game grid)

### Store client

`launcher/lib/store_client.dart` — wraps Unix socket connection, sends commands, streams events as a Dart `Stream<Map>`.

### Navigation change

Home screen gets bottom nav or tab bar: **Library | Store**.

### Game launch

Library screen uses `store_client.dart` → `{"cmd": "launch", "id": "..."}` (daemon handles steam-run). Removes direct `Process.start` from Flutter for downloaded games. Nix-installed games (yogaflow, skyhopper) can still use existing mechanism or route through daemon too.

---

## 4. NixOS Integration

### New systemd service

`os/modules/services/tomoro-store.nix`:

```nix
systemd.services.tomoro-store = {
  wantedBy = [ "multi-user.target" ];
  after = [ "network-online.target" ];
  serviceConfig = {
    ExecStart = "${platform}/bin/tomoro-store";
    User = "tomoro";
    RuntimeDirectory = "tomoro";   # creates /run/tomoro/
    StateDirectory = "tomoro";     # creates /var/lib/tomoro/
  };
};
```

Import in `os/modules/kiosk/default.nix`.

### Add `tomoro-store` to platform crate outputs

`platform/default.nix` already builds all crates — add store crate there.

---

## 5. File Checklist

| File | Action |
|------|--------|
| `backend/main.py` | New — FastAPI catalog API |
| `backend/db.py` | New — SQLite helpers |
| `backend/seed.py` | New — seed existing games |
| `backend/requirements.txt` | New |
| `platform/crates/store/src/main.rs` | New — Rust daemon |
| `platform/crates/store/Cargo.toml` | New |
| `platform/Cargo.toml` | Add store member |
| `launcher/lib/store_client.dart` | New — socket client |
| `launcher/lib/screens/store_screen.dart` | New |
| `launcher/lib/screens/library_screen.dart` | New |
| `launcher/lib/screens/home_screen.dart` | Modify — add nav tabs |
| `os/modules/services/tomoro-store.nix` | New — systemd service |
| `os/modules/kiosk/default.nix` | Import tomoro-store service |

---

## 6. Verification

1. `cargo build` in `platform/` — store daemon compiles
2. `echo '{"cmd":"list"}' | socat - UNIX-CONNECT:/tmp/store.sock` — returns empty list
3. Seed backend with one game pointing to real tar.gz; send install command; verify extraction at `/var/lib/tomoro/games/{id}/`
4. Flutter store screen shows catalog
5. End-to-end: store screen → install → progress bar → library shows game → launch
