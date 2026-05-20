# AGENTS.md

## Purpose

This file aligns all agents working in this repository on one shared product direction and execution standard.

Project Chill is now a focus companion game with a strong character/story layer. Treat this file and the docs below as the basic prompt every thread must read before proposing or making changes.

## Source Of Truth

All agents must read these docs before proposing or making changes:

1. `docs/Vertical_Slice_01_Spec.md`
2. `docs/Game_Spec_and_Process_Guide.md`
3. `docs/Development_Summary.md`
4. `docs/AI_Dialogue_Infrastructure.md`
5. `docs/THREAD_HANDOFF.md`

If there is a conflict, priority order is:

1. `AGENTS.md`
2. `Vertical_Slice_01_Spec.md`
3. `Game_Spec_and_Process_Guide.md`
4. `AI_Dialogue_Infrastructure.md`
5. `THREAD_HANDOFF.md`
6. `Development_Summary.md`

Some older docs still contain focus-first wording. Until they are revised, co-presence-first direction in this file and `docs/Vertical_Slice_01_Spec.md` overrides any mandatory task, mandatory focus, or focus-gated story framing.

The `docs/CODEX_*.md` files describe a retired two-AI workflow and are deprecated. The "Collaboration Workflow" section below is authoritative.

## Product Direction (Non-Negotiable)

- Build a 2D fixed-camera online focus companion game inspired by the work/study call structure of Chill With You.
- The player launches the game to study, work, or focus with Yua as quiet company.
- The setting is a cozy video call / online chatroom, not the player physically entering Yua's room.
- No player avatar, no WASD movement, and no open-world navigation.
- Yua is always visible as the emotional anchor of the call.
- Interaction is click/tap plus dialogue UI, optional focus timer, optional task input, and limited Type Mode.
- Yua is a peer user, never a supervisor. No mandatory tasks, no quizzing, no homework-checking. Focus is what drives progression, but it is never forced, nagged, or presented as a chore checklist or transactional unlock - it emerges naturally from time spent working together.
- The core loop is co-presence-first: launch call, receive a time-aware greeting, share a cozy idle state while Yua does her own work, then the player may optionally start a focus session, enter a task, click Yua, or send a bounded Type Mode message.
- Story and relationship progression is deterministic and driven by accumulated focus time and completed focus sessions. Focus stays optional and player-initiated, but it is the engine that opens Yua up. Pure AFK idling advances nothing.
- Light interactions (clicking Yua, Type Mode messages, returning across days) are pleasant, remembered, and add small ambient warmth, but they do not by themselves unlock authored story milestones. Shared focused time does.
- Scripted dialogue and authored story milestones are the backbone.
- AI is optional augmentation for lightweight check-ins, task understanding when the player volunteers a task, memory extraction, post-session reflection, and limited casual chat.
- AI must not replace authored story progression or become unlimited distraction. Its in-fiction boundary is that Yua is busy with her own work.
- Memory continuity must be game-side and persistent.
- Voice is deferred. Do not treat voice/TTS as required for the current implementation phase.

## Character And Story North Star

- Yua is calm, warm, introverted, observant, gently teasing, and emotionally safe.
- She is also working during the call, primarily on writing. She is mostly diligent (roughly three-quarters effort), but carries a streak of avoidance toward her own creative project - something she half-pretends does not exist.
- Having someone present and focusing alongside her is what tips her from avoidance back into motivation. The player is meant to feel that same lift: a bit reluctant alone, but driven again with company. Keep the overall tone warm and positive, not heavy.
- The long-term story spine is: the more focused time the player shares with Yua, the more she opens up and pushes through her own avoidance to make real progress on her creative work.
- Story should unfold through small disclosures and deterministic relationship milestones that are earned by shared focused time, not by light clicking.
- The game should feel useful as a productivity tool and emotionally meaningful as a character game.

## Architecture Principles

- Focus-session state is first-class and is the primary driver of story/relationship progression: duration, optional task, completion, pauses/abandonment, total focus time, and focus-related progress.
- Co-presence state is also tracked: meaningful interaction counts, accumulated engaged time, return rhythm, memory tags, story flags, and Yua openness/relationship progress. Light interactions feed memory and ambient warmth; story milestones come from focus time.
- Prefer deterministic game logic for progression and continuity. Story milestones are gated on accumulated focus time and completed sessions, but the player is never forced to focus and never punished for not focusing. Do not rely on mandatory task entry or model conversation history as gates.
- Do not rely on model conversation history as the only memory source.
- Keep AI behind a service boundary (`ai_dialogue_service`) to allow provider swaps.
- Keep scripted dialogue as the backbone for tone, progression, and narrative stability.
- Add fail-safe fallbacks for API failure.
- Keep voice/TTS code isolated and optional until the project returns to voice polish.

## Delivery Standards

- Implement in small vertical slices that are playable/testable.
- Preserve beginner-friendly structure and explainability.
- Avoid large untested rewrites.
- Add or update docs when behavior or architecture changes.
- Keep assets, data, scenes, and scripts organized by the folder layout in the spec doc.

## Current Phase Focus

Current target phase:

- Refactor the existing demo direction into a co-presence-first online call loop:
  1. launch call
  2. time-aware greeting
  3. cozy idle co-presence with Yua visibly doing her own work
  4. player may optionally click Yua, send a bounded Type Mode message, start a focus session, or enter a task
  5. Yua acknowledges naturally as a peer, not as a teacher or coach
  6. active focus, if started, keeps chat brief because both sides are working
  7. shared focused time advances deterministic story/relationship progression; light interactions are remembered but do not unlock milestones; pure AFK idling advances nothing
  8. persist engaged interaction count, engaged time, optional focus totals, memory, story flags, return timestamps, and Yua openness/relationship progress

Do not jump into deep polish, full voice, or advanced AI autonomy before this co-presence-first loop is stable.

## Agent Handoff Protocol

When handing off work, include:

- changed files
- what is working
- what is not implemented yet
- risks or assumptions
- exact next recommended step
- exact Godot editor checks if scene/UI behavior changed

## Human Collaboration Rule

The user is non-technical and should receive concrete Godot editor steps, not only abstract architecture advice.

## Collaboration Workflow

- Claude is the single agent on this project and does everything: design discussion, planning, and implementation. There is no Codex hand-off and no second AI.
- The owner and Claude discuss high-level design together. Claude then plans and implements the work directly.
- Claude edits directly in the main working tree. Do not use git worktrees: the owner runs the game in Godot from the main tree and cannot run a worktree copy, and being non-technical does not review cross-branch diffs.
- `docs/prompts/` holds scoped task specs (narrative, UI, progression/save). Claude executes these itself; they are no longer pasted to an external implementer.
- Claude verifies its own changes and gives the owner concrete Godot editor steps for anything visual or scene/UI related.
