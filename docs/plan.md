# Game Maker: Plan

A GitHub template repo that lets a non-coder build a simple game with Claude (or another coding agent), guided by an opinionated process, with an optional friendly shell (chat UI + panels) on top later.

First real user and first test: Chris's wife, building a game for their kids.

Status: M0 in progress. Kit v0.1.0 built; spike 2 and the update flow pass in a Linux container. Nothing tested on her Windows laptop or with the kids yet. See section 12 for decisions and results.

---

## 1. Target user

- Plays games. Understands basics like "install" and "deploy" at a vocabulary level.
- Does not write code and cannot read it. Lives in natural language.
- Cannot tell whether something is broken, cannot resolve merge conflicts, cannot judge a permission prompt.
- Will scope-creep. Needs help finding a realistic version 1.

Design consequence: the process, not the code, is the product. Every step must be verifiable by playing the game or reading plain language.

### Audience for game one: children aged 2 and 4

- They must not browse the internet or play games hosted on the open internet. Everything runs locally; no accounts, no network calls, no ads.
- Play happens on the wife's computer, handed over and supervised, then (later) on the kids' tablets as an APK.
- Design rules the wizard should enforce: no reading required (pictures, sound, voice cues), huge touch targets, forgiving input (any tap or key does something nice), no fail states or timers, no way to accidentally exit (fullscreen, "kid mode" that ignores Esc/alt-tab where possible, or at least a grown-up-only exit), short sessions.
- Laptop input is a real issue: a 2-year-old mashes keys and drags a trackpad poorly. Test with actual kids early; prefer "any key / any click" interactions.
- The wizard's age question should map to these defaults.

## 2. Principles

1. One path first: Godot. Playtest locally on the user's own computer (the kids play on her laptop, supervised; nothing is published or hosted online). Shipping to the kids' tablets is a separate, later step: an Android APK sideloaded onto the tablet. No public hosting. iOS and app stores are explicitly "not yet".
2. State lives in files, never in the model's memory. Any session can resume cold from `STATE.md`.
3. One feature per session. Each session ends with a checkpoint commit and a state update.
4. Claude verifies its own work (smoke tests, screenshots) before asking the human to playtest. Human playtests are 3 to 5 plain-language steps.
5. Be willing to say no. Use a written feasibility list rather than ad hoc judgment.
6. Root `CLAUDE.md` stays tiny. Detail lives in skills and the playbook, loaded only when needed.
7. No data collection from children. No accounts, analytics or network calls in games by default.

## 3. Repo layout (v0.1, as built)

One clone per game. Paths are either kit-owned (replaced on update) or game-owned (never touched by updates); that split is what makes updates conflict-free.

```
xogame/                       (kit repo; each game is a clone of it)
├── README.md                 kit  human-facing setup + "things you can say"
├── CLAUDE.md                 kit  tiny router
├── .claude/settings.json     kit  permission allowlist (kit scripts, read-only git) + deny list
├── .claude/skills/           kit  start, continue, playtest, undo, wrap-up, update, voices
├── docs/                     kit  plan.md (this), DEVELOPING.md
├── kit/
│   ├── VERSION, UPSTREAM, CHANGELOG.md   update metadata ("Game impact" per release)
│   ├── feasibility.md        green / yellow / red
│   ├── playbooks/godot/      PLAYBOOK.md (dev loop + designing for ages 2-5), ship-android.md (stub)
│   ├── templates/            STATE.md, GAME.md, ROADMAP.md, roadmap.html
│   ├── gamekit/              Godot add-on copied into every game (Kit autoload, KitShape,
│   │                         KitMascot, confetti, test runner, sound generator, CC0 sounds)
│   ├── starter/              "Pop!" toy, copied once into game/ by new-game.sh
│   ├── studio/               Voice Studio (separate Godot app; games never touch the mic)
│   └── tools/                get-godot, new-game, test, play, studio, checkpoint, undo, update, ...
├── game/                     game  created by the start wizard (game/addons/gamekit = synced copy)
├── STATE.md, GAME.md, ROADMAP.md, roadmap.html   game  created by the start wizard
└── .tools/                   ignored  pinned Godot download
```

