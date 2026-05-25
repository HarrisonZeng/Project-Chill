# Audio Plan — Project Chill, Vertical Slice 01

## Overview

The game is a cozy online co-working companion. Music is **ambient company for
focus** — it must not pull attention, compete with dialogue, or feel like a
game soundtrack. The player hears this for 30–90 minutes at a stretch while
actually working. Every track must pass the "would I notice if it looped?"
test: no, ideally.

The music bar supports a playlist with prev/next, loop/sequential/random modes.
A set of 3 tracks is the right size for VS01: coherent mood, enough variety to
rotate, nothing wasted.

---

## Track Set

| # | Working title | Role | Must-have? |
|---|---|---|---|
| 1 | Morning Coffee | Hero — primary co-working loop | **Yes** |
| 2 | Afternoon Light | Sibling — slightly airier | Yes |
| 3 | Paper & Rain | Sibling — more introspective | Yes |
| 4 | Late Night Mode | Optional — evening/night time bucket | Nice-to-have |
| 5 | Small Progress | Optional — short payoff cue for Yua beat | Nice-to-have |

Start by generating Track 1. If it lands, generate 2 and 3 in the same session
to keep the palette coherent. Generate 4 and 5 only once the first three pass.

---

## Per-Track Specs & Suno Prompts

---

### Track 1 — "Morning Coffee" (Hero)

**Role:** The anchor. This is what plays by default and what most players will
hear the most. It must work alone.

**Spec:**
- Mood: warm, calm, quiet industry — feels like being in a cozy room with
  someone who is also working
- Instrumentation: upright piano (or slightly muted grand), soft brushed drums,
  walking bass line, light vinyl hiss
- Tempo: ~75 BPM — slow enough to not feel driving, not so slow it feels sleepy
- Texture: sparse. No more than 3–4 simultaneous elements. Never crowded.
- Length: ~2–3 minutes, with loop point set so the end rejoins naturally
- Loop requirement: no audible seam. The last 4 bars should blend back into the
  first without a gap or obvious restart.

**Suno Prompt (primary):**
```
lo-fi hip hop, ambient, instrumental, cozy study music, warm upright piano,
soft Rhodes undertone, gentle vinyl crackle, slow tempo 75 BPM, no lyrics, no
vocals, seamless loop, consistent texture throughout, light brush drums, subtle
walking bass, minimal sparse arrangement, peaceful focus, no drops, no builds,
no melody that demands attention, background music for working
```

**Suno Prompt (alternate — use if primary feels too busy):**
```
lo-fi chill beats, study music, ambient instrumental, warm muted piano, vinyl
hiss, gentle brush snare, slow bass, 70 BPM, soft and intimate, cozy room tone,
background music for concentration, no sudden changes, no vocals, seamless loop,
minimal, consistent texture
```

---

### Track 2 — "Afternoon Light"

**Role:** Sibling to the hero. Slightly more airy and present — like mid-
afternoon light through a window. Still unobtrusive.

**Spec:**
- Mood: warm and slightly bright, still focused, a little more melodic than Track 1
  but the melody should be incidental, not a hook
- Instrumentation: electric Rhodes piano (lead), fingerpicked acoustic guitar
  (background), subtle light reverb, analog warmth
- Tempo: ~78 BPM
- Texture: Rhodes carries it; guitar adds texture rather than a second melody
- Length: ~2–3 minutes, loopable

**Suno Prompt (primary):**
```
lo-fi chill, instrumental, ambient, electric Rhodes piano, light fingerpicked
acoustic guitar, soft reverb, vinyl warmth, 78 BPM, mellow and airy, study
ambience, no vocals, no lyrics, seamless loop, gentle texture, peaceful, cozy
coffee shop background music, consistent throughout, no drops
```

**Suno Prompt (alternate):**
```
chillhop instrumental, Rhodes electric piano, acoustic guitar plucks, subtle
percussion, analog warmth, 75 BPM, soft and dreamy, focus music, no vocals,
seamless loop, no drops, warm and bright, cozy, incidental melody, background
```

---

### Track 3 — "Paper & Rain"

**Role:** The most introspective of the three. A slight dip in energy — for
when the player wants to settle into quieter work. Still warm, not sad.

