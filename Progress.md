# Progress.md — Project Chill Live State

> **Live state log. Claude is the single agent (planning + implementation), working directly in the main tree.**
> Read this first every session. Update it after every completed task or check.

---

## Current Phase

**Vertical Slice 01 — Co-Presence-First First Session** (in progress)

See `docs/Vertical_Slice_01_Spec.md`. Target: one polished end-to-end first session proving "I showed up, engaged however I liked, Yua was present with her own work, and the game remembered me."

1. Launch call → time-aware greeting (no mandatory task)
2. Cozy idle co-presence (Yua visibly doing her own work)
3. Optional focus session (with or without a task)
4. Only focus time + progressing through the authored script advance the story; light interactions are remembered and add warmth; idle advances nothing
5. Yua writing payoff beat after a completed focus session
6. Persist one consolidated profile: engagement, focus totals, memory, story flags, timestamps, Yua openness

---

## What Is Built

| Component | Status | Notes |
|---|---|---|
| Main scene + UI scaffold | ✅ Exists | Needs refactor from VN-room to online-call composition |
| Scripted dialogue JSON | ✅ Exists | Has intro, return, check-in, focus, small talk, goodbye, memory follow-ups; some supervisor-tone nodes need replacing |
| Dialogue router | ✅ Exists | `scripts/core/dialogue_router.gd` |
| Memory manager | ✅ Exists | `scripts/dialogue/memory_manager.gd` |
| AI dialogue service | ✅ Exists | `scripts/dialogue/ai_dialogue_service.gd` — mock fallback works without API key |
| Focus timer | ✅ Exists | Needs wiring as an optional, progression-driving tool |
| Todo / task input | ✅ Exists | Needs wiring as optional context |
| Music controls | ✅ Exists | Persona 5 placeholder BGM must be replaced before any public build |
| Voice manager | ✅ Exists | Plays pre-generated clips; no runtime TTS yet |

---

## What Is Not Yet Done

| Gap | Priority | Notes |
|---|---|---|
| Split-save bug | 🔴 High | `main_scene.gd` and `memory_manager.gd` write two different profile files — consolidate to one |
| Dialogue metadata dropped | 🔴 High | `ScriptedDialogueManager._register_node` discards `unlock`/`set_flags`/`tags`/`speaker` |
| Save schema for slice | 🔴 High | Add focus totals, story flags, Yua openness, profile version, corrupted-save recovery |
| Focus-driven progression gate | 🔴 High | Deterministic: focus time + script progress move story; light = warmth only; idle = nothing |
| Co-presence call loop wiring | 🔴 High | Launch → greeting → idle → optional focus → payoff → save → relaunch |
| Online-call visual composition | 🟡 Medium | Scene feels like a room, not a video call |
| UI hierarchy and polish | 🟡 Medium | Focus timer is one optional tool, not the hero control |
| Narrative: Yua bible + Ep 0/1 | 🟡 Medium | Mandarin, peer-not-supervisor, 75/25 avoidance/motivation |
| Idle video (`yua_idle_loop.ogv`) | 🟡 Medium | Wired but apparently not playing — import/playback/composition bug |
| Type Mode + memory loop | 🟡 Medium | Works but needs stronger intent |
| AI check-in integration | 🟢 Later | |
| Runtime TTS / voice | ⏸ Deferred | Not a slice blocker |

---

## Active Tasks

_None currently in flight._

---

## Completed Tasks

| Task | Notes |
|---|---|
| Initial project scaffold | Scene, dialogue JSON, memory, AI service all exist |
| Memory follow-up tags | school, exam, work, sleep supported |
| Mock AI fallback | Type Mode works without API key |
| Spec set for Vertical Slice 01 | `docs/Vertical_Slice_01_Spec.md` + `docs/prompts/*` written: co-presence-first, focus-drives-story |

---

## Blockers

_None currently._

---

## Next Recommended Action

Implement Vertical Slice 01, starting with the **progression/save plumbing** (`docs/prompts/prompt_progression_save_session.md`) — it unblocks narrative and UI work:
1. Consolidate the two save files into one profile + migration.
2. Extend the save schema (focus totals, story flags, Yua openness, profile version, recovery).
3. Fix `ScriptedDialogueManager._register_node` to preserve metadata.
4. Add the deterministic focus-driven progression gate.

Then narrative (Yua bible + Episode 0/1 + payoff) and UI (online-call framing).

---

## User Godot Checks Pending

_None currently._
_(Claude: list manual Godot steps here after any scene or flow change.)_
