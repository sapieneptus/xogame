#!/usr/bin/env bash
# Bring in the latest version of the Game Maker kit without touching the game.
# Kit files (CLAUDE.md, README.md, .claude/, kit/, docs/) take the new version;
# game files (game/, STATE.md, GAME.md, ROADMAP.md, ...) always keep yours.
set -euo pipefail
TOOLS="${KIT_TOOLS:-$(cd "$(dirname "$0")" && pwd)}"
# This script replaces itself during the update, so run from a temporary copy.
if [ -z "${KIT_UPDATE_COPY:-}" ]; then
  tmp="$(mktemp)"; cp "$0" "$tmp"
  KIT_TOOLS="$TOOLS" KIT_UPDATE_COPY="$tmp" exec bash "$tmp" "$@"
fi
trap 'rm -f "$KIT_UPDATE_COPY"' EXIT
source "$TOOLS/env.sh"; source "$TOOLS/git-common.sh"
cd "$KIT_ROOT"

url="${KIT_UPSTREAM_URL:-$(cat kit/UPSTREAM 2>/dev/null || true)}"
branch="${KIT_UPSTREAM_BRANCH:-main}"
[ -n "$url" ] || kit_fail "kit/UPSTREAM does not say where updates come from."
old_version=$(cat kit/VERSION 2>/dev/null || echo "unknown")

before=$(kit_checkpoint "Before kit update")
kit_say "Saved checkpoint $before. Fetching the latest kit..."
git fetch -q "$url" "$branch" || kit_fail "Could not download the update. Check the internet connection."
new_version=$(git show FETCH_HEAD:kit/VERSION 2>/dev/null || echo "unknown")
if git merge-base --is-ancestor FETCH_HEAD HEAD 2>/dev/null; then
  kit_say "Already up to date (kit version $old_version)."
  exit 0
fi

merge_args=(--no-ff --no-commit FETCH_HEAD)
if ! git merge-base HEAD FETCH_HEAD >/dev/null 2>&1; then
  merge_args=(--allow-unrelated-histories "${merge_args[@]}")   # repo made with "Use this template"
fi
set +e
kit_git merge -q "${merge_args[@]}" >/dev/null 2>&1
set -e

# Resolve any conflicts by ownership. No human judgement needed.
while IFS= read -r path; do
  [ -z "$path" ] && continue
  if is_kit_owned "$path"; then
    if git cat-file -e "FETCH_HEAD:$path" 2>/dev/null; then
      git checkout -q FETCH_HEAD -- "$path"
    else
      git rm -q --cached -- "$path" 2>/dev/null || true; rm -f -- "$path"
    fi
    kit_say "  kit file updated: $path"
  else
    if git cat-file -e "HEAD:$path" 2>/dev/null; then
      git checkout -q HEAD -- "$path"
    else
      git rm -q --cached -- "$path" 2>/dev/null || true; rm -f -- "$path"
    fi
    kit_say "  kept your version: $path"
  fi
  git add -A -- "$path" 2>/dev/null || true
done < <(git diff --name-only --diff-filter=U)

# Kit files take the new kit's version, even where git quietly merged both sides' edits.
# (Extra files added locally inside kit folders, e.g. a custom skill, are left alone.)
for k in "${KIT_OWNED[@]}"; do
  if git cat-file -e "FETCH_HEAD:$k" 2>/dev/null; then
    git checkout -q FETCH_HEAD -- "$k"
  fi
done
# Never let an update bring in a game folder or overwrite the game's own files.
for g in game STATE.md GAME.md ROADMAP.md roadmap.html; do
  if git cat-file -e "HEAD:$g" 2>/dev/null; then git checkout -q HEAD -- "$g"; fi
done

kit_git add -A
kit_git commit -q -m "Update Game Maker kit: $old_version -> $new_version" || true
if [ -f "$GAME_DIR/project.godot" ]; then "$TOOLS/sync-kit.sh"; kit_git add -A; kit_git commit -q -m "Sync kit into game" || true; fi
after=$(kit_checkpoint "Kit updated to $new_version")

kit_say "Kit updated from $old_version to $new_version (checkpoint $after)."
kit_say "What changed (kit/CHANGELOG.md):"
awk -v old="$old_version" '/^## /{ if (index($0, old)) exit } { print }' kit/CHANGELOG.md 2>/dev/null | sed -n '1,40p'
kit_say "If anything goes wrong, undo with: kit/tools/undo.sh $before"
