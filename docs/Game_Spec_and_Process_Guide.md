# Project Chill

## 1. Vision (Reference-Driven)

The demo style follows your reference image: a warm room scene with the female character always visible, viewed from a fixed camera.

This is a visual-novel style companion experience, not a movement game.

Core interaction style:

- no player avatar
- no WASD movement
- immediate entry into character scene
- interaction by clicking character hotspots or dialogue UI
- player replies by preset choices or free text (AI mode)

## 2. Product Goal

Build a polished vertical slice where the player can:

- open the app and directly see the character in her room
- start conversation by clicking character or textbox
- choose scripted options most of the time
- switch to AI mode for free chat when needed
- hear voiced character responses
- feel remembered across sessions by lightweight memory

## 3. Experience Loop

1. Game starts into `main_scene` with fixed composition.
2. Character idles with subtle animation and ambient audio.
3. Player clicks character or dialogue area to open interaction.
4. Dialogue system offers:
   - scripted branch choices (default)
   - optional AI free-text input
5. Character responds with text + voice.
6. Memory system stores selected player facts and follow-up hooks.
7. On future login, system can surface context-aware lines (example: "How was school?").

## 4. Scope (v0.1)

### In scope

- fixed camera scene with character-centric composition
- click interactions (character + UI controls)
- dialogue panel with both:
  - preset response buttons
  - free-text chat input in AI mode
- hybrid dialogue router (scripted first, AI fallback/augment)
- memory extraction + persistence
- TTS voice playback for character lines
- session restore and login greeting logic

### Out of scope for v0.1

- full open-world navigation
- complex inventory and quest systems
- full emotional simulation engine
- multiplayer
- advanced real-time lip sync

## 5. Scene and UI Direction

Use the reference image as the visual target:

- warm sunset color palette
- character as the visual anchor at center-right
- decorative room props for cozy mood
- utility buttons as subtle overlays
- dialogue panel on lower third

Recommended first layout layers:

1. background layer (room image/video)
2. character layer (sprite, Live2D, or animated image)
3. interaction hotspots (character/head/desk)
4. dialogue and choice UI
5. utility HUD (settings, log, save/load)

## 6. Core Systems

### A. Interaction System (click-first)

- click character -> default greeting/action
- click hotspot -> contextual line
- click textbox/focus input -> submit text

### B. Dialogue System (hybrid)

- default path: scripted nodes and choices
- AI mode path: generate response using persona + memory context
- fallback rules when AI unavailable: use scripted safe lines

### C. Memory System (lightweight but useful)

Use two memory tiers:

- short-term memory: last 20 message highlights
- pinned memory: durable facts (school, exam, favorite song, etc.)

Store metadata:

- `fact`
- `confidence`
- `source_message`
- `last_seen_at`
- `follow_up_tag`

### D. Voice System

- scripted lines: pre-generate and cache voice audio
- AI lines: request TTS at runtime, then cache by text hash
- playback through `AudioStreamPlayer`
- subtitle/text always shown for accessibility

### E. Save/Profile System

Persist locally (JSON for prototype):

- conversation state
- pinned memories
- recent summaries
- last logout intent
- last login timestamp

## 7. Best-Practice Architecture For Your Use Case

This architecture fits your goal of mostly scripted narrative with selective AI:

1. `dialogue_router.gd`
   - decides scripted vs AI path
2. `scripted_dialogue_manager.gd`
   - handles authored branches and choices
3. `ai_dialogue_service.gd`
   - calls model API when AI mode is active
4. `memory_manager.gd`
   - extracts and stores memory entries
5. `session_manager.gd`
   - login/logout hooks and save/load
6. `voice_manager.gd`
   - audio generation/caching/playback
7. `ui_dialogue_panel.gd`
   - messages, choices, text input, mode toggle

## 8. How To Accomplish "Remember School Tomorrow" Reliably

Do not rely on raw model memory alone. Use explicit game-side memory.

Implementation pattern:

1. Player says: "I need to go to school tomorrow."
2. Memory extractor stores fact:
   - `topic=school`
   - `intent=upcoming_event`
   - `time_hint=tomorrow`
   - `follow_up_tag=ask_about_school`
3. On next login, `session_manager` checks pending follow-up tags.
4. If present, injects a scripted greeting candidate:
   - "Welcome back. How was school today?"
5. Dialogue router prioritizes this line before normal chat.

This gives deterministic continuity even if the AI provider changes.

## 9. AI Model Strategy

You can absolutely use a pre-trained model with fixed personality/story framing.

Recommended pattern:

- persona and lore live in your own system prompt/profile file
- scripted dialogue remains the main narrative backbone
- AI is used for:
  - free chat moments
  - natural transitions
  - paraphrasing contextual replies

Keep AI bounded:

- include short memory summary, not full chat history
- enforce style constraints (tone, max length, no lore breaks)
- keep a safety fallback line if API fails

## 10. Folder Structure (VN-Oriented)

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
      voice_cache/
  scenes/
    main/
      main_scene.tscn
    ui/
      dialogue_panel.tscn
      choice_button.tscn
    character/
      companion_view.tscn
  scripts/
    core/
      dialogue_router.gd
      session_manager.gd
    dialogue/
      scripted_dialogue_manager.gd
      ai_dialogue_service.gd
      memory_manager.gd
    audio/
      voice_manager.gd
    ui/
      ui_dialogue_panel.gd
  data/
    dialogue/
      scripted_nodes.json
      persona_profile.json
    saves/
      player_profile.json
  docs/
    Game_Spec_and_Process_Guide.md
    Development_Summary.md
    AI_Dialogue_Infrastructure.md
```

## 11. Development Phases

### Phase 1: Visual Novel Foundation

- fixed main scene
- character sprite/view and idle presentation
- dialogue panel and choice buttons
- click-to-talk interaction

### Phase 2: Scripted Dialogue Backbone

- branch nodes
- choice consequences
- save/load dialogue progress

### Phase 3: AI Mode + Memory

- free-text input mode
- model call abstraction
- memory extraction and storage
- follow-up trigger on next login

### Phase 4: Voice

- voice manager
- pre-generated voice for scripted lines
- runtime TTS + cache for AI lines

### Phase 5: Polish

- transitions
- button feedback and animation
- typing effect and audio timing
- mood consistency pass

## 12. Immediate Next Build Steps

1. Create VN-oriented folders and scene stubs.
2. Build `main_scene.tscn` with fixed character composition.
3. Build `dialogue_panel.tscn` with:
   - dialogue text
   - choice container
   - text input
   - `AI Mode` toggle
4. Implement scripted dialogue only (no API yet).
5. Add local memory save/load.
6. Add AI mode using stub responses first.
7. Integrate real model API and voice after flow is stable.

## 13. Definition Of Success (First Demo)

The demo is successful when:

- user can immediately enter a cozy character scene
- user can converse using choices or AI chat input
- character voice plays with responses
- at least one remembered fact is used correctly in a later session
- experience feels calm, intimate, and stable
