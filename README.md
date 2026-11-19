**English** · [Français](README.fr.md)

# Storm Codex Suite

Storm Codex Suite runs the [Storm Codex](https://github.com/matella/storm-codex) web app and PostgreSQL with Docker Compose. It provides replay stats, OBS overlays, and patch notes. If you only want to browse your own replays on Windows, use the standalone app instead.

## Quick start

You need **Docker Desktop** (Windows/macOS) or Docker + Compose (Linux). Nothing else.

### 1. Launch the site
```bash
git clone https://github.com/matella/storm-codex-suite
cd storm-codex-suite
cp .env.example .env          # Windows: copy .env.example .env
docker compose up -d
```
Open **http://localhost:5102**. The server downloads reference data in the background. On first start, hero data and patch notes may take a moment to appear.

### 2. Configure yourself
Admin is **open by default** (`ADMIN_TOKEN` empty) — no login on a local network.
1. **Admin → My identity** — your HotS name(s), comma-separated for multiple accounts.
2. **Admin → Upload tokens** — create a token and copy it.

### 3. Send your replays (uploader)
The uploader bakes **no** server URL or token — you set them in `.env`, then start its profile:
```bash
UPLOADER_TOKEN=<token from step 2>
REPLAYS_DIR=C:/Users/<you>/Documents/Heroes of the Storm/Accounts
# UPLOADER_SERVER_URL=http://storm-codex:8088   ← leave as-is if everything runs on one machine
```
```bash
docker compose --profile uploader up -d
```
It backfills your existing replays, then watches for new games. Stats fill in as replays upload —
before that, "0 heroes" is normal.

> **Server on a different machine?** Set `UPLOADER_SERVER_URL=http://<server-ip>:5102` and run the
> uploader on the gaming PC. Under Docker Desktop, allow file sharing for the drive holding the replays.

### 4. OBS overlays (optional)
Add **Browser Sources** (1920×1080, transparent background):
`http://localhost:5102/queue` · `/ticker` · `/widget?me=<name>` · `/now-playing`

## What's inside

| Service | Role |
|---|---|
| `storm-codex` (Rust) | the whole site: stats, overlays, patch notes — one front, one origin |
| `postgres` | single shared DB |
| `uploader` (optional) | headless replay uploader (Docker) |

Current Storm Codex images use the schema-v1 releases from [HotsPatchNotes](https://github.com/matella/HeroesOfTheStormPatchNotes). The server uses that source by default and checks for updates every 24 hours. The `REFERENTIAL_URL` entry in this repository's Compose file and sample env is legacy; current images ignore it. To override the source, add `REFDATA_URL` to the `storm-codex` service environment in a Compose override. See the [Storm Codex operations guide](https://github.com/matella/storm-codex/blob/main/docs/spec/09-operations.md).

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
