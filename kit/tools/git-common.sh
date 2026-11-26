# Git helpers shared by checkpoint/undo/update. Sourced, not run.

# Paths that belong to the kit. Updates replace these; everything else is the game's.
KIT_OWNED=(CLAUDE.md README.md .claude kit docs .gitignore .gitattributes)

kit_git() {
  # Commit even if git has no name/email configured on this computer.
  git -C "$KIT_ROOT" -c user.name="$(git -C "$KIT_ROOT" config user.name || echo 'Game Maker')" \
      -c user.email="$(git -C "$KIT_ROOT" config user.email || echo 'game-maker@localhost')" "$@"
}

is_kit_owned() {
  local p="$1" k
  for k in "${KIT_OWNED[@]}"; do
    [ "$p" = "$k" ] && return 0
    case "$p" in "$k"/*) return 0 ;; esac
  done
  return 1
}

# Save everything as a checkpoint commit + tag. Prints the tag name.
kit_checkpoint() {
  local msg="$1"
  kit_git add -A
  if ! kit_git diff --cached --quiet; then
    kit_git commit -q -m "$msg"
  fi
  local n tag
  n=$(git -C "$KIT_ROOT" tag -l 'save-*' | sed 's/save-//' | sort -n | tail -1)
  tag="save-$(( ${n:-0} + 1 ))"
  # Don't stack tags on a commit that already has one.
  local existing
  existing=$(git -C "$KIT_ROOT" tag --points-at HEAD -l 'save-*' | head -1)
  if [ -n "$existing" ]; then echo "$existing"; return; fi
  kit_git tag -a "$tag" -m "$msg"
  echo "$tag"
}
