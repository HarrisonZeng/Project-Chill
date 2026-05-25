# Animation Plan — Project Chill (Vertical Slice 01)

## Context and constraints

The game's `VideoStage/VideoPlayer` is a full-screen Godot `VideoStreamPlayer`
(`expand = true`, `loop = true`, anchors fill the 1600×900 viewport). When
`assets/video/yua_idle_loop.ogv` is present and loadable, `_configure_visual_mode()`
automatically switches to video mode and hides the static background + companion
sprite — no code change needed for a correctly named drop-in.

**Hard limit:** `VideoStreamPlayer` in Godot 4 stable requires Ogg Theora (`.ogv`)
or Ogg Theora in a WebM container. Generated MP4 must be converted with FFmpeg
(see Import Notes at the bottom).

**A placeholder `yua_idle_loop.ogv` already exists.** The goal here is to replace
it with a production-quality clip.

---

## Character + setting reference

Keep this consistent across every clip so they cut together.

| Attribute | Spec |
|---|---|
| **Subject** | Yua — young East Asian woman, early-to-mid 20s, dark hair (shoulder length, slight wave, often tucked behind one ear), soft features, calm expression. Glasses optional but preferred (reinforces studious/writer energy). Casual but intentional clothes: muted palette — dusty mauve, warm cream, soft sage. |
| **Framing** | Video-call shot. Yua centered-left in frame, face and upper torso visible, desk and immediate surroundings in the background. Think "90-minute video call" framing — not portrait close-up, not wide establishing. |
| **Desk** | Warm wood surface. Laptop open, a physical notebook beside it. Small ceramic mug (tea, not coffee). Soft ambient objects: a small plant, one or two books. No excessive clutter. |
| **Room** | Cozy home/dorm interior. Bookshelf partially visible. Curtain or window with soft daylight or warm evening light. Not a sterile office, not a fantasy setting. |
| **Palette** | Warm amber + dusty rose + soft sage. Muted saturation — feels analog/film, not oversaturated anime. Think a Moleskine-era study aesthetic. |
| **Lighting** | Warm side-light from the window (or desk lamp for evening). No harsh flash or ring light — this is ambient, lived-in. |
| **Art style** | Semi-realistic illustrated — NOT hyper-anime, NOT photorealistic. Aim for: soft shading, mild grain, hand-drawn-feeling lines. Closest references: "cozy lofi girl" aesthetic but slightly more character-driven and less stylized. |
| **Camera** | Locked. No movement. No zoom. No cuts. Filmed from a fixed angle as if from the player's monitor, slightly above eye-level (standard video call angle). |

---

## Clip inventory

### VS01 required clips

| # | Name | Purpose | Plays when | Loops? | Duration | Priority |
|---|---|---|---|---|---|---|
| 1 | `yua_idle_loop.ogv` | **Hero idle loop** — the default screen state. Yua at her desk, present, doing her own work. | Game launch → stays until a non-looping beat triggers (if any) | **Yes, seamless** | 8–10 s | **Must-have** |

### VS01 nice-to-have (low cost, high value)

| # | Name | Purpose | Plays when | Loops? | Duration | Priority |
|---|---|---|---|---|---|---|
| 2 | `yua_payoff_beat.ogv` | Payoff moment — Yua opens the file she'd been avoiding. Short, non-looping; plays over dialogue panel. | After first completed focus session (focus threshold trigger) | No — play once, then resume idle loop | 4–6 s | Nice-to-have |

### Skipped for VS01

- **Focus-active variant**: The idle loop covers focus sessions fine — Yua being present is the point. Swapping to a different loop requires a new `LOOP_VIDEO_PATH` constant and code; not worth the cost or complexity now.
- **Click-acknowledge beat**: The click interaction currently triggers dialogue; a reactive video clip would require code to interrupt the loop and resume it. Defer.

---

## Seedance prompts

### Clip 1 — `yua_idle_loop` (MUST-HAVE)

**Use this prompt verbatim. It is ready to paste into Seedance.**

---

```
A young East Asian woman named Yua in her mid-20s, dark shoulder-length hair with
a slight wave tucked behind one ear, wearing thin-frame glasses and a soft
dusty-mauve knit top, sits at a warm wood desk on a video call. She is working:
she types a few words on her laptop, pauses, reads back what she wrote, glances
briefly toward the camera with a quiet neutral expression, then returns to typing.
Her movements are small and natural — a slight lean forward to read, a subtle
exhale, fingers resting then typing again. The cycle returns to its start at the
end so the clip loops seamlessly.

Setting: a cozy home interior. Behind her, a partial bookshelf and a soft-curtained
window with warm ambient daylight. A ceramic mug and a closed physical notebook sit
at the edge of the desk. The room is quiet and lived-in, not staged.

Camera: static, locked, no movement, no zoom, no panning, no cuts. Framed as a
video-call window — Yua's face and upper torso fill roughly 60% of the frame,
centered-left, as if viewed from the other person's monitor at a slightly
downward angle.

Style: semi-realistic illustration, soft warm shading, mild analog grain, muted
palette (warm amber, dusty rose, soft sage). Not hyper-stylized anime. Not
photorealistic. Mood: quiet, warm, focused.

Lighting: warm side-light from the window. Soft ambient fill. No ring light, no
flash, no harsh shadows.

Aspect ratio: 16:9. Duration: 8 seconds. Seamless loop.

Negative: no text on screen, no speech bubbles, no warping or melting hands, no
scene change, no camera movement, no cuts, no other people, no phone in hand,
no excessive motion blur.
```

