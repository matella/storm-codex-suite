#!/usr/bin/env bash
# Régénère le snapshot référentiel depuis le HotsPatchNotes LOCAL (données accumulées, riches) et
# remplace l'asset `referential.tar.gz` de la Release consommée par REFERENTIAL_URL. Conçu pour
# tourner en cron sur le box (le soir). Aucune dépendance à `gh` : API GitHub via curl + PAT.
#
# Secret : crée ~/.snapshot-env avec une ligne `GH_TOKEN=<PAT contents:write sur le repo>`.
# (Le PAT n'apparaît jamais ici ; le script le lit depuis ce fichier.)
set -euo pipefail

REPO="${REPO:-matella/storm-codex-suite}"
TAG="${TAG:-referential-1}"          # Release dont on remplace l'asset (marquée "latest")
HPN_URL="${HPN_URL:-http://localhost:5001}"
DIR="$(cd "$(dirname "$0")" && pwd)"

[ -f "$HOME/.snapshot-env" ] && . "$HOME/.snapshot-env"
: "${GH_TOKEN:?GH_TOKEN manquant — mets-le dans ~/.snapshot-env (PAT contents:write sur $REPO)}"

echo "[$(date -Iseconds)] génération du snapshot depuis $HPN_URL"
HPN_URL="$HPN_URL" "$DIR/make-snapshot.sh" /tmp/snapshot >/dev/null
mv -f /tmp/snapshot.tar.gz /tmp/referential.tar.gz

api() { curl -fsSL -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/vnd.github+json" "$@"; }

REL="$(api "https://api.github.com/repos/$REPO/releases/tags/$TAG")"
REL_ID="$(printf '%s' "$REL" | python3 -c "import sys,json;print(json.load(sys.stdin)['id'])")"
ASSET_ID="$(printf '%s' "$REL" | python3 -c "import sys,json;print(next((a['id'] for a in json.load(sys.stdin).get('assets',[]) if a['name']=='referential.tar.gz'),''))")"

# Remplace l'asset : supprime l'ancien (les noms doivent être uniques dans une Release) puis upload.
[ -n "$ASSET_ID" ] && api -X DELETE "https://api.github.com/repos/$REPO/releases/assets/$ASSET_ID" >/dev/null || true
curl -fsSL -H "Authorization: Bearer $GH_TOKEN" -H "Content-Type: application/gzip" \
  --data-binary @/tmp/referential.tar.gz \
  "https://uploads.github.com/repos/$REPO/releases/$REL_ID/assets?name=referential.tar.gz" >/dev/null

echo "[$(date -Iseconds)] ✓ snapshot publié → $REPO ($TAG), $(du -h /tmp/referential.tar.gz | cut -f1)"
