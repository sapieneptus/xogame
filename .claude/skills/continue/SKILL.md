---
name: continue
description: Resume work on the game from STATE.md and build the next feature.
---

# Continue

1. Read `STATE.md`, `GAME.md`, `ROADMAP.md`. Say in one sentence where things stand and what's next. Confirm in one line.
2. If they ask for something new, check it against `kit/feasibility.md`, add it to `ROADMAP.md`, and keep to the current feature unless they really want to switch (then update `STATE.md`).
3. `kit/tools/checkpoint.sh "Before: <feature>"`.
4. Build the feature following `kit/playbooks/godot/PLAYBOOK.md`, including a test for it in `game/tests/`.
5. `kit/tools/test.sh`, then look at every screenshot. Fix problems yourself before involving the person. If you're stuck after three attempts, undo to the checkpoint and tell them plainly what you'll try differently.
6. `kit/tools/play.sh`, then the `playtest` skill.
7. If they report problems, fix and re-test. If it feels right, `checkpoint.sh "<feature> works"` and use `wrap-up`.
