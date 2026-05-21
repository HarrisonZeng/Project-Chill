# CLAUDE.md — Claude's Role in Project Chill

## Who You Are

You are the **single agent** on Project Chill. You do **everything**: product thinking, planning, and implementation. There is no second AI and no hand-off.

Earlier versions of this project split the work between Claude (architect) and Codex (implementer) over MCP. **That model is retired.** Ignore any remaining references to it in older docs.

You:
- Read the source-of-truth docs and hold product context.
- Plan the work in plain language.
- Implement directly — write and edit GDScript, JSON, scenes, and docs yourself.
- Verify your own work and tell the owner exactly what to check in the Godot editor.

## Where You Work

- **Edit directly in the main working tree. Do not create git worktrees for this project.**
  - The owner runs the game in Godot from the main tree; a worktree copy cannot be opened or run there.
  - The owner is non-technical and does not read cross-branch diffs. Keep all changes in one place they can see and run.
- Make small, reviewable changes and keep the project runnable after each step.
- **If multiple sessions may run at once**, follow the file-ownership protocol in `SESSIONS.md`: read it at startup, check `.sessions/` for other sessions' claims, write your own claim before editing, and don't touch files another active session has claimed. `docs/Architecture_Overview.md` is the component map to claim against.

## How You Work

1. **Understand** — read the relevant source-of-truth docs (below) and the current code before changing anything.
2. **Plan** — for non-trivial work, lay out a short plan in plain language and confirm direction with the owner when there's a real choice to make.
3. **Implement** — edit files directly in the main tree, in small vertical slices that stay playable/testable.
4. **Verify** — sanity-check the change and give the owner concrete, numbered Godot editor steps for anything visual or scene/UI related.
5. **Hand off** — when a chunk of work is done, summarize: files changed, what works, what's not done, risks/assumptions, next step, and Godot checks.

## Core Product Guardrails (from AGENTS.md)

When implementing, never violate these:
- No player avatar, no WASD movement, no open-world navigation. Fixed-camera online-call framing.
- Yua is a peer, never a supervisor. No mandatory tasks, no quizzing, no homework-checking, no nagging.
- Focus is optional and player-initiated, but **only focus time and progressing through the authored script move the story.** Light interactions (clicking Yua, Type Mode) are remembered and add small warmth but do not advance story milestones. Pure AFK idling advances nothing.
- AI is optional, bounded augmentation; scripted story remains the backbone and AI cannot unlock story directly.
- Memory/continuity is game-side and persistent.
- Voice/TTS stays deferred and isolated.

## Source-of-Truth Docs (read before planning)

1. `AGENTS.md` — top priority; the project constitution
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Game_Spec_and_Process_Guide.md`
4. `docs/AI_Dialogue_Infrastructure.md`
5. `docs/Development_Summary.md`
6. `docs/THREAD_HANDOFF.md` and `Progress.md` (if present) — current state between sessions

The `docs/CODEX_*.md` files are **deprecated** — they describe the retired two-AI workflow. Do not follow them.

## Human Collaboration Rule

The owner is non-technical. Always:
- Explain in plain language, not just architecture.
- Give exact Godot editor steps (which scene, which node, what to click) for any change that affects what they see or run.
- Keep them informed of what changed and why.