### STATE.md schema

```
phase: scoping | building | shipping | maintaining     (no file = new: run start)
playbook: godot
version_in_progress: v1
current_feature: <name or none>
next_action: <one sentence>
last_checkpoint: <save-N tag>
last_session_summary: <3 sentences max>
open_questions_for_user: <list>
```

## 4. Session protocol

Start: read `STATE.md` and `ROADMAP.md`. Confirm the next action with the user in one line.
Work: one feature. Make a checkpoint commit before changing anything.
Verify: run smoke test + screenshot; fix what fails before involving the human.
Playtest: 3 to 5 steps, answers are "works" or "feels wrong, because...".
Wrap-up: commit, update `STATE.md`, regenerate `roadmap.html`, tell the user to start a fresh session for the next feature.
Subagents: verification only (a fresh-eyes reviewer that has not seen the build). Not for building.

## 5. Research findings

Existing templates (all developer-oriented):
- Claude Code Game Studios (Donchitos): studio-style agents/skills/hooks for Claude Code. Assumes the user reads code.
- Claude Code Solo Studio: lightweight Godot/Unity template for solo devs.
- Godogen (htdt): Claude Code skills that generate complete Godot 4 projects from a description (~2.4k stars). Generation pipeline, not a guided process. Worth studying for its visual QA loop.
- Playbook (npm: playbook-ai): interview-driven CLAUDE.md generator for non-technical founders. Same wizard pattern, different domain.

Gap: none found combining scope-tempering + versioned roadmap + session-resume + plain-language playtesting for non-coders making games.

Claude Code + Godot: several developer write-ups report good results; Godot's text-based scene files suit agents, and agents can build their own test runners and verify UI without opening the editor. Supports the self-verification principle.

Herdr (herdr.dev):
- Three pieces: Herdr TUI (terminal), Herdr app (native desktop, released Oct 2026, Apache 2.0), herdr-core (server that runs the terminals; local or over SSH). The app and TUI are separate programs and do not share agents.
- The app is customized through plain files in `~/.config/herdr-app/`: `layouts/*.json` (whole-window layout), `mods/*/*.js` (JavaScript that draws panels, menus, dialogs, commands), `themes/`, `keys.json`, `settings.json`, and `AGENTS.md` (an API reference for agents).
- Useful commands (per third-party write-up): `herdr-app --skill` prints the agent guide, `herdr-app check` validates edits.
- Distribution: a public GitHub repo with topic `herdr-layout` / `herdr-mod`, containing `layouts/<name>.json`, `mods/`, `RECIPE.md`, `preview.png`. Installed by telling your agent to fetch the recipe.
- Evidence that rich panels exist: markdown preview panel, task-graph and plan-viewer mods, and "Flockbook" which shows agent sessions as chat-style threads with expandable tool-call cards.
- Caveats: mods are unsandboxed trusted code; the app is young (frequent releases, mod APIs have changed between versions, two recent hotfixes for input regressions); shipped layouts are overwritten on update so duplicate before editing; telemetry is on by default (Settings > Privacy); Apple Silicon only on Mac; Linux needs Vulkan; Windows 10 1803+ x64.
- NOT confirmed: whether a mod can host a text input, embed a webview (for the game or `roadmap.html`), or replace/wrap a terminal pane. The public docs page is high level; the real API is in `AGENTS.md` after install, `herdr.dev/guide`, and the herdr-app repo.

Licensing note: sources disagree (Apache 2.0 for the official app; one fork lists AGPL-3.0-or-later dual licensing). Verify against the official repo before building on or redistributing.

## 6. The chat-bubble shell

