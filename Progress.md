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

- **[ART/SOUND — live checklist]** `docs/Demo_Art_Checklist.md` holds every non-text item for the
  demo (room, Yua, sound, intro, UI, voice plan) with status and the open owner decisions. Read it
  first when doing anything visual or audio; tick items there, not here.

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

- **2026-08-17 (Ep2 CANON + style profile):** Round 7 verdict: merge option 2 (clear logic) ×
  option 5 (cuter, more anime-girl) — both Claude's. Merged canon in
  `Opening_and_Script_Directions.md` + decisions artifact (Ep2 card). Per owner request, taste
  log gained a **positive style profile** derived from actual picks (logic before flourish;
  cute = self-mockery + 理直气壮 + self-answered questions; metaphors childlike/lived-in not
  literary — 翻书/船打哈欠/纸边翘 beat 隔着雾按键/晾衣绳; two-sentence beats: state then
  release; concrete callbacks; ending = her next step + player's freedom). Private note: owner
  has picked the same writer's drafts in every round since grounding — proposed promoting it to
  primary drafter with others as challengers; awaiting owner. Context pack advanced to Ep3
  (theme: 坐不住 — she confesses her distractibility; relationship +half step).
- **2026-08-17 (Ep0 + Ep1 CANON):** Owner picked Ep0 option 5 and Ep1 option 5 (both Claude's).
  Root-cause admitted for the 封口费/目击者 spread: Claude wrote it in round 4, then mis-recorded
  it in the taste log as an owner-liked direction → all writers iterated on it. Retracted with an
  explicit note; new vetoes: 保密梗, 「明天再来」-style scheduling (Yua never arranges the
  player's time), 装傻过头. Context pack 铁律 #6 added. Ep1 beat 4 rewritten to close in the
  present («好，我接着写我的了…你想再来一段就再来，想歇就歇»). Canon text in
  `Opening_and_Script_Directions.md` and the decisions artifact (new ✅ 定稿 section; old V1/V2
  demoted to archive). NEXT: write Ep0-full + Ep1 into `scripted_nodes.json` v10 with new node
  IDs, name-reaction engine hook, task-notebook display, 15/30/60 chips; then arena round 7 = Ep2.
- **2026-08-17 (arena round 6 — structural fix):** Owner round-5 verdicts exposed the real
  bug: writers saw setting facts but not the STORY — hence 存档/建角色 non-sequiturs and Ep1
  jumping to shop anecdotes with someone she met 30 min ago. Fixes: context_pack.md rewritten as
  「到目前为止发生了什么」(canon opening verbatim + her exact emotional state + relationship
  state = zero mutual knowledge) with five 铁律; briefs now carry LOCKED beat order (Ep0: name →
  tools discovered together, not toured → 15/30/60 push; Ep1: talk about the session FIRST →
  branches → life leaks only via "你刚才在忙什么", one sentence, no shop events); zh_arena.py
  task text tells writers order is a contract; taste log +3 vetoes. Round 6 published: Ep0 ×6,
  Ep1 ×5 (DeepSeek returned one). Answer key kept private in
  `tools/zh_arena_out/round6_key.md` per owner ("don't want to know").
- **2026-08-17 (arena round 5 + grounding fix):** Owner round-4 verdicts: MiniMax benched as
  writer (stays for runtime/polish); Ep0's naming ask / transition / ending all vetoed as awkward
  or not-cute; Ep1 beat-1 玄学 line + 汇报 framing vetoed; Claude's 爱心变企鹅 tone canonized as
  non-main-plot benchmark. ROOT-CAUSE FIX for DeepSeek's non-native output: briefs never included
  the actual project — built `tools/zh_arena_out/context_pack.md` (game, world, canon opening,
  relationship state) + `docs/Yua_Taste_Log.md` (owner's accumulated vetoes/likes — every writer
  must read; updated each round) + `--extra` flag in zh_arena.py. Grounded DeepSeek immediately
  went native (收银机叮那声响得我耳朵发烫 / 绿萝排班表 excuse). Round 5 published: Ep0 back-half
  and Ep1, SIX options each (2 per writer: DeepSeek/Codex/Claude), blind, shuffled. Awaiting picks
  → stitch into scripted_nodes.json v10.
- **2026-08-17 (arena round 4):** Owner round-3 verdicts: Ep0 content A (Claude) minus the mic
  test (cut — game has no voice; Type_Mode_Design.md's EP0 free-line beat is dead), needs smooth
  work transition + task-notebook guide woven in + Yua's own visible-but-mysterious task
  (「继续写那个东西」= writing-line seed); B/C判定跑题. Ep1 redirected: happy not angry (chill
  game), hard length caps (≤2 sentences/beat, event ≤3). Round 4 published: Ep0 revision as
  direct-approval item + four NEW happy Ep1s (辣条奶奶 / 请带我回家便签 / 自动贩卖机荐书卡 /
  爱心变企鹅), labels reshuffled (A=MiniMax B=Codex C=DeepSeek D=Claude). Next: owner verdicts →
  write Ep0+Ep1 canon into scripted_nodes.json v10 → round 5 Ep2.
- **2026-08-16 (arena round 3, new format):** Owner round-2 verdicts absorbed (labels now ABCD;
  whole-EP vs whole-EP comparison; each writer must INVENT content, not re-phrase; 3a↔3b logic
  fixed by making beat 2 plant both hooks; continuity fix — she's a FIRST-TIME app user, all
  veteran-talk banned; M2-her tested and skipped: perfect guardrails but stage-direction habit +
  can't do meta-tasks). Round 3 ran BOTH missing scenes: Ep0 back half (naming→mic→first timer)
  and full Ep1 rewrites — 4 complete versions each, all-different 怒点 (公放剧透 / 冰美式毁书腰 /
  荐书卡当杯垫 / 试读本只到第三章). Published as whole-EP blind page, labels reshuffled
  (answer key: A=Claude B=DeepSeek C=Codex D=MiniMax). Awaiting owner verdicts → then stitch
  Ep0+Ep1 canon INTO scripted_nodes.json v10, then round 4 = Ep2. Owner picked per-line (1A 2B 3A+D 4A 5B 6B-modified).
  Stitched opening now canon in `Opening_and_Script_Directions.md` + decisions artifact. Key changes
  from verdict notes: game = penguin-style MOBA with recognizable MOBA slang (打野/别送/摆烂/重开 —
  no real game named; 小七-as-jungler becomes a post-aquarium easter egg); 小七→队友 in line 2;
  confession logic simplified (motive→evidence→病情自诊); **「同桌」 banned as non-native — app copy
  and all lines now use 搭子**. PROCESS FIX per owner: arena task rewritten — contestants are
  编剧不是翻译, free to restructure narrative/beats/jokes; only scene function + persona + placeholders
  are fixed. Applies from round 2.
- **2026-08-14 (writing arena):** DeepSeek key registered (User env `DEEPSEEK_API_KEY`; API
  exposes `deepseek-v4-pro` + `-flash`). Style guide gained a 目标线 section: bar = better than
  CWYL, cuter, native, in-situation 梗 only, anime-girl feel, "would the player screenshot this?"
  Built `tools/zh_arena.py` — ONE shared brief (guide+scene+lines) written to disk; MiniMax-M3 and
  DeepSeek-V4-Pro get the identical prompt string; Codex (via MCP, gpt-5.4 — default terra model
  needs newer CLI) reads the brief file locally; Claude writes its entry in-session. Round 1 run
  on opening-D's 6 lines; blind 甲乙丙丁 comparison published:
  https://claude.ai/code/artifact/92c804dd-4a84-9b86-f1c3f3d0e23e (answer key collapsed at
  bottom). Owner picks per-line winners → stitched into the final script. Flow repeats per episode.
- **2026-08-14 (Chinese quality pipeline):** Owner flagged persistent awkwardness in my Chinese.
  Built the systemic fix: `docs/Chinese_Style_Guide.md` (checkable contract — 翻译腔 blacklist,
  rhythm caps, Yua's five techniques, doc rules incl. "explain every proper noun on first use")
  + `tools/zh_polish.py` (runs any text/file through native MiniMax-M3 with the guide as rubric;
  outputs polished text + per-change reasons citing guide rules; 16k token budget because M-series
  thinks long — empty-output guard added). Demo on the owner-flagged 书咖 paragraph: killed
  「剧情的火就从这点燃」→「故事就从这儿开头」,「努力有了着落」 nominalization, long attributives
  split. Polished copy applied to artifact + world doc. New writing flow: Claude drafts content →
  M3 polishes per guide → Claude re-checks hard rules → owner sees only flagged deltas.

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
