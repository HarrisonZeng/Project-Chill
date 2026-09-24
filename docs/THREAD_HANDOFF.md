# Thread Handoff (Project Chill)

> Refreshed **2026-09-24** for a model/thread switch. Use this file to resume the project in a new
> Claude session. It is deliberately thin: **`Progress.md` is the live state** (its Session Log has
> the full 2026-09-23/24 build entry) — this file says what the project is, where it stands today,
> and how to pick it up. If they disagree, `Progress.md` wins.

## Project Snapshot

Project Chill is a Godot 4 (4.6) 2D fixed-camera **co-presence companion game**: the player opens
what feels like an online co-working call. Yua — a 21-year-old bookshop clerk in a seaside ferry
town, secretly writing a light novel — is on the other side. The player works or studies alongside
her, running optional focus-timer sessions (15/30/60). Mandarin-first; audience 小红书/Bilibili.
The owner (Harrison) is non-technical; explain in plain language, give numbered Godot steps.

Non-negotiables (full versions in `AGENTS.md`, which outranks everything):

- No player avatar, no movement. Fixed call framing; Yua always visible.
- Yua is a peer, never a supervisor. No mandatory tasks, no nagging, no 查岗, no 打卡 of the story.
  She never schedules the player (no 明天见 / 下次来). Absence is symmetric, never punished.
- **Only completed focus time advances story.** Clicks and typing add remembered warmth only;
  AFK advances nothing; AI cannot unlock story.
- Scripted Mandarin episodes are the backbone; AI (MiniMax-M3 via `MINIMAX_API_KEY`) is bounded
  augmentation: one reply beat, then back to authored nodes, always with a scripted fallback.
- Memory is game-side and persistent (one profile JSON via `memory_manager`).
- No romance framing, never "AI 女友"; no age/gender collection. Voice/TTS deferred.

## Where The Story Stands (2026-09-24)

- **Plan of record:** `docs/Story_Beat_Sheet_v3.md` — 60 episodes in five workplace chapters
  (书店 1–12 → 水族馆 13–24 → 咖啡店 25–36 → 花店/天文馆/民宿 37–48 → 回书店 49–60), novel revealed
  at Ep2, first AI-core episode Ep5, "主人公是你" thread 8→15→21→44→54→60, four focus-time gates
  (Ep12/24/47/60), 9 「她需要你」 episodes, a real readable ending. Owner + sister markup still
  pending (phone page: artifacts/yua_beat_sheet.html).
- **In the game (script v12, `data/dialogue/scripted_nodes.json`):** Ep0 (questionnaire → call →
  开局翻车 → name reaction from the profile) and **Ep1–Ep15 as playable drafts**. Ep1/Ep3(你听)/
  Ep6(脑子飞了) are owner-approved canon; everything else is 草稿 awaiting language passes.
- **Owner's taste (must read before writing any line):** `docs/Yua_Taste_Log.md` (vetoes +
  positive profile; outranks `docs/Chinese_Style_Guide.md`). Writers' grounding pack:
  `tools/zh_arena_out/context_pack.md`.

## Systems Built 2026-09-23/24 (all uncommitted in the main tree — owner reviews in Godot first)

| System | Files | Notes |
|---|---|---|
| Launch questionnaire | `scenes/ui/intake.tscn`, `scripts/ui/intake_controller.gd` | app voice, 昵称 / 一起学习·一起工作·其他; a "fun question" slot is reserved and empty |
| Script v12 + new node fields | `scripted_nodes.json`, `scripted_dialogue_manager.gd` | `remember`, `next_by_memory`, `typed_routes.remember_said`; `ACTION_NAME_REACT` |
| Daily cap (2 story eps/day) | `main_scene.gd` (`daily_episode_cap`) | harness sets 0 |
| Greeting selector | `scripts/core/greeting_selector.gd`, `data/dialogue/greeting_pools.json` | special date > away > door report > 「上次你说」(AI) > notebook > return > 时段×章 |
| Living notebook | `scripts/core/notebook_manager.gd`, `data/dialogue/notebook_pools.json`, 「她的本子」 in `tasks_panel_controller.gd` | one mention per visit |
| AI modes | `data/dialogue/ai_modes.json`, `yua_world.txt` | YOUR_THING / DOOR_IDEA / STUCK / HERO_NAME / LAST_TIME; verified live |
| AI plumbing fixes | `ai_dialogue_service.gd` (HTTPRequest per call), `main_scene.gd` (`_route_with_timeout`) | found by the live check |

