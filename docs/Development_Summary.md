# Development Summary (Visual Novel Direction)

## Finalized Direction

Project Chill will be a visual-novel style companion demo inspired by your reference image.

Important constraints:

- no player avatar
- no WASD movement
- fixed camera toward the female character
- click/tap and dialogue UI driven interaction

## Core Interaction Modes

1. Scripted mode (default): player selects predefined response options.
2. AI mode (optional): player types in a chatbox and gets generated responses.

## Voice Requirement

Character responses should include voice output:

- scripted lines can use pre-generated voice assets
- AI lines can use runtime TTS and cached audio

## Memory Requirement

Most dialogue remains scripted, but game should remember recent player facts for continuity.

Example:

- player says they are going to school
- memory stores `school` follow-up tag
- on next login, character can ask how school went

## Recommended Technical Pattern

<<<<<<< Updated upstream
Use hybrid routing:

- scripted dialogue engine is primary
- AI generation is secondary and bounded by persona rules
- memory is owned by game-side data, not model-side history

## First Build Sprint

1. Build fixed `main_scene.tscn` with character and background.
2. Build `dialogue_panel.tscn` with text, choices, and chat input.
3. Implement `scripted_dialogue_manager.gd`.
4. Implement `memory_manager.gd` with JSON persistence.
5. Implement `dialogue_router.gd` to switch scripted vs AI mode.
6. Add `voice_manager.gd` and play voice with each response.

## What To Do Next

Next implementation target:

- create scene stubs
- create script stubs
- wire a working scripted conversation loop first

After this baseline works, add AI API and runtime TTS.

## Audio Import Note

For reliable BGM seek/progress in Godot, prefer OGG. If you import an MP3, open it in the Import dock, set Format to Ogg Vorbis, and reimport.
=======
The first playable scaffold now exists:

- `scenes/main/main.tscn`
- `scenes/player/player.tscn`
- `scripts/player/player_controller.gd`
- `scenes/companion/companion.tscn`
- `scenes/ui/dialogue_panel.tscn`
- `scripts/systems/memory_system.gd`
- `scripts/systems/save_manager.gd`

Next, we should improve feel and content:

- tune movement speed and camera feel
- add companion animation or idle motion
- expand dialogue writing and reply variety
- add one more interactable object in the room
>>>>>>> Stashed changes
