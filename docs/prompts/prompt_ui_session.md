# Prompt: Project Chill UI/UX Redesign Session

You are a Godot 4 UI/UX implementation agent for Project Chill. Start cold and read the relevant docs before proposing changes.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Game_Spec_and_Process_Guide.md`
4. `docs/Development_Summary.md`
5. `docs/AI_Dialogue_Infrastructure.md`
6. `scenes/main/main_scene.tscn`
7. `scripts/core/main_scene.gd`

## Goal

Make the screen feel like a cozy online co-working video call with Yua, not a wallpaper covered by floating debug widgets.

Critical pivot rule: the focus timer must not be the mandatory hero action. Co-presence with Yua is the default state. The timer is one optional tool.

## Scope For Vertical Slice 01

Address these UI problems:

- Hide the dev toolbar from the player-facing slice.
- Integrate the plain-text date display into the call UI instead of leaving it as a debug readout.
- Redo the 4-button focus timer into one clean optional control.
- Clean test garbage from the task panel.
- Fix or gracefully hide the "No track loaded" mini-player state.
- Make Yua's video/presence the prominent subject.
- Reserve a full-screen overlay node for later time-of-day lighting, but do not implement lighting polish yet.
- If `assets/video/yua_idle_loop.ogv` exists but is not visibly playing, investigate import/playback/composition. Treat it as a likely wiring/import issue, not a missing asset.

Known asset warning:

- `assets/bgm/Persona 5 chill mix - GVirusInfected.mp3` is placeholder only and not licensable for Steam. Do not build UI around it as final content.

## Hard Limits

- Do not touch dialogue content or story logic.
- Do not add addons or new dependencies.
- Do not make focus look mandatory.
- Do not remove Type Mode.
- Do not implement full-screen time-of-day lighting yet; only reserve the overlay node.
- Do not start full visual polish beyond the first slice.

## Stage 1 Required Output

First produce:

1. ASCII mockups for idle/co-presence, focus-active, and chat-active states.
2. Framework concept: which panels exist, which are hidden by default, and where the optional timer lives.
3. Palette and typography direction suitable for a calm online co-working call.
4. Concrete Godot node-change plan.
5. Risks and assumptions.

Then pause and wait for owner approval before implementation.

## Later Stages After Approval

Implement incrementally, one component at a time:

1. Clean idle/co-presence layout.
2. Optional timer control.
3. Task panel cleanup.
4. Mini-player state cleanup.
5. Yua video/presence prominence.
6. Reserved lighting overlay node.

After each component, run the project and provide concrete Godot editor checks for a non-technical user, for example:

- Open `scenes/main/main_scene.tscn`.
- Press Play Current Scene.
- Confirm Yua is the largest subject on screen.
- Confirm the first view does not force task entry.
- Click the optional focus control and confirm focus-active state is compact.
- Return to idle and confirm Type Mode remains available.

Handoff must include changed files, what works, what is not implemented, risks/assumptions, next recommended step, and exact Godot editor checks.
