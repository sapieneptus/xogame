#!/usr/bin/env bash
# Download the pinned Godot version into .tools/ (no installer, no admin rights).
# Safe to run again: does nothing if it is already there.
set -euo pipefail
source "$(dirname "$0")/env.sh"

if [ -f "$GODOT_BIN" ]; then
  kit_say "Godot $GODOT_VERSION is already installed."
  exit 0
fi

mkdir -p "$GODOT_DIR"
zip="$GODOT_DIR/godot.zip"
url="https://downloads.godotengine.org/?version=${GODOT_VERSION}&flavor=stable&slug=${GODOT_SLUG}&platform=${KIT_OS}"
kit_say "Downloading Godot $GODOT_VERSION (about 70 MB)..."
curl -fL -# --retry 3 -o "$zip" "$url" || kit_fail "The download did not work. Check the internet connection and try again."

kit_say "Unpacking..."
if command -v unzip >/dev/null 2>&1; then
  unzip -q -o "$zip" -d "$GODOT_DIR"
elif [ "$KIT_OS" = "windows" ]; then
  powershell.exe -NoProfile -Command "Expand-Archive -Force -Path '$(cygpath -w "$zip")' -DestinationPath '$(cygpath -w "$GODOT_DIR")'"
else
  kit_fail "No unzip tool found."
fi
rm -f "$zip"
chmod +x "$GODOT_BIN" 2>/dev/null || true

[ -f "$GODOT_BIN" ] || kit_fail "Godot unpacked, but not where expected ($GODOT_BIN)."
kit_say "Godot $GODOT_VERSION is ready."
