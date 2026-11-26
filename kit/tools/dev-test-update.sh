#!/usr/bin/env bash
# Kit development only: end-to-end check of update.sh and undo.sh.
# Builds a fake "upstream kit" and a fake game in a temp folder, makes them
# diverge (including a conflicting edit to a kit file), then updates.
set -euo pipefail
source "$(dirname "$0")/env.sh"
SRC="$KIT_ROOT"
W="$(mktemp -d)"
G_ID=(-c user.name=dev -c user.email=dev@localhost)
pass=0; fail=0
ok()  { if eval "$1"; then echo "  ok: $2"; pass=$((pass+1)); else echo "  FAIL: $2"; fail=$((fail+1)); fi; }
link_godot() { mkdir -p "$1/.tools"; ln -s "$SRC/.tools/godot" "$1/.tools/godot"; }

echo "== Setting up upstream kit and a game clone in $W"
git clone -q "$SRC" "$W/upstream"; git -C "$W/upstream" checkout -q -B main
git clone -q "$W/upstream" "$W/game"; link_godot "$W/game"
(
  cd "$W/game"
  kit/tools/new-game.sh "Balloon Pop" >/dev/null
  cp kit/templates/STATE.md STATE.md
  echo "# Balloon Pop" > GAME.md
  kit/tools/checkpoint.sh "Game started" >/dev/null
  sed -i 's/const MAX_SHAPES := 18/const MAX_SHAPES := 12/' game/main.gd
  echo "- Claude added a local note (this should be replaced by the update)." >> CLAUDE.md
  mkdir -p .claude/skills/my-skill && echo "custom" > .claude/skills/my-skill/SKILL.md
  kit/tools/checkpoint.sh "Fewer shapes on screen" >/dev/null
)

echo "== Releasing kit 0.2.0 upstream (conflicts with the game's CLAUDE.md edit)"
(
  cd "$W/upstream"
  echo "- New rule from kit 0.2.0." >> CLAUDE.md
  printf '\n\n## Added in 0.2.0\nfunc kit_hello() -> String:\n\treturn "hello from 0.2.0"\n' >> kit/gamekit/kit.gd
  echo "0.2.0" > kit/VERSION
  printf '# Kit changelog\n\n## 0.2.0\n- Added Kit.kit_hello().\n- Game impact: none.\n\n' > /tmp/cl && tail -n +3 kit/CHANGELOG.md >> /tmp/cl && mv /tmp/cl kit/CHANGELOG.md
  echo "# updated in 0.2.0" >> kit/tools/update.sh
  git add -A; git "${G_ID[@]}" commit -q -m "Kit 0.2.0"
)

echo "== Updating the game"
(cd "$W/game" && KIT_UPSTREAM_URL="$W/upstream" kit/tools/update.sh)
cd "$W/game"
ok 'diff -q CLAUDE.md ../upstream/CLAUDE.md >/dev/null' "CLAUDE.md now matches the new kit (conflict resolved to kit)"
ok 'grep -q "MAX_SHAPES := 12" game/main.gd' "the game's own change survived"
ok 'grep -q kit_hello game/addons/gamekit/kit.gd' "the game's copy of the kit was refreshed"
ok '[ "$(cat kit/VERSION)" = 0.2.0 ]' "kit version is 0.2.0"
ok '[ -f STATE.md ] && grep -q "Balloon Pop" GAME.md' "STATE.md and GAME.md untouched"
ok '[ -f .claude/skills/my-skill/SKILL.md ]' "a locally added skill was kept"
ok '[ -z "$(git status --porcelain)" ]' "nothing left uncommitted"
ok 'kit/tools/test.sh >/dev/null 2>&1' "the game's checks pass after the update"

echo "== Undoing the update"
before=$(git for-each-ref --format='%(refname:short) %(contents:subject)' 'refs/tags/save-*' | awk '/Before kit update/{print $1; exit}')
kit/tools/undo.sh "$before" >/dev/null
ok '! grep -q kit_hello kit/gamekit/kit.gd' "undo brought back the old kit"
ok 'grep -q "MAX_SHAPES := 12" game/main.gd' "undo kept the game's change"

echo "== A game made with GitHub's 'Use this template' (no shared history)"
mkdir -p "$W/tgame"; git -C "$W/upstream" archive HEAD~1 | tar -x -C "$W/tgame"
git -C "$W/tgame" init -q; link_godot "$W/tgame"
(
  cd "$W/tgame"
  git add -A; git "${G_ID[@]}" commit -q -m "Initial commit"
  kit/tools/new-game.sh >/dev/null; kit/tools/checkpoint.sh "Game started" >/dev/null
  KIT_UPSTREAM_URL="$W/upstream" kit/tools/update.sh >/dev/null
)
cd "$W/tgame"
ok '[ "$(cat kit/VERSION)" = 0.2.0 ] && grep -q kit_hello game/addons/gamekit/kit.gd' "template-made game updated to 0.2.0"
ok 'kit/tools/test.sh >/dev/null 2>&1' "its checks pass"

echo; echo "update tests: $pass passed, $fail failed  (work folder: $W)"
[ "$fail" -eq 0 ]
