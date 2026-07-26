import sqlite3
import os

DB_PATH = os.environ.get("DB_PATH", "store.db")


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with get_conn() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS games (
                id          TEXT PRIMARY KEY,
                name        TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                cover_url   TEXT NOT NULL DEFAULT '',
                download_url TEXT NOT NULL,
                version     TEXT NOT NULL,
                size_bytes  INTEGER NOT NULL DEFAULT 0,
                binary      TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS devices (
                device_id  TEXT PRIMARY KEY,
                last_seen  TEXT NOT NULL
            );
        """)
