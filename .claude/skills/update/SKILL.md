---
name: update
description: Bring in the latest version of the Game Maker kit (new tools, fixes, sounds) without touching the game.
---

# Update the kit

1. Tell them: "I'll fetch the latest Game Maker kit. Your game won't be changed, and I'll save a checkpoint first."
2. `kit/tools/update.sh`. It saves a checkpoint, merges the new kit, settles any clashes automatically (kit files take the new version, game files keep theirs) and lists what changed.
3. `kit/tools/test.sh`. If checks fail because the kit changed how something works, read `kit/CHANGELOG.md` for the change and fix the game's own files to match. If you can't, `kit/tools/undo.sh <checkpoint it printed>` and tell them the update will wait.
4. Summarise what's new in one or two plain sentences (only what matters to them).
