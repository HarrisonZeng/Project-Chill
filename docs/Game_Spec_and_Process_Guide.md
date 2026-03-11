# Project Chill

## 1. Vision

Project Chill is a small, cozy Godot 4 demo about spending quiet time with an AI companion in a warm bedroom-like space.

The feeling we want:

- calm
- safe
- emotionally warm
- low pressure
- easy to understand

The player should be able to enter the room, move around a little, sit down, interact with the companion, and have short conversations that feel personal because the companion remembers a few recent details.

This is a demo, not a full commercial game. The goal is to build a polished vertical slice that proves the mood, interaction loop, and technical direction.

## 2. Demo Goal

Build a first playable demo with:

- one main room
- one companion character
- simple player movement
- one or two interaction points
- a dialogue UI
- lightweight memory of recent player topics
- save/load for a small amount of state

If the demo feels soothing and the companion feels responsive, it is successful.

## 3. Core Player Experience

The intended loop is:

1. The player enters a cozy room.
2. The player walks to the companion or an interactable object.
3. The player presses an interact button.
4. The game opens a dialogue panel or short contextual interaction.
5. The companion replies with warmth and remembers a few recent things.
6. The player stays, explores, or ends the session feeling relaxed.

This should feel more like a comforting digital space than a challenge-based game.

## 4. Design Pillars

Use these pillars to guide decisions. If a feature does not support at least one of them, it can wait.

### Emotional warmth

The companion should feel kind, grounded, and gentle.

### Simplicity

The first demo should stay small enough to finish.

### Readability

UI, controls, and scenes should be understandable to a beginner developer and easy for a player to use.

### Stability

Prefer simple, reliable systems over ambitious but fragile ones.

## 5. Scope For Version 0.1

### In scope

- single-room environment
- player movement
- camera setup
- one companion with idle animation
- interaction prompt
- dialogue panel
- typed player input or button-based prompts
- memory list with the last few key topics
- local save data in JSON or Godot save format
- placeholder art and placeholder audio if needed

### Out of scope for now

- online multiplayer
- complex quests
- large branching narrative system
- procedural world generation
- full voice acting pipeline
- mobile export optimization
- advanced inventory systems
- large-scale AI autonomy

## 6. Suggested First Demo Features

### Room scene

One room is enough. It can include:

- desk
- chair or bed
- window
- lamp
- companion position

### Player controller

Start with simple movement:

- move with keyboard
- optional run toggle later
- face the interaction target

For a beginner-friendly first pass, use a top-down or angled 2D/2.5D presentation instead of full free-camera 3D.

### Companion interaction

The first interaction can support:

- approach companion
- press `E` or an input action like `interact`
- open dialogue panel
- send a short player message
- display companion reply

### Memory system

Keep it small and predictable:

- store the last 10 important player topics or mood words
- include those topics in future prompt context
- save only lightweight text data

### Save system

The demo only needs to save:

- player position
- recent memory list
- simple session flags

## 7. Technical Direction

### Engine

- Godot 4.x
- GDScript

### Assistant

- Codex

Codex will help with:

- planning
- writing GDScript
- reviewing bugs
- refactoring
- proposing scene structure
- documenting decisions

The Godot editor will still be used by you for:

- creating scenes
- placing nodes
- connecting some signals
- importing assets
- testing the game feel

## 8. Human and Codex Responsibilities

### You

- decide the mood and creative direction
- choose or create art, music, and writing tone
- test scenes in Godot
- tell Codex what worked, what felt wrong, and what you want next

### Codex

- write and explain code
- propose file structures
- help debug errors
- turn ideas into concrete tasks
- keep docs updated
- suggest safe next steps for a beginner

## 9. Working Style With Codex

When asking for help, try to give:

- the goal
- the file name or scene name
- the error message if there is one
- what you expected to happen
- what actually happened

Good prompt examples:

- "Create a Godot 4 player controller in GDScript for a CharacterBody2D with WASD movement."
- "Help me build a dialogue panel scene for Godot 4 and explain each node."
- "Here is my error from Godot. Please fix the script and explain why it happened."
- "Suggest the next smallest step for this prototype."

