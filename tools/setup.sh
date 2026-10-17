#!/usr/bin/env bash
# Recreate the local, non-committed working data from the original archives:
#   extracted/ss2-3.8.0     SS2 plugins + Main BA2s (textures skipped)
#   extracted/scripts       SS2 compiled .pex
#   extracted/wsfw-2.6.1    Workshop Framework plugin, BA2, .pex
#   extracted/papyrus-base  vanilla Papyrus sources (needed to build)
#   decompiled/             Champollion output for SS2 + WSFW (for research)
# Usage: bash tools/setup.sh [--base-only]
set -euo pipefail
cd "$(dirname "$0")/.."
. tools/paths.sh

echo "== Vanilla Papyrus sources"
rm -rf extracted/papyrus-base
mkdir -p extracted/papyrus-base
"$SEVENZIP" x -y -o"extracted/papyrus-base" "$BASE_SCRIPTS_ZIP" >/dev/null

if [ "${1:-}" = "--base-only" ]; then
  exit 0
fi

echo "== Sim Settlements 2"
mkdir -p extracted/ss2-3.8.0
"$SEVENZIP" x -y -o"extracted/ss2-3.8.0" "$SS2_ZIP" \
  "SS2 - Main.ba2" "SS2_XPAC_Chapter2 - Main.ba2" "SS2_XPAC_Chapter3 - Main.ba2" "SS2Extended - Main.ba2" \
  "*.esm" "*.esp" "MCM" -r >/dev/null
for ba2 in extracted/ss2-3.8.0/*Main.ba2; do
  "$PYTHON" -I tools/ba2_extract.py "$ba2" extracted/scripts
done

echo "== Workshop Framework"
mkdir -p extracted/wsfw-2.6.1
"$SEVENZIP" x -y -o"extracted/wsfw-2.6.1" "$WSFW_ZIP" "WorkshopFramework - Main.ba2" "WorkshopFramework.esm" >/dev/null
"$PYTHON" -I tools/ba2_extract.py "extracted/wsfw-2.6.1/WorkshopFramework - Main.ba2" extracted/wsfw-2.6.1

echo "== Decompiling"
"$CHAMPOLLION" extracted/scripts/Scripts -r -s -t -p decompiled
"$CHAMPOLLION" extracted/wsfw-2.6.1/Scripts -r -s -t -p decompiled
