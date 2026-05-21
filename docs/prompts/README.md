# Project Chill — Specs & Workflow

## How we work

Claude is the **single agent** on this project. It does everything: design discussion, planning, and implementation, working **directly in the main tree** (no worktrees, no second AI).

1. **Design discussion** — the owner and Claude work out high-level direction together.
2. **Plan + implement** — Claude plans the work and implements it directly.
3. **Verify** — Claude checks its own work and gives the owner concrete Godot editor steps for anything visual.

(Earlier versions routed implementation to Codex via MCP. That is retired — ignore any "paste to Codex" wording in older notes.)

## Spec files (one per session / stream)

Each file is a self-contained kickoff brief for one work stream toward the
Vertical Slice 01 demo. Each carries its own `SESSIONS.md` claim and a model
recommendation. Scope is **Vertical Slice 01 only** — no full story arc, no
advanced AI autonomy.

| Brief | Stream | Owns | Model |
|---|---|---|---|
| `prompt_narrative_session.md` | Narrative & story | `scripted_nodes.json` + narrative docs | Opus |
| `prompt_progression_save_session.md` | Backend engine (progression/save/AI) | core scripts incl. `main_scene.gd` | Opus |
| `prompt_ui_session.md` | UI / online-call look | UI controllers + `main_scene.tscn` + theme | Sonnet |
| `prompt_animation_seedance_session.md` | Animation planning → `docs/Animation_Plan.md` + Seedance prompts | (doc only) | Sonnet |
| `prompt_audio_suno_session.md` | Music planning → `docs/Audio_Plan.md` + Suno prompts | (doc only) | Sonnet |

### Parallel ordering (collision-safe)

- **Run now in parallel:** Narrative + Animation + Suno + UI. Different files; the
  two asset briefs touch no code at all.
- **Engine waits** on the narrative session's milestone-flag contract, and shares
  `main_scene.gd` with UI — so run Engine **after** narrative delivers the contract
  and when UI is out of the core loop. Only one session in `main_scene.gd` at a time.
- See `SESSIONS.md` (root) for the full ownership map and the claim protocol.

(Filenames keep the `prompt_` prefix; treat them as specs.)
