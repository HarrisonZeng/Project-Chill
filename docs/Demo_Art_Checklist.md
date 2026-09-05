# Demo Art & Sound Checklist

> Everything non-text that the demo needs, in one place, so nothing from the
> 2026-08-17 art-direction pass gets lost. **Living document — tick things
> off here and Claude reads it at session start.**
>
> The bar this is measured against: a **30-second vertical clip for
> 小红书/Bilibili** plus the password-restricted itch link for friends. Anything
> that doesn't show up in a short video is secondary. Not a Steam demo.

Legend: ✅ done · 🔧 in progress · ⬜ not started · 🅾 owner decides/acts · ⏸ deliberately after demo

---

## A. The scene (room, layers, light)

| # | Item | Status | Notes |
|---|---|---|---|
| A1 | Room layout | ✅ live | U-desk OPEN toward the camera (owner 2026-08-20: the rejoined version read as a closed O with a floating PC and a backwards keyboard). `codex exec -i` edit of the master: front segment removed, monitor set on the left return facing the chair, keyboard keys toward the chair, floor open in front. Glass cut is now `compose_layers --mode=panes --smart` from measured mullions (237/425/650/828, y<384) with the bouquet protected by colour, so it is re-runnable on any future master in seconds. |
| A1b | Hands-over-desk overlay so the desk can hide her lap while her hands stay on the keyboard | ✅ live | Both stances, 0.0000 against the character. Desk front trimmed to start below her elbows so the arms connect. `face` scenario asserts the overlay rect and photographs it with the desk hidden. |
| A2 | Room lighting follows the view outside — no daylight rays at night | ✅ live | Night room is now made by `tools/art/relight.gd` — a per-pixel grade of the day master (cool ambient + lamp pool + monitor glow), so it is pixel-aligned by construction and the day masks apply unchanged (`--mode=applymask`). Re-run it whenever the master changes; it takes seconds and never drifts. Yua + hands modulated cool at night, warm at sunset. |
| B2b | **Stance art was mislabelled** — "at her screen" was showing the eyes-closed variant | ✅ fixed | Real at-screen image (head turned to her monitor) installed with its own hands cut (0.0000). `face` scenario photographs it. Eyes-closed image kept as `yua_rest_keyed` for a future resting expression. |
| A3 | Six painted window views (day/night/rain/sunset/seaside/treetops), warm, hand-painted, low-rise | ✅ | Live. 2.1 MB total after lossy import. `views` scenario photographs each through the window. |
| A4 | Rain on the glass follows the view; dust motes; no layer motion (was shimmering) | ✅ | Motion must only ever move the *outside* layer — room and desk share pixels. |
| A5 | Legs-under-desk / chair as its own layer | ⏸ | Not meaningful for the demo; the new room already seats her correctly. |
| A6 | Codex-generated *regenerations* of room layers | ❌ never | Only **edits** of the master align. Anything above ~0.05 on `inspect_layers.gd --compare` is unusable. See §F. |

## B. Yua

| # | Item | Status | Notes |
|---|---|---|---|
| B1 | Complete, uncut character silhouette | ✅ | Replaced the botched cutout with Codex's complete figure (same bounding box). |
| B2 | Two stances — looking at me / at her screen — switchable in Settings, saved | ✅ | `yua_at_player.png`, `yua_at_work.png` |
| B3 | Blink (every 3–6 s, sometimes double) | ✅ | `companion_face.gd`; `face` scenario photographs mid-blink. `at_player` only — see B5. |
| B4 | Smile when clicked | ✅ | 2.5 s crossfade. Also usable: `shy` (came out as happy-eyes-closed). |
| B5 | Expression variants that failed and need a stricter retry: **surprised** (mouth was a drawn ring), **thinking** (near no-op + stray dot), **at_work_blink** (unedited copy) | ⬜ | Retry brief must say: *redraw both eyes / the whole mouth; a change under 0.002 mean diff is a failure*. Not blocking. |
| B6 | Expressions driven by dialogue mood | ⬜ | Needs a `mood` field per line in `scripted_nodes.json` — none exists yet. Do with the v10 script pass. |
| B7 | Breathing bob | ⏸ | Deliberately not added after the twitching complaint. Try only if the video still reads as static. |
| B8 | VRoid / Live2D / Blue-Archive rigging | ⏸ | After demo. Blink + expressions cover the "she's alive" bar for a 30 s clip. |