## 10. Recommended Folder Structure

Use a structure like this as the project grows:

```text
project_root/
  assets/
    audio/
    fonts/
    sprites/
    backgrounds/
  scenes/
    main/
    player/
    companion/
    ui/
    props/
  scripts/
    player/
    dialogue/
    systems/
    ui/
  data/
    dialogue/
    saves/
  docs/
    Game_Spec_and_Process_Guide.md
    Development_Summary.md
    Design_Log.md
```

This is only a guide. We can adjust it once real scenes and scripts exist.

## 11. Coding Conventions

Use these defaults unless the project later needs something different:

- Godot 4 syntax only
- `snake_case` for variables and functions
- `PascalCase` for class names
- clear node names in scenes
- short scripts with one responsibility each
- exported variables for values you may tweak in the editor
- comments only where they help explain non-obvious logic

## 12. Architecture For The First Prototype

Keep the first version modular but simple.

### Suggested systems

- `player_controller.gd`
- `interaction_component.gd`
- `dialogue_manager.gd`
- `memory_system.gd`
- `save_manager.gd`
- `dialogue_panel.gd`

### Suggested flow

1. Main scene loads room, player, companion, and UI.
2. Player enters interaction range.
3. Interaction prompt appears.
4. Player presses interact.
5. Dialogue UI opens.
6. Dialogue manager sends player text to local logic or API layer.
7. Memory system updates tracked topics.
8. Response appears in UI.
9. Save manager can persist memory and simple state.

## 13. AI Dialogue Strategy

Start with a local placeholder dialogue system before using any online AI API.

Why:

- easier to debug
- cheaper
- faster to build
- no networking problems while learning the basics

Recommended progression:

1. Stage A: fake responses from a local list
2. Stage B: add memory tracking
3. Stage C: add optional API integration
4. Stage D: polish tone and persistence

This lets us prove the game loop before adding complexity.

## 14. Development Phases

### Phase 1: Foundation

- create docs
- create folder structure
- create main scene
- create player movement
- test camera and room scale

### Phase 2: Interaction

- create companion scene
- add interaction zone
- add input action for interaction
- show simple prompt

### Phase 3: Dialogue

- create dialogue panel
- send simple player input
- return placeholder companion replies

### Phase 4: Memory

- track recent topics
- show memory affecting future responses
- save and load memory

### Phase 5: Polish

- improve visuals
- tune pacing
- improve transitions and audio
- prepare demo build

## 15. Beginner-Friendly Development Routine

For each work session, do only one small, testable task.

Good session examples:

- create the player scene
- make movement feel correct
- add the companion node
- build the dialogue panel layout
- save one variable to disk

Avoid trying to solve everything in one session.

## 16. Testing Checklist

Whenever we add a feature, test:

- does the scene run without errors
- does the player understand what to do
- does the feature work twice in a row
- does saving and loading keep the expected data
- does the game still feel calm and uncluttered

## 17. Risks To Manage Early

### Scope creep

It is easy to add too many systems too early. Keep the first demo small.

### AI complexity

Real AI integration can wait until the non-AI version feels good.

### Asset overload

Placeholder assets are fine at the start.

### Beginner overwhelm

We should always pick the next smallest meaningful step.

## 18. Definition Of Success For The First Demo

The first demo is successful if:

- the player can move around a cozy room
- the player can interact with the companion
- the companion can respond in a believable way
- the game remembers a few recent player details
- the whole flow works reliably from launch to quit

## 19. Immediate Next Steps

Start here, in this order:

1. Create the project folders listed above.
2. Create a `main` scene for the room.
3. Create a simple `player` scene with movement.
4. Add a placeholder companion scene.
5. Add an `interact` input action in Godot.
6. Build a basic dialogue panel with placeholder text.
7. Test the loop: move -> interact -> open panel -> close panel.

Once that works, we can start writing the actual scripts together.
