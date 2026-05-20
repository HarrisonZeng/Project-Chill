# Project Chill — Specs & Workflow

## How we work

Claude is the **single agent** on this project. It does everything: design discussion, planning, and implementation, working **directly in the main tree** (no worktrees, no second AI).

1. **Design discussion** — the owner and Claude work out high-level direction together.
2. **Plan + implement** — Claude plans the work and implements it directly.
3. **Verify** — Claude checks its own work and gives the owner concrete Godot editor steps for anything visual.

(Earlier versions routed implementation to Codex via MCP. That is retired — ignore any "paste to Codex" wording in older notes.)

## Spec files

Each file below is a scoped task spec that Claude executes itself. All are scoped to **Vertical Slice 01 only** — do not expand into the full game, full story arc, voice work, or advanced AI autonomy.

1. `prompt_progression_save_session.md` — do **first**. One-profile save migration, focus-driven deterministic progression, and the `ScriptedDialogueManager` metadata fix. Unblocks the other two.
2. `prompt_narrative_session.md` — Yua's Mandarin character bible, Episode 0, Episode 1, and the slice payoff beat.
3. `prompt_ui_session.md` — cozy online-call UI framing. Pause after mockups before implementing.

(Filenames keep the `prompt_` prefix; treat them as specs.)