## C. Sound

| # | Item | Status | Notes |
|---|---|---|---|
| C1 | Music playlist (6 Suno tracks) | ✅ | **🅾 Owner: check that tracks loop/segue without a gap or click** — Claude can't hear it. |
| C2 | Rain ambience when the rainy view is up | ✅ | Synthesized (`tools/audio/synth_sfx.gd`), fades, follows the same rain amount as the glass. A real CC0 field recording would be richer: drop it at `assets/audio/rain_loop.wav`, nothing else changes. |
| C3 | Focus-complete chime — the one UI sound | ✅ | Soft E-B-E arpeggio. Functional: you're heads-down 25 min and need to know it ended. |
| C4 | Typing sound / UI clicks / other SFX | ❌ decided no | Owner call: distracting in a focus app; music covers the rest. |
| C5 | Ambient audio starts on the player's first click | ✅ | Browser autoplay rule made this mandatory anyway. Ties in with D1. |
| C6 | Voice for Yua | ⏸ after script | Plan in §E. |

## D. Intro, UI, packaging

| # | Item | Status | Notes |
|---|---|---|---|
| D1 | A natural way *into* the call each launch (no title screen — it's a call app) | ⬜ design agreed in principle | Proposal: **an incoming/connecting call**. Her name + avatar, "连接中…", one tap to answer → the room fades in and audio starts (this *is* the click that unlocks browser audio). Returning players get a shorter "重新连接" beat. Doubles as the diegetic title screen and fits opening D's co-work-app framing. Cheap. **🅾 Owner: yes/no on this direction.** |
| D2 | UI chrome matches the room (currently placeholder grey buttons, text-only music controls, heavy dark dialogue box) | ⬜ | Biggest visual lever left. **Owner wants to pick a direction from real references first.** Claude to present 4 directions with named games/apps and Codex mockups on our own frame: (A) video-call chrome — FaceTime/Discord/腾讯会议; (B) cozy paper/journal — Animal Crossing, Coffee Talk, Spiritfarer; (C) lo-fi minimal dark — lofi girl, Spotify, Endel; (D) anime VN plate — Blue Archive, Steins;Gate. |
| D3 | App icon (still Godot's default robot) | ⬜ | Trivial; Codex generates (her face or the dino plush). Also set in export presets. |
| D4 | itch cover image + 小红书 thumbnail | ⏸ later | One good screenshot + title treatment. |
| D5 | Vertical (9:16) crop plan before recording | ⏸ later | Decide the crop first — frame on her + the window. |
| D6 | Web export size | ✅ watched | Views 2.1 MB; magenta `*_keyed.png` sources excluded from export. Keep an eye when adding art. |

## E. Voice — how to start, once the script is final

1. **Keep it isolated.** `scripts/audio/voice_manager.gd` already exists and plays pre-generated clips; nothing else in the game knows about voice. Keep that boundary (AGENTS.md).
2. **Audition first.** Generate the *same* Yua line in 4–5 candidate Mandarin voices and let the owner pick — MiniMax speech is the obvious first try (owner already has the subscription; `mmx-cli` is installed on this PC). Alternatives if none fit: Fish Audio, CosyVoice (open), ElevenLabs (best cloning, paid).
3. **Batch the scripted lines.** Once the voice is picked and the script is final, one script generates a clip per authored line into `assets/audio/voice/<node_id>.ogg`; `voice_manager` picks them up by id. That's why this waits for the script — every rewrite invalidates clips.
4. **AI (Type Mode) replies** can't be pre-generated → runtime TTS through the same provider. Fine for the family demo (key already accepted in-build); revisit before any public build.
5. Ship the demo without voice if step 2 doesn't land a voice the owner likes. Voice that's slightly wrong is worse than none.

## F. How to ask Codex for art (what actually worked)

- **Run:** `codex exec -m gpt-5.5 -s workspace-write --skip-git-repo-check "<brief>"` from the project root. The MCP bridge is stale on this machine; the CLI works. Runs 5–15 min; put it in the background.
- **Reference-guided edits DO work — but only with the image ATTACHED: `codex exec -i <file> < brief.txt`** (learned 2026-08-19, after two failures). Asking Codex to *read a path* from disk does not work (its tool can't take a file path as input; it either stops or, worse, copies an existing file over the requested name). With `-i` the picture is in context and the tool uses it. Two CLI quirks: `-i` takes *multiple* files, so put the prompt on **stdin** (`< brief.txt`) or it swallows the prompt as a second image; and it silently reports "No prompt provided via stdin" if you get that wrong.
- **What a `-i` edit gives you:** a reference-*guided* regeneration — same room, same objects, same style, but things shift a little (window width, desk position, object sizes). Fine for a **master** (we key layers programmatically afterwards, and re-seat Yua by screenshot). Not pixel-preserving, so never use it for a layer that must align with an existing master; for that, programmatic keying of the master itself is still the way (which is what all the 0.0000 "edits" were).
- **Say the geometry, not the direction.** "Closer to the left border" got read as "move the desk to the left wall". Describe where each thing IS and where it ENDS UP; name what must not move (chair, keyboard facing camera).
- **Watch for substitution.** When it can't do a task it may quietly copy an existing file over the requested name and rationalise ("the tracked master is a better fit"). Always measure the output against what it was supposed to derive from, and delete same-named files first so there's nothing to copy.
- Room-gap prompt for ChatGPT (attach `assets/art/backgrounds/room_original.png`, save result as `room_master.png`, 1536×1024): *"Edit this image. Keep everything exactly as it is — same camera, same 3/4 angle, same style, same colours, same objects — except: push the window counter (the desk surface under the window and its return down the right wall, with everything on it) further away from the camera so its near edge sits about 130 px higher in the frame, and show wooden floor in the gap that opens between it and the near desk — enough space for a chair and a person. The near desk with the monitor, keyboard, mouse, mat, dinosaur plush and plant must not change at all. No people, no text. Output 1536×1024."*
- **Backdrops (window views): free generation is fine** — they never have to align with anything. Give the framing rule (content across the whole frame, horizon ~35% down) and the style words explicitly ("cel-style, flat colour areas, luminous Shinkai sky, low-rise, warm").
- **Anything that sits against the room must be an EDIT of the master**, never a fresh generation. Say it three times in the brief. Deliver transparency as flat magenta `#FF00FF` (image models can't output alpha); key it with `tools/art/compose_layers.gd --mode=key`.
- **Verify, don't eyeball:** `tools/art/inspect_layers.gd --compare=<master>|<layer>` — under 0.03 = aligned edit; above 0.10 = regenerated, throw away. `--bbox` for character framing. `--sheet` for a contact sheet.
- **Face variants:** same rule; a good one measures 0.002–0.003 against the base. 0.0000 means it didn't edit at all.
- **After Codex writes into `assets/`**, always run a full `godot --import` (not piped through `Select-Object -First`, which kills it half-done) and check `git status` — it may have overwritten a file you cared about.

## G. Not before the demo (agreed)

3D room · VRoid/Live2D · more window views · chair layer · legs layer · voice · typing/UI SFX · breathing bob.

---

## Owner decisions still open

- 🅾 A1 — does the new room layout read right, once wired?
- 🅾 D1 — yes/no to the "incoming call" intro.
- 🅾 D2 — pick a UI direction from the four (references + mockups coming).
- 🅾 C1 — do the music tracks loop cleanly?
- 🅾 E2 — pick Yua's voice from the audition (after script).

> **2026-09-05 — Yua frame set rebuilt on the original face.** Every frame (neutral, blink, at-screen, smile, shy, surprised, thinking, rest) is now the crisp original with only the face region grafted from a Codex `-i` edit of that original; each measures 0.004–0.008 against the base. `*_keyed.png` files are the magenta sources for those grafts. Stances share one head, so `yua_at_work_*` are copies of the `at_player` frames with the at-screen eyes as base.

> **2026-09-06 — 16-frame set + motion.** New face-only frames on the original face: focus, sleepy, giggle, wink, pout, delighted (0.005–0.013 vs base). New poses with the head held still: **drink** (mug to lips) and **chin** (chin on hand) — arm regions grafted with tone match, each with its own hands cut. Second typing frame `yua_hands_b` alternates with `yua_hands` while focus runs (`companion_face.set_working`). Idle life every 20–45 s: glance at screen / window / sip / chin. Failed and dropped: `worried` (Codex shifted three filenames by one — the good ones re-labelled), `window` (repainted the whole head). GIF route: Godot `--write-movie` + ffmpeg (`winget install Gyan.FFmpeg`). **Do not run the harness while the owner has the game open — it collides with the live save.**
