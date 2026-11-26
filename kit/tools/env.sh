# Shared settings for the kit's scripts. Sourced, not run.
# Works in Linux/macOS shells and in Git Bash on Windows (which Claude Code uses there).

GODOT_VERSION="4.7.2"

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GAME_DIR="${GAME_DIR:-$KIT_ROOT/game}"   # the game being made (override for kit development)
TOOLS_DIR="$KIT_ROOT/.tools"          # downloaded programs; never committed
GODOT_DIR="$TOOLS_DIR/godot/$GODOT_VERSION"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) KIT_OS="windows" ;;
  Darwin*)              KIT_OS="macos" ;;
  *)                    KIT_OS="linux" ;;
esac

case "$KIT_OS" in
  windows)
    GODOT_SLUG="win64.exe.zip"
    # The _console build prints to the terminal, which tests need.
    GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_win64_console.exe"
    GODOT_GUI_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_win64.exe" ;;
  macos)
    GODOT_SLUG="macos.universal.zip"
    GODOT_BIN="$GODOT_DIR/Godot.app/Contents/MacOS/Godot"
    GODOT_GUI_BIN="$GODOT_BIN" ;;
  linux)
    GODOT_SLUG="linux.x86_64.zip"
    GODOT_BIN="$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
    GODOT_GUI_BIN="$GODOT_BIN" ;;
esac

kit_say() { printf '%s\n' "$*"; }
kit_fail() { printf 'PROBLEM: %s\n' "$*" >&2; exit 1; }

kit_need_godot() {
  [ -x "$GODOT_BIN" ] || [ -f "$GODOT_BIN" ] || kit_fail "Godot is not installed yet. Run kit/tools/get-godot.sh first."
}

kit_need_game() {
  [ -f "$GAME_DIR/project.godot" ] || kit_fail "There is no game folder yet. The start wizard creates it."
}
