#!/usr/bin/env bash
# Run the game's automatic checks and save screenshots to .test-output/.
# Usage: kit/tools/test.sh [name]   (name = only run tests whose file name contains it)
set -euo pipefail
source "$(dirname "$0")/env.sh"
kit_need_godot; kit_need_game
"$(dirname "$0")/sync-kit.sh"
"$(dirname "$0")/import.sh"

out="$KIT_ROOT/.test-output"
rm -rf "$out"; mkdir -p "$out"
filter="--kit-test"; [ -n "${1:-}" ] && filter="--kit-test=$1"
out_arg="$out"; [ "$KIT_OS" = "windows" ] && out_arg="$(cygpath -m "$out")"

cmd=("$GODOT_BIN" --path "$GAME_DIR" --rendering-driver opengl3 --audio-driver Dummy --windowed --position 40,40 -- "$filter" "--kit-out=$out_arg")
if [ "$KIT_OS" = "linux" ] && [ -z "${DISPLAY:-}" ]; then
  cmd=(xvfb-run -a -s "-screen 0 1280x720x24" "${cmd[@]}")
fi

log="$out/log.txt"
set +e
timeout 300 "${cmd[@]}" >"$log" 2>&1
code=$?
set -e

# Show the readable part of the log.
sed -n '/=== Game checks/,$p' "$log"
problems="$(grep -E "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Nonexistent function" "$log" || true)"
if [ -n "$problems" ]; then
  echo; echo "Script errors found:"; grep -E -A2 "SCRIPT ERROR|Parse Error|Failed to load|Invalid call|Invalid access|Nonexistent function" "$log" | head -40
  code=1
fi
if [ $code -eq 124 ]; then echo "The checks took too long and were stopped."; fi
if ! grep -q "RESULT: PASS" "$log"; then code=1; fi
echo
[ $code -eq 0 ] && echo "ALL CHECKS PASSED" || echo "CHECKS FAILED (full log: .test-output/log.txt)"
exit $code
