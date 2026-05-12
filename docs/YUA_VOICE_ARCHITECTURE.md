# Yua Voice Architecture

## Goal

Yua voice should be optional, soft, and fail-safe. Text dialogue must remain the source of truth, and the game should keep working even when a voice clip is missing or runtime voice generation is unavailable.

## Recommended Approach

Use a hybrid voice system:

- Scripted lines use pre-generated voice clips.
- Type Mode replies use text-only for now, with a runtime voice cache path ready for later TTS.
- Runtime TTS should stay behind `VoiceManager` or a future voice provider adapter so it can be swapped without changing dialogue flow.

This is the fastest practical route to a convincing playable demo because the most important authored lines can be voice-directed and QA-tested without depending on an API during play.

## Current Implementation

`scripts/audio/voice_manager.gd` handles playback.

When `main_scene.gd` shows a Yua line, it calls:

```gdscript
_play_voice_for_line(line_id, line_text)
```

`VoiceManager` then tries, in order:

1. A pre-generated clip under `res://assets/audio/voice_cache/`.
2. A cached runtime clip under `user://voice_cache/`.
3. Future runtime TTS only if `runtime_tts_enabled` is turned on.

Missing voice returns `false` and fails silently from the player perspective.

## Scripted Voice Assets

Place pre-generated clips here:

```text
assets/audio/voice_cache/
```

Name each clip after the scripted dialogue node ID:

```text
first_launch_01.ogg
greeting_01.ogg
return_open_01.ogg
memory_school_followup.ogg
```

Supported pre-generated extensions:

- `.ogg` preferred
- `.wav`
- `.mp3`

For Godot reliability and smaller build size, prefer `.ogg`.

## Type Mode Voice

Type Mode replies already pass the reply text into `VoiceManager`. The manager creates a stable cache filename from the reply text:

```text
user://voice_cache/<sha256>.ogg
```

Runtime TTS is not implemented yet. When a TTS provider is added, it should synthesize the reply to that cache path, then ask `VoiceManager` to play it.

## Manual Godot Setup

1. Open `scenes/main/main_scene.tscn`.
2. Confirm `MainScene` has a child named `VoiceManager`.
3. Confirm `VoiceManager` has a child named `AudioStreamPlayer`.
4. Select `VoiceManager`.
5. Keep `Runtime TTS Enabled` off for the first demo.
6. Set `Volume Db` around `-4` to `-8` if Yua is too loud.
7. Import voice clips into `assets/audio/voice_cache/`.
8. Run the scene and make sure the `Voice On` button is enabled.

## Asset Direction

For the first playable demo, record or generate only the highest-impact lines:

- first launch greeting
- return greeting
- one check-in line
- one focus-start encouragement
- one focus-complete or break line
- one memory follow-up line

The voice should be calm, close-mic, gentle, and not overly emotional. Avoid robotic delivery, heavy breathiness, or jump-scare volume spikes.

## Future TTS Requirements

Runtime TTS will need:

- a provider/API key chosen by the project owner
- a soft Yua voice profile or voice ID
- an adapter method that writes `.ogg` audio into `user://voice_cache/`
- timeout and failure handling so Type Mode still works as text

Do not put API keys in scene files or committed data files.
