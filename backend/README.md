# Tomoro Store Backend

FastAPI + SQLite catalog API. The Mudmaker entry is read from its public
`version.json` on each catalog request, so uploading a new current build to the
game manager updates the Store without reseeding the database. Add another
public manifest URL to `GAME_MANIFESTS` in `main.py` to list another game.

## Run locally

```bash
pip install -r requirements.txt
python seed.py          # optional: populate the legacy SQLite catalog
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

The appliance starts this API on `127.0.0.1:8000` through the
`tomoro-catalog` service. The Store daemon downloads ZIP builds from the
manifest and the launcher starts installed games in the kiosk session.

The manager's `/api/games` endpoint requires authentication. Use public
`version.json` links here; do not put a manager password in the launcher.