Tests: `powershell -File "tools/godot_check/check.ps1"` → 25 scenarios green. Live model check:
`check.ps1 -Mode test -Scenario ai_live -Ai` (costs API credit) → 11/11.

## Next Up (in the order the owner and I agreed)

1. Owner reviews the build in Godot (steps in the 2026-09-24 Progress.md entry) and marks up the
   beat sheet; then **commit** (nothing from 09-23/24 is committed yet).
2. The "fun question" for the questionnaire (candidate: 「如果你写了一本书，会叫什么名字？」 → her
   file gets that placeholder title, paid off later) — owner to pick.
3. 「她的稿子」 reader panel (Ep12 chapter text is inline for now), 工作中自语 pool, per-chapter
   scene art, Ep16+ drafts, then language passes on all drafts with the taste log.
4. Standing: Yua's 16-frame art rebuild (B10, other session), 店长/店名/游戏名 placeholders.

## Key Files

- `Progress.md` — live state, active tasks, session log. **Read first.**
- `AGENTS.md`, `CLAUDE.md` — constitution + Claude's role (single agent, main tree, no worktrees)
- `SESSIONS.md` + `.sessions/` — multi-session file-ownership protocol
- `docs/Story_Beat_Sheet_v3.md`, `docs/Ambient_and_Systems_Draft_v1.md` — the plan for story and systems
- `docs/Yua_Taste_Log.md`, `docs/Chinese_Style_Guide.md`, `docs/Yua_World_Components.md` — writing contract + world
- `docs/Memory_of_Memorie_Research_2026-09-16.md`, `docs/CWYL_Xiaoheihe_Feedback_2026-08-17.md` — competitors
- `scripts/core/main_scene.gd` — coordinator/core loop · `tools/godot_check/` — test harness

The `docs/CODEX_*.md` files describe a retired two-AI workflow — deprecated, do not follow.

## Environment Quirks (save yourself an hour)

- Python: `C:/Users/zengh/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8`;
  openai lib at `tools/python_libs`. **Bash heredocs break on Chinese punctuation — write scripts
  to files with the Write tool.** Multi-line edits of `main_scene.gd` are safest via a small
  Python patch script asserting exactly one match per replacement.
- Keys are User env vars: `MINIMAX_API_KEY` (direct, api.minimaxi.com, model MiniMax-M3, `<think>`
  stripped client-side), `DEEPSEEK_API_KEY`. Never write keys into the repo.
- Codex via MCP: `gpt-5.4` is now rejected, `gpt-5.5` works. Arena runner: `tools/zh_arena.py`.
- Another session once left stray "780" lines in `scripts/audio/bgm_manager.gd` that broke every
  boot; if `check.ps1 -Mode boot` fails on a file you did not touch, `git diff` it first.
- Artifacts (phone pages) are private to the owner's login; a "deleted" message usually means a
  logged-out browser — send the HTML file with SendUserFile as a fallback.

## How To Resume

1. Read `CLAUDE.md`, `AGENTS.md`, then `Progress.md` (current phase + the 2026-09-24 entry).
2. Follow `SESSIONS.md`: check `.sessions/` claims, write your own before editing.
3. Run `powershell -File "tools/godot_check/check.ps1"` to confirm the green baseline.
4. Continue from **Next Up** above. Verify with the harness before handing anything to the owner.
