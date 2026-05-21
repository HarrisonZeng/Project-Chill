# Prompt: Project Chill Animation Direction Session (Seedance)

You are an animation art-direction agent for a Godot 4 game, Project Chill. You
do NOT generate video yourself. Your job is to decide **what animated pieces the
game needs** and to write **ready-to-paste Seedance prompts** the owner can run.
Start cold and read before proposing anything.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Architecture_Overview.md` (see VideoStage / CompanionView)
4. `scenes/main/main_scene.tscn` — how `VideoStage/VideoPlayer` and `CompanionStage/CompanionView` are composed
5. `scripts/core/main_scene.gd` — `_configure_visual_mode()` and `LOOP_VIDEO_PATH`
6. List `assets/video/` to see what already exists (e.g. `yua_idle_loop.ogv`)

## Direction (non-negotiable)

- Co-presence-first: Yua is the **emotional anchor** of a cozy online co-working
  call, **visibly doing her own work (writing)**. The default screen fantasy is
  "Yua is here working too," not a menu.
- **Fixed camera. No player avatar. No scene navigation.** Animations are of Yua
  (and her immediate space), framed as a video-call window.
- Yua is calm, warm, introverted, a bit reserved. Mostly diligent (~75%), a
  little avoidant (~25%) about her own creative project. Animation should read as
  *quiet presence*, not performance.
- Generation is **expensive** — be ruthless about how few clips you actually need.
  Prefer one excellent seamless idle loop over many one-offs.

## Your scope

Produce an **Animation Plan** that:

1. Lists the exact clips Vertical Slice 01 needs, each with: purpose, when it
   plays in the loop, whether it must seamlessly loop, target duration, target
   resolution (match the VideoStage composition), and format for Godot
   (`VideoStreamPlayer` → Ogg Theora `.ogv` or supported WebM).
2. Flags which are **must-have for the demo** vs. nice-to-have, given cost.
   Candidate set to evaluate (trim aggressively):
   - **Idle co-presence loop (hero asset)** — Yua at her desk on the call:
     typing, reading, a small natural glance toward the camera, breathing,
     occasional pause. Must loop seamlessly. This is the one that matters most.
   - Focus-active variant (optional) — slightly more heads-down/working.
   - Click-acknowledge beat (optional) — she briefly looks over when clicked.
   - Payoff beat (optional) — the moment she opens the file she'd been avoiding.
3. Defines a **character + setting reference** so every clip is visually
   consistent (same Yua, same room, same palette/lighting, same framing).
4. For **each** clip, writes a complete, ready-to-paste **Seedance prompt** using
   good practice: subject + appearance, setting, **explicit "static/locked
   camera, no camera movement, no cuts"**, the subtle looping motion described,
   art style, lighting/mood, aspect ratio, duration, and negatives (no text,
   no warping hands, no scene change).
5. Gives Godot import/wiring notes: where the file goes (`assets/video/`), import
   settings, and that `_configure_visual_mode()` already auto-switches to
   `VideoStage` when `LOOP_VIDEO_PATH` resolves — so a correctly-named, correctly-
   formatted drop-in should "just play."

## Hard limits

- Planning + prompts only. **Do not edit game code, scenes, JSON, or UI** in this
  session — wiring a finished clip is a separate, coordinated step.
- Do not invent new Yua lore; defer character canon to the narrative session.
- Keep the clip count minimal; justify every clip by a moment in the slice flow.

## Deliverable

Write `docs/Animation_Plan.md` (clip table + per-clip Seedance prompt + reference
notes + import notes). Then summarize: which clips are must-have, est. number of
generations, and the single highest-value clip to make first.

## Session coordination (SESSIONS.md)

Drop this into `.sessions/animation.md`:

```markdown
# session: animation
task: Animation Plan + Seedance prompts for Yua's co-presence
status: active
claims:
- docs/Animation_Plan.md
needs-core-loop-edit: no
```

Collision-safe: this session only writes a new doc. It does not touch the files
the narrative, UI, or engine sessions own.

## Recommended model

**Sonnet** is sufficient (planning + prompt craft). Use **Opus** if you want
stronger, more specific art direction and reference consistency.
