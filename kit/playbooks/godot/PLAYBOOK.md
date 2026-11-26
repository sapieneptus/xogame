# Playbook: Godot games played on this computer

Engine: Godot 4.7.2 (pinned in `kit/tools/env.sh`), GDScript, 2D, "GL Compatibility" renderer (runs on older laptops and Fire tablets).

## The game folder
- `game/` is a normal Godot project. `main.tscn` + `main.gd` is the starting scene.
- `game/addons/gamekit/` is the kit, copied in by `sync-kit.sh`. Never edit it there. Use it through `Kit` and its classes:
  - `Kit.play("pop", pitch)` sound effects (game's `assets/sounds/` first, then the kit's: pop, chime, fanfare, sparkle, boing, whoosh, tick, bubble, tada, music_box_loop).
  - `Kit.say("line_id")` recorded voice line from `assets/voice/`; silent (returns false) until recorded, so build with it from day one.
  - `Kit.play_music(name)`, `Kit.celebrate(position)` (confetti), `Kit.COLORS` (named colours that match voice line ids), `Kit.HAPPY_PITCHES` (notes that always sound nice together).
  - `KitShape` (big bright shapes drawn in code), `KitMascot` (friendly character: `hop()`, `cheer()`, `look_at_point()`; set `body_color`, `mascot_name`).
- Kid mode is automatic: full screen, close button and Alt+F4 ignored, grown-up exit = hold Ctrl+Shift+Q for 2 seconds. The Windows key and Alt+Tab can't be blocked by any game; a grown-up stays nearby.

## The loop for every feature
1. `kit/tools/checkpoint.sh "Before: <feature>"`.
2. Make the change in small steps. Prefer drawing in code and the kit's sounds over new files.
3. Add or update a test in `game/tests/test_<feature>.gd` (extends `KitTest`; see `game/tests/test_smoke.gd` and `game/addons/gamekit/tests/kit_test.gd`). Test what the child does (`tap`, `press`, `drag`, `mash`) and what they should see (`check`, `difference(before, after, around(point))`). Take a `shot()` at each important moment.
4. `kit/tools/test.sh`. It fails on any failed check or script error.
5. Open and look at every screenshot. Tests prove logic; only looking catches "it works but looks wrong" (wrong colour, hidden behind something, off screen, too small, overlapping the mascot). Describe to yourself what a 2-year-old would see.
6. `kit/tools/play.sh` and hand over to the `playtest` skill.

## Designing for young children (defaults for ages 2-5)
- No reading needed. Pictures, sounds and voice carry everything.
- Every input does something nice within a tenth of a second: any key, any tap, a sloppy drag. Nothing is "wrong".
- Huge targets: at least 140 px across on a 1280x720 screen. Keep important things away from the edges.
- No failing, no timers, no losing progress. Mistakes get a gentle "boing", never a buzzer.
- Rewards often: something special every 30-60 seconds of play (confetti, fanfare, mascot cheer, a voice line). Show progress visually (stars filling up).
- Mascot reacts to what the child does. Kids love characters.
- Short loops (a minigame finishes in 1-3 minutes) and calm music.
- Rate-limit mashing so it stays pleasant (see `MIN_SECONDS_BETWEEN_POPS` in the starter).
- Age 2: one thing to do per screen, cause and effect. Age 4: simple goals (find, match, sort, count to five), two or three steps.
- Learning content (colours, shapes, letters, numbers, animals) is a bonus, best delivered by voice: "Blue!" when they tap blue.

## Sounds and pictures
- Sounds: the kit's sounds first. For new ones, write a recipe like those in `game/addons/gamekit/tools/make_sounds.gd` into `game/tools/sounds.gd` and generate into `game/assets/sounds/`.
- Voices: the `voices` skill and Voice Studio; the person records them.
- Pictures: draw in code (shapes, the mascot) first. Their drawings or photos can go in `game/assets/pictures/` (ask before using photos of people).
- Every file not made by the kit gets a line in `game/assets/CREDITS.md`. Only use things that are theirs, made by the kit, or clearly public domain (CC0).

## Never
- Network calls, accounts, analytics, ads, links to websites.
- Editing kit files to make the game work. If the kit truly needs a change, tell the person it's a kit improvement and write it down in `ROADMAP.md` under "Kit wishes".
