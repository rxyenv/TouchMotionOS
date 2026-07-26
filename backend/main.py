from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from datetime import datetime, timezone
from typing import Optional
import db

app = FastAPI(title="Tomoro Store API")


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


# ── routes ───────────────────────────────────────────────────────────────────

@app.get("/catalog")
def list_catalog(x_device_id: Optional[str] = Header(default=None)):
    log_device(x_device_id)
    with db.get_conn() as conn:
        rows = conn.execute("SELECT * FROM games ORDER BY name").fetchall()
    return {"games": [row_to_game(r) for r in rows]}


@app.get("/catalog/{game_id}")
def get_game(game_id: str, x_device_id: Optional[str] = Header(default=None)):
    log_device(x_device_id)
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
