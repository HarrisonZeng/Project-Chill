# Voice verification — 2026-09-08

- 23 generated MP3s decode in Godot: 126.5 seconds total. See audio_validation.json.
- Isolated voice test: 43/43 passed, clean exit after audio cleanup.
- Real MiniMax -> Godot -> MP3 cache -> playback: passed (2.04-second Chinese clip).
- Full existing project check.ps1 -Mode all: ALL OK, including call_intro, episodes,
  ep3_platform, type_mode, UI and boot. One rapid-shutdown audio resource warning
  appeared during ep0_once; assertions passed. The isolated voice test waits for
  the audio mixer and exits cleanly. Missing-node warning in text_sources is its
  intentional fallback test.
- Standalone audition scene rendered at 1600x900 and visually inspected.
- No code changes to the shared main_scene.gd, main_scene.tscn or script JSON.
- No generated credentials stored; process uses the already configured MiniMax key.
- No commit, push, or publication performed.

Changed files belonging to this session:
- scripts/audio/voice_manager.gd
- scripts/audio/minimax_voice_provider.gd (+ Godot UID)
- scripts/audio/voice_audition.gd (+ Godot UID)
- scenes/tools/voice_audition.tscn
- data/dialogue/voice_manifest.json
- assets/audio/voice_auditions/*
- assets/audio/voice_cache/*
- tools/voice/*
- docs/YUA_VOICE_ARCHITECTURE.md

Next: audition A-F and select a voice, then direct the next small script batch.
Godot checks for the owner: open scenes/tools/voice_audition.tscn, F6, compare
Chinese/English/Japanese tabs. F8, then F5 main scene with voice enabled to hear
available opening paragraphs. Text-only gaps in the opening are expected.
