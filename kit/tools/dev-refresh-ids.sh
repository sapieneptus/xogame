#!/usr/bin/env bash
# Kit development only: let Godot generate its ID files (.uid, .import) for the
# kit and starter, and copy them back into kit/ so every game gets the same IDs.
# Run after adding or renaming scripts, sounds or pictures in kit/gamekit or kit/starter.
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot
tmp="$(mktemp -d)"
GAME_DIR="$tmp/game" "$(dirname "$0")/new-game.sh" >/dev/null
GAME_DIR="$tmp/game" "$(dirname "$0")/import.sh"
# Kit add-on files.
(cd "$tmp/game/addons/gamekit" && find . \( -name '*.uid' -o -name '*.import' \) -print) | while read -r f; do
  mkdir -p "$KIT_ROOT/kit/gamekit/$(dirname "$f")"
  cp "$tmp/game/addons/gamekit/$f" "$KIT_ROOT/kit/gamekit/$f"
done
# Starter files (everything except the synced kit and Godot's cache).
(cd "$tmp/game" && find . -path ./addons -prune -o -path ./.godot -prune -o \( -name '*.uid' -o -name '*.import' \) -print) | while read -r f; do
  cp "$tmp/game/$f" "$KIT_ROOT/kit/starter/$f"
done
"$GODOT_BIN" --headless --path "$KIT_ROOT/kit/studio" --import >/dev/null 2>&1 || true
rm -rf "$tmp"
kit_say "Godot ID files refreshed in kit/gamekit, kit/starter and kit/studio."
