# Development Summary (Online Focus Companion Direction)

## Finalized Direction

Project Chill is a Godot 4 online focus companion game with a strong character/story layer.

Players launch the game when they want company while studying, working, or focusing. The setting is a cozy video call / online chatroom with Yua. The player is not physically entering her room, and the game does not progress by calendar days.

Important constraints:

- no player avatar
- no WASD movement
- fixed camera / fixed call composition
- Yua always visible
- click/tap and dialogue UI driven interaction
- focus timer and task input are core gameplay
- progression is based on completed focus sessions and total focus time
- voice is deferred for now

## Core Loop

1. Launch the call.
2. Yua greets the player based on real-world time and return context.
3. Short check-in captures what the player is working on.
4. Player sets a focus session.
5. During focus, casual chat is restricted and Yua keeps the player accountable.
6. Finishing a session unlocks break chat, reflection, or scripted story progress.
7. Progress, memory, task context, and Yua story state persist across relaunch.

## Core Interaction Modes

1. Focus mode: player is working; Yua gives minimal accountability lines.
2. Break mode: player can chat, reflect, or receive a story beat.
3. Scripted story mode: authored Yua scenes unlocked by focus milestones.
4. AI Type Mode: bounded free text for check-ins, task understanding, memory extraction, and post-session reflection.

## Story Direction

Yua is a quiet writer using the shared online call to keep herself accountable. As the player completes focus sessions, Yua also makes progress on her writing. The story unfolds through small disclosures and milestone scenes.

The emotional arc is not "come back to my room each day." It is "we keep working together, and this shared call slowly becomes meaningful."

## AI Direction

AI should help with:

- pre-focus check-ins
- understanding the player's task
- extracting memory tags
- short encouragement
- post-session reflection
- limited break/casual chat after work is completed

AI should not:

- replace authored story beats
- unlock progression by itself
- become unlimited pre-focus chat
- invent major Yua lore

## Memory Requirement

Memory is game-side and persistent. It should support future check-ins and focus support.

Example:

- player says they have computer science class today
- memory stores `school` / `class` context
- future check-in can ask if today's task is for the same class

## Current Implementation State

- Main scene and UI scaffold exist.
- Scripted dialogue JSON is active.
- Memory manager, AI service, and dialogue router exist.
- Focus timer, todo UI, and music controls exist.
- Existing content still reflects an earlier VN-room/check-in prototype and needs to be refactored toward focus-session progression.
- Voice manager exists but voice is not an immediate requirement.

## What To Do Next

Next implementation target:

- convert the playable loop to focus-first:
  1. greeting
  2. task/check-in
  3. focus session
  4. restricted interactions during focus
  5. completion reward
  6. session-based story unlock

After that, expand reactive line pools and focus-gated Yua story milestones.

## Audio Import Note

For reliable BGM seek/progress in Godot, prefer OGG. If you import an MP3, open it in the Import dock, set Format to Ogg Vorbis, and reimport.
