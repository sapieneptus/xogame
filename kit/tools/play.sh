#!/usr/bin/env bash
# Open the game on this computer, full screen, in kid mode.
# Grown-up exit: hold Ctrl + Shift + Q for two seconds.
# Usage: kit/tools/play.sh [--windowed]   (--windowed: normal window, Esc/close work)
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot; kit_need_game
"$(dirname "$0")/sync-kit.sh"
"$(dirname "$0")/import.sh"
extra=()
[ "${1:-}" = "--windowed" ] && extra=(-- --windowed)
nohup "$GODOT_GUI_BIN" --path "$GAME_DIR" "${extra[@]}" >/dev/null 2>&1 &
disown || true
kit_say "The game is opening. To close it, hold Ctrl + Shift + Q for two seconds."
