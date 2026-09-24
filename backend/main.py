from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from datetime import datetime, timezone
from typing import Optional
from urllib.error import URLError
from urllib.request import Request, urlopen
import json
import db

app = FastAPI(title="Tomoro Store API")

GAME_MANIFESTS = {
    "Mudmaker": "https://allrealapps.blob.core.windows.net/game-content/Mudmaker/version.json",
}

@app.on_event("startup")
def startup():
    db.init_db()


# ── models ──────────────────────────────────────────────────────────────────

class DeviceRegister(BaseModel):
    device_id: str


# ── helpers ─────────────────────────────────────────────────────────────────

def log_device(device_id: Optional[str]):
    if not device_id:
        return
    now = datetime.now(timezone.utc).isoformat()
    with db.get_conn() as conn:
        conn.execute(
            "INSERT INTO devices(device_id, last_seen) VALUES(?,?) "
            "ON CONFLICT(device_id) DO UPDATE SET last_seen=excluded.last_seen",
            (device_id, now),
        )


def row_to_game(row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "description": row["description"],
        "cover_url": row["cover_url"],
        "download_url": row["download_url"],
        "version": row["version"],
        "size_bytes": row["size_bytes"],
        "binary": row["binary"],
    }


def manifest_to_game(game_id: str, manifest_url: str) -> dict:
    """Adapt a public game-manager version.json to the Store catalog."""
    try:
        with urlopen(manifest_url, timeout=8) as response:
            manifest = json.load(response)
        download_url = manifest["url"]
        version = manifest["version"]
        binary = manifest["executableName"]
        if not all(isinstance(value, str) and value for value in (download_url, version, binary)):
            raise ValueError("incomplete game manifest")
        if not download_url.startswith("https://"):
            raise ValueError("game download must use HTTPS")
    except (URLError, OSError, ValueError, KeyError, TypeError) as exc:
        raise HTTPException(status_code=502, detail=f"{game_id} manifest unavailable") from exc

    size_bytes = 0
    try:
        with urlopen(Request(download_url, method="HEAD"), timeout=8) as response:
            size_bytes = int(response.headers.get("Content-Length", "0"))
    except (URLError, OSError, ValueError):
        pass

    return {
        "id": game_id,
        "name": manifest.get("gameName") or game_id,
        "description": manifest.get("description") or "",
        "cover_url": "",
        "download_url": download_url,
        "version": version,
        "size_bytes": size_bytes,
        "binary": binary,
    }


# ── routes ───────────────────────────────────────────────────────────────────

@app.get("/catalog")
def list_catalog(x_device_id: Optional[str] = Header(default=None)):
    log_device(x_device_id)
    with db.get_conn() as conn:
        rows = conn.execute("SELECT * FROM games ORDER BY name").fetchall()
    games = {row["id"]: row_to_game(row) for row in rows}
    for game_id, manifest_url in GAME_MANIFESTS.items():
        games[game_id] = manifest_to_game(game_id, manifest_url)
    return {"games": sorted(games.values(), key=lambda game: game["name"].lower())}


@app.get("/catalog/{game_id}")
def get_game(game_id: str, x_device_id: Optional[str] = Header(default=None)):
    log_device(x_device_id)
    if game_id in GAME_MANIFESTS:
        return manifest_to_game(game_id, GAME_MANIFESTS[game_id])
    with db.get_conn() as conn:
        row = conn.execute("SELECT * FROM games WHERE id=?", (game_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="game not found")
    return row_to_game(row)


@app.post("/devices/register")
def register_device(body: DeviceRegister):
    now = datetime.now(timezone.utc).isoformat()
    with db.get_conn() as conn:
        conn.execute(
            "INSERT INTO devices(device_id, last_seen) VALUES(?,?) "
            "ON CONFLICT(device_id) DO UPDATE SET last_seen=excluded.last_seen",
            (body.device_id, now),
        )
    return {"registered": body.device_id, "last_seen": now}
