# AGENTS.md

## Purpose

This file aligns all agents working in this repository on one shared product direction and execution standard.

Project Chill is now a focus companion game with a strong character/story layer. Treat this file and the docs below as the basic prompt every thread must read before proposing or making changes.

## Source Of Truth

All agents must read these docs before proposing or making changes:

1. `docs/Game_Spec_and_Process_Guide.md`
2. `docs/Development_Summary.md`
3. `docs/AI_Dialogue_Infrastructure.md`
4. `docs/CODEX_TAKEOVER_PLAYBOOK.md`
5. `docs/CODEX_WORKFLOW.md`
6. `docs/THREAD_HANDOFF.md`

If there is a conflict, priority order is:

1. `Game_Spec_and_Process_Guide.md`
2. `AI_Dialogue_Infrastructure.md`
3. `CODEX_TAKEOVER_PLAYBOOK.md`
4. `CODEX_WORKFLOW.md`
5. `THREAD_HANDOFF.md`
6. `Development_Summary.md`

## Product Direction (Non-Negotiable)

- Build a 2D fixed-camera online focus companion game inspired by the work/study call structure of Chill With You.
- The player launches the game to study, work, or focus with Yua as quiet company.
- The setting is a cozy video call / online chatroom, not the player physically entering Yua's room.
- No player avatar, no WASD movement, and no open-world navigation.
- Yua is always visible as the emotional anchor of the call.
- Interaction is click/tap plus dialogue UI, focus timer, task input, and limited Type Mode.
- The core loop is focus-first: check in, set a task/session, focus, then unlock break chat or story progress.
- Progression is based on completed focus sessions, total focus time, milestones, and memory, not calendar-day chapters.
- Scripted dialogue and authored story milestones are the backbone.
- AI is optional augmentation for check-ins, task understanding, memory extraction, post-session reflection, and limited casual chat.
- AI must not replace authored story progression or become an unlimited distraction before focus.
- Memory continuity must be game-side and persistent.
- Voice is deferred. Do not treat voice/TTS as required for the current implementation phase.

## Character And Story North Star

- Yua is calm, warm, introverted, observant, gently teasing, and emotionally safe.
- She is also working during the call, primarily on writing.
- The long-term story spine is: the more the player works alongside Yua, the more she opens up and progresses on her own creative work.
- Story should unfold through small disclosures, focus-session rewards, and session milestones.
- The game should feel useful as a productivity tool and emotionally meaningful as a character game.

## Architecture Principles

- Focus-session state is first-class: duration, task, completion, pauses/abandonment, total focus time, and milestone progress.
- Prefer deterministic game logic for progression and continuity: session counts, focus hours, memory tags, story flags, unlock rules.
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

- Refactor the existing demo direction into a focus-first online call loop:
  1. launch call
  2. time-aware greeting
  3. short check-in / task capture
  4. start focus session
  5. restrict distractions during focus
  6. finish session
  7. unlock break chat or scripted story progress
  8. persist focus totals, session count, memory, and story flags

Do not jump into deep polish, full voice, or advanced AI autonomy before this focus-first loop is stable.

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
