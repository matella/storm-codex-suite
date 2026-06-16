#!/usr/bin/env bash
# Produit le snapshot référentiel (referential.tar.gz) à partir d'une API HotsPatchNotes live.
# C'est un outil MAINTENEUR : il package héros/talents/patches + images pour que storm-codex soit
# autonome (les utilisateurs ne scrapent jamais). Lancé par la GitHub Action (cron) ou à la main.
#
# Usage : HPN_URL=http://localhost:5001 ./scripts/make-snapshot.sh [out_dir]
set -euo pipefail

HPN="${HPN_URL:-http://localhost:5001}"
OUT="${1:-./snapshot}"
mkdir -p "$OUT/images/heroes" "$OUT/images/battlegrounds"

echo "→ heroes / battlegrounds / patches list"
curl -fsS "$HPN/api/heroes"        > "$OUT/heroes.json"
curl -fsS "$HPN/api/battlegrounds" > "$OUT/battlegrounds.json"
curl -fsS "$HPN/api/patches?page=1&pageSize=500" > "$OUT/patches.json"

echo "→ talents (par héros) + détails patches"
python3 - "$HPN" "$OUT" <<'PY'
import json, os, sys, urllib.request
hpn, out = sys.argv[1], sys.argv[2]
def get(p): return json.load(urllib.request.urlopen(hpn + p))
talents = {}
for h in get("/api/heroes"):
    short = h.get("shortName")
    if not short: continue
    try: talents[short] = get(f"/api/heroes/{short}").get("talents")
    except Exception: pass
json.dump(talents, open(f"{out}/talents.json", "w"))
details = {}
for it in get("/api/patches?page=1&pageSize=500").get("items", []):
    iid = it.get("internalId")
    if not iid: continue
    try: details[iid] = get(f"/api/patches/{iid}")
    except Exception: pass
json.dump(details, open(f"{out}/patch-details.json", "w"))
print(f"  {len(talents)} héros talents, {len(details)} patch details")
PY

echo "→ images (portraits + battlegrounds)"
python3 - "$HPN" "$OUT" <<'PY'
import json, sys, urllib.request, os
hpn, out = sys.argv[1], sys.argv[2]
def dl(path):
    if not path or not path.startswith("/images/"): return
    rel = path[len("/images/"):]
    dest = os.path.join(out, "images", rel)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    try: urllib.request.urlretrieve(hpn + path, dest)
    except Exception: pass
for h in json.load(open(f"{out}/heroes.json")): dl(h.get("icon"))
for b in json.load(open(f"{out}/battlegrounds.json")): dl(b.get("imageUrl"))
PY

TARBALL="${OUT%/}.tar.gz"
tar -czf "$TARBALL" -C "$OUT" .
echo "✓ snapshot → $TARBALL ($(du -h "$TARBALL" | cut -f1))"
