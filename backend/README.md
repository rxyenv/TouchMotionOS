# Tomoro Store Backend

FastAPI + SQLite catalog API. MVP — replace later.

## Run locally

```bash
pip install -r requirements.txt
python seed.py          # populate catalog
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Env vars

| Var | Default | Purpose |
|-----|---------|---------|
| `DB_PATH` | `store.db` | SQLite file path |

## Deploy (Railway / Fly.io)

- Set `DB_PATH` to a persistent volume path (e.g. `/data/store.db`)
- Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

## Endpoints

```
GET  /catalog            → list all games
GET  /catalog/{id}       → single game
POST /devices/register   → {"device_id": "<uuid>"}
```

All game-browsing requests should include `X-Device-ID: <uuid>` header.
