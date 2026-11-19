**Français** · [English](README.md)

# Storm Codex Suite

Storm Codex Suite lance l’application web [Storm Codex](https://github.com/matella/storm-codex) et PostgreSQL avec Docker Compose. La suite regroupe les statistiques de replays, les overlays OBS et les notes de patch. Pour consulter tes propres replays sous Windows, tu peux utiliser l’application autonome à la place.

## Démarrage rapide

Il te faut **Docker Desktop** (Windows/macOS) ou Docker + Compose (Linux). Rien d'autre.

### 1. Lancer le site
```bash
git clone https://github.com/matella/storm-codex-suite
cd storm-codex-suite
cp .env.example .env          # Windows : copy .env.example .env
docker compose up -d
```
Ouvre **http://localhost:5102**. Le serveur télécharge le référentiel en arrière-plan. Au premier lancement, les données des héros et les notes de patch peuvent mettre un moment à apparaître.

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

Les images Storm Codex actuelles utilisent le référentiel au format v1 publié par [HotsPatchNotes](https://github.com/matella/HeroesOfTheStormPatchNotes). Le serveur utilise cette source par défaut et vérifie les mises à jour toutes les 24 heures. L’entrée `REFERENTIAL_URL` dans le fichier Compose et l’exemple `.env` est héritée de l’ancienne version : les images actuelles l’ignorent. Pour changer de source, ajoute `REFDATA_URL` à l’environnement du service `storm-codex` dans un fichier de surcharge Compose. Voir le [guide d’exploitation](https://github.com/matella/storm-codex/blob/main/docs/spec/09-operations.md).

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
