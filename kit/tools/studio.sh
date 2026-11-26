#!/usr/bin/env bash
# Open the Voice Studio to record the game's voice lines (game/assets/voice/lines.txt).
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot; kit_need_game
voice="$GAME_DIR/assets/voice"
mkdir -p "$voice"
[ "$KIT_OS" = "windows" ] && voice="$(cygpath -m "$voice")"
"$GODOT_BIN" --headless --path "$KIT_ROOT/kit/studio" --import >/dev/null 2>&1 || true
nohup "$GODOT_GUI_BIN" --path "$KIT_ROOT/kit/studio" -- "--voice-dir=$voice" >/dev/null 2>&1 &
disown || true
kit_say "The Voice Studio is opening."
