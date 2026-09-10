# Thread Handoff (Project Chill)

> Refreshed 2026-09-05. Use this file to resume the project in a new Claude session or on
> another machine. It is deliberately thin: **`Progress.md` is the live state** — this file only
> says what the project is and how to pick it up. If they disagree, `Progress.md` wins.

## Project Snapshot

Project Chill is a Godot 4 (4.6) 2D fixed-camera **co-presence companion game**: the player opens
what feels like an online co-working call. Yua — a bookshop clerk writing her own novel — is on
the other side, working on her manuscript. The player works or studies alongside her, optionally
running focus-timer sessions. Mandarin-first; the demo audience is 小红书/Bilibili.

Non-negotiables (full versions in `AGENTS.md`, which outranks everything):

- No player avatar, no movement. Fixed call framing; Yua always visible.
- Yua is a peer, never a supervisor. No mandatory tasks, no nagging, no 打卡.
- **Only completed focus time advances story.** Clicks and Type Mode add remembered warmth only;
  AFK advances nothing; AI cannot unlock story.
- Scripted Mandarin episodes (Ep0–Ep14, flag-guarded, v10 for Ep0–Ep2) are the backbone.
  Type Mode (always-on free-text → AI, MiniMax-M3 → Poe → mock) is bounded augmentation.
- Memory is game-side and persistent (one profile JSON via `memory_manager`).
- Voice/TTS deferred and isolated behind `voice_manager`.

## Current Goal

**Demo Ship Push** (`docs/Demo_Ship_Plan.md`): a postable web/Windows demo + short vertical video.
The web demo already auto-publishes to itch (password-restricted) on every push to `main`.
Immediate milestone: a sister-review build — see the [THIS WEEKEND] block in `Progress.md`.

## Key Files

- `Progress.md` — live state, active tasks, session log. **Read first.**
- `AGENTS.md`, `CLAUDE.md` — constitution + Claude's role (single agent, main tree, no worktrees)
- `SESSIONS.md` + `.sessions/` — multi-session file-ownership protocol
- `docs/Dialogue_Flow_Map.md` — the dialogue decision tree as-built + the 2026-08-19 bug fixes
- `docs/Demo_Art_Checklist.md` — every non-text demo item, with open owner decisions
- `docs/Chinese_Style_Guide.md` + `docs/Yua_Taste_Log.md` — writing contract; taste log outranks guide
- `scripts/core/main_scene.gd` — coordinator/core loop · `data/dialogue/scripted_nodes.json` — script
- `tools/godot_check/` — self-serve test harness (`check.ps1`; run before any handoff)
- Research: `docs/User_Feedback_Mining.md` (Steam), `docs/CWYL_Xiaoheihe_Feedback_2026-08-17.md` (CN)
- Marketing: `docs/Social_Post_Drafts_2026-08.md`

The `docs/CODEX_*.md` files describe a retired two-AI workflow — deprecated, do not follow.

## How To Resume

1. Read `CLAUDE.md`, `AGENTS.md`, then `Progress.md` (current phase + active tasks).
2. Follow `SESSIONS.md`: check `.sessions/` claims, write your own before editing.
3. Run `powershell -File "tools/godot_check/check.ps1"` to confirm the green baseline (~8s).
4. Continue from the top item in `Progress.md` Active Tasks. Verify with the harness before
   handing anything to the owner; give the owner numbered Godot steps for anything visual.
