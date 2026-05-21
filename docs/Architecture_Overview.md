# Architecture Overview

A map of how Project Chill's code is organized, why, and where the seams are.
Read this with `SESSIONS.md` (the file-ownership protocol) when planning work
that several sessions will touch in parallel.

## Layers

```
                 ┌─────────────────────────────────────────┐
                 │  main_scene.gd  (Coordinator + core loop) │
                 │  dialogue flow · focus/progression · AI    │
                 │  routing glue · save coordination · wiring │
                 └───────────────┬───────────────────────────┘
        ┌────────────────────────┼────────────────────────────┐
        │                        │                             │
   UI components            Services                      Static / data
   (own a subtree)          (own a domain)                (no node, pure)
   call_status              memory_manager                UiStrings (i18n)
   music_bar                ai_dialogue_service           data/dialogue/*.json
   tasks_panel              dialogue_router               data/saves/*.json
   DialoguePanel (scene)    scripted_dialogue_manager
   CompanionView (scene)    bgm_manager / voice_manager
```

### Coordinator — `scripts/core/main_scene.gd`
The root scene script. After the component extraction it owns only what is
genuinely the *core game loop*:
- scripted dialogue flow (show node, choices, typewriter, special choices)
- focus timer + completion → story progression (the productivity differentiator)
- AI routing glue (Type Mode → `dialogue_router`)
- save/load coordination (reads/writes everything through `memory_manager`)
- wiring the UI components together and forwarding their signals

It is intentionally still the biggest file because the core loop is one cohesive
concern. Splitting it across files would not help parallel work — a session
touching the loop touches all of it.

### UI components — `scripts/ui/*_controller.gd`
Each owns one subtree of `scenes/main/main_scene.tscn` and is attached to that
subtree's root node. They are self-contained: they connect their own child
signals, resolve their own text via `UiStrings`, and talk to the coordinator
through **signals** (out) and **method calls** (in). They never read or write
the save file directly — `main_scene` owns persistence.

| Component | Script | Scene node it's attached to |
|---|---|---|
| Call-status pill | `scripts/ui/call_status_controller.gd` | `OverlayLayer/HUD/CallStatusPill` |
| Music / voice bar | `scripts/ui/music_bar_controller.gd` | `BottomLeftMusicBar` |
| Tasks / todo panel | `scripts/ui/tasks_panel_controller.gd` | `OverlayLayer/Tools` |
| Dialogue panel | (scene) `scenes/ui/dialogue_panel.tscn` | `BottomPanel/DialoguePanel` |
| Companion view | (scene) `scenes/character/companion_view.tscn` | `CompanionStage/CompanionView` |

The component contract (the pattern to copy for the next extraction):
- `extends <NodeType>` matching the subtree root; `class_name` optional.
- `main_scene` holds the ref as `: Node` (avoids the "could not find type"
  global-class timing issue) and calls methods on it.
- inputs the coordinator owns are pushed in via methods (`apply_language(lang)`,
  `setup(dep)`, `start_playback(...)`, getters/setters for persisted state).
- things the coordinator must react to go out via signals (`save_requested`,
  `voice_toggle_requested`, `status_message`, …).

### Services — `scripts/dialogue/*`, `scripts/audio/*`
Domain logic with clean boundaries, instantiated by `main_scene` in `_ready`:
- **`memory_manager.gd`** — the single save/profile authority. One JSON profile
  at `user://data/saves/player_profile.json` (`PROFILE_VERSION = 2`). Holds
  session/UI state (`get_value`/`set_value`/`merge_values`), memories,
  follow-ups, and `story_flags`. The legacy split-save (`user://player_profile.json`)
  is migrated in once and then ignored — **the split-save bug is fixed.**
- **`ai_dialogue_service.gd`** — provider abstraction (`AiProvider` base,
  `MockAiProvider`, `PoeAiProvider`), HTTP, and fallback text. Swappable.
- **`dialogue_router.gd`** — decides scripted vs AI per turn; always returns a
  safe fallback so the loop never stalls.
- **`scripted_dialogue_manager.gd`** — loads `data/dialogue/scripted_nodes.json`.
  Known gap: `_register_node` keeps only `id`/`line`/`choices` and drops
  `unlock`/`set_flags`/`tags`/`speaker`, so JSON-driven milestone metadata is
  not yet honored (see the progression spec).
- **`bgm_manager.gd` / `voice_manager.gd`** — leaf audio nodes; called via
  duck-typed `has_method` checks.

### Static — `scripts/ui/ui_strings.gd`
`UiStrings.t(key, lang)` — a `class_name` static string table (EN/ZH). New UI
text goes here; `main_scene._ui_text()` is the old inline table being migrated
into `UiStrings` one component at a time (call-status, music, tasks done).

## What changed in the de-monolith (May 2026)
`main_scene.gd` went from **1,914 lines / 121 functions → 1,386 / 90**, with the
peripheral UI moved into `call_status_controller`, `music_bar_controller`, and
`tasks_panel_controller`. Each was a separate commit so any single extraction can
be reverted in isolation.

## Remaining split opportunities (optional, future)
Lower priority — the core loop is cohesive, so these are quality, not blockers:
1. **DialogueView** — text rendering, typewriter, and choice-button styling
   could move into a script on the existing `DialoguePanel` scene, leaving the
   *flow decisions* in `main_scene`.
2. **Settings** — three small handlers + the language cascade. Awkward boundary
   (the toggle button is outside the panel and the cascade is inherently the
   coordinator's job), so likely stays unless it grows.
3. **Focus** — could become a thin view, but its state drives story progression,
   so the logic stays in the coordinator regardless. Not worth the signal churn now.
4. **Finish the `_ui_text` → `UiStrings` migration** as the remaining widgets
   are touched, then delete `_ui_text`.

## Coupling notes / gotchas
- Components are typed `: Node` in `main_scene`; method/signal access on them is
  "unsafe" (a GDScript warning, not an error) and resolves at runtime.
- Persistence is centralized: components expose getters/setters and emit
  `save_requested`; only `main_scene._save_persistent_state()` writes, via
  `memory_manager`.
- `_refresh_ui_language()` in `main_scene` is the language cascade — it calls
  each component's `apply_language(lang)`. New components must add a call here.
