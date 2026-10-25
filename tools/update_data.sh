#!/usr/bin/env bash
# Re-downloads the Spiritfarer Fandom Wiki pages and rebuilds src/data/spiritfarer.json.
# Run this when the wiki has been updated, then `npm run build` (and `python3 generate_sh.py`).
set -e
cd "$(dirname "$0")/.."
CACHE=tools/wiki_cache
mkdir -p "$CACHE"
echo "⬇️   Downloading wiki pages..."
python3 -I tools/dump_wiki.py "$CACHE" Islands Locations Events Quests "Spirit Characters" Mechanics
echo "🔧  Building dataset..."
python3 -I tools/build_data.py "$CACHE" src/data/spiritfarer.json
