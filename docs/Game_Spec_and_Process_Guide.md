# Project Chill Game Spec And Process Guide

## 1. Vision

Project Chill is a 2D fixed-camera online focus companion game.

Players launch the game when they want company while studying, working, or trying to focus. The fantasy is not "visit a character's room every day." The fantasy is:

> I do not want to work alone. I want someone gentle, believable, and familiar beside me while I get through this.

The game is partly a productivity app, but with a strong human/character element and authored story progression.

## 2. Reference Understanding

The current reference direction is inspired by Chill With You's work/study call structure:

- remote call framing first, story game second
- heroine always visible
- real productivity tools are part of the loop
- many tiny contextual lines for start, work, break, finish, return, and time of day
- main story episodes unlock gradually through repeated work together
- intimacy grows from co-presence and routine, not from constant chat

Project Chill should mirror this structure for now, then diverge into its own character, writing-project story, UI style, and AI-enhanced memory.

## 3. Product Goal

Build a Steam-worthy focus companion game where the player can:

- open the app and join a cozy video call / online chatroom with Yua
- do a short AI-assisted check-in about what they are working on
- set a focus session and task
- work quietly with Yua on screen
- receive contextual encouragement without being distracted
- unlock break chat, story scenes, and Yua's writing progress after completing sessions
- feel remembered across sessions through game-side memory
- see atmosphere and greetings respond to real-world time

Voice is deferred. Text, animation, ambience, and strong writing are the immediate priority.

## 4. Non-Negotiables

- No player avatar.
- No WASD or movement controls.
- No open-world navigation.
- Fixed composition focused on Yua and the call UI.
- Interaction is click/tap, dialogue choices, task input, focus controls, and bounded Type Mode.
- Focus comes before casual chat/progression.
- Progression is based on completed focus sessions, total focus time, and milestones.
- Scripted story remains primary.
- AI remains optional and bounded.
- Memory is stored game-side and persists locally.

## 5. Setting And Presentation

The gameplay setting is a cozy online call / `xianshang liaotianshi` style focus room.

Yua is on the other side of the call. She is not physically in the same room as the player. She is also working, usually writing.

The screen should communicate:

- online call presence
- soft shared workspace
- Yua always visible
- real-time lighting and ambience
- task/focus controls integrated as call tools
- dialogue lower-third or chat/call overlay

Real-world time should matter:

- morning / noon / evening / night lighting
- time-aware greeting pools
- time-aware work/rest click reactions
- late-night concern lines
- return-after-absence lines

## 6. Core Gameplay Loop

1. Player launches the game.
2. Yua appears in the call.
3. Yua gives a time-aware greeting or return line.
4. Short check-in asks what the player is working on.
5. Player enters a task and chooses a focus duration.
6. Focus session starts.
7. During focus, casual chat is restricted.
8. Clicking Yua during focus gives short "back to work" or accountability lines.
9. Session finishes or is abandoned.
10. Yua reacts based on completion, duration, and context.
11. Player unlocks break chat, reflection, or a scripted story milestone.
12. State saves: session count, total focus time, task/memory tags, story flags.

## 7. Progression Model

Progression is session-based, not day-based.

Track:

- completed focus sessions
- total completed focus time
- current focus streak or return rhythm
- short / normal / long session counts
- abandoned or paused sessions
- current story milestone
- Yua writing progress
- player memory tags
- relationship/familiarity flags

Example gates:

- after tutorial focus: unlock normal break chat
- after 1 completed session: first story episode
- after 3 completed sessions: Yua mentions her writing project
- after 5 completed sessions: Yua shares a small draft problem
- after 2 total focus hours: deeper trust variant
- after repeated late-night focus: special concern/check-in lines
- after repeated abandoned sessions: gentle reset scene

## 8. Story Spine

Yua is a quiet writer who uses shared calls to keep herself accountable. The player is also working or studying. Over many focus sessions, the two build a routine.

Her arc:

1. polite online focus partner
2. comfortable quiet coworker
3. gently teasing familiar presence
4. admits she is stuck on a writing project
5. shares small draft fragments or creative worries
6. uses the player's steady presence to keep going
7. lets the player influence small aspects of her story direction

The core emotional promise:

- the player makes real progress
- Yua makes creative progress
- the shared call becomes meaningful because both sides keep showing up

## 9. Content Structure

Use two layers of content.

### A. Main Story Milestones

Authored VN-style episodes unlocked by session progress.

Examples:

- `tutorial_call_01`: first connection and tool introduction
- `episode_01`: first real focus session together
- `episode_02`: Yua explains why shared work helps her
- `episode_03`: Yua reveals she writes
- `episode_04`: first writing slump
- `episode_05`: player helps choose a small creative direction

These scenes are scripted and stable.

### B. Reactive Session Lines

Small contextual line pools for everyday use:

