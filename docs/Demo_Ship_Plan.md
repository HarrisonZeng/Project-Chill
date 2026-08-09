# Demo Ship Plan — from today to a postable demo (written 2026-08-09, overnight audit)

Goal: in **~6 weeks** (inside your 2–3 month window), a downloadable Windows demo + a short
vertical video you can post to 小红书 and Bilibili to find first users. Not Steam-ready — postable.

This doc has four parts:
1. What is ACTUALLY built (verified in code tonight, not from stale docs)
2. Ship-blockers — the exact, short list between today and a public build
3. The week-by-week plan, with **[CLAUDE]** / **[YOU]** on every item
4. **Your morning checklist** — do this first, ~30 minutes

---

## 1. Verified current state (I read every core file tonight)

The game is materially further along than `Progress.md` claimed. Status of the old 🔴 items:

| Old "not done" item | Reality |
|---|---|
| Split-save bug | **Fixed.** One profile (`user://data/saves/player_profile.json`), owned by memory_manager, with legacy migration + corrupted-save recovery |
| Dialogue metadata dropped | **Fixed.** `unlock` / `set_flags` / `tags` / `speaker` are preserved and actively used |
| Save schema for slice | **Done.** All spec fields exist: focus totals, story flags, openness, nickname, return rhythm, AI privacy flag |
| Focus-driven progression gate | **Done.** `progression_gate.gd` — pure, deterministic, focus-only. Clicks/idle can never advance story |
| Co-presence call loop | **Done end-to-end in code.** Launch → idle (Yua working, click to talk) → time-aware greeting (4 time buckets × 3 variants) or short-return variant (<30 min) → optional task → focus timer → episode reveal on completion → settle back → save → relaunch recognition |

Also built and working (per code):
- **Full Ep0–Ep14 Mandarin script, v9** — flag-guarded episodes; casual eps gated by session count, intimacy eps additionally gated by real accumulated focus seconds (a 3-second test session cannot speed-run the relationship)
- Nickname capture (`{name}` token), `{focus_minutes}` token, night-aware goodbyes
- Type Mode always available, AI modes for break-chat and task-shrinking, **mock provider fallback** (no API key → still playable), AI privacy on/off switch wired into the router
- Memory follow-ups (school/exam/work/sleep), 23 reactive lines for clicking Yua during focus (goes to "……" if you pester her 4+ times — good gag)
- Beat-by-beat dialogue presentation (paragraphs advance on click — this matters for the script work below)
- Suno BGM tracks (Persona 5 placeholder is gone), music bar, EN/ZH language toggle, text-speed setting, chat history panel
- Debug episode jumper (type an ep number → Go) + save reset button

**The honest gap list:** the scene's look (call-frame composition), script depth per episode, a Windows export, and packaging/marketing. That's it. No systems work remains for the demo.

---

## 2. Ship-blockers (exact locations, all small)

