# SESSIONS.md — Running multiple sessions without collisions

This project is edited directly in the main tree (no worktrees). When you run
**more than one Claude session at the same time**, they share the same files —
so two sessions editing the same file will clobber each other. This file is the
rulebook + map that lets simultaneous sessions stay out of each other's way.

If you only ever run one session at a time, you can ignore all of this.

---

## The protocol (every session follows this)

At the **start** of a session, before editing anything:

1. **Read this file** (the rulebook + the ownership map below).
2. **Look at `.sessions/`** — each file there is another running session's claim.
   Read them to see which files are already taken.
3. **Write your own claim** to `.sessions/<short-name>.md` using the template at
   the bottom. List the files (or whole components) you intend to touch.

While **working**:

4. **Before editing any file, check it isn't in another active claim.** If it is,
   don't touch it — pick different work, or tell the owner so they can decide.
5. Keep your claim current if your scope changes.

At the **end** of a session:

6. **Delete your `.sessions/<short-name>.md`** (or mark it `done`) so the files
   free up for others.

`.sessions/` is git-ignored scratch space — these claim files are never
committed and you never need to manage them by hand; the session does it.

> Why per-session files instead of one shared list? So two sessions writing
> claims at the same moment can't overwrite each other — each only ever writes
> its own file.

---

## Ownership map — claim by component, not by guesswork

Pick whole rows when you can; that's the cleanest way to avoid overlap. (Full
detail in `docs/Architecture_Overview.md`.)

| Concern | Files you'd touch | Notes |
|---|---|---|
| **Core loop / dialogue flow / focus / progression** | `scripts/core/main_scene.gd` | The big coordinator. High-traffic — try to have only **one** session in here at a time. |
| **Call-status pill** | `scripts/ui/call_status_controller.gd` | + its node in `main_scene.tscn` |
| **Music / voice bar** | `scripts/ui/music_bar_controller.gd` | + `BottomLeftMusicBar` in `main_scene.tscn` |
| **Tasks / todo panel** | `scripts/ui/tasks_panel_controller.gd` | + `OverlayLayer/Tools` in `main_scene.tscn` |
| **Dialogue panel UI** | `scenes/ui/dialogue_panel.tscn` (+ its script if added) | |
| **Companion / character** | `scenes/character/companion_view.tscn` | |
| **Save / profile / memory** | `scripts/dialogue/memory_manager.gd` | The save authority. |
| **AI service / routing** | `scripts/dialogue/ai_dialogue_service.gd`, `scripts/core/dialogue_router.gd` | |
| **Scripted content** | `data/dialogue/scripted_nodes.json`, `scripts/dialogue/scripted_dialogue_manager.gd` | Narrative edits live in the JSON. |
| **UI text / i18n** | `scripts/ui/ui_strings.gd` | Shared — keep edits append-only (add keys, don't reorder) so two sessions rarely conflict. |
| **Audio** | `scripts/audio/bgm_manager.gd`, `scripts/audio/voice_manager.gd` | |
| **Theme / visual style** | `data/theme/project_chill.tres` | |
| **Docs / specs** | `docs/**`, `AGENTS.md`, `CLAUDE.md` | |

### Shared hot-spots (coordinate carefully)
- **`scenes/main/main_scene.tscn`** — almost every UI component has a node here.
  Editing *different nodes* in it from two sessions is usually fine, but say so
  in your claim (e.g. `main_scene.tscn:BottomLeftMusicBar`).
- **`scripts/core/main_scene.gd`** — if your component work needs to add a
  method call or signal hookup here, note it; ideally batch those through the
  session that owns the core loop.

### Good parallel split (example)
Session A → music bar · Session B → tasks panel · Session C → narrative JSON +
UiStrings keys. Three different files, no overlap.

---

## Claim template

Copy into `.sessions/<short-name>.md`:

```markdown
# session: <short-name>
started: <date/time>
task: <one line — what this session is doing>
status: active        # active | done
claims:
- scripts/ui/music_bar_controller.gd
- scenes/main/main_scene.tscn:BottomLeftMusicBar
needs-core-loop-edit: no   # yes if you must edit main_scene.gd
```
