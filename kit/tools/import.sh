#!/usr/bin/env bash
# Let Godot process new or changed files (sounds, pictures, scripts). Fast when nothing changed.
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot; kit_need_game
log="$(mktemp)"
if ! "$GODOT_BIN" --headless --path "$GAME_DIR" --import >"$log" 2>&1; then
  cat "$log"; rm -f "$log"; kit_fail "Godot could not process the game's files (see above)."
fi
if grep -E "SCRIPT ERROR|Parse Error|Failed to load script" "$log"; then
  rm -f "$log"; kit_fail "A game script has a mistake (see above)."
fi
rm -f "$log"
