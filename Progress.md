# Progress.md — Project Chill Live State

> **Live state log. Claude is the single agent (planning + implementation), working directly in the main tree.**
> Read this first every session. Update it after every completed task or check.
> Last full audit: **2026-08-09 (overnight)** — every claim below was verified against the actual code, not prior docs.

---

## Current Phase

**Demo Ship Push** — target: a postable Windows demo + short video for 小红书/Bilibili in ~6 weeks.
Master plan: `docs/Demo_Ship_Plan.md` (week-by-week, with [CLAUDE]/[YOU] on every task).

Vertical Slice 01 (co-presence-first session) is **functionally complete in code**; remaining work is
look (call-frame composition), script depth, Windows export, and packaging/marketing.

---

## What Is Built (verified 2026-08-09)

| Component | Status | Notes |
|---|---|---|
| Single-profile save + migration + corruption recovery | ✅ | `memory_manager.gd` owns `user://data/saves/player_profile.json`; legacy path migrated |
| Deterministic progression gate | ✅ | `scripts/core/progression_gate.gd` — focus-only; clicks/idle never advance story |
| Episode system Ep0–Ep14 (Mandarin, v9) | ✅ | Flag-guarded; intimacy eps also gated on real accumulated focus seconds |
| Co-presence loop end-to-end | ✅ | idle → click-to-talk → time-aware greetings (4 buckets × 3) → optional task → focus → episode reveal → settle → save → relaunch recognition (short-return variant <30 min) |
| Focus timer | ✅ | Chips 15/25/45 + custom + dev-only 3-sec test; abort path is guilt-free (`ABORT_001`) |
| Nickname + tokens | ✅ | `{name}`, `{focus_minutes}` |
| Type Mode + AI modes | ✅ | Always-on input; BREAK_CHAT / TASK_CLARIFY; mock provider without API key; AI privacy toggle wired |
| Memory follow-ups | ✅ | school / exam / work / sleep |
| Reactive click lines | ✅ | 23 lines in `reactive_lines.json`; "……" after 4+ pesters during focus |
| Beat-by-beat dialogue display | ✅ | Blank line = one beat; choices appear after last beat |
| BGM (Suno production tracks) | ✅ | Persona 5 placeholder REMOVED — no longer a blocker |
| Music bar / settings / chat history / EN-ZH toggle | ✅ | |
| Debug tools | ✅ | Episode jumper + save reset (`DEBUG TIMELINE` block, `main_scene.gd:1760+`); auto-hidden in release exports |
| Web (browser) export | ✅ | `Web` preset in `export_presets.cfg`; gl_compatibility override; verified booting + playable in Chromium |
| Bundled CJK font | ✅ | `assets/fonts/chill_kai_gb.woff2` (1.5 MB subset) as theme fallback — browser builds have no system fonts |
| Auto-publish to itch.io | ✅ live | <https://hzen666.itch.io/project-relax> (password-restricted). Every push to `main` republishes in ~3 min — see `docs/Web_Demo_Publishing.md` |
| Real AI replies in the browser demo | ⏸ one step left | Key ships inside the build (`baked_keys.gd`, filled by CI). Owner must run `gh secret set MINIMAX_API_KEY` once; until then the demo uses mock replies |
| Voice | ⏸ deferred | `voice_manager` plays pre-generated clips but **no clip assets exist**; fine for demo |
| Idle video mode | ⏸ off by choice | File deliberately renamed `yua_idle_loop_disable.ogv`; rename back to re-enable (decision D2) |

## What Remains for the Demo (the real list)

