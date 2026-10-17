# Local tool and input locations used by tools/setup.sh and tools/build.sh.
# Every value can be overridden with an environment variable, or permanently in
# tools/paths.local.sh (gitignored), which is sourced last.

# Game install that provides the Papyrus compiler and the vanilla script sources (Base.zip)
FO4_DIR="${FO4_DIR:-/e/SteamLibrary/steamapps/common/Fallout 4 377160}"
PAPYRUS_COMPILER="${PAPYRUS_COMPILER:-$FO4_DIR/Papyrus Compiler/PapyrusCompiler.exe}"
BASE_SCRIPTS_ZIP="${BASE_SCRIPTS_ZIP:-$FO4_DIR/Data/Scripts/Source/Base/Base.zip}"

SEVENZIP="${SEVENZIP:-/c/Program Files/7-Zip/7z.exe}"
CHAMPOLLION="${CHAMPOLLION:-/c/Users/Mike/Downloads/Champollion.v1.3.2/Champollion.exe}"
PYTHON="${PYTHON:-python}"

# Mod archives the research is based on (only needed by tools/setup.sh)
MOD_DOWNLOADS="${MOD_DOWNLOADS:-/d/ModOrganizer/Downloads}"
SS2_ZIP="${SS2_ZIP:-$MOD_DOWNLOADS/Sim Settlements 2 - All Chapters Pack 73394 3.8.0 2026-10-02T08-12Z q0wM4yC2N.zip}"
WSFW_ZIP="${WSFW_ZIP:-$MOD_DOWNLOADS/Workshop Framework 35004 2.6.1 2026-10-02T07-49Z mlHIzEBsE.zip}"

if [ -f "$(dirname "${BASH_SOURCE[0]}")/paths.local.sh" ]; then
  # shellcheck source=/dev/null
  . "$(dirname "${BASH_SOURCE[0]}")/paths.local.sh"
fi
