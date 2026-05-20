# Project Chill — Specs & Collaboration Workflow

## How we work

1. **Design discussion** — high-level design happens between the owner and Claude.
2. **Specs** — after discussion, Claude writes design + implementation specs (the files in this folder, plus `docs/Vertical_Slice_01_Spec.md`).
3. **Implementation** — the owner pastes the relevant spec to Codex (Codex CLI/IDE), discusses with it if needed, and Codex implements.
4. **Review** — Claude reviews the finished code only when the owner asks, ideally via a diff or a specific file, not a full re-read.

Claude does **not** call Codex through MCP to discuss or implement. The owner routes implementation to Codex directly. This keeps Claude's token use to design + spec-writing + targeted review, and keeps Codex's reading/iteration off Claude's context.

## Spec files (paste to Codex)

Each file is a self-contained implementation spec. All are scoped to **Vertical Slice 01 only** — do not expand into the full game, full story arc, voice work, or advanced AI autonomy.

1. `prompt_progression_save_session.md` — run **first** (or in parallel). One-profile save migration, option-B deterministic progression, and the `ScriptedDialogueManager` metadata fix. Unblocks the other two.
2. `prompt_narrative_session.md` — Yua's Mandarin character bible, Episode 0, Episode 1, and the slice payoff beat.
3. `prompt_ui_session.md` — cozy online-call UI framing. Pause after mockups before implementing.

(Filenames keep the `prompt_` prefix for now; treat them as specs.)
