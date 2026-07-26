"""Seed the catalog with known games. Run once after init."""
import db

GAMES = [
    {
        "id": "tomoro-skyhopper",
        "name": "SkyHopper",
        "description": "Dodge obstacles in the sky.",
        "cover_url": "",
        "download_url": "https://cdn.example.com/tomoro-skyhopper-v1.0.tar.gz",
        "version": "1.0.0",
        "size_bytes": 104857600,
        "binary": "SkyHopper.x86_64",
    },
    {
        "id": "tomoro-yogaflow",
        "name": "YogaFlow",
        "description": "Full-body pose-guided yoga experience.",
        "cover_url": "",
        "download_url": "https://cdn.example.com/tomoro-yogaflow-v1.0.tar.gz",
        "version": "1.0.0",
        "size_bytes": 204800000,
        "binary": "YogaFlow.x86_64",
    },
]


def main():
    db.init_db()
    with db.get_conn() as conn:
        for g in GAMES:
            conn.execute(
                """INSERT INTO games(id, name, description, cover_url, download_url, version, size_bytes, binary)
                   VALUES(:id,:name,:description,:cover_url,:download_url,:version,:size_bytes,:binary)
                   ON CONFLICT(id) DO UPDATE SET
                     name=excluded.name, description=excluded.description,
                     cover_url=excluded.cover_url, download_url=excluded.download_url,
                     version=excluded.version, size_bytes=excluded.size_bytes,
                     binary=excluded.binary""",
                g,
            )
    print(f"Seeded {len(GAMES)} games.")


if __name__ == "__main__":
    main()