| # | Blocker | Where | Fix effort |
|---|---|---|---|
| B1 | Debug bar ships on | `main_scene.gd:1766` `DEBUG_TIMELINE_ENABLED := true` | 1 line at ship time |
| B2 | "3 秒试玩" chip would let public players speed-run Ep1–Ep4 (they're count-gated only) | `TASK_INPUT_002` node + `ACTION_SET_TIMER_1` | Hide behind the debug flag |
| B3 | **No Windows export preset** — only Xogot (iPad) exists | `export_presets.cfg` | I write the preset; you click Export once |
| B4 | English system strings leak into the zh experience ("Focus started…", "Timer set to…") | constants + `_show_system_status` calls in `main_scene.gd` | ~1 hr, I do it |
| B5 | Default language is `en`; demo audience is Chinese | `main_scene.gd` `ui_language` default | 1 line |
| B6 | Idle video is deliberately disabled (file renamed `yua_idle_loop_disable.ogv`) | `assets/video/` | Decision D2 below, then rename or delete |
| B7 | AI provider needs a key (Poe/minimax) → public build would be mock-only unless we ship a key | `main_scene.gd:231` | Decision D3 — recommend mock-only for demo v1 |

None of these is more than an afternoon. **The demo's critical path is not code — it's look + script + packaging.**

---

## 3. Week-by-week

### Week 1 — Script depth + zh polish
- **[YOU, 30 min]** Morning checklist (§4) + decisions D1–D5 + verdicts on the script proposal doc.
- **[CLAUDE]** Apply approved script edits to `scripted_nodes.json` (bumps script version — note: your own save will replay the intro once, that's expected, and the debug bar can jump you anywhere).
- **[CLAUDE]** B4 + B5 (all-Chinese surface, zh default).
- **[CLAUDE]** Tie the 3-sec chip to the debug flag (B2).

### Week 2 — Make it read as a video call on screen
This is the highest-impact work for 小红书: people judge in 3 seconds of scroll.
- **[YOU, 15 min]** From your morning screenshots I'll mock 2–3 composition directions (call chrome: 通话中 dot, elapsed time, her name tag; frame treatment; where timer/tasks sit when idle). You pick one.
- **[CLAUDE]** Implement the chosen composition in `main_scene.tscn` + controllers.
- **[YOU, optional]** If we want new/extra Yua art or an idle loop that matches the call frame, you run the generation (Seedance/your tools — briefs already exist in `docs/Animation_Plan.md`); I wire whatever you produce.

### Week 3 — Windows build exists
- **[CLAUDE]** Add Windows Desktop preset to `export_presets.cfg`, embed-pck, project icon.
- **[YOU, 20 min]** In Godot: Editor → Manage Export Templates → Download (one time), then Project → Export → Windows → Export. Zip appears; you run the .exe once on your own PC.
- **[CLAUDE]** First-run smoke checklist for the exported build (fonts render zh? BGM loads? save writes?). You run it, I fix what breaks.

### Week 4 — Friend test (the real gate)
- **[YOU]** Send the zip to 2–3 friends (ideally people who study/work at a desk daily). Ask nothing — just watch or ask after: Where were you confused? What did you click first? Did you meet Ep1? Would you leave it open while working?
- **[CLAUDE]** Turn raw notes into a ranked fix list; fix the top items same week.

### Week 5 — Package + content
- **[CLAUDE]** Ship flip: B1 debug off, final pass, version stamp. Export candidate build.
- **[CLAUDE]** Drafts for you: 小红书 post copy (3 variants), Bilibili devlog outline/script, itch.io page text (zh+en), 60–90s capture shot-list (which moments to record, in what order — Ep0 first-meeting is the hook).
- **[YOU]** Record the screen capture following the shot list (OBS or even phone-over-screen is fine for v1), light edit, pick cover frame.

### Week 6 — Post
- **[YOU]** Post 小红书 (video + 网盘 link or itch link), Bilibili devlog. Open a 小 QQ/微信 feedback group, link it in comments.
- **[CLAUDE]** Standing by same-day for hotfixes; then we triage feedback into the next cycle.

**Slack:** 2 spare weeks inside your 2–3 month window for slips, art iterations, or a second friend-test round.

---

## Decisions — RESOLVED 2026-08-09 (owner)

- **D1 ✅ 中文 default, EN switchable.**
- **D2 ✅ Static 2D art for now**; video loop revisit later.
- **D3 ✅ TWO-STAGE STRATEGY (this reshapes the plan):**
  - **Stage 1 (this push): concept content, not a public build.** Post videos of the experience —
    scripted flow + AI conversations (Type Mode, name reaction, memory) captured from the dev build
    with AI ON — to test the concept with a potential audience on 小红书/Bilibili.
  - **Stage 2 (later): actual playable shipping with AI.** Game design must account for AI-at-scale
    from now (bounded calls, mock fallback, cost ceilings) — already our architecture.
  - Consequence: Windows export drops from Week-3-critical to Week-4-optional (still wanted for
    friend tests); capture quality + AI-on moments become the critical path.
- **D4 ✅ itch.io / TapTap later** — first make the game make sense.
- **D-UI ✅ Dialogue layer: 方案 A 字幕式** (subtitle style, minimal chrome, self-view tile) from
  `docs/mockups/dialogue_ui_mockup.html`. Implementation is the next scene-work item.
- **D5 ⏳ still open:** script blocks in `docs/Yua_Script_Polish_Proposal.md` await 用新版/保留/改一改
  per block (blocks 1–7).

---

## 4. YOUR MORNING CHECKLIST (~30 min, in Godot)

Open the project in Godot, press **F5**. Then:

1. **First launch** (if the game remembers you: click the debug bar's **Reset Save**, close, F5 again).
   Expect: Yua's first-meeting intro (灯亮着/连上了…). Read it through. ⬜ works ⬜ broken
2. **Type a nickname** when she asks. Expect she uses it in the next line. ⬜
3. After intro, **click the timer card** (top-right), pick **15 分钟**… then actually use **3 秒试玩** via the task flow if offered, or set a custom 1-minute timer — we just need a completed session.
   Expect on completion: **Ep 1 plays** (她刚好改到能停的地方…). ⬜
4. **During a focus session, click Yua 4+ times.** Expect: varied short lines, then "……". ⬜
5. **Stop a session midway.** Expect: the gentle abort line (停啦？没事…), no guilt-trip. ⬜
6. **Close the game entirely, reopen.** Expect: a time-of-day greeting (it's morning → 早…), and if you reopen within 30 min, the short "又是你" variant. ⬜
7. **Type Mode:** at any episode choice marked (自己写), type anything. Expect: a reply appears (mock — may be generic; that's correct without an API key). ⬜
8. **Debug bar:** type `5`, click **Go**. Expect: Ep5 (writing reveal) plays. Skim Ep5–Ep8 this way. ⬜
9. **Video vs art:** quit. In Explorer, rename `assets/video/yua_idle_loop_disable.ogv` → `yua_idle_loop.ogv`. F5. Look at her. Then rename it back if you prefer the art. This is decision **D2**. ⬜
10. **Screenshots (4):** ① idle screen whole window ② a dialogue with choices open ③ focus running ④ anything that looks ugly/wrong. Drop them in chat.

Then reply with: checklist ✅/❌ per line, the 4 screenshots, and D1–D5.

---

## What I can do with zero input from you (I'll keep moving whenever you're away)
Script application after your verdicts · all-zh strings · debug gating · export preset · composition implementation once you pick a direction · post copy, shot lists, page text · fix lists from feedback.

## What only you can do
Run/see the game in Godot and judge the feel · taste-verdicts on script and look · art/video generation runs · the export click and testing the .exe on a real machine · recording/posting · recruiting the 2–3 friend testers.
