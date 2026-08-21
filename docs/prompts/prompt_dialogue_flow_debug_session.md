# Prompt: Project Chill — Dialogue Flow Mapping & Bug Hunt Session

> Paste everything below the line into a new Claude Code session started in
> `D:\Project Chill\project-chill`.

---

You are the single agent on Project Chill (a Godot 4 co-presence companion game). Your job this
session is **not** to write new story content. It is to **map how dialogue actually flows, then
find and fix the bugs in that flow.**

The dialogue system has grown organically and now has several overlapping sources of text with no
single owner. The owner is seeing real misbehavior in play. Treat this as a debugging and
architecture-clarification session.

## Read first (in this order)

1. `CLAUDE.md` — your role and the verify-before-handoff rule
2. `AGENTS.md` — product guardrails (Yua is a peer; focus drives story; AI can't unlock story)
3. `SESSIONS.md` + `ls .sessions/` — file-ownership protocol; **write your own claim before editing**
4. `docs/Architecture_Overview.md` — the layer map
5. `Progress.md` — live state
6. `tools/godot_check/README.md` — how you test your own work

Then read the code (see "The moving parts" below).

## Ground truth as of 2026-08-19 (verified, don't re-derive)

- `powershell -File "tools/godot_check/check.ps1" -Mode all` → **ALL 11 scenarios pass** (~8s).
  **This is the single most important fact.** The suite is green while the game is visibly buggy,
  which means *every bug the owner reports lives in a path no scenario walks.* Your first
  deliverable is scenarios that fail.
- `data/dialogue/scripted_nodes.json` has **~725 uncommitted changed lines** (mid-rewrite to
  `demo_script_version: 10`, Ep0–Ep2 rewritten to the 2026-08-17 canon). Several bugs are likely
  *in this new content*, not in the engine. `git diff data/dialogue/scripted_nodes.json` is a
  primary source.
- `scripts/core/main_scene.gd` (~2,108 lines) is the coordinator and owns dialogue flow.
- Two **active** sessions (`.sessions/art-room-u-gap.md`, `.sessions/art-yua-hands.md`) claim only
  image assets. All dialogue code/data is free — but re-check `.sessions/` yourself at startup.
- `docs/Architecture_Overview.md:76-78` claims `_register_node` drops `set_flags`/`tags`/`unlock`.
  `Progress.md` says that was fixed 2026-08-09. **Verify against the code; the docs are stale in
  places.** Where a doc contradicts code, trust the code and fix the doc.

## The bugs the owner reports (your target list)

1. **Ep0 loops.** Dialogue sometimes runs from the end of Ep0 back to the *start* of Ep0.
2. **Stale text.** Leftover/obsolete lines still surface in play.
3. **System text spoken as Yua.** System/status/fallback strings sometimes appear in the dialogue
   box as if Yua said them.
4. **AI ↔ scripted transition is undefined.** Entering and leaving free-form chat, and what happens
   to the scripted position while the player is in it, was never properly designed.

These are symptoms, not root causes. Expect fewer root causes than symptoms.

## The moving parts (there are more text sources than you'd guess)

Map **all** of these and how they compete for the one dialogue box:

| Source | Where |
|---|---|
| Authored episodes Ep0–Ep14 | `data/dialogue/scripted_nodes.json` (`episodes[]`, `epNN_01` nodes) |
| Functional nodes (`idle`, `TASK_INPUT_*`, `FOCUS_*`, `ABORT_*`, `EXIT_*`) | same file |
| Return/greeting nodes (`return_open_01`, `return_open_short`, `greeting_{morning,noon,evening,night}_0N`) | same file, ~line 888+ |
| Reactive click lines (incl. focus-time `……` cooldown) | `data/dialogue/reactive_lines.json` |
| AI modes | `data/dialogue/ai_modes.json` |
| AI replies + fallbacks | `scripts/core/dialogue_router.gd`, `scripts/dialogue/ai_dialogue_service.gd` |
| Status/system messages | `main_scene.gd` (`_set_status_message`, `_show_system_status`) |
| Debug/timeline strings | `main_scene.gd` DEBUG block (~line 1870+) |

Key routing config at the top of `scripted_nodes.json`: `fallback_id: "idle"`,
`intro_node: "ep00_01"`, and `_pacing_doc` explaining flag-guarded episodes
(`seen_flag` + `session_gate` + `unlock.total_focus_seconds_min`, falling back to
`FOCUS_DONE_REPEAT` when nothing is eligible).

Engine side: `scripts/dialogue/scripted_dialogue_manager.gd` (node lookup, flags),
`scripts/core/progression_gate.gd` (focus→episode gating),
`scripts/dialogue/memory_manager.gd` (the save authority — flags only "stick" if persisted).

## How to work

### Phase 1 — Map before you touch anything

Produce `docs/Dialogue_Flow_Map.md`: the actual decision tree, as built (not as intended).
It must answer, with `file:line` citations:

- On launch, what decides the first line? (greeting bucket vs return-open vs intro vs resume)
- On clicking Yua at idle, what is chosen, and in what priority order?
- After a **terminal** node (empty `choices: []`, e.g. `ep00_close`), what is `current_node_id`,
  and what does the *next* click show? **Trace this one precisely — it's the prime suspect for the
  Ep0 loop.** Follow `_safe_node_id()`, `fallback_id`, and `intro_node` and show how control could
  land back on `ep00_01`.
- When a focus session completes, how is the next episode picked, and what happens when none is
  eligible?
- Exactly which flags are written, **when they're persisted to disk**, and what reads them.
  (A flag set in memory but saved late/never = replay after relaunch. The `episodes` scenario
  already relaunches — so if it passes, look at the paths it *doesn't* cover: quitting mid-episode,
  terminal nodes, AI mode active at save time.)
- Every path that can write to the dialogue box, and which of them are allowed to be "Yua's voice".

A diagram (mermaid) plus a precedence table is worth more than prose here.

### Phase 2 — Reproduce before you fix

**Do not fix anything you have not first reproduced in a failing test.** This is the rule that
matters most, because the suite is currently green and lying to you.

For each bug, add or extend a scenario in `tools/godot_check/scenarios/`:

```bash
powershell -File "tools/godot_check/check.ps1" -Mode test -Scenario <name>
```

Prove it fails, then fix, then prove it passes. The driver gives you `click_yua()`, `choose()`,
`play_forward()`, `complete_focus()`, `relaunch()`, `wipe_save()`, `node_id()`, `flags()`,
`full_line()`, `check_line_lacks()` — enough to script the exact sequences above. `relaunch()` and
`full_line()`/`check_line_lacks()` are your main instruments for bugs 1 and 3.

Suggested new scenarios: `ep0_terminal` (no loop back into Ep0 after the intro settles, across a
relaunch), `text_sources` (no English/system/debug string ever reaches the dialogue box), and
`ai_transition` (enter free chat → return → scripted position is intact).

### Phase 3 — Fix, smallest change first

Prefer making the *precedence explicit* over adding another special case. If you find N places
deciding "what line shows next", the fix is usually one ordered resolver, not N patches. But do not
refactor the whole coordinator in one go — the owner must be able to run the game after each step.

For bug 4 (AI ↔ scripted), you'll likely need a small **design decision** rather than just a fix.
Frame the options for the owner in plain language and recommend one; don't silently invent policy.
Constraints from `AGENTS.md`: AI is bounded augmentation, cannot unlock story, and Yua's in-fiction
boundary is that she's busy with her own work. Note that Type Mode is now **always on** (the old
toggle was removed; `ai_mode_toggle` is hardcoded `null` in `main_scene.gd`), so "entering AI mode"
may no longer be a real state — check whether `AI_MODE_*` / `_handle_ai_mode_choice` is now dead
code, and whether `current_ai_mode_id` still earns its keep.