- game start
- return after short/long absence
- morning/noon/evening/night greetings
- focus start
- continuous/back-to-back focus
- short focus
- long focus
- break start
- focus finish
- abandoned/stopped midway
- click Yua during work
- click Yua during break
- app end after short/normal/long use
- self-talk while idle or working

These lines are what make the game feel alive during real productivity sessions.

## 10. AI Role

AI is most useful in controlled windows:

- check-in before focus
- task understanding
- memory extraction
- post-session reflection
- limited casual chat after work is completed
- paraphrasing encouragement in Yua's tone

AI should not:

- replace authored story milestones
- unlock progression directly without validation
- become unlimited pre-focus chat
- invent major Yua lore
- store memory only in model history

Prompt context should include:

- Yua persona
- current mode: check-in, focus start, break, reflection, casual chat
- current task if known
- session stats summary
- short memory summary
- strict reply length and tone rules

## 11. Memory System

Memory should support focus and familiarity.

Store durable but lightweight facts:

- school/class
- exam/test
- work/job/project
- sleep/tiredness
- stress
- preferred focus duration
- recurring task or subject
- last unfinished goal

Use memory naturally:

- "You mentioned that class before. Same one today?"
- "Another late session? Let's keep it smaller."
- "You usually do better with shorter blocks. Want to start there?"

Memory is a feature, not the whole structure. Progress still comes from focus sessions.

## 12. Core Systems

### Focus Session System

Tracks:

- selected duration
- task/intention text
- start time
- time left
- pause/abandon state
- completion
- short/normal/long category

### Progression System

Tracks:

- completed session count
- total focus seconds/minutes
- current milestone
- unlocked story episodes
- Yua writing progress
- hidden familiarity tags

### Dialogue System

Routes:

- scripted story nodes
- reactive line pools
- AI check-in/reflection
- fallback lines

### Memory System

Extracts and stores game-side memory tags from check-ins and Type Mode.

### Real-Time Atmosphere System

Applies time-of-day lighting, greeting pools, and ambience.

### Save/Profile System

Persists:

- focus totals
- session history summary
- current milestone
- unlocked story
- memory tags
- task preferences
- last seen/return timestamps

## 13. Recommended Folder Structure

```text
project_root/
  assets/
    art/
      backgrounds/
      character/
      ui/
    audio/
      bgm/
      sfx/
      voice_cache/       # deferred
  scenes/
    main/
      main_scene.tscn
    ui/
      dialogue_panel.tscn
      focus_panel.tscn
    character/
      companion_view.tscn
  scripts/
    core/
      main_scene.gd
      session_progression.gd
      dialogue_router.gd
    dialogue/
      scripted_dialogue_manager.gd
      ai_dialogue_service.gd
      memory_manager.gd
      reactive_line_manager.gd
    audio/
      bgm_manager.gd
      voice_manager.gd      # optional/deferred
    ui/
      ui_dialogue_panel.gd
  data/
    dialogue/
      scripted_nodes.json
      reactive_lines.json
      yua_system_prompt.txt
      yua_runtime_rules.txt
    progression/
      focus_milestones.json
    saves/
      player_profile.json
  docs/
    Game_Spec_and_Process_Guide.md
    Development_Summary.md
    AI_Dialogue_Infrastructure.md
```

## 14. Development Phases

### Phase 1: Concept Refactor

- update docs from room/day VN to online focus companion
- rename design language around sessions, calls, and milestones
- define focus-first acceptance path

### Phase 2: Focus-First Loop

- launch call
- time-aware greeting
- task/check-in input
- start focus session
- restrict chat during focus
- finish or abandon session
- unlock break chat after completion

### Phase 3: Session Progression

- total focus time
- completed sessions
- milestone unlocks
- Yua writing progress
- save/load progression

### Phase 4: Reactive Lines

- line pools for start/work/break/finish/click/end/time-of-day
- deterministic line selection with enough variety
- context-aware "back to work" reactions during focus

### Phase 5: AI Check-In And Reflection

- AI understands current task and mode
- AI extracts memory tags
- AI stays short, warm, and bounded
- AI cannot bypass focus gates

### Phase 6: Scripted Story Milestones

- write focus-gated Yua story episodes
- connect story progress to completed sessions and total focus time
- keep story emotional and low-drama

### Phase 7: UI And Atmosphere

- online call framing
- readable focus controls
- real-time lighting
- polished break/chat flow

### Phase 8: Voice And Advanced Polish

- optional TTS/pregenerated voice
- refined animation
- deeper ambience
- Steam demo polish

## 15. Current Definition Of Success

The next successful vertical slice should prove:

- player opens the call and gets a time-aware greeting
- player enters a task
- player starts a focus session
- Yua discourages distraction during focus
- finishing the session increments progress
- break chat or a story beat unlocks only after focus
- memory can personalize a future check-in
- all state persists across relaunch
