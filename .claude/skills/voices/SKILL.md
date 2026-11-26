---
name: voices
description: Plan and record voice lines for the game with the Voice Studio.
---

# Voice lines

1. Agree what the game should say. Short, warm, encouraging lines; one per moment (colours, "well done", the mascot's greeting...). Write them in `game/assets/voice/lines.txt` as `id | what to say | how to say it`. The id is what the game uses: `Kit.say("id")`.
2. Tips to give once: a quiet room, about a hand's width from the microphone, and say each line two or three different ways if they like - the last take is kept.
3. `kit/tools/studio.sh`. Explain the keys: Space to record and stop, Enter to listen, arrow keys to move between lines. Recordings are trimmed and levelled automatically.
4. When they're done, `kit/tools/test.sh`, then `play.sh` so they can hear the lines in the game.
5. Note in `game/assets/CREDITS.md` that the voice lines were recorded by them.
