# Prompt: Project Chill Progression / Save / AI Engine Session

You are the backend engineering agent for Project Chill's Vertical Slice 01. You
own the core game loop and the systems behind it. Start cold and read before
editing.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Architecture_Overview.md`
4. `docs/AI_Dialogue_Infrastructure.md`
5. `scripts/core/main_scene.gd` (the coordinator + core loop)
6. `scripts/dialogue/scripted_dialogue_manager.gd`
7. `scripts/dialogue/memory_manager.gd` (the single save/profile authority)
8. `scripts/core/dialogue_router.gd`, `scripts/dialogue/ai_dialogue_service.gd`
9. `data/dialogue/scripted_nodes.json`
10. **The narrative session's milestone contract** — the list of `story_flags`
    and trigger conditions. Required before you wire the *specific* gates (Task D).

## Direction (non-negotiable)

Co-presence-first; Yua is a peer, never a supervisor. Focus is optional and
player-initiated — never forced or nagged — **but focus time and progressing
through the authored script are the only things that advance the story.** Light
interactions (Yua click, Type Mode, returns) are remembered and add small ambient
warmth but do not unlock milestones. Pure AFK idling advances nothing. AI may
propose memory and produce bounded chat, but **AI never unlocks story.**

## Dependency / sequencing

- The **generic infrastructure** (Tasks B, C below) can be built immediately — it
  doesn't depend on which specific flags narrative invents.
- The **specific gate wiring** (Task D) needs the narrative milestone contract.
  Build the mechanism first; fill in the concrete flags/thresholds when narrative
  delivers them. Mark any placeholder thresholds `PROPOSED — confirm with owner`.

## Tasks

### A. Save consolidation — DONE, verify only
The old split-save bug is already fixed: `memory_manager` is the single profile
(`user://data/saves/player_profile.json`, `PROFILE_VERSION = 2`) and migrates the
legacy `user://player_profile.json` once. `main_scene` writes session/UI state
through `merge_values`/`save_profile`. **Do not re-introduce a second save path.**
Just confirm a clean first launch creates one profile and migration still works.

### B. Preserve dialogue metadata (keystone)
`scripted_dialogue_manager._register_node` currently keeps only `id`/`line`/
`choices` and silently drops `unlock`, `set_flags`, `tags`, `speaker`. Extend it
to preserve those so JSON-authored milestone metadata is honored. Keep existing
`id`/`line`/`choices` behavior intact. Without this, the narrative session's
milestone wiring does nothing.

### C. Close the save-schema gaps for the slice
`memory_manager` already holds `story_flags`, `memories`, follow-ups, and session/
UI fields. Add the Vertical Slice fields that aren't persisted yet:
`total_focus_seconds`, `focus_started_count`, `engaged_interaction_count`,
`engaged_time_seconds`, `last_meaningful_interaction_at`, `return_count` (or a
return-rhythm summary), `current_story_milestone`, `yua_openness` (relationship
progress), and `corrupted_save_recovery` metadata. Add corrupted-save recovery:
on JSON parse failure, back up the bad file with a timestamped name and start a
clean profile flagged with `corrupted_save_recovery`.

### D. Deterministic focus-drives-story gate
Add a progression/eligibility function (in `dialogue_router.gd` or a focused new
progression script) that selects the eligible authored beat from deterministic
state. Rules:
- Story/relationship milestones advance only from accumulated focus time +
  completed focus sessions. This is the required driver.
- Light interactions are remembered (+ small `yua_openness` ambient warmth if you
  want) but do not advance milestones.
- Idling advances nothing. Starting focus without a task still counts. Task entry
  is optional context, never a gate.
- "Gate" = deterministic eligibility, **not** a player-facing lock or chore
  checklist. Yua never demands or nags.
- Scripted story is the backbone; the gate just picks which authored beat is next.

### E. AI systems wiring (phase 2 — after B–D)
Bounded AI augmentation, none of which unlocks story:
- Wire 1–2 real AI-mode triggers from the loop: a gentle post-focus reflection
  (`AI_MODE_POST_SESSION`) and task-clarify when the player *volunteers* a task
  (`AI_MODE_TASK_CLARIFY`). The modes already exist in `ai_dialogue_service`.
- Confirm Type Mode → `dialogue_router` → fallback works when AI is unavailable.
- Memory extraction stays a proposal layer; game-side rules decide what persists
  (today: keyword rules in `memory_manager`). Deeper AI-proposed memory is
  post-demo.
- Real provider: confirm `POE_API_KEY` path works; mock stays the default.
- Add an **AI / Type-Mode on-off (privacy) hook** the settings UI can flip — no
  network calls when off. (The settings *control* is the UI session's job; expose
  the backend flag here.)

## Verification

Run focused checks and give the non-technical owner concrete Godot steps:
1. Fresh launch creates one profile; relaunch recognizes return context.
2. Add a test node with `speaker`/`tags`/`unlock`/`set_flags`; confirm the manager
   preserves them.
3. **Three-path contrast (the slice's core proof):** idle = pleasant but no story
   progress; click/Type Mode = remembered + warmth but no milestone; completed
   focus = story milestone advances + the Yua payoff beat triggers.
4. Focus counts, `total_focus_seconds`, and `story_flags` persist across relaunch.
5. Break the save file with invalid JSON; confirm recovery backup behavior.
6. AI failure still leaves scripted greeting/idle/focus/Type-Mode fallback working.

## Hard limits

- Do not author dialogue content — that's the narrative session's JSON. You build
  the systems that read/route it.
- Do not do UI/visual work — that's the UI session.
- Keep AI optional and bounded; never let it gate or replace authored story.

## Session coordination (SESSIONS.md)

Drop this into `.sessions/engine.md`:

```markdown
# session: engine
task: progression/save engine — metadata fix, focus-drives-story gate, save fields, AI wiring
status: active
claims:
- scripts/core/main_scene.gd
- scripts/dialogue/scripted_dialogue_manager.gd
- scripts/dialogue/memory_manager.gd
- scripts/core/dialogue_router.gd
- scripts/dialogue/ai_dialogue_service.gd
needs-core-loop-edit: yes
```

**Do not run at the same time as the UI session** — both need `main_scene.gd`,
the single-occupancy room. Wait for the narrative milestone contract before Task D.

## Recommended model

**Opus.** This is careful, hard-to-test logic (the gate, metadata, save
migration) where mistakes are costly and silent.

Handoff must include changed files, what works, what isn't implemented, risks/
assumptions, exact next step, and exact Godot editor checks.
