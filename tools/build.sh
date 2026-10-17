#!/usr/bin/env bash
# Compile the script, build the plugin and package an MO2-installable zip in dist/
# (the file to upload to Nexus).
# Usage: bash tools/build.sh
set -euo pipefail
cd "$(dirname "$0")/.."
. tools/paths.sh

STAGE=build/package

if [ ! -f extracted/papyrus-base/ScriptObject.psc ]; then
  bash tools/setup.sh --base-only
fi

rm -rf build dist
mkdir -p "$STAGE/Scripts/Source/User" dist

# source/stubs only provides SS2 type signatures for the compiler; it is never shipped.
# F4SE sources are deliberately not on the import path so the mod can't come to depend on F4SE.
"$PAPYRUS_COMPILER" "AISS2LearnOnTheJob:JobTrainingQuest" -f="Institute_Papyrus_Flags.flg" \
  -i="source/scripts;source/stubs;extracted/papyrus-base" -o="$STAGE/Scripts" -op

"$PYTHON" -I tools/build_plugin.py "$STAGE/SS2LearnOnTheJob.esp"
cp -r source/scripts/. "$STAGE/Scripts/Source/User/"

(cd "$STAGE" && "$SEVENZIP" a -tzip "../../dist/SS2LearnOnTheJob.zip" . >/dev/null)
echo "Built dist/SS2LearnOnTheJob.zip"
