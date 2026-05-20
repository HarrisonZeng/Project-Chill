# Prompt: Project Chill Progression/Save Session

You are the highest-priority Godot 4 engineering agent for Project Chill's Vertical Slice 01 save and progression plumbing. Start cold and read before editing.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Game_Spec_and_Process_Guide.md`
4. `docs/Development_Summary.md`
5. `docs/AI_Dialogue_Infrastructure.md`
6. `scripts/core/main_scene.gd`
7. `scripts/core/dialogue_router.gd`
8. `scripts/dialogue/memory_manager.gd`
9. `scripts/dialogue/scripted_dialogue_manager.gd`
10. `data/dialogue/scripted_nodes.json`

## Direction

The game is co-presence-first, not focus-first.

Yua is a peer user, never a supervisor. Task entry is optional. Focus is optional and player-initiated - never forced or nagged - but focus is the engine of progression: accumulated focus time and completed focus sessions are what advance Yua's openness and the authored story. Light interactions (clicks, Type Mode, returns) are remembered and add ambient warmth but do not unlock story milestones on their own. Pure AFK idling advances nothing.

## Tasks

### A. Consolidate Save Paths

Fix the split-save bug:

- `scripts/core/main_scene.gd` currently writes `user://player_profile.json`.
- `scripts/dialogue/memory_manager.gd` currently writes `user://data/saves/player_profile.json`.

Create one canonical profile path and migrate/merge any existing data from both old files. The migration must preserve focus totals, todos, UI settings, memories, follow-ups, story flags, timestamps, and any existing compatible fields.

Add corrupted-save recovery: if JSON parse fails, preserve the bad file with a timestamped backup name and start a clean profile with `corrupted_save_recovery` metadata.

### B. Extend Save Schema

Add option-B progression fields:

- `profile_version`
- `last_seen_at`
- `last_meaningful_interaction_at`
- `return_count` or return rhythm summary
- `engaged_interaction_count`
- `engaged_time_seconds`
- `focus_started_count`
- `completed_focus_count`
- `total_focus_seconds`
- optional `current_focus_task` / `last_task_text`
- `story_flags`
- `current_story_milestone`
- Yua `openness` / relationship progress
- memory entries and pending follow-ups
- `corrupted_save_recovery`

If exact weights are needed, mark them `PROPOSED - confirm with owner`; do not hard-code product-final thresholds without approval.

### C. Preserve Dialogue Metadata

Extend `ScriptedDialogueManager._register_node` so it preserves at least:

- `unlock`
- `set_flags`
- `tags`
- `speaker`

It must continue supporting existing `id`, `line`, and `choices` behavior.

### D. Deterministic Option-B Progression

Add a progression/gate function in `dialogue_router.gd` or a new focused progression script.

Rules:

- Story/relationship milestones advance only from accumulated focus time and completed focus sessions; this is the required driver.
- Light interactions (Yua click, Type Mode message, return rhythm) are remembered and add small ambient warmth, but do not advance story milestones or `yua_openness` on their own.
- Pure idling does not advance anything.
- Starting focus without a task still counts.
- Entering a task is optional context, not a gate.
- No mandatory-task gating. Focus is optional: the player is never forced to focus and never nagged or punished for not focusing.
- Focus drives progression but is never presented to the player as a chore checklist or transactional unlock.
- AI can suggest memory, but cannot unlock story directly.
- Scripted story remains the backbone; progression selects eligible authored beats deterministically from focus-based state.

## Verification Requirements

Run focused checks and give concrete Godot editor steps for a non-technical user:

1. Delete or temporarily move both old save files, then launch.
2. Confirm one new canonical profile is created.
3. Click Yua or send a Type Mode line without starting focus.
4. Confirm `engaged_interaction_count` updates and memory is stored, but `yua_openness` and story milestones do NOT advance without focus.
5. Relaunch and confirm Yua recognizes return context.
6. Start focus with no task and complete a short test timer.
7. Confirm focus counts and total focus time update, and that story/relationship progress (`yua_openness`, story flags) advances from the completed focus.
8. Leave the app idle without interaction and confirm progression does not advance.
9. Seed both old save paths with different compatible data and confirm migration merges them.
10. Break one old save file with invalid JSON and confirm recovery backup behavior.
11. Add a test scripted node with `speaker`, `tags`, `unlock`, and `set_flags`; confirm the manager preserves the metadata.

Handoff must include changed files, what works, what is not implemented, risks/assumptions, exact next recommended step, and exact Godot editor checks.
