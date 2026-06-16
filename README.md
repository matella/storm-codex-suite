# Storm Codex Suite

All-in-one **Heroes of the Storm** companion: replay stats, OBS overlays, and integrated patch
notes — one `docker compose up`, self-hosted, pre-seeded. No scraping, no setup gymnastics.

## Run it

```bash
git clone https://github.com/matella/storm-codex-suite
cd storm-codex-suite
cp .env.example .env        # tweak if you want (all defaults are sane for local use)
docker compose up -d
```

Open **http://localhost:5102**. A first-run wizard walks you through:
1. **Set your in-game name(s)** (Admin → My identity).
2. **Connect the uploader** (Admin → Upload tokens) — see below.
3. **Add OBS overlays** (optional): `/queue`, `/ticker`, `/widget?me=<name>`, `/now-playing`.

The hero/talent/patch **referential is auto-downloaded** (a published snapshot) — patch notes and
hero data work out of the box, and refresh automatically (≤24 h after a new HotS patch).

## The uploader (sends your replays)

Replays live on your **gaming PC**. Two options:

- **Native (recommended, Windows):** download the uploader `.exe`, point it at the server URL + your
  upload token + your `Documents/Heroes of the Storm/Accounts` folder. Watches + backfills.
- **Headless Docker** (tout-Docker setups, on the gaming PC): set `UPLOADER_TOKEN` + `REPLAYS_DIR`
  in `.env`, then `docker compose --profile uploader up -d`.

## What's inside

| Service | Role |
|---|---|
| `storm-codex` (Rust) | the whole site: stats, overlays, patch notes — one front, one origin |
| `postgres` | single shared DB |
| `uploader` (optional) | headless replay uploader (Docker) |

Patch-notes data is produced by **HotsPatchNotes** (maintainer-side ingestion) and shipped as a
versioned **snapshot** (GitHub Release) — see `scripts/make-snapshot.sh` + the `snapshot` workflow.

## Backups

```bash
./scripts/backup.sh                 # → backups/storm_codex-<date>.sql.gz  (keeps last 14)
# restore:
gunzip -c backups/<file>.sql.gz | docker exec -i storm-codex-pg psql -U storm -d storm_codex
```

## Notes
- Pure-local by default (open admin mode, no advanced auth). Put it behind a reverse proxy with TLS
  if you ever expose it.
- Music overlay (`/now-playing`) shows your live Spotify track only if an Orpheus instance is wired
  (`ORPHEUS_URL`) — off by default in the public bundle.
