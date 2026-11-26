---
name: undo
description: Go back to an earlier checkpoint when something broke or they don't like a change.
---

# Undo

1. `kit/tools/undo.sh --list` to see recent checkpoints. Pick the one that matches what they want (by default the previous one).
2. Tell them in one sentence what you're about to go back to ("back to before we added the balloons").
3. `kit/tools/undo.sh <checkpoint>`. It keeps history, so the undo can itself be undone.
4. `kit/tools/test.sh`; then update `STATE.md` (current feature, next action) and tell them it's back how it was.