Idea: a thin UI that talks to Claude and hides everything that would overwhelm a non-technical user.

Key finding: do not screen-scrape the terminal UI. Claude Code has a structured mode. `claude -p --input-format stream-json --output-format stream-json --verbose` (add `--include-partial-messages` for token streaming) emits newline-delimited JSON events and accepts JSON user messages on stdin. IDE extensions (VS Code, JetBrains) use this pattern: they spawn Claude Code as a subprocess and render events in their own UI. The Agent SDK (Python and TypeScript) exposes the same loop with callbacks and a client class meant for chat interfaces.

So the shim is: spawn Claude Code in stream-json mode in the project folder, render events as chat bubbles, and apply a filter layer:
- Show: assistant text; a one-line friendly status for tool use ("Updating the game...", "Testing it..."); the playtest checklist as a card; screenshots.
- Hide by default: raw tool calls and results, diffs, stack traces, file paths. Offer a "details" toggle for the developer.
- Translate errors: Claude is instructed (in CLAUDE.md) to explain failures in plain language; the shell never shows raw stderr by default.
- Permissions: headless mode cannot rely on the user judging prompts. Pre-approve a safe tool set (read/write/edit inside the project folder, the Godot export and test commands, git) and deny the rest. Use `--allowedTools` / permission mode, or `--permission-prompt-tool` for anything in between. Needs real design and a security review.
- Resume: `--resume <session id>` and the state files give continuity.

Two ways to host it:

A. Herdr layout + mods (no fork)
- Ship a layout and mods in the template repo: chat mod (stream-json bridge), roadmap/next-action panel (renders `STATE.md`, `ROADMAP.md`), game preview.
- Pros: free terminal/session management, community distribution, agents can edit the UI.
- Cons: depends on unconfirmed mod capabilities (input box, webview); young API; a lot of agent-supervision UI the user does not need; install is a desktop app plus the Claude Code CLI.

B. Small local web app over the Agent SDK
- A tiny Node or Python server serving a chat UI and panels in the browser (or later wrapped with Tauri/Electron). Panels are iframes/HTML: `roadmap.html` and the game itself (a web build served from localhost by the same local server, which can set any headers Godot needs) come for free.
- Pros: full control, rich content, cross-platform, no dependency on another project's mod API.
- Cons: we own the UI and packaging; still needs Claude Code or SDK auth set up on the user's machine.

Recommendation: spike both (section 9). My current lean is B for the user-facing shell, because the herdr value (multi-agent supervision, terminal panes) is mostly unused by a one-agent non-coder. Reconsider if herdr mods turn out to support input and webviews cleanly. Do not fork herdr unless both fail.

Also check first: Claude's own desktop app and web Claude Code may already be good enough as the chat surface for this user. The shell is only worth building if the friction there is real.

## 7. Roadmap for this project

M0 (content, no shell): repo scaffold, wizard, feasibility, one playbook, starter Godot project, local run in fullscreen "kid mode". Test with wife on one real game idea. Log every point of confusion.
M1: fix what M0 revealed. Add the APK ship step (`ship.md`) once the local loop works. Add playtest automation (headless smoke test + screenshot) and the checkpoint/undo flow.
M2: shell spike(s) and decision.
M3: shell v1 with chat bubbles, roadmap and next-action panels, game preview.
M4: second playbook only if M0 to M3 show real demand (candidate: plain HTML/JS web games, which are simpler than Godot for some games).

Success metric for M0: a first playable running on her computer in under 30 minutes of the first session, and a second feature added in a fresh session with no re-explaining.

## 8. Risks