---

**Generation notes:**
- Run 2–3 generations and pick the one with the most natural hand motion and cleanest loop joint.
- Reject any take where hands distort, faces flicker, or the camera drifts.
- The brief camera-glance moment (she looks toward the viewer) is optional — if the model generates it, great; if not, don't force a retry. The default gaze can stay toward the laptop.

---

### Clip 2 — `yua_payoff_beat` (nice-to-have)

**Use this prompt verbatim. Generate only after the idle loop is locked.**

---

```
A young East Asian woman named Yua in her mid-20s — same appearance as the
idle-loop clip: dark shoulder-length hair, thin-frame glasses, dusty-mauve knit
top, warm wood desk — takes a slow deliberate breath, then opens a document on
her laptop that she has been hesitating to touch. Her expression shifts from
quiet avoidance to something small and resolute. She does not smile broadly — it
is a subtle, private moment of choosing to begin. She looks briefly at the screen,
then exhales slowly.

Setting, camera, and style: identical to the idle-loop clip. Static locked camera.
Same room, same desk, same lighting. No camera movement, no cuts.

This clip does NOT need to loop. It plays once (4–5 seconds) and stops.

Aspect ratio: 16:9. Duration: 4–5 seconds. Non-looping.

Negative: no text on screen, no speech bubbles, no warping hands, no scene change,
no camera movement, no cuts, no smile larger than a quiet half-smile.
```

---

**Generation notes:**
- Generate only 1 take initially. If the expression is too broad or too flat, retry once.
- The clip plays behind the dialogue panel; subtle is better than dramatic.
- The exact in-game trigger for this beat is TBD (the spec proposes "first completed focus session"). Confirm with owner before wiring.

---

## Import and wiring notes

### File placement

| Clip | Drop-in path |
|---|---|
| Idle loop | `assets/video/yua_idle_loop.ogv` |
| Payoff beat | `assets/video/yua_payoff_beat.ogv` |

### Converting MP4 → OGV (Ogg Theora)

Seedance outputs MP4. Convert with FFmpeg before placing in the project:

```bash
# Idle loop — convert + verify it actually loops cleanly
ffmpeg -i yua_idle_loop.mp4 -codec:v libtheora -q:v 7 -codec:a libvorbis -q:a 5 yua_idle_loop.ogv

# Payoff beat (no audio track needed)
ffmpeg -i yua_payoff_beat.mp4 -codec:v libtheora -q:v 7 -an yua_payoff_beat.ogv
```

`-q:v 7` is a good quality/size tradeoff. Range is 0–10 (10 = best, largest).

### Godot import

1. Drop the `.ogv` into `assets/video/`.
2. Godot auto-imports it — no manual import settings needed; defaults are fine.
3. Reopen the Godot editor and press Play. If the idle loop file is present and valid,
   `_configure_visual_mode()` loads it, calls `video_player.play()`, and switches
   `VideoStage` visible / `Background` + `CompanionStage` hidden automatically.

### Wiring the payoff beat (future step — do not wire in this session)

The payoff beat is not wired yet. When the time comes, the implementation will:
1. Add a `PAYOFF_VIDEO_PATH` constant in `main_scene.gd`.
2. In the focus-completion branch, pause the idle loop, swap in the payoff clip,
   play it once, then resume the idle loop after it finishes.
3. Coordinate with the focus/progression session so this does not collide with
   `main_scene.gd` edits in progress.

---

## Summary

| | |
|---|---|
| **Must-have for demo** | `yua_idle_loop.ogv` — 1 clip |
| **Nice-to-have** | `yua_payoff_beat.ogv` — 1 clip |
| **Estimated generations** | 3–4 total (2–3 idle loop takes to pick from + 1 payoff beat) |
| **Highest-value clip to make first** | `yua_idle_loop` — it is the default game state and the only asset that needs to exist for VS01 to feel alive |

The idle loop is the one that matters. Everything else in the slice can run on
scripted dialogue and the static companion sprite while the loop is in progress.
Generate the idle loop first, get it right, then decide if the payoff beat adds
enough to be worth the generation cost.