### Phase 4 — Verify and hand off

- `powershell -File "tools/godot_check/check.ps1" -Mode all` must be green, **including your new
  scenarios**.
- Use `-Mode shot -Node <id> -Sessions <n>` to *look* at any beat yourself and Read the PNG. Only
  ask the owner about feel, pacing, animation, audio.
- Update `docs/Architecture_Overview.md` and `Progress.md` if you find their claims stale.
- Hand off with: files changed · what works · what's not done · risks/assumptions · next step ·
  numbered Godot editor steps for anything visual.

## Guardrails

- Edit **directly in the main working tree**. Never create a git worktree.
- Follow `SESSIONS.md`: write `.sessions/dialogue-debug.md` claiming `main_scene.gd`,
  `scripted_nodes.json`, `dialogue_router.gd`, `scripted_dialogue_manager.gd`,
  `progression_gate.gd`, and `tools/godot_check/scenarios/*` before editing. Delete it at the end.
- The owner is **non-technical**. Explain in plain language; give exact, numbered Godot steps.
- Don't rewrite story content to dodge an engine bug. If a line must change, say so and why.
- If you must choose between "quick patch" and "make the precedence legible", tell the owner the
  trade-off and recommend one — don't just pick silently.

## Start here

1. Read the docs above; write your `.sessions/` claim.
2. Run `check.ps1 -Mode all` yourself to confirm the green baseline.
3. `git diff data/dialogue/scripted_nodes.json` to see the in-flight script rewrite.
4. Begin Phase 1 (the map). Report the map to the owner **before** you start fixing.