| Gap | Priority | Owner | Notes |
|---|---|---|---|
| Script depth pass (Ep1/2/3/5, FOCUS_DONE, ep13 honesty line) | 🔴 | Claude after owner verdicts | Proposal awaiting checkmarks: `docs/Yua_Script_Polish_Proposal.md` |
| Call-frame visual composition | 🔴 | Claude implements; owner picks direction | Biggest lever for 小红书 scroll-appeal |
| Windows export preset (only Xogot/iPad/Web exist) | 🔴 | Claude writes preset; owner exports | `export_presets.cfg` |
| ~~itch.io page + `BUTLER_API_KEY` secret~~ | ✅ | Owner, done 2026-08-13 | Demo live and password-restricted |
| `gh secret set MINIMAX_API_KEY` so the demo gives real AI replies | 🟡 | Owner, 1 command | Claude cannot do this one — it will not handle API keys. Command in `docs/Web_Demo_Publishing.md` |
| Open the live demo with the password and confirm it boots | 🟡 | Owner, 2 min | Only check Claude could not run; the page password blocks it |
| All-Chinese surface (system status lines are English) + zh default | 🟡 | Claude | B4/B5 in ship plan |
| ~~Gate "3 秒试玩" chip behind debug flag~~ | ✅ | Claude | Now hidden unless `_debug_timeline_enabled()` |
| ~~Debug bar off at ship~~ | ✅ | Claude | Now driven by `OS.is_debug_build()`; on in editor, off in release |
| Friend test (2–3 people) | 🟡 | Owner | Week 4 |
| Post assets: video capture, copy, itch page | 🟡 | Claude drafts; owner records/posts | Week 5–6 |

---

## Active Tasks

- **DIRECTION FINAL (8/13 evening).** 主职 = 书咖 (轻小说书店×咖啡角, placeholder 灯塔书咖);
  副业 = 水族馆 (小七/企鹅/Hina kept); B1 seaside; C1 fantasy/轻小说; opening D confirmed with
  explicit co-work-app framing; EP0 name-AI-reaction confirmed; 勇哥360° meme as a swappable
  时事单元 slot; **暗线 DELETED**. See `Yua_World_Components.md` v3 + revised opening D beats.
- **[OWNER — naming only]** ① 店长=退休轻小说编辑 yes/no ② 书咖 name ③ fake game name.
  Placeholders are usable; not blocking.
- **[CLAUDE — next big task, unblocked]** Write final Ep0–5 into `scripted_nodes.json` (v10):
  书咖 world + opening D + name-AI-reaction + V1 skeleton transplanted (aquarium eps → 副业
  weekend eps). Then 杂谈池 pools.
- **[CLAUDE — next session]** Implement dialogue UI 方案 A in `main_scene.tscn` + controllers.
- **[CLAUDE — next session]** Type Mode implementation (`docs/Type_Mode_Design.md` §4) + persona
  fixes found in AI sampling (stage-direction leak, romance over-escalation).
- **[CLAUDE]** B4/B5 (all-zh system strings, zh default) — unblocked.
- **[OWNER — decides]** Word two in-fiction Mandarin replacements for the English UI-speak in
  `dialogue_router.gd:10-11` (details in "User Godot Checks Pending"). Found by `godot_check`.
- **[OWNER — asset]** If opening B chosen: generate the 10–15s "her desk" AI video (shot list in
  the openings doc — hands/desk/rain only, no face).

## Blockers

_None._

---

## User Godot Checks Pending

**Checks 1–4 no longer need you.** `tools/godot_check/` now runs the real game headless and
verifies them automatically (~8s):

```bash
powershell -File "tools/godot_check/check.ps1"
```

| Old manual check | Now automated as | Result |
|---|---|---|
| 1. EP0 must not restart, no greeting spam | `first_click` | ✅ 8/8 |
| 2. Focus-click cooldown gives "……" | `focus_click` | ✅ 8/8 |
| 3. Ep1 then **Ep2** (flags survive a restart) | `episodes` | ✅ 5/5 |
| 4. Typed reply: no chips, no "回到按钮" wording | `type_mode` | ⚠️ 7/8 — see below |

Each was proven to fail before it passed: removing `ep01_seen` from `ep01_01` makes `episodes`
report `expected 'ep02_01', got 'ep01_01'`, i.e. the exact original bug.

