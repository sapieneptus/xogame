#!/usr/bin/env bash
# Copy the kit's Godot add-on into the game (game/addons/gamekit).
# That folder belongs to the kit: it is replaced on every sync, so never edit it there.
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_game
dest="$GAME_DIR/addons/gamekit"
rm -rf "$dest"
mkdir -p "$GAME_DIR/addons"
cp -R "$KIT_ROOT/kit/gamekit" "$dest"
printf 'This folder is copied from kit/gamekit by kit/tools/sync-kit.sh.\nDo not edit it here; changes are overwritten.\n' > "$dest/DO_NOT_EDIT.txt"
