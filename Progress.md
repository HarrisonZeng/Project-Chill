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

- **[OWNER — decides] How should free typing and the authored script hand off to each other?**
  This is the one reported dialogue bug NOT fixed on 2026-08-19, because it is a design question,
  not a defect. Today: Type Mode is always on, typed text goes to the AI from wherever the player
  is standing, and there is no notion of "returning to the story" — the scripted position is just
  whatever node was last shown. Since the old Type Mode toggle was removed, `current_ai_mode_id`
  and the `AI_MODE_*` choice ids may now be dead code (no node in the current script uses them).
  Options, in plain language: **(a)** free chat is a side conversation that always drops back to
  where she left off; **(b)** free chat simply continues from wherever it is and the next focus
  session pulls the story forward (simplest, closest to today's behaviour); **(c)** she gently
  steers back after a few turns. Claude recommends **(b)** — it matches "focus is the only thing
  that moves the story" and lets us delete the dead mode machinery. See
  `docs/Dialogue_Flow_Map.md` §6.

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

**v10 script is live — Ep0/Ep1/Ep2 canon in the game (2026-08-19).** Harness 66/66 green.
Owner playtest (~15 min, F5 in Godot):

1. Debug bar **Reset Save** → close → F5 → click Yua. Expect the new cold open: MOBA lines
   («上啊上啊——打野呢？！»), «重开», then **click through «（点击接通）»**, her panic +
   confession + 「重新读档」. ⬜ Does the pacing of the beats feel right? Too many clicks?
2. Name ask («请问怎么称呼？») → **type a nickname in the input box** → «{name}。好，这就算认识了». ⬜
   (AI 取名反应 not yet wired — that's a Type-Mode-Design.md §1 task; today it goes straight
   to the acknowledgment.)
3. Tools beat → try **both** «我也写一句» (type a task → «嗯，收到。『…』那，选个时长») and
   «先不写了» → the 15/30/60 pick. **Picking starts focus immediately** — confirm no extra
   "开始" step. ⬜
4. Let a session finish (custom chip → 1 min, or debug 3-sec) → **Ep1** with three choices;
   try «你刚才在忙什么？» → «在忙……本子上那个『东西』…啊，说多了。就这样！» → 收尾. ⬜
5. Second completed session → **Ep2**: pick «要有点声音» → «你听» → the sea/horn/leaves beat →
   «啊啊啊这么文艺的句子…当我没说！你什么都没听见！» ⬜ **This is the money beat — does it
   read cute on screen, in rhythm, at your typewriter speed?**
6. HUD chips now 15/30/60 (default 30). ⬜
7. Screenshot anything that looks off. Known/expected: UI labels still English until B4/B5.

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
| 4. Typed reply: no chips, no "回到按钮" wording | `type_mode` | ✅ 8/8 |
| 5. Ep0 never replays (incl. relaunch + debug jump) | `ep0_once` | ✅ 4/4 |
| 6. No English/system text in Yua's dialogue box | `text_sources` | ✅ 13/13 |

Each was proven to fail before it passed: removing `ep01_seen` from `ep01_01` makes `episodes`
report `expected 'ep02_01', got 'ep01_01'`, i.e. the exact original bug.

**Check 4 is now green (2026-08-19).** The English UI-speak had two separate causes, not one.
The constants in `dialogue_router.gd` were already rewritten to Mandarin, but the *guard* that
selects them compared the failed reply against `"AI provider is not available."` — a string that
exists nowhere in the codebase — so `ai_dialogue_service.FALLBACK_REPLY` ("Mm. I can't reach the
AI right now…") passed straight through on every provider failure. A failed call now always
speaks Yua's line. See `docs/Dialogue_Flow_Map.md` §4.2 for the full list.

Claude can now also *see* the game without you. `check.ps1 -Mode shot -Node ep03_01 -Sessions 3`
jumps to any beat, opens a real window for ~2s, and saves PNGs to `tools/godot_check/shots/`
which Claude reads directly. So layout, overlap, clipping and wrong text no longer need you
either. What still does: feel, pacing, animation, audio.

---

## Session Log

- **2026-08-20 (round-8 verdict + two owner proposals):** Owner: round 8 read non-native across the
  board; root cause = my brief instructed "beat 1 callbacks the previous ep" → everyone wrote meta-
  commentary openers («请记一功») — now a taste-log veto + a process rule (self-check the brief
  first). **Blind testing dropped by owner request** — options now labeled by model. Ep3 assembled
  from owner's picks: beat 1 (海啊树啊风啊, de-meta'd), beat 2 (椅子→躺), beat 3 REWRITTEN as a
  motive question «你呢，也是因为一个人专心不了才来的嘛？» with branches [对的……]/[也不是啦，就是
  有人一起更有效率些]/type; two response options per branch + two endings drafted, published for
  pick. **「那个东西」 vetoed** as a recurring referent → proposal 「我的小项目」 (Ep0–2 will be
  swept once approved). **Living notebook** (owner idea): Yua's visible to-do list with daily
  chores that get crossed off on real-day return + one-line mention at greeting — designed in
  `docs/Yua_Notebook_Design.md` (pools, engine, UI, taste constraints, 3 owner decisions).

- **2026-08-20 (Ep0–2 IN GAME + name reaction + Ep3 arena):**
  - `scripted_nodes.json` → **v10**: Ep0 (开局翻车 → 取名 → 工具一起摸索 → 15/30/60), Ep1, Ep2 canon
    written as nodes (v9 backed up at `tools/zh_arena_out/scripted_nodes_v9_backup.json`). New engine
    actions `ACTION_GO_15/30/60` set duration AND start focus immediately (canon «选完就得开始了»).
    HUD chips now 15/30/60 (Chip25→Chip30, Chip45 removed), default 30 min. TASK_INPUT_002 /
    FOCUS_READY_001 route to the GO actions.
  - **AI name reaction wired**: `AI_MODE_NAME_REACT` added to ai_modes.json (3-way: real/net/整活,
    anti-template wording). Live-probed: MiniMax-M3 10/10 correct incl. recognizing 千早爱音=MyGO and
    夜雨声烦=全职高手; M2.7-highspeed rejected (invented lore, not faster). Latency 4–17s → design
    changed from 1.5s-timeout to: show «{name}……» beat, await up to 12s, else scripted fallback
    (`_scripted_name_reaction`, script-aware: CJK ≥4 chars or digits/spaces/>12 latin = net-name).
    New harness scenario `name_react` (10/10). Full suite: 13 suites ALL OK.
  - Ep3 arena round 8 published (6 options: 倒水擦桌 / 椅子躺下 / 整理桌面 / 笔按颜色 / 只是看一眼).
    Key private in `tools/zh_arena_out/round8_key.md`.


- **2026-08-19 (dialogue flow map + bug hunt):** Mapped the dialogue decision tree as-built
  (`docs/Dialogue_Flow_Map.md`, with a mermaid diagram + click-priority table) and fixed the
  four flow bugs the owner reported. **Critical context: the whole godot_check suite was GREEN
  the entire time the game was misbehaving** — every bug lived in a path no scenario walked, so
  two new scenarios were written to fail first: `ep0_once` and `text_sources`.
  ① **Ep0 replay** — "has the intro been seen" had TWO sources of truth (`has_seen_intro` save
  field + `intro_seen` story flag). `_note_meaningful_interaction()` saved *before* the field
  flipped, then `ep00_close`'s `set_flags` saved again with the stale value, producing a profile
  that said seen-and-not-seen at once. New `_intro_already_seen()` reconciles both at every entry
  point; the flip persists immediately; the debug jumper moves both together and marks the
  session opener spent (it previously restarted Ep0 mid-session).
  ② **Operator English spoken as Yua** — `dialogue_router.gd` compared the failed reply against
  `"AI provider is not available."`, a string that exists NOWHERE in the codebase, so the real
  `FALLBACK_REPLY` English reached the dialogue box on all 8 provider-failure paths. Failures now
  always use the in-fiction line. Also: empty replies were tagged `success:true` (now `false`);
  `_strip_reasoning` only caught the *opening* `<think>` tag while MiniMax echoes only the closing
  one (now strips to the last closing tag, case + variants); four English memory follow-ups and the
  English `Dialogue error:` strings are now Mandarin in her voice (real ids go to `push_warning`).
  ③ **Stale text** — deleted `FOCUS_{COMPLETE,START,STOP,SET}_LINE` (English, several in Yua's
  *first person*, shown in the status strip right under her line), `DEFAULT_RETURN_CHOICE_TEXT`
  (injected an English chip pointing at `greeting_01`, a node id that does not exist), and three
  dead `*_PLACEHOLDER_TEXT` constants. Status text is now neutral via `_ui_text("status_*")`.
  Also fixed an infinite "Back to safety" loop and bogus missing-node warnings on every UI refresh.
  ④ **AI↔scripted transition** — NOT fixed; needs an owner decision (see Active Tasks).
  Suite now 13 scenarios, all green. `Architecture_Overview.md` corrected (it wrongly claimed
  `_register_node` still drops `set_flags`).

- **2026-08-19 (SCRIPT v10 IN GAME):** Ep0/Ep1/Ep2 canon written into `scripted_nodes.json`
  (v9 backed up to `tools/zh_arena_out/scripted_nodes_v9_backup.json`). New Ep0 chain: ep00_01–05
  (MOBA cold open → 接通 → confession → 读档) → ep00_name (name_input tag, engine hook intact)
  → ep00_named → ep00_tools (task-notebook beat; «我也写一句» routes to TASK_INPUT_001) →
  ep00_close (15/30/60, sets intro_seen). Ep1: ep01_01 → a/b/c → ep01_end. Ep2: ep02_01 →
  a/b/AI → ep02_listen (文艺→破功) → ep02_end. Engine: new `ACTION_GO_15/30/60` = set duration
  AND start focus (canon «选完就得开始了»); `_capture_focus_task` peer-toned + routes to GO_*;
  default duration 30 min; HUD chips 15/30/60 (Chip25→Chip30, Chip45 removed). Also fixed the
  long-standing `dialogue_router.gd` English UI-speak (three in-fiction Mandarin lines).
  Harness: `first_click` scenario updated for v10 (intro now auto-starts focus; stop + play
  through ABORT_001 before idle-click checks) — **66/66 green, first fully clean board.**
  Shot of ep02_listen verified visually. Owner playtest steps in "User Godot Checks Pending".
  NOT yet: AI name-reaction hook (Type_Mode_Design §1), Yua's notebook line shown on HUD, B4/B5.

- **2026-08-17 (Ep2 CANON v2 — owner's 文艺→破功 invention):** Owner overrode the 2+5 merge:
  keep option 5 as body, but beat 4 = option 1's literary sea/horn lines (last line changed to
  a sound image: leaves «像有人在很远的地方翻书»), THEN she punctures it herself («啊啊啊这么文艺
  的句子脑子里想想还好，在你面前说出来就有点尴尬……当我没说！»). This is now a named house
  device in the taste log (item 7: 抒情 2–4 句 → 破功 1–2 句, ~every 3 eps max) and profile item
  3 was rewritten: literary imagery is ALLOWED if it pays the 尴尬税. Canon updated in doc,
  context pack, decisions artifact. Context pack already at Ep3.
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
