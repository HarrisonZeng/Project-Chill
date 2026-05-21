# Prompt: Project Chill UI / Online-Call Look Session

You are a Godot 4 UI/UX implementation agent for Project Chill. Start cold and
read before proposing changes.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Architecture_Overview.md` — **important: the UI is now componentized**
4. `scenes/main/main_scene.tscn`
5. `scripts/ui/call_status_controller.gd`, `music_bar_controller.gd`, `tasks_panel_controller.gd`
6. `scripts/ui/ui_strings.gd`
7. `data/theme/project_chill.tres`

## Goal

Make the screen feel like a **cozy online co-working video call with Yua**, not a
wallpaper covered by floating debug widgets.

Critical pivot rule: the focus timer must **not** be the mandatory hero action.
Co-presence with Yua is the default state; the timer is one optional tool.

## What changed since the old UI brief

The UI was de-monolithed. Most widgets now live in their own component scripts,
which is where you'll work:

- Call-status pill → `scripts/ui/call_status_controller.gd` (date/time, status dot)
- Music/voice bar → `scripts/ui/music_bar_controller.gd` (incl. the old "No track loaded" state)
- Tasks/todo panel → `scripts/ui/tasks_panel_controller.gd`
- Layout/composition lives in `scenes/main/main_scene.tscn`; palette/type in `data/theme/project_chill.tres`.

Prefer editing the **component scripts + the `.tscn` + the theme**. Touch
`scripts/core/main_scene.gd` only for a brief, explicit hookup pass, and only
when no other session is in that file (see SESSIONS.md).

## Scope for Vertical Slice 01

- Hide dev/test controls and the debug timeline from the player-facing slice.
- Make Yua's video/presence the prominent subject (`VideoStage`/`CompanionView`).
- Ensure the focus timer reads as one optional, compact control — not the hero.
- Polish the three states from the spec: idle/co-presence, focus-active, chat-active.
- Clean the music bar's empty state and the task panel's seed/test content.
- If `assets/video/yua_idle_loop.ogv` exists but isn't visibly playing, treat it
  as an import/playback/composition bug, not a missing asset.
- **Settings/customization expansion** (optional within this slice): the panel
  currently has only language + text speed. Good additions: BGM volume, an AI /
  Type-Mode on-off toggle (privacy), voice on/off. NOTE: any **persisted** new
  setting also needs one save/load line in `main_scene.gd` — coordinate that one
  line per SESSIONS.md.
- Reserve a full-screen overlay node for later time-of-day lighting; do not
  implement lighting polish yet.

## Hard limits

- Do not touch dialogue content or story logic (`scripted_nodes.json`, the flow).
- Do not change the progression/save behavior.
- Do not add addons or new dependencies.
- Do not make focus look mandatory; do not remove Type Mode.
- Do not build around the Persona 5 placeholder BGM as final content.

## Stage 1 required output (pause for approval)

1. ASCII mockups for idle/co-presence, focus-active, and chat-active states.
2. Framework concept: which panels exist, which are hidden by default, where the
   optional timer lives.
3. Palette + typography direction for a calm co-working call (reconcile with the
   existing theme).
4. Concrete node-change plan, named against the components/scene above.
5. Risks and assumptions.

Then pause and wait for owner approval before implementing.

## After approval

Implement incrementally, one component at a time. After each, run the project and
give the non-technical owner concrete Godot editor checks (open scene, press Play,
what to look for). Handoff must include changed files, what works, what's not done,
risks/assumptions, next step, and Godot checks.

## Session coordination (SESSIONS.md)

Drop this into `.sessions/ui.md`:

```markdown
# session: ui
task: Online-call look — composition, components, theme, settings
status: active
claims:
- scripts/ui/call_status_controller.gd
- scripts/ui/music_bar_controller.gd
- scripts/ui/tasks_panel_controller.gd
- scenes/main/main_scene.tscn
- data/theme/project_chill.tres
needs-core-loop-edit: maybe   # only for persisted-settings save/load lines
```

Do not run this at the same time as the Engine session — both may need
`main_scene.gd`.

## Recommended model

**Sonnet** for the implementation (lots of mechanical Godot edits + visual
iteration). Use **Opus** for the Stage 1 composition/design pass if you want a
stronger look.
