# Thread Handoff (Project Chill)

## Project Snapshot

Project Chill is a Godot 4 visual-novel style companion demo inspired by the Chill With You aesthetic.

Non-negotiables:

- 2D fixed camera
- no player avatar or movement
- female companion always visible
- click/tap + dialogue UI interaction
- scripted dialogue is primary
- AI mode is optional for free-text
- voice output required for character responses
- memory is game-side and persistent

## Current State

- Main scene and UI scaffold exists.
- Scripted dialogue JSON is active and used in the main flow.
- Memory manager, AI service, and dialogue router exist.
- Follow-up memory hook is wired on session start.
- Music/timer/todo UI exists (placeholders are acceptable).

## Key Files

- `AGENTS.md`
- `docs/Game_Spec_and_Process_Guide.md`
- `docs/AI_Dialogue_Infrastructure.md`
- `data/dialogue/scripted_nodes.json`
- `scripts/core/main_scene.gd`
- `scripts/dialogue/memory_manager.gd`

## Character Tone

- Calm, warm, gentle, emotionally safe
- Short-to-medium lines, low drama
- Encourages small steps and steady focus

## If You Need to Continue Scriptwriting

- Expand from `greeting` into check-in, focus, small-talk, and gentle goodbye.
- Use AI mode prompts to capture memory triggers: school, work, exam, sleep.
- Keep choices simple and readable on mobile.

## Open Issues

- Large MP3 removed from repo; replace with smaller placeholder or external file.
- Visual polish pending: real background and character art composition.
- Voice system needs real TTS or pre-generated audio.

## Current Objective

Make the first session loop feel calm and complete:

1. Click character -> greeting
2. Choose a path (check-in / focus / chat)
3. Use AI mode once for a memory trigger
4. Relaunch -> follow-up line appears

## How to Resume

1. Read `AGENTS.md` and `docs/`.
2. Open `data/dialogue/scripted_nodes.json` for current dialogue state.
3. Open `scripts/core/main_scene.gd` to see how the flow is wired.
