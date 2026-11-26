#!/usr/bin/env bash
# Put every file back the way it was at a checkpoint, without losing history
# (the undo is itself a new checkpoint, so it can be undone too).
# Usage: kit/tools/undo.sh            -> back to the previous checkpoint
#        kit/tools/undo.sh save-12    -> back to that checkpoint
#        kit/tools/undo.sh --list     -> show recent checkpoints
set -euo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/git-common.sh"
cd "$KIT_ROOT"

if [ "${1:-}" = "--list" ]; then
  git for-each-ref --sort=-creatordate --count=15 --format='%(refname:short)  %(creatordate:relative)  %(contents:subject)' 'refs/tags/save-*'
  exit 0
fi

target="${1:-}"
if [ -z "$target" ]; then
  if [ -n "$(git status --porcelain)" ]; then
    # Unsaved changes: go back to the last checkpoint.
    target=$(git describe --tags --abbrev=0 --match 'save-*' HEAD 2>/dev/null || true)
  else
    # Everything saved: go back to the checkpoint before the latest one.
    latest=$(git describe --tags --abbrev=0 --match 'save-*' HEAD 2>/dev/null || true)
    [ -n "$latest" ] && target=$(git describe --tags --abbrev=0 --match 'save-*' "$latest^" 2>/dev/null || true)
  fi
fi
[ -n "$target" ] || kit_fail "There is no earlier checkpoint to go back to."
git rev-parse -q --verify "refs/tags/$target" >/dev/null || kit_fail "No checkpoint called $target."

# Keep the current state first, so the undo itself can be undone.
before=$(kit_checkpoint "Before undo to $target")
git restore --source="$target" --staged --worktree -- :/
kit_checkpoint "Undo: back to $target" >/dev/null
kit_say "Done. Everything is back to checkpoint $target. (The state before this undo is saved as $before.)"