- Instruction-following drift on long wizards. Mitigation: short root file, state in files, skills loaded on demand.
- Local run quirks (kid input on a laptop, accidental exits) and Android build setup (SDK, JDK, export templates, signing, sideloading). Mitigation: spikes 1 and 1b first.
- Claude can't truly judge fun or visual quality. Mitigation: human playtest steps; screenshots only catch obvious breakage.
- Non-coders can't recover from a bad state. Mitigation: automatic checkpoints, `/undo`.
- Permission/safety in a headless shell. Mitigation: allowlist, project-folder scoping, no network except deploy.
- Kids' content: avoid collecting data; check store policies before any app-store path.
- Platform churn: herdr mod APIs and Claude Code flags change. Mitigation: pin versions, keep the repo (content) independent from any shell.
- Scope: this is a side project. Keep M0 small.

## 9. Spikes (do in this order, each with pass/fail)

1. Local play: the game runs on the wife's actual computer in fullscreen, started by one action Claude takes. Compare a native Godot window against a web build served on localhost in a fullscreen browser; use a single-threaded web export if going the web route (verify current Godot docs). Pass: a 2-year-old and a 4-year-old can play with whatever input her computer has without exiting or breaking out; starts in about 10 s. If both fail, evaluate plain HTML/JS (Phaser or similar) as the first playbook.
1b. APK: export a debug APK and sideload it onto the kids' tablet. Record every step and failure. Pass: the wife can repeat it with at most one "extra hand" step. Compare (a) local Android SDK + JDK + Godot export templates + debug keystore, driven by Claude on her machine, vs (b) building in CI (a private GitHub Actions repo) and downloading the APK. Confirm tablet model first (Amazon Fire vs stock Android changes sideloading steps; iPad is out of scope).
2. Headless test of a Godot game by Claude: launch, simulate input or scripted run, capture a screenshot. Pass: Claude catches a deliberately introduced bug without human help.
3. Cold resume: new session, only `STATE.md` + `ROADMAP.md`. Pass: continues the right feature, no re-explaining, over 5 consecutive sessions.
4. Wizard dry run with wife on a real idea. Pass: v1 scoped to at most 3 features she agrees with, and she accepts at least one "no".
5. Shell spike A (herdr): install the app, run `herdr-app --skill`, read `AGENTS.md`. Questions: can a mod render text input? embed a webview or HTML? wrap a pane? read files? run commands? Build a mod that renders `STATE.md` + `ROADMAP.md`.
6. Shell spike B (local web app): ~100 lines using the Agent SDK or `claude -p` stream-json; chat bubbles + an iframe for `roadmap.html`; apply the filter rules.
7. Permission model: define the allowlist; try to break out of the project folder; document what is blocked.

## 10. Open questions

- Which Godot version to pin, and how is it installed for a non-coder (or can the agent environment run exports so the user never installs Godot)?
- Where does Claude run for the user: Claude Code on the web (nothing to install, but sandboxed environment and no local preview), or desktop? This decides the shell options.
- Does the user need a GitHub account? Local-first makes it optional (backup only), but the "Use this template" flow assumes one; a downloadable zip could replace it.
- Which tablet model(s)? Amazon Fire vs stock Android decides the sideloading steps.
- Android export prerequisites for Godot (JDK, Android SDK, export templates, debug keystore): who installs them and how, and can Claude do it on her machine?
- Game assets: where do art and sound come from, and what licensing guidance does the wizard give?
- Telemetry/privacy defaults for any shell we ship.

## 11. Sources

- Claude Code headless / stream-json: https://code.claude.com/docs/en/headless
- Agent SDK (Python): https://code.claude.com/docs/en/agent-sdk/python
- Herdr: https://herdr.dev, https://herdr.dev/docs/mods, https://herdr.dev/layouts/, https://herdr.dev/mods
- Herdr app layouts and mods write-up: https://www.bitdoze.com/herdr-app-layouts-mods/
- Herdr overview: https://www.eesel.ai/blog/herdr
- Claude Code Game Studios: https://github.com/Donchitos/Claude-Code-Game-Studios
- Claude Code Solo Studio: https://github.com/Ghraven/Claude-Code-Solo-Studio
- Godogen: https://github.com/htdt/godogen
- Playbook for non-technical founders: https://cdn.jsdelivr.net/npm/playbook-ai@1.7.1/README.md
- Claude Code + Godot write-ups: https://dev.to/abagames/godot-is-well-suited-for-game-development-with-ai-coding-agents-2lcm, https://thebrandonwu.substack.com/p/building-a-visual-novel-with-claude

