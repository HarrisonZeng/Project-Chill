# godot_check — let Claude test the game without you

Before this existed, every change ended with "please open Godot and check". This
runs the real game with no human watching and reports back in a few lines.

It boots `scenes/main/main_scene.tscn` — the actual game, not a mock — clicks Yua,
walks the conversation, runs the focus timer, restarts the game, and asserts what
should have happened.

## Run it

```bash
powershell -File "tools/godot_check/check.ps1"
```

That runs everything in about 8 seconds. Individual modes, cheapest first:

| Command | What it does | Time |
| --- | --- | --- |
| `check.ps1 -Mode lint` | Every `.gd` compiles, every `.json` parses. Doesn't boot the game. | 0.4s |
| `check.ps1 -Mode boot` | Loads the real main scene and reports anything `_ready()` throws. | ~1s |
| `check.ps1 -Mode test -Scenario data` | One scenario. `-Scenario all` for every one. | ~1s |
| `check.ps1 -Mode shot -Node ep03_01` | Photograph any moment in the story (see below). | ~3s |
| `check.ps1 -Mode all` | lint + boot + every scenario. | ~8s |
| `check.ps1 -Mode list` | What scenarios exist and what each protects. | ~1s |

Add `-Raw` to see everything Godot printed instead of the summary.

Exit code is 0 when everything passed, 1 otherwise.

## What it prints

Success is one line per scenario:

```
TEST lint             2/2 ok
BOOT             ok
TEST data             10/10 ok
TEST episodes         5/5 ok
ALL OK
```

Failure prints only the assertion that broke, plus the game state at that moment
— enough to diagnose without a second, noisier run:

```
  x second session shows Ep2, not Ep1 again  — expected 'ep02_01', got 'ep01_01'
    state: node=ep01_01 sessions=2 focus=false choices=["很充实，这 25 分钟值了！", ...]
    line:  你先歇口气——刚才那一段，你感觉怎么样？
TEST episodes         3/5 FAIL
```

Engine banners, debug prints and ANSI colour are stripped; repeated errors are
collapsed. A whole passing run costs about as much to read as this paragraph,
which is the point — it can be run after every change without burning context.

## Screenshots

Headless mode has no pixels, so anything visual needs `-Mode shot`, which runs the
same scenarios in a real window and writes PNGs to `shots/`.

```bash
powershell -File "tools/godot_check/check.ps1" -Mode shot -Node ep03_01 -Sessions 3
```

That jumps straight to `ep03_01` with 3 completed sessions on the clock, captures
it, takes the first choice, and captures the reply — without playing there by hand.
`-Sessions` matters for mid-story nodes: it sets the surrounding state so the scene
renders the way it really would.

With no `-Node`, it captures the opening (idle, then the first click). `shots/` is
cleared at the start of each run and is git-ignored.

Any scenario can also take its own pictures at chosen moments:

```gdscript
await g.shot("before-timer")
await g.choose(0)
await g.shot("after-choice")
```

`shot()` does nothing in headless mode, so those calls can live in a test
permanently and only cost anything under `-Mode shot`.

A window appears for a couple of seconds while this runs — that is the renderer,
and it is the only mode that interrupts you.

## Scenarios

| Scenario | What it protects |
| --- | --- |
| `lint` | Every `.gd` compiles and every `.json` parses. Runs even when the game is too broken to boot. |
| `data` | Every choice points at a real node; no blank unleavable node; episode gates unique and their `seen_flag` actually set; reactive pools non-empty; every scene instantiates. |
| `smoke` | Boots to idle, clicking Yua opens a conversation, a focus session completes and counts. |
| `first_click` | Ep0 plays once. Repeat clicks give presence lines from the idle pools — never an Ep0 restart, never a re-greet. |
| `episodes` | Ep1 on the first completed session, **then a full restart**, then Ep2 on the second. The restart is the point: episode flags that live only in memory look correct until the game quits. |
| `focus_click` | During focus the first click answers and later clicks inside the cooldown give `……`; typing never reaches the AI while she is working. |
| `type_mode` | A typed reply at a 自己写 choice: no chips afterwards, no UI-speak in her line, chat continues, clicking her still responds. |
| `look` | Not a test — the camera. Used by `-Mode shot`. |

## Two guarantees

**Your save is safe.** `check.ps1` copies `player_profile.json` out before the run
and puts it back afterwards, even if a run crashes. Scenarios start from a wiped
save so results don't depend on how far you've played.

**No API spend.** Typed replies normally go to the live AI provider. The harness
disables AI before the scene starts, so a test run makes no network call and costs
nothing. Pass `-Ai` to deliberately exercise the real provider.

## Writing a scenario

Drop a `.gd` file in `scenarios/`. It is picked up automatically.

```gdscript
const DESC := "One line describing what this protects."

func run(g) -> void:
    await g.click_yua()
    g.check_node("clicking Yua opens the intro", "ep00_01")

    await g.play_forward()          # take the first option until it settles
    await g.complete_focus()        # run a focus session to completion
    g.check("session counted", g.sessions() == 1)
```

Driver calls: `click_yua()`, `click_card()`, `choose(index_or_text)`,
`type_reply(text)`, `play_forward()`, `start_focus()`, `complete_focus()`,
`set_focus_minutes(n)`, `relaunch()`, `frames(n)`, `wipe_save()`, `shot(label)`,
`opt(name)` (reads a value passed through from `check.ps1`).

Reading state: `node_id()`, `line()` (current beat), `full_line()` (whole authored
line), `choices()`, `sessions()`, `focus_running()`, `flags()`, `has_node_id(id)`.
The live scene is `g.game` if you need something the driver doesn't wrap.

Assertions: `check(label, ok, detail)`, `check_node(label, expected)`,
`check_line_has(label, needle)`, `check_line_lacks(label, needle)`.

Add `const NEEDS_GAME := false` for a scenario that only inspects files, so it
still runs when the game can't boot.

Two things to know:

- Dialogue is revealed one paragraph beat at a time, so `line()` is usually only
  part of the authored text. Compare against source text with `full_line()`.
- Don't force-recompile a script that is currently running — it segfaults the
  engine. `lint` excludes `harness.gd` and itself for that reason.

## Godot location

Found automatically at `D:\Godot_v4.6.1-stable_win64_console.exe`. Override with
`-Godot <path>` or the `GODOT_BIN` environment variable. Use the `_console` build:
the plain `.exe` doesn't write to stdout on Windows, so there would be nothing to
report.

## What this does not cover

`-Mode shot` gives a still frame, which catches overlap, clipping and wrong text.
It cannot judge feel, pacing, animation, audio, or video playback — those still
need the owner in the editor.
