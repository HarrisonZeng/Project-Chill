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
| Auto-publish to itch.io | ✅ code / ⏸ owner setup | `.github/workflows/publish-web-demo.yml`; needs itch page + `BUTLER_API_KEY` — see `docs/Web_Demo_Publishing.md` |
| Voice | ⏸ deferred | `voice_manager` plays pre-generated clips but **no clip assets exist**; fine for demo |
| Idle video mode | ⏸ off by choice | File deliberately renamed `yua_idle_loop_disable.ogv`; rename back to re-enable (decision D2) |

## What Remains for the Demo (the real list)

| Gap | Priority | Owner | Notes |
|---|---|---|---|
| Script depth pass (Ep1/2/3/5, FOCUS_DONE, ep13 honesty line) | 🔴 | Claude after owner verdicts | Proposal awaiting checkmarks: `docs/Yua_Script_Polish_Proposal.md` |
| Call-frame visual composition | 🔴 | Claude implements; owner picks direction | Biggest lever for 小红书 scroll-appeal |
| Windows export preset (only Xogot/iPad/Web exist) | 🔴 | Claude writes preset; owner exports | `export_presets.cfg` |
| itch.io page + `BUTLER_API_KEY` secret (unblocks the web demo) | 🔴 | Owner, ~15 min | Steps in `docs/Web_Demo_Publishing.md` |
| All-Chinese surface (system status lines are English) + zh default | 🟡 | Claude | B4/B5 in ship plan |
| ~~Gate "3 秒试玩" chip behind debug flag~~ | ✅ | Claude | Now hidden unless `_debug_timeline_enabled()` |
| ~~Debug bar off at ship~~ | ✅ | Claude | Now driven by `OS.is_debug_build()`; on in editor, off in release |
| Friend test (2–3 people) | 🟡 | Owner | Week 4 |
| Post assets: video capture, copy, itch page | 🟡 | Claude drafts; owner records/posts | Week 5–6 |

---

## Active Tasks

- **[CLAUDE — next session]** Implement dialogue UI 方案 A (subtitle style) in `main_scene.tscn` + controllers; owner screenshots each iteration.
- **[CLAUDE — next session]** Type Mode implementation checklist in `docs/Type_Mode_Design.md` §4 (name-react nodes, EP0 free line, type-first episodes, runtime-rule additions).
- **[CLAUDE]** B4/B5 (all-zh system strings, zh default) — unblocked.
- **[OWNER]** D5 script verdicts still open: `docs/Yua_Script_Polish_Proposal.md` blocks 1–7.
- **[OWNER]** Re-test bugs #1/#2 after pulling these fixes (steps in "User Godot Checks Pending").

## Blockers

_None._

---

## User Godot Checks Pending

Bug-fix verification (~10 min, F5 in Godot):

1. **Reset Save** on the debug bar, close, F5. Click Yua → intro plays. Play through to the
   timer suggestion (ep00_close). Now click her repeatedly: expect short "我在" style lines that
   gently point at the timer — **EP0 must NOT restart, no greeting spam**. ⬜
2. Set a 1-minute custom timer, start, and click her several times: first click gets a real line,
   every further click within 3 minutes gets "……". ⬜
3. Complete the session → Ep1 plays. Complete a second session → **Ep2** plays (NOT Ep1 again —
   this was silently broken before; episode flags never saved). ⬜
4. At a (自己写) choice, type something: her reply now ends with no chips; typing again continues
   the chat, clicking her settles back. No "回到按钮" wording anywhere. ⬜

---

## Session Log

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
