# Yua voice system and auditions

Updated 2026-09-08. Voice implementation and auditions were explicitly requested
by the owner; this work supersedes the earlier voice-deferral for this component.

## What is implemented

- `scripts/audio/voice_manager.gd`: optional playback of exact-text authored clips,
  legacy node-ID clips for standalone callers, and cached desktop TTS.
- `scripts/audio/minimax_voice_provider.gd`: non-streaming MiniMax Speech 2.8 HD
  adapter, 20-second timeout, bounded responses, cancellation and error handling.
- `scenes/tools/voice_audition.tscn`: independent audition player. It never reads or
  writes the player profile and never calls an API. Chinese, English, Japanese and
  actual game clips have separate filters, replay/stop/next, seek and volume.
- `assets/audio/voice_auditions/manifest.json`: 13 voice/delivery comparisons plus
  10 game paragraphs. Includes actual prompts, IDs, settings and spoken text.
- `data/dialogue/voice_manifest.json`: 10 exact-text Chinese paragraphs mapped to
  clips under `assets/audio/voice_cache/`. The first designed voice is a provisional
  demonstration cast, not a final owner-approved choice.

The opening pack covers selected paragraphs in ep00_01, ep00_02, ep00_03,
ep00_close and FOCUS_START_001. This is not full episode voice coverage.
Missing clips remain text-only. A changed paragraph no longer matches its old
clip. Other sessions can therefore edit the script without stale voice playback.

## How to listen (Godot editor)

1. In FileSystem, open `scenes/tools/voice_audition.tscn`.
2. Press F6 (Run Current Scene).
3. Start with A-D: same Chinese text, same speed, different stock voices.
4. E-F are two original voice-design prompts: 清亮自然 and 温润微低.
5. G-I use E for quiet work, light teasing, and a sincere/embarrassed contrast.
6. English and 日本語 each compare that same custom voice with a native-language
   stock voice. These are audition lines, not committed game translations.
7. 游戏片段 plays the actual 10 authored paragraphs used by the main scene.
8. Press F8 to stop. Open the main scene and F5 for normal gameplay; leave the
   existing voice toggle on to hear matching opening paragraphs.

All generation completed and audio was decoded by Godot. Vocal casting remains
subjective: these are candidates to listen to, not claimed listening-based winners.
No cloned or celebrity reference voice was used.

## Main-scene integration

The existing coordinator calls `play_voice_for_line` with whole-node text while
it displays one paragraph at a time. VoiceManager binds a narrow subtitle bridge
to its parent when that parent has `_set_dialogue_text`. Each frame it observes:
`dialogue_text`, `dialogue_beat_index`, `current_node_id`, `voice_enabled`,
`focus_running`, and `ai_features_enabled`.

It plays only the current visible paragraph; skips cancel the old audio/request;
hiding dialogue and muting stop playback. Unmuting does not replay the old line.
This keeps edits out of the coordinator and scene files held by other sessions.
The bridge's property names are an explicit coupling to preserve if UI is refactored.
Standalone callers and the audition scene do not use the bridge.

## Optional live desktop TTS

Off by default. No networking is required for the audition or generated game clips.
To try live synthesis on this PC:

1. Ensure the Godot process inherits `MINIMAX_API_KEY` (already configured on the
   owner's PC; restart the editor if the environment was changed after it opened).
2. In the main scene select VoiceManager and enable Runtime Tts Enabled.
3. Keep AI features/privacy permission and the voice toggle on.
4. Send a brief Type Mode message while not focusing. Its visible reply can be
   synthesized and cached. Text appears immediately and never waits for voice.
5. Disable Runtime Tts Enabled again if you want only the recorded clip pack.

The adapter is desktop-only; browser exports never send a key to MiniMax. A future
public live-TTS feature needs a server boundary. Keys are read from the environment,
never scene data, the voice manifest, generated metadata, or build exports.

Runtime cache: `user://voice_cache/<hash>.mp3`, where the hash includes text,
voice ID, model, language, speed, pitch and emotion. Stop/mute advances a request
serial so a late response cannot play over a newer line. AI-off and active focus
cancel pending synthesis. Previously generated local clips remain playable.

## Regeneration

`tools/voice/generate_auditions.mjs` reads MINIMAX_API_KEY from its process only.
Run it with Node from this repository. It uses installed mmx-cli for normal TTS,
and the documented HTTP API for voice design and emotion controls missing in
mmx 1.0.15. Unchanged successful samples are reused to avoid repeat charges.
Custom voice IDs and original prompts are preserved in the audition manifest.

Generation makes paid API calls under the owner's explicit audition request.
No auto-generation occurs at game launch. No entire-script batch was generated.

## Verification and handoff

- Isolated: `godot --headless --path . --script tools/voice/test_voice.gd`.
  Verifies all 23 MP3s decode, stale text is rejected, settings alter cache keys,
  stop/mute/skip/hide behave, missing credentials fail safely, late replies are ignored.
- Live adapter: `godot --headless --path . --script tools/voice/test_runtime.gd`.
  One short Chinese request, reused from cache on later runs. Does not touch profile.
- Visual: audition scene rendered and inspected at 1600x900.
- Full project: `powershell -File tools/godot_check/check.ps1 -Mode all`.
  Check `tools/voice/verification.md` for this run's result and inherited issues.

Not implemented: full-script dubbing, streaming TTS, phoneme lip-sync, runtime TTS
for web, final voice selection, and automatic revoicing after script changes.
Next step: owner compares A-F, picks a voice, then direct a small Ep0/Ep1 batch.

Official references:
- https://platform.minimax.io/docs/api-reference/speech-t2a-http
- https://platform.minimax.io/docs/api-reference/voice-design-design
- https://platform.minimax.io/docs/api-reference/voice-management-get
