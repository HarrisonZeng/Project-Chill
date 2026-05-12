# Thread Handoff (Project Chill)

## Purpose

Use this file to resume the project on another Codex thread or another machine.
This is the portable replacement for live Codex thread history, which cannot be stored in Git directly.

## Project Snapshot

Project Chill is a Godot 4 2D fixed-camera companion demo inspired by Chill With You.

Non-negotiables:

- no player avatar
- no movement
- Yua is always visible
- interaction is click/tap plus dialogue UI
- most dialogue is scripted
- player-facing free text exists as `Type Mode`
- memory is game-side and persistent
- voice is optional and has a pre-generated playback path for demo lines

## Current Product Goal

Build a convincing short playable demo where:

1. the player enters Yua's room
2. Yua greets them
3. the player can choose guided replies or type in their own words
4. Yua supports a small focus / check-in / goodbye loop
5. the player can mention something about tomorrow
6. Yua remembers and follows up next session

## Current State

- Main scene exists and runs.
- Character art and room art are already wired into the scene.
- Dialogue panel exists and has been reworked recently.
- Yua is the active companion character name in UI and script.
- Scripted dialogue JSON exists and now includes:
  - first launch intro
  - return-session opening
  - check-in / focus / small talk branches
  - goodbye branch
  - memory follow-ups for school / exam / work / sleep
- `Type Mode` exists as the player-facing free-text feature.
- AI routing exists behind the scenes.
- If no API key is present, the game now falls back to a mock provider so Type Mode is always testable.
- Memory extraction and follow-up persistence are implemented in game-side save data.
- Utility messages (timer/todo/music) were separated from the main dialogue text so they do not overwrite the narrative layer.

## Important Product Decisions

- Do not use visible player-facing `AI` terminology in-game.
- Keep `Type Mode` as the only visible label for free-text input.
- Scripted dialogue remains the backbone.
- Type Mode is the differentiator, but it should not replace the main loop.
- The experience should feel calm, warm, gentle, and emotionally safe.

## Key Files

- `AGENTS.md`
- `docs/Game_Spec_and_Process_Guide.md`
- `docs/Development_Summary.md`
- `docs/AI_Dialogue_Infrastructure.md`
- `docs/CODEX_TAKEOVER_PLAYBOOK.md`
- `docs/CODEX_WORKFLOW.md`
- `docs/CODEX_THREAD_PROMPTS.md`
- `scenes/main/main_scene.tscn`
- `scenes/ui/dialogue_panel.tscn`
- `scenes/character/companion_view.tscn`
- `scripts/core/main_scene.gd`
- `scripts/core/dialogue_router.gd`
- `scripts/dialogue/ai_dialogue_service.gd`
- `scripts/dialogue/memory_manager.gd`
- `data/dialogue/scripted_nodes.json`
- `data/dialogue/yua_system_prompt.txt`
- `data/dialogue/yua_runtime_rules.txt`
- `scripts/audio/voice_manager.gd`
- `docs/YUA_VOICE_ARCHITECTURE.md`

## Current Demo Loop

1. first-time player gets an intro scene
2. returning player gets a return-opening scene
3. player can move through guided replies
4. player can enter Type Mode and reply in their own words
5. game stores simple memory topics from player text
6. on later launch, Yua may follow up on one remembered topic

## Known Gaps

- UI still needs more visual polish and better hierarchy
- the overall plot/game loop still needs tightening to feel fully demo-ready
- voice playback is optional and ready for pre-generated clips, but no runtime TTS provider is wired yet
- some docs may still reflect earlier directions and should be treated carefully

## Best Next Priorities

1. refine the first 3-5 minutes of scripted experience
2. tighten the room UI and reduce visual clutter
3. make the Type Mode + memory follow-up loop feel stronger and more intentional
4. keep building toward one polished vertical slice rather than many half-finished features

## How To Resume

1. read `AGENTS.md`
2. read the main docs listed there
3. read this handoff file
4. inspect `scripts/core/main_scene.gd`
5. inspect `data/dialogue/scripted_nodes.json`
6. continue from the highest-priority playable-demo task
