#!/usr/bin/env bash
# Create game/ from the starter project. Refuses if a game already exists.
set -euo pipefail
source "$(dirname "$0")/env.sh"
[ -e "$GAME_DIR/project.godot" ] && kit_fail "A game already exists in $GAME_DIR. Not touching it."
mkdir -p "$GAME_DIR"
cp -R "$KIT_ROOT/kit/starter/." "$GAME_DIR/"
"$(dirname "$0")/sync-kit.sh"
if [ -n "${1:-}" ]; then
  sed -i.bak "s/^config\/name=.*/config\/name=\"$1\"/" "$GAME_DIR/project.godot" && rm -f "$GAME_DIR/project.godot.bak"
fi
kit_say "New game created from the starter."