**Spec:**
- Mood: meditative, intimate, slightly quieter — like working while it rains
  outside
- Instrumentation: fingerpicked acoustic guitar (gentle), soft string pad or
  cello (distant, not prominent), light rain texture as ambience (optional — if
  Suno renders it, great; if not, request another reroll without it)
- Tempo: ~70–72 BPM
- Texture: very sparse. The guitar is the only melodic element; strings/rain
  are texture only.
- Length: ~2–3 minutes, loopable

**Suno Prompt (primary):**
```
lo-fi ambient, instrumental, acoustic fingerpicked guitar, soft string pads,
gentle rain texture, warm reverb, 72 BPM, meditative and calm, cozy study music,
no vocals, seamless loop, no builds, sparse arrangement, intimate and peaceful,
background focus music, minimal, no sudden changes
```

**Suno Prompt (alternate):**
```
ambient lo-fi, acoustic guitar fingerpicking, soft cello undertone, subtle rain
ambience, 70 BPM, introspective and warm, no lyrics, instrumental, seamless
loop, very minimal and textural, study music, peaceful and quiet, consistent
texture, no drops
```

---

### Track 4 — "Late Night Mode" (optional)

**Role:** Softer and dimmer than the core three. Intended to pair with the
evening/night time-aware greeting bucket. Generate only after Tracks 1–3 pass.

**Spec:**
- Mood: hushed, sleepy-adjacent but not actually sleepy — "working late,
  comfortable with the quiet"
- Instrumentation: very muted piano, soft synth pad (barely audible), maybe a
  distant vinyl hiss
- Tempo: ~65–68 BPM
- Texture: the sparsest of the set. Long spaces between notes are fine.
- Length: ~2–3 minutes, loopable

**Suno Prompt (primary):**
```
ambient lo-fi, instrumental, late night study music, muted piano, soft synth
pads, gentle vinyl hiss, 68 BPM, dim and hushed, cozy and quiet, no vocals,
seamless loop, sparse texture, nighttime focus, very soft, minimal melody,
peaceful, barely-there, consistent texture
```

**Suno Prompt (alternate):**
```
late night lo-fi, instrumental, ambient, soft muted piano, warm pad tones,
subtle vinyl crackle, 65 BPM, hushed and still, no lyrics, seamless loop,
very minimal, for working late, introspective and gentle, no drops, no builds,
consistent throughout
```

---

### Track 5 — "Small Progress" (optional payoff cue)

**Role:** A short, slightly warmer piece (~30–60 seconds) for the emotional beat
where Yua pushes through her writing avoidance. This is not a looping BGM track
— it is a one-shot cue that plays over or after the scripted payoff lines, then
the regular BGM resumes. Keep it gentle; it is an exhale, not a celebration.

This track is wired differently: it is not in the BGM playlist but played
directly via a separate `AudioStreamPlayer` in the scene, triggered by the
payoff milestone. Generating it in Suno is still valid; the wiring step is
separate and coordinated.

**Spec:**
- Mood: tender, quietly hopeful — the feeling of "something small but real
  happened"
- Instrumentation: piano + perhaps a single soft guitar note or string swell
  (very brief); ending resolves naturally
- Tempo: ~75–80 BPM, or rubato (free) if Suno allows
- Length: 30–60 seconds. Ends naturally (no loop needed).

**Suno Prompt (primary):**
```
lo-fi ambient, instrumental, short interlude, gentle emotional lift, warm piano,
soft guitar note, 78 BPM, hopeful and tender, no vocals, short piece, quiet
resolution, cozy and heartfelt, 30-60 seconds, ending naturally, soft resolve,
non-looping, not dramatic, understated warmth
```

**Suno Prompt (alternate):**
```
ambient lo-fi, short piano piece, emotional warmth, solo piano with light guitar,
tender and hopeful, instrumental, no vocals, quiet resolution, gentle payoff,
cozy and touching, natural ending, not looping, understated, brief, 40-60 seconds
```

---

## Licensing — CONFIRM BEFORE SHIPPING

> **This is the most important thing to resolve before relying on any
> Suno-generated track in the Steam/public build.**

