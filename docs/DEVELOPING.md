# Developing the kit

This repo is the kit itself. Games are clones of it with a `game/` folder added.

## Ownership (what makes updates conflict-free)
- Kit-owned (replaced on update): `CLAUDE.md`, `README.md`, `.claude/`, `kit/`, `docs/`, `.gitignore`, `.gitattributes`. Listed in `kit/tools/git-common.sh` (`KIT_OWNED`).
- Game-owned (never touched by updates): `game/`, `STATE.md`, `GAME.md`, `ROADMAP.md`, `roadmap.html`, anything else at the root.
- `game/addons/gamekit/` is a copy of `kit/gamekit/`, refreshed by `sync-kit.sh` (every test/play run and after updates). Upstream never contains `game/`, so merges never touch it.
- The starter (`kit/starter/`) is copied once into `game/` by `new-game.sh`. Improving the starter doesn't change existing games; put shared behaviour in `kit/gamekit/` instead.

## Working on it
- `kit/tools/get-godot.sh` once.
- Test the starter + kit without creating `game/` in this repo:
  `GAME_DIR=/some/tmp/dir kit/tools/new-game.sh && GAME_DIR=/some/tmp/dir kit/tools/test.sh`
- Voice Studio clean-up test: `.tools/godot/<ver>/<godot> --headless --path kit/studio -s res://tests/test_clean.gd` (import first with `--import`).
- Regenerate sounds: `kit/tools/make-sounds.sh`.
- Linux without a display: `test.sh` uses `xvfb-run` automatically.

## Releasing a kit change
1. Bump `kit/VERSION`.
2. Add a `kit/CHANGELOG.md` entry with a "Game impact" line. If `Kit`/`KitTest`/`KitShape`/`KitMascot` APIs change in a way games might use, say exactly what to change; the `update` skill reads it.
3. Prefer adding over changing: keep old function names working for at least one version.
4. Run the update flow against a game clone (see `docs/plan.md`, spike results) before pushing.
