# AGENTS.md

## Purpose

This file aligns all agents working in this repository on one shared product direction and execution standard.

## Source of Truth

All agents must read these docs before proposing or making changes:

1. `docs/Game_Spec_and_Process_Guide.md`
2. `docs/Development_Summary.md`
3. `docs/AI_Dialogue_Infrastructure.md`

If there is a conflict, priority order is:

1. `Game_Spec_and_Process_Guide.md`
2. `AI_Dialogue_Infrastructure.md`
3. `Development_Summary.md`

## Product Direction (Non-Negotiable)

- Build a visual-novel style companion demo inspired by the provided reference image.
- No player avatar and no WASD movement.
- Fixed scene focused on the female character.
- Interaction is click/tap + dialogue UI.
- Dialogue is hybrid: scripted as primary, AI mode as optional augmentation.
- Voice output is required for character responses.
- Memory continuity must be game-side and persistent.

## Architecture Principles

- Prefer deterministic game logic for continuity (memory tags, follow-up triggers).
- Do not rely on model conversation history as the only memory source.
- Keep AI behind a service boundary (`ai_dialogue_service`) to allow provider swaps.
- Keep scripted dialogue as the backbone for tone and narrative stability.
- Add fail-safe fallbacks for API or TTS failure.

## Delivery Standards

- Implement in small vertical slices that are playable/testable.
- Preserve beginner-friendly structure and explainability.
- Avoid large untested rewrites.
- Add or update docs when behavior or architecture changes.
- Keep assets and scripts organized by the folder layout in the spec doc.

## Phase Focus

Current target phase:

- VN foundation + scripted dialogue loop + memory persistence scaffold.

Do not jump into deep polish or advanced systems before baseline loop is stable.

## Agent Handoff Protocol

When handing off work, include:

- what changed
- what is working
- what is not implemented yet
- exact next recommended step

## Human Collaboration Rule

The user is non-technical and should receive concrete Godot editor steps, not only abstract architecture advice.
