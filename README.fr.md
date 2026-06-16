**Français** · [English](README.md)

# Storm Codex Suite

Compagnon tout-en-un pour **Heroes of the Storm** : stats de replays, overlays OBS et patch notes
intégrés — un seul `docker compose up`, auto-hébergé, pré-rempli. Aucun scraping, aucune gymnastique
d'installation.

## Démarrage rapide

Il te faut **Docker Desktop** (Windows/macOS) ou Docker + Compose (Linux). Rien d'autre.

### 1. Lancer le site
```bash
git clone https://github.com/matella/storm-codex-suite
cd storm-codex-suite
cp .env.example .env          # Windows : copy .env.example .env
docker compose up -d
```
Ouvre **http://localhost:5102**. Le **référentiel** héros/talents/patches se **télécharge tout seul**
(un snapshot publié, rafraîchi ≤ 24 h après chaque patch HotS) — les patch notes et les données héros
fonctionnent immédiatement, sans scraping.

### 2. Te configurer
L'admin est **ouvert par défaut** (`ADMIN_TOKEN` vide) — pas de login sur un réseau local.
1. **Admin → My identity** — ton/tes pseudo(s) HotS, séparés par des virgules si plusieurs comptes.
2. **Admin → Upload tokens** — crée un token et copie-le.

### 3. Envoyer tes replays (uploader)
L'uploader ne grave **aucune** URL serveur ni token — tu les renseignes dans `.env`, puis tu démarres
son profil :
```bash
UPLOADER_TOKEN=<le token de l'étape 2>
REPLAYS_DIR=C:/Users/<toi>/Documents/Heroes of the Storm/Accounts
# UPLOADER_SERVER_URL=http://storm-codex:8088   ← laisse tel quel si tout tourne sur la même machine
```
```bash
docker compose --profile uploader up -d
```
Il rattrape tes replays existants (backfill), puis surveille les nouvelles parties. Les stats se
remplissent au fil des uploads — avant ça, « 0 héros » est normal.

> **Serveur sur une autre machine ?** Mets `UPLOADER_SERVER_URL=http://<ip-du-serveur>:5102` et lance
> l'uploader sur le PC de jeu. Sous Docker Desktop, autorise le partage du disque contenant les replays.

### 4. Overlays OBS (optionnel)
Ajoute des **Browser Sources** (1920×1080, fond transparent) :
`http://localhost:5102/queue` · `/ticker` · `/widget?me=<pseudo>` · `/now-playing`

## Ce qu'il y a dedans

| Service | Rôle |
|---|---|
| `storm-codex` (Rust) | tout le site : stats, overlays, patch notes — un seul front, une seule origine |
| `postgres` | base de données unique |
| `uploader` (optionnel) | uploader de replays headless (Docker) |

Les données de patch notes sont produites par **HotsPatchNotes** (ingestion côté mainteneur) et
livrées sous forme de **snapshot** versionné (GitHub Release) — voir `scripts/make-snapshot.sh` +
le workflow `snapshot`.

## Sauvegardes

```bash
./scripts/backup.sh                 # → backups/storm_codex-<date>.sql.gz  (garde les 14 derniers)
# restauration :
gunzip -c backups/<fichier>.sql.gz | docker exec -i storm-codex-pg psql -U storm -d storm_codex
```

## Notes
- Pur local par défaut (admin ouvert, pas d'auth avancée). Mets-le derrière un reverse proxy avec TLS
  si tu l'exposes un jour.
- L'overlay musique (`/now-playing`) n'affiche ta lecture Spotify live que si une instance Orpheus est
  branchée (`ORPHEUS_URL`) — désactivé par défaut dans le bundle public.
