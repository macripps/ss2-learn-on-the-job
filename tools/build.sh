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

# Imports, flags and output dir ($STAGE/Scripts) live in the project file, shared with the VS Code extension.
"$PAPYRUS_COMPILER" SS2LearnOnTheJob.ppj

"$PYTHON" -I tools/build_plugin.py "$STAGE/SS2LearnOnTheJob.esp"
cp -r source/scripts/. "$STAGE/Scripts/Source/User/"

(cd "$STAGE" && "$SEVENZIP" a -tzip "../../dist/SS2LearnOnTheJob.zip" . >/dev/null)
echo "Built dist/SS2LearnOnTheJob.zip"