Suno's commercial rights depend on subscription tier:

- **Free tier:** Generated audio is for personal, non-commercial use only.
  You cannot use it in a sold or publicly distributed product.
- **Pro / Premier tier (as of 2024–2025):** Suno grants commercial rights,
  including distribution in paid products, to subscribers on these tiers.
  You own the output and can use it commercially.

**Action required before shipping:**

1. Confirm you are on a Pro or Premier plan (not Free) when generating these
   tracks.
2. Read the current Suno Terms of Service (suno.com/terms) — terms have changed
   before and may change again. The ownership/commercial-use clause is the one
   to check.
3. Keep a record of which plan you were on and the date of generation for each
   track — this is your license evidence if ever asked.
4. If you're unsure or the plan lapses before shipping, the safest fallback is
   to find CC0 / royalty-free lo-fi tracks from a source like Free Music Archive
   or Pixabay Music (filter by CC0) as a substitute.

---

## Godot Wiring Notes

### File format

Use **`.ogg` (OGG Vorbis)** for all looping BGM tracks. Reasons:
- Godot supports setting precise **loop points** in the importer for `.ogg`,
  which eliminates the gap-at-loop-point that `.mp3` can have.
- Smaller file size than `.wav` at equivalent quality.
- Godot's `AudioStreamOGGVorbis` is the native choice.

For the optional payoff cue (Track 5), `.ogg` is also fine; loop points are
not needed since it plays once.

### Where files go

```
assets/bgm/
  track_01_morning_coffee.ogg
  track_02_afternoon_light.ogg
  track_03_paper_and_rain.ogg
  track_04_late_night_mode.ogg   ← optional
  track_05_small_progress.ogg    ← optional, wired separately
```

Remove `Persona 5 chill mix - GVirusInfected.mp3` from the playlist when adding
the new tracks. You can keep the file in `assets/bgm/` temporarily but it must
not be in the exported build.

### Import settings (Godot editor)

For each of Tracks 1–4 (looping BGM):
1. Select the `.ogg` file in the FileSystem panel.
2. Open the Import tab.
3. Set **Loop** to enabled (checkbox).
4. If Suno exports a track that already loops cleanly at the natural end, the
   default loop (0 → end) is fine. If there is a short silence at the end you
   want to skip, set **Loop Offset** to trim it.
5. Click **Reimport**.

For Track 5 (payoff cue): Loop off, play once.

### Adding to the BGM playlist

`bgm_manager.gd` uses an exported `Array[AudioStream] playlist` variable. This
is set in the Godot Inspector on whichever node has `BgmManager` attached:

1. In the Scene panel, find the `BgmManager` node.
2. In the Inspector, locate the **Playlist** array.
3. Drag `track_01_morning_coffee.ogg`, `track_02_afternoon_light.ogg`, and
   `track_03_paper_and_rain.ogg` from the FileSystem panel into the Playlist
   array slots (in order).
4. Remove the Persona 5 placeholder if it is still listed.
5. The track order in the array is what Sequential mode follows (0 → 1 → 2 → stop)
   and what prev/next steps through.

That's the entire wiring for Tracks 1–3. The music bar controller already
handles everything else — track name display, prev/next, play/pause, mode
switching — via `bgm_manager`'s existing API.

Track 5 (payoff cue) requires a separate `AudioStreamPlayer` node and a
`bgm_manager.call("pause_bgm")` → play cue → `bgm_manager.call("resume_bgm")`
sequence. That wiring is a separate coordinated implementation step; do not do
it during the audio generation session.

---

## Recommended Generation Order

1. **Generate Track 1 first.** This is the must-have. If the first attempt
   doesn't land, use the alternate prompt or reroll. Don't proceed until the
   hero track is right.
2. **Generate Tracks 2 and 3 in the same Suno session** immediately after Track
   1 so the palette stays coherent — same session, similar style tags.
3. **Confirm the licensing question** before continuing to Tracks 4 and 5.
4. Generate Track 4 (late night) only if the first three are solid.
5. Generate Track 5 (payoff) only once the payoff story beat is scripted and
   the triggering logic is implemented — otherwise it's a track with no home.