**Check 4 found a real leak.** `dialogue_router.gd:10-11` still returns English UI-speak on the
two non-happy paths — `AI_FALLBACK_TEXT` ("…continue with the buttons.") when a configured
provider call fails, and `AI_DISABLED_TEXT` ("Type Mode is off right now, so let's keep to the
buttons…") when AI is switched off in settings. The 2026-08-09 fix only replaced the *empty*
reply case in `_handle_ai_route`, so these two survived. Needs two in-fiction Mandarin lines in
Yua's voice — **[OWNER] to word them**, then Claude swaps them in and `type_mode` goes green.

Claude can now also *see* the game without you. `check.ps1 -Mode shot -Node ep03_01 -Sessions 3`
jumps to any beat, opens a real window for ~2s, and saves PNGs to `tools/godot_check/shots/`
which Claude reads directly. So layout, overlap, clipping and wrong text no longer need you
either. What still does: feel, pacing, animation, audio.

---

## Session Log

- **2026-08-11 (creative package completed):** Closed the two gaps in
  `Opening_and_Script_Directions.md`: V2「站台与申请季」now has a full line-by-line Ep0–5
  (written against 套餐一 station-town+songwriting so it tastes both the stakes AND an alternate
  world; opening eavesdrop = her humming, Ep5 pays it off with the station-jingle 三个音 backstory,
  Suno-able). Stage-direction leak (PART 4 defect #1) fixed in `yua_runtime_rules.txt` — AI may
  never output （动作）; authored lines still may. Doc topped with a status box mapping owner's
  partial verdicts. All three deliverables of the 8/10 creative goal now exist: 3 openings ·
  3 scripts with plot (V1 + V2 line-by-line, V3 = V1+暗线 delta lines) · 杂谈池 separated ·
  AI-voice alignment table applied. Awaiting owner: opening pick, world 套餐, script direction.
- **2026-08-11 (tone guardrails):** Owner phone-testing found ① "……" in nearly every reply
  (read as gloomy) and ② instant love-confession when asked 你喜欢我吗. Fixed in three layers:
  `yua_system_prompt.txt` (ellipsis capped at 1/reply + never as opener, default mood 平静明亮;
  romance section rewritten as concrete rules — never say/confirm 喜欢, deflect-and-redirect
  examples, visible cool-down if pushed), `yua_runtime_rules.txt` (same two rules compactly, in
  the highest-authority layer), `yua_studio.py` (studio now injects a relationship-stage context
  like the game does — configurable via `stage_note` in config.json — fixing studio-Yua running
  warmer than game-Yua). Re-probed with the exact failing messages: confession gone, 搭子就是搭子
  deflections, ellipses 0–1/reply. Game benefits automatically (same files + its own openness
  gates). Owner must restart the studio server to pick up the stage-note code.
- **2026-08-10 (phone studio v2):** Owner feature requests: 排练台词 is now a proper on/off toggle
  (button lights up; exits on second tap); multiple named chat sessions with a header picker
  (默认 session stays shared with the CLI studio; new sessions live in
  `yua_studio_data/sessions/`); persona editor on the phone (人设/世界/规则 tabs — saves go live
  for studio AND game next message, timestamped backup to `prompt_backups/` before every save,
  too-short saves refused). Also: found 3+ stale servers shadowing the port from earlier smoke
  tests (git-bash kill doesn't kill Windows processes) — killed them all and the server now
  refuses to double-start with a clear message. All endpoints tested green via PowerShell.
- **2026-08-10 (phone studio):** Built `tools/yua_studio_web.py` — mobile web version of Yua
  Studio served from the PC (LAN or Tailscale), sharing the same persona files, memory.md,
  history, and MiniMax-M3 line as the CLI + game. Token-protected URL, mobile chat UI with
  她记得什么 / 提炼记忆 / 排练台词 buttons. Smoke-tested live (page, chat, memory endpoints).
  `tools/yua_studio_data/` added to .gitignore (owner's private chats never enter git).
  Recommendation recorded: MiniMax consumer apps (星野/海螺) rejected as tuning bench — different
  model stack + memory, no file sync back to the project.
- **2026-08-10 (AI provider switch):** Game + Yua Studio now use the owner's direct MiniMax
  subscription: key stored as User env var `MINIMAX_API_KEY` (never in git), endpoint
  `api.minimaxi.com` (`.io` rejects this key), default model **MiniMax-M3** (tested faster AND
  better in-voice than M2.7-highspeed, which broke into English once). M-series returns inline
  `<think>` reasoning — added `_strip_reasoning` in `ai_dialogue_service.gd` + same strip in the
  studio, and `max_tokens: 3000` so thinking can't starve the visible reply. Provider order:
  MiniMax → Poe → mock. `godot_check`: all suites green except the pre-existing `type_mode` 7/8
  (the `dialogue_router.gd:10-11` English lines, still awaiting owner wording). NOTE for owner:
  restart the Godot editor once so it picks up the new env var.

- **2026-08-10 (tooling session, part 2):** Added self-service screenshots. `g.shot(label)` can be
  called at any point in a scenario (no-op headless, so it's free to leave in), and
  `-Mode shot -Node <id> -Sessions <n>` jumps to any authored beat and photographs it plus its
  first reply. Claude reads the PNGs directly, so visual checks (layout, overlap, clipping, wrong
  text) no longer need the owner. New `look` scenario is the camera. Fixed: the harness closed the
  AI gate before `_ready()` had run (adding a node during `_initialize` doesn't fire ready until
  the first frame), which crashed on `tasks_ui`.

- **2026-08-10 (tooling session):** Built `tools/godot_check/` — Claude can now run the game
  itself instead of asking the owner to open Godot. `check.ps1` drives Godot headless through
  the real `main_scene.tscn` (clicks Yua, walks dialogue, runs the focus timer, restarts the
  game) and reports in ~8 lines, in ~8s total. Modes: `lint` (0.4s), `boot`, `test`,
  `shot` (windowed PNG). 7 scenarios; 6 green, `type_mode` red on a real find (English UI-speak
  in `dialogue_router.gd:10-11`). Backs up the owner's save and disables AI, so runs cost
  nothing and can't clobber progress. Manual checks 1–3 retired. `CLAUDE.md` now requires
  running it before handing work over.

- **2026-08-09 (overnight, market-research session):** Competitive landscape research →
  `docs/Market_Landscape_AI_Companion_Games.md`. Full code audit; Progress.md corrected (previous
  version listed already-fixed items as open). Wrote `docs/Demo_Ship_Plan.md` and
  `docs/Yua_Script_Polish_Proposal.md`. No game code or script JSON touched.
- **2026-08-09 (day, same session):** Owner decisions D1–D4 + UI-A recorded (two-stage strategy:
  concept videos first, playable later). Fixed: `set_flags` Array form ignored (episodes could
  repeat forever), EP0 restart on click, greeting spam (per-session opener + new idle_click pools),
  focus-click 3-min reply cooldown, all OOC "按钮" wording in the AI path (no meta chips; in-fiction
  fallback line). New docs: `Type_Mode_Design.md`, `User_Feedback_Mining.md`,
  `mockups/dialogue_ui_mockup.html`. Key research find: CWYL players' top request cluster (43
  mentions) is free-form AI chat — our differentiator, validated by the competitor's own audience.
- **2026-08-10 (later):** V3 direction approved; aquarium flagged as placeholder. Wrote
  `docs/Yua_World_Components.md` (component menu: 8 day-jobs × 5 places × 6 dreams × 9 seasonings +
  3 pre-built 套餐, 新海诚 calibration). Built `tools/yua_studio.py` — persistent persona chat
  (memory.md + history + /draft rehearsal mode + /model switch), smoke-tested live. Owner still
  thinking on: opening choice, world 套餐. Next Claude work blocked only on those two picks.
- **2026-08-10:** Analyzed CWYL's actual extracted script (`tmp/cwyl_extract/`): their tutorial is
  as plain as ours; their hook is Satone's biography+stakes by Ep3 and full voice/motion aliveness.
  Root cause of "AI mode is cuter than script" (girlfriend feedback): the AI has the Layer-2 world
  (aquarium, 小七, sea town) that the script never uses. Sampled live AI voice via Poe/minimax with
  the real persona stack (10 scenarios) and extracted 5 copyable voice techniques; found 2 persona
  bugs (stage directions leak, romance over-escalation). Wrote
  `docs/Opening_and_Script_Directions.md`: 3 openings (A eavesdrop+answer-call, B AI-video "her
  desk" POV, C silent in-medias-res), 3 full Ep0–5 script directions with real plot (V1 aquarium+
  night-document, V2 application-season stakes, V3 = V1 + fixed-pairing mystery thread), separated
  杂谈池 (15 categories), and the yua_draft.py AI-drafting-pipeline proposal. Awaiting owner picks.
