---
name: start
description: First-session wizard for a new game. Use when STATE.md does not exist yet.
---

# Start wizard

Goal of this session: something fun on screen within about 10 minutes, then a realistic version 1 and a roadmap. Warm, plain, one question at a time.

## 1. Set up (say what you are doing in one line each)
- `kit/tools/get-godot.sh` (downloads the game engine, about 70 MB; "Godot is the free program games are built with").
- `kit/tools/new-game.sh "<working title or My Game>"`, then `kit/tools/test.sh`. If anything fails, fix it before going on; don't show the person errors.

## 2. First win: a toy, straight away
- Tell them: "Before we plan anything, here is a little toy to try. Every tap or key makes a shape pop up; ten pops makes a party. To close it, hold Ctrl + Shift + Q for two seconds."
- `kit/tools/play.sh`. Ask them to try it (and hand it to the kids if they are around), then close it.
- Ask what the kids did and liked. This is real playtest data: note it in `GAME.md` later.

## 3. Discover (at most five questions, one at a time)
- What is the game, in a sentence or two? (Offer to grow it out of the toy if they have no idea yet.)
- Who will play, and how old are they? Map age to defaults from the playbook's "Designing for young children".
- Is there a character? Offer the kit's mascot: they can pick its name and colour.
- Would they like to record voice lines themselves? (The kit has a recording studio.)
- What would make them proud of version 1?

## 4. Feasibility and scope
- Check each idea against `kit/feasibility.md`. Yellow or red: say so plainly in one or two sentences and offer the nearest simple alternative. Don't argue them into disappointment, but don't agree to what won't work.
- Version 1 = at most three features, each with a "done when..." sentence they can check by playing.
- Everything else goes in `ROADMAP.md` under v2, v3 or "not doing". It is fine and good to say "great idea, that's for version 2".
- Write `GAME.md` and `ROADMAP.md` from `kit/templates/`. Fill `kit/templates/roadmap.html` into `roadmap.html` and offer to open it. Ask if version 1 feels right; adjust.

## 5. Finish
- Create `STATE.md` from `kit/templates/STATE.md`: phase `building`, next_action = first v1 feature.
- Use the `wrap-up` skill.
