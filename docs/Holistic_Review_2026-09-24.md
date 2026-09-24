# Project Chill — holistic review, 24 September 2026

This review covers the current local working tree, including the uncommitted September 23–24 changes. It combines repository/document review, offline Godot checks, a targeted progression probe, and inspection of freshly rendered 1600×900 screens. No gameplay files were changed. It does not assess the currently hosted build, live AI output, audible music quality, or retention with real players.

## Overall judgment

Project Chill has a coherent identity and a substantial playable prototype. Its strongest promise is mutual progress: the player works alongside someone whose writing gradually becomes more real, and whose small decisions remember the player. The next milestone should make that promise convincing over a first visit and a return visit. More episodes alone will not establish it.

I would use this build for a small, guided playtest after addressing story order. I would not call it a finished public demo. Content volume, presentation completeness, and player validation are at different stages.

## What is actually implemented

| Area | Current local state | Assessment |
| --- | --- | --- |
| Core loop | Call framing, optional focus timer and tasks, scripted conversation, bounded typing, persisted progress | Substantial working foundation; long real sessions still need human validation |
| Story | Ep0 plus Ep1–Ep15; 134 dialogue nodes | Playable drafts, not 15 approved episodes; handoff identifies Ep1/Ep3/Ep6 as approved canon |
| Full story | 60-episode, five-chapter beat sheet | Plan, not implemented content; Ep16 onward remains future work |
| Continuity | Role/name intake, time/return greetings, remembered choices, later branches, living notebook | A major strength; worthwhile only if players notice the consequences naturally |
| Presentation | Cozy room, views/weather, journal-style controls, redesigned purple-haired Yua | Clear visual direction; new character's expressive frame set remains unfinished |
| AI | Provider boundary, bounded story replies, scripted fallback, persistent game-side memory | Appropriate architecture; this review verified offline routes, not new live model responses |
| Audio | Music/ambience/chime systems; voice tooling and audition assets | Yua voice is explicitly disabled by `VOICE_FEATURE_ENABLED = false`; casting is unresolved |
| Delivery | Automated local checks and web publishing workflow | Useful infrastructure; public AI distribution needs a different credential arrangement |

## What deserves protection

**The relationship has a concrete subject.** Writing a novel gives Yua her own interests, avoidance, progress, and reasons to ask the player something. The automatic-door suggestion, remembered platform, manuscript reaction, and protagonist name are stronger material than generic reassurance. They can make the player feel consequential without turning Yua into a supervisor.

**The living notebook fits the game unusually well.** Seeing her have unfinished chores and a writing goal beside the player's optional tasks expresses peer companionship through the interface. It should remain readable, optional, and about her own life.

**The visual identity is becoming recognizable.** The plum ponytail, glasses, bookmark accessory, and porpoise sweatshirt give Yua memorable details. The warm room and paper controls belong together. The restrained interface leaves her as the main point of attention.

**The deterministic/AI split is sensible.** Authored progression is reviewable and recoverable; a failed model request can still land on a valid line and continue. Keeping that boundary is more valuable than adding unlimited chat.

## Highest-impact gaps

### 1. Yua's visible behavior needs to match the promise of working together

The current `yua_at_player.png` and `yua_at_work.png` have identical file hashes. The new asset directory does not yet contain the previous expression/pose collection, and the art checklist explicitly marks the new 16-frame rebuild unfinished. The code supports more life than the current assets deliver.

Prioritize a believable working gaze, blink, typing-hands change, smile, and one embarrassed reaction. These should connect to focus and authored dialogue. A line in which she is caught gaming or embarrassed after reading her prose needs a corresponding reaction. A small, well-integrated set is enough; full rigging is unnecessary for this milestone.

### 2. The first visit delays the most distinctive experience

The questionnaire begins on a nearly empty dark screen with “先回答几个问题。” Nickname/role can support later personalization, but the player encounters setup before the attractive room and character. Keep this introduction brief and give every question a visible payoff.

At two story episodes per calendar day, Ep5's substantive “what are you working on?” beat first becomes available on day three. Name reaction and other interaction exist earlier, so the opening is not devoid of personalization. Still, the strongest remembered exchanges are easy for a first-time tester to miss.

Preserve the agreed daily cap for the initial playtest, but measure its effect. Give the first visit a modest, observable memory callback without advancing story through clicking. For a guided story review, provide an explicitly labeled accelerated route; do not mistake that route for evidence that normal pacing feels good.

### 3. Finish the first meaningful payoff before expanding the episode count

Ep12 currently presents four short manuscript paragraphs inline. That is enough to test routing, but it is not yet the planned substantial chapter/reader experience. A persistent manuscript view, a satisfying short piece to read, and a later change reflecting the player's reaction would make the relationship tangible.

Several draft episodes also share “叮——收工” openings and similar dismissals. This makes their structure audible as a template. Preserve approved lines; vary the framing of drafts. Ep9's anger-centered opening deserves an owner pass against the taste log's explicit objection to anger as the main event. This is an editorial mismatch to discuss, not a reason to remove all conflict from her life.

### 4. Quiet usability matters as much as dialogue

