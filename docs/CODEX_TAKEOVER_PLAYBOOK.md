# Codex Takeover Playbook

## Goal

This document defines how Codex takes primary ownership of Project Chill development from this point onward.

The user remains the product approver and Godot editor operator for visual/manual checks. Codex owns first-pass implementation, writing, system design, integration, and review.

## Product North Star

- 2D fixed-camera online focus companion game
- cozy video call / online chatroom setting
- no player avatar
- no movement controls
- Yua always visible
- player opens the game for study/work/focus company
- focus timer and task input are core gameplay
- progression comes from completed focus sessions and total focus time
- scripted story milestones are the main authored experience
- AI is optional augmentation for check-ins, task understanding, memory, and reflection
- memory is game-side and persistent
- voice is deferred

## Operating Model

- `main` is the stable branch
- Codex manager thread is the only thread that merges to `main`
- worker threads operate on isolated scopes
- every worker handoff must include:
  - files changed
  - what is working
  - what is not implemented yet
  - risks or assumptions
  - exact next recommended step
  - exact Godot checks if scene/UI behavior changed

## Thread Roles

### Manager / Integrator

- owns architecture
- owns merge decisions
- owns conflict resolution
- owns docs and handoff updates
- ensures all work supports the focus-first call loop

### Core Gameplay

- owns `scripts/core/main_scene.gd`
- owns focus-first runtime orchestration
- wires check-in, task setup, focus state, completion, break/story unlock, and save flow

### UI / Scene Design

- owns `scenes/main/main_scene.tscn`
- owns `scenes/ui/dialogue_panel.tscn`
- owns `scenes/character/companion_view.tscn`
- makes the presentation feel like a cozy online call/focus room

### Scriptwriting / Narrative

- owns `data/dialogue/scripted_nodes.json`
- owns Yua story milestones, branch pacing, and scripted tone
- writes focus-gated story progress around Yua's writing/project arc

### Reactive Lines / Content Systems

- owns reactive line pools and productivity-support behavior
- covers focus start, work clicks, break, finish, app start/end, return context, and time of day
- keeps timer/todo/music aligned with the focus companion loop

### Memory / Save / Session

- owns `scripts/dialogue/memory_manager.gd`
- owns deterministic memory, follow-up logic, save shape, session totals, and milestone state

### AI / Prompting

- owns `scripts/dialogue/ai_dialogue_service.gd`
- owns `scripts/core/dialogue_router.gd`
- owns prompt/rule assets under `data/dialogue/`
- keeps AI bounded to check-in/reflection/break contexts

### QA / Playtest

- review-first thread
- checks product-direction regressions, focus loop breaks, tone drift, memory continuity, and integration risks

## Merge Order

Use this order unless a specific task requires a temporary exception:

1. Scriptwriting / Narrative
2. Memory / Save / Session
3. AI / Prompting
4. Reactive Lines / Content Systems
5. Core Gameplay
6. UI / Scene Design
7. QA / Playtest

## Rejection Rules

Reject worker output if it:

- adds movement or player-avatar logic
- breaks the fixed-camera online call direction
- makes AI mandatory for story progression
- allows unlimited casual chat before focus
- makes progression day-based instead of session/focus-based
- renames shared nodes without explicit compatibility notes
- reintroduces voice/TTS as a blocker for the current phase
- adds complexity that is not justified by the focus-first vertical slice

## Acceptance Targets

### Phase 1: Focus-First Loop

- open call
- receive time-aware greeting
- enter task/check-in
- start focus session
- click Yua during focus and receive accountability line
- finish session
- progress persists

### Phase 2: Session Progression

- completed session count and total focus time are tracked
- story milestone unlocks after focus
- Yua writing progress can advance
- returning after absence feels natural

### Phase 3: AI Check-In

- AI responds in-character during check-in/reflection
- AI extracts memory tags
- scripted mode remains primary
- AI cannot bypass focus gates

### Phase 4: Reactive Line Depth

- line pools cover start/work/break/finish/end/time-of-day
- focus and rest states feel different
- repeated sessions do not feel empty

## User Responsibilities

The user still handles:

- real asset selection and import
- Godot editor layout/polish validation
- subjective taste approval
- API key setup when needed

## Resume Procedure

When restarting on another machine or in a new Codex session:

1. Read `AGENTS.md`
2. Read `docs/Game_Spec_and_Process_Guide.md`
3. Read this file
4. Read `docs/THREAD_HANDOFF.md`
5. Resume from the current phase and merge order
