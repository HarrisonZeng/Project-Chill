# Progress.md — Project Chill Live State

> **Sync point for Claude and Codex.**  
> Read this first every session. Update it after every completed task or review.

---

## Current Phase

**Phase 1 — Focus-First Loop** (in progress)

Target: a working, playable focus-session loop:
1. Launch call → time-aware greeting
2. Short check-in / task capture
3. Start focus session
4. Restricted interactions during focus (accountability lines only)
5. Finish session → unlock break chat or scripted story beat
6. Persist: session count, total focus time, memory, story flags

---

## What Is Built

| Component | Status | Notes |
|---|---|---|
| Main scene + UI scaffold | ✅ Exists | Needs refactor from VN-room to online call composition |
| Scripted dialogue JSON | ✅ Exists | Includes intro, return, check-in, focus, small talk, goodbye, memory follow-ups |
| Dialogue router | ✅ Exists | `scripts/core/dialogue_router.gd` |
| Memory manager | ✅ Exists | `scripts/dialogue/memory_manager.gd` |
| AI dialogue service | ✅ Exists | `scripts/dialogue/ai_dialogue_service.gd` — mock fallback works without API key |
| Focus timer | ✅ Exists | Needs wiring to focus-first game loop |
| Todo / task input | ✅ Exists | Needs wiring |
| Music controls | ✅ Exists | Needs wiring |
| Voice manager | ✅ Exists | Plays pre-generated clips; no runtime TTS yet |

---

## What Is Not Yet Done

| Gap | Priority | Notes |
|---|---|---|
| Focus-first call loop wiring | 🔴 High | Core gameplay — Phase 1 target |
| Focus state restricts chat | 🔴 High | Accountability lines only during focus |
| Session completion → story unlock | 🔴 High | Scripted milestone trigger |
| Session count + focus time persistence | 🔴 High | Save shape exists; wiring needed |
| Online call visual composition | 🟡 Medium | Scene feels like a room, not a video call |
| UI hierarchy and visual polish | 🟡 Medium | Reduce clutter, improve readability |
| Type Mode + memory loop | 🟡 Medium | Works but needs stronger intent |
| Reactive line pool depth | 🟢 Later | Phase 4 |
| AI check-in integration | 🟢 Later | Phase 3 |
| Runtime TTS / voice | ⏸ Deferred | Not a Phase 1 blocker |

---

## Active Tasks

_None currently in flight. Assign a task to Codex when ready._

| Task | Owner | Branch | Status |
|---|---|---|---|
| — | — | — | — |

---

## Completed Tasks

| Task | Branch | Merged | Notes |
|---|---|---|---|
| Initial project scaffold | — | ✅ | Scene, dialogue JSON, memory, AI service all exist |
| Memory follow-up tags | — | ✅ | school, exam, work, sleep supported |
| Mock AI fallback | — | ✅ | Type Mode works without API key |

---

## Blockers

_None currently._

---

## Next Recommended Action

**Claude:** Discuss the Phase 1 focus-first loop refactor plan with Codex.  
Propose which Codex worker thread to run first (per merge order: Scriptwriting → Memory → AI → Reactive → Core Gameplay → UI → QA).

Suggested first task for Codex: **Core Gameplay** — wire the focus-first call loop in `scripts/core/main_scene.gd`.

---

## Merge Log

| Date | Branch | Accepted by | Summary |
|---|---|---|---|
| — | — | — | — |

---

## User Godot Checks Pending

_None currently._  
_(Claude: list manual Godot steps here after any scene or flow change.)_