Note: findings come from blogs, READMEs and docs summaries, not hands-on testing. Treat the herdr capability claims as hypotheses until spike 5.

## 12. Decisions and results log

### 2026-11-26: decisions
- Her computer is Windows; kids' tablets are Amazon Fire. Claude Code runs locally (desktop app or CLI) so it can open the game on her screen; Claude Code on the web can't. On Windows, Claude Code uses Git Bash, so the kit's tools are bash scripts that run on Windows, macOS and Linux.
- Godot confirmed as the first playbook, pinned to 4.7.2 (newest stable today), downloaded into `.tools/` by a script (no installer, no admin rights). Renderer: GL Compatibility (old laptops, Fire tablets).
- Kid-mode reality: a game can ignore Esc, the close button and Alt+F4, and does. It cannot block the Windows key or Alt+Tab. The grown-up exit is holding Ctrl+Shift+Q for 2 s. Supervised play plus a one-click relaunch is the realistic target; OS-level kiosk modes (Windows Assigned Access, Fire screen pinning / Amazon Kids) are a later option.
- First win before the wizard: the starter is already a toy for ages 2-4. Start = install, launch the toy (~10 min), then scope.
- Kid appeal (from LittleBeans and Lucas games): nice sounds, a sense of reward, responsiveness, mascots. Built into the starter and playbook: pentatonic notes so mashing sounds musical, star progress plus a celebration every 10 inputs, a mascot that reacts to every input.
- Assets: sounds generated by maths in a Godot script (CC0 by construction, needs nothing but Godot); shapes and mascot drawn in code; voice lines recorded by her in the Voice Studio (auto trim and level). ElevenLabs deliberately avoided.
- Updates: games are `git clone`s (shared history). `kit/tools/update.sh` checkpoints, merges upstream, resolves conflicts by path ownership (kit paths take upstream, game paths keep local), re-syncs gamekit and prints the changelog. Also works for repos made with "Use this template" (unrelated histories).
- Checkpoints are `save-N` git tags; undo restores files from a tag as a new commit (history kept, so undo is undoable).

### 2026-11-26: results (Linux cloud container, Xvfb virtual display)
- Spike 2 (Claude tests the game itself): PASS. The runner simulates taps, keys, drags and toddler mashing, checks facts, and saves screenshots. Planted bugs: off-by-one celebration (caught), typo in a function name (caught at import), null crash in celebration (caught), shape drawn behind background (caught), shape in the wrong place (caught), shape colour made fully transparent with its shadow still drawn (not caught by checks; visible in screenshots). Hence the playbook rule that Claude must look at every screenshot.
- Update flow (`kit/tools/dev-test-update.sh`): 12/12. Conflicting edit to a kit file resolved to upstream, game change kept, gamekit refreshed, locally added skill kept, checks pass after update, undo of an update works, template-made repo updates.
- Repeated syncs/tests leave a game's git status clean (Godot .uid/.import files ship with the kit).
- Voice Studio: audio clean-up tested with a synthetic recording; UI renders. Real microphone NOT tested.
- NOT yet tested anywhere: Windows (Git Bash paths, Godot console build, unzip fallback, mic permission prompt), the `.claude/settings.json` allowlist in a real Claude Code session, kids actually playing, the start wizard with her, APK/Fire.

### Next
1. Spike 1 on her laptop: setup from README, `play.sh`, kids play the toy. Log every confusion.
2. Spike 4: wizard dry run with her on a real idea.
3. Spike 3: cold resume over several sessions.
4. Spike 1b (APK on a Fire tablet).
