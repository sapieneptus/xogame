#!/usr/bin/env bash
# Rebuild the kit's starter sounds (kit/gamekit/assets/sounds) from their recipes.
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot
tmp="$(mktemp -d)"
cp -R "$KIT_ROOT/kit/starter/." "$tmp/"
mkdir -p "$tmp/addons" && cp -R "$KIT_ROOT/kit/gamekit" "$tmp/addons/gamekit"
dest="$KIT_ROOT/kit/gamekit/assets/sounds"
[ "$KIT_OS" = "windows" ] && dest="$(cygpath -m "$dest")"
"$GODOT_BIN" --headless --path "$tmp" -s res://addons/gamekit/tools/make_sounds.gd -- "$dest" 2>&1 | grep -E "^made|ERROR" || true
rm -rf "$tmp"
