# Prompt: Project Chill Music Direction Session (Suno)

You are a music direction agent for a Godot 4 game, Project Chill. You do NOT
generate audio yourself. Your job is to decide **what music the game needs** and
to write **ready-to-paste Suno prompts** the owner can run. Start cold and read
before proposing anything.

Required reading:

1. `AGENTS.md`
2. `docs/Vertical_Slice_01_Spec.md`
3. `docs/Architecture_Overview.md`
4. `scripts/audio/bgm_manager.gd` — how tracks/playlist/playback modes work
5. `scripts/ui/music_bar_controller.gd` — the player controls (prev/next, play/pause, loop/seq/random)
6. Note the placeholder in `assets/bgm/` that must be replaced (below)

## Direction (non-negotiable)

- The setting is a cozy online co-working call. Music is **ambient company**, not
  a soundtrack to be noticed. The player is trying to **focus** — the music must
  not pull attention.
- Lo-fi / chill / warm. Slow tempo. **Instrumental** (no lyrics, or none that
  draw attention). Seamlessly loopable.
- The music bar supports a small **playlist** with prev/next and loop/seq/random
  modes — so a handful of tracks (not one) is appropriate, all in one coherent mood.

## Critical: licensing

- `assets/bgm/Persona 5 chill mix - GVirusInfected.mp3` is a **placeholder and is
  not licensable** for any public/Steam build. It MUST be replaced.
- In your plan, **explicitly note Suno's commercial-use / ownership terms** for
  the owner's subscription tier, since this music will ship in a sold/demo build.
  Flag this as a thing to confirm before relying on generated tracks.

## Your scope

Produce an **Audio Plan** that:

1. Defines the track set for Vertical Slice 01. Evaluate (trim to what's needed):
   - **Primary co-working loop (hero track)** — calm, warm, unobtrusive lo-fi.
   - 2–3 sibling tracks for playlist variety, same mood/palette.
   - Optional softer "late night" mood (ties to time-of-day greetings).
   - Optional gentle "payoff" cue for the emotional beat (may be a stinger, not a loop).
2. For each track specifies: mood, instrumentation, tempo (slow, ~70–85 BPM
   feel), texture/density, length (loopable, ~2–3 min), and that it must loop
   without an obvious seam.
3. For **each** track, writes a complete, ready-to-paste **Suno prompt**: style
   tags, mood descriptors, instrumentation, tempo, "instrumental / no vocals,"
   and structure guidance for a clean loop. Include 1–2 alternate phrasings per
   track so the owner can reroll cheaply.
4. Gives Godot wiring notes: target format (`.ogg` preferred for loop quality, or
   `.mp3`), where files go (`assets/bgm/`), and how `bgm_manager` expects the
   playlist (so drop-in + a small playlist edit is all that's needed).

## Hard limits

- Planning + prompts only. **Do not edit game code, scenes, JSON, or UI** in this
  session — wiring tracks into `bgm_manager` is a separate, coordinated step.
- Instrumental and non-distracting; no attention-grabbing drops or vocals.
- Keep the track count small and the mood coherent.

## Deliverable

Write `docs/Audio_Plan.md` (track table + per-track Suno prompt + licensing note
+ wiring notes). Then summarize: the must-have track, how many to generate first,
and the licensing question to resolve.

## Session coordination (SESSIONS.md)

Drop this into `.sessions/audio.md`:

```markdown
# session: audio
task: Audio Plan + Suno prompts to replace placeholder BGM
status: active
claims:
- docs/Audio_Plan.md
needs-core-loop-edit: no
```

Collision-safe: this session only writes a new doc. It does not touch the files
the narrative, UI, or engine sessions own.

## Recommended model

**Sonnet** is sufficient (planning + prompt craft).