The timer is legible and the main scene has a clear character focus. Small secondary labels and pale notebook text are less comfortable, particularly when the game is a smaller window alongside work. Her notebook is also below player tasks in one scroll area, so it may be missed precisely by players with longer task lists.

Test a real working session at a smaller window size: starting/pausing/resuming, task editing, text readability, ending a session while attention is elsewhere, music controls, and returning after an interruption. Prefer small refinements to the existing visual direction over another full UI redesign.

### 5. Scope now needs a deliberate limit

Sixty episodes, multiple workplaces, manuscript variants, greetings, notebook states, and AI branches multiply editorial and continuity work. Finish one convincing chapter and return loop before producing the remaining 45 episodes. Evaluate later workplaces by how they develop her writing and the relationship; location variety alone is not enough.

## Concrete technical findings

**High priority — later episodes can bypass an unmet earlier story gate.** In `scripts/core/progression_gate.gd:84`, a locked episode is skipped while the selector continues to later entries. Ep12 requires 5,400 focus seconds; Ep13 has no prerequisite requiring Ep12. A direct probe using 13 completed sessions, 780 focus seconds, intro seen, and Ep1–Ep11 seen returns `ep13_01`. One-minute custom sessions are accepted by the current UI. This can move into the aquarium chapter before the first-manuscript payoff, and later return to the missed episode. Add explicit chapter/story prerequisites or enforce the intended sequential rule. The existing story-flow check raises focus time before the next completion, so it does not cover this case.

**Public-release prerequisite — the web workflow can embed the provider credential.** `.github/workflows/publish-web-demo.yml:53` deliberately inserts the MiniMax secret into the exported client. Its comments explicitly acknowledge and scope this arrangement to the previously accepted password-restricted family demo. That existing agreement is not a blocker to private review, but it should not silently become the public architecture. Before broad distribution, use a server-side boundary with usage limits, or distribute the offline scripted build. This review did not inspect the live site's credential state.

**Prompt consistency — the door-idea mode contradicts itself.** `data/dialogue/ai_modes.json:14` asks Yua to say she will try it tomorrow, then prohibits tomorrow/next-time promises. Resolve the wording before judging the model's adherence. More broadly, align current lively, self-deprecating authored Yua with the older calm/introverted prompt examples through specific approved examples.

**Engineering maintenance — the coordinator and status docs need consolidation.** `main_scene.gd` exceeds 2,800 lines. Existing greeting/notebook/UI separation is a good direction; extract only as a concrete change requires it. Avoid a sweeping rewrite. Update stale top-level progress summaries so they distinguish implemented drafts, approved content, retired art, disabled voice, and future plans. Capture the accepted local build in version control after owner review.

**Coverage gaps — green checks do not establish finished quality.** Add coverage for the reproduced gate-order case, closing midway through a story exchange, calendar rollover, and shipped browser behavior. Art tests should distinguish a valid node/texture from visibly different frames. Real-session and multi-day human feedback remains essential.

## Verification and limits

- Verified that redirected `APPDATA` resolves Godot's user-data path inside `.sessions/holistic-review/` before running any scenario. The owner's running game and real save were left alone.
- Ran the repository's default `-Mode all`: lint, boot, and 25 scenario invocations completed with `ALL OK`. The live-AI scenario intentionally skipped its paid network checks; its pass is not evidence of a live API response.
- The expected missing-node fallback warning appeared in `text_sources`; it is part of that test.
- Rendered and inspected idle/dialogue, intake, notebook, settings, and Type Mode at 1600×900. The visible debug toolbar belongs to the editor/debug run; the publishing workflow uses a release export.
- The first screenshot attempt failed because the scratch output directory did not exist. After creating it, captures succeeded. One notebook screenshot run emitted an ObjectDB/resource-in-use warning at shutdown; it did not reproduce in the full offline suite and is not established as a gameplay leak.
- The targeted progression probe reproduced the ordering defect described above. This review did not repair it.
- No new live AI or voice requests, hosting changes, export certification, listening-quality claims, or real-player retention claims.

## Recommended next milestone and owner checks

**Milestone: a polished first visit, one real focus session, and one return with a specific remembered detail.**

1. Fix story ordering, then complete the small expressive art set on the chosen Yua design.
2. Polish the existing opening and first payoff; make one early memory consequence noticeable without unlocking story from chat.
3. Finish the manuscript reading/payoff experience before writing Ep16 onward.
4. Run a small private playtest over several actual days. Observe time to the first voluntary focus start, session completion, unprompted returns, and whether players can recall something Yua remembered. These are proposed observations, not current measured results.
5. Resolve public credential delivery before opening distribution more widely.

For the owner in Godot: press **F6** on `scenes/main/main_scene.tscn` (or **F5** for the project). Do not reset your real save merely to replay onboarding. The review's isolated intake screenshots can be inspected first; use a separate test profile for a full fresh-start playtest. Switch between Yua's “看着我” and working stance to assess the current asset gap. Run an actual 15-minute session while doing something else, then note whether her completion line and expression fit. Open the task panel, add enough tasks to scroll, and see whether “她的本子” remains discoverable. Reopen the game on a later visit and record the precise detail, if any, that made the greeting feel personal.

Changed files: this review document only, plus ignored review claim/scratch artifacts. No scenes, dialogue, art, gameplay scripts, or publishing settings were edited.
