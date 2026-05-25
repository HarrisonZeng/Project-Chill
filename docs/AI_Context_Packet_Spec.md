# AI Context Packet Spec — what the game feeds Yua's AI each call

Owner: Narrative & Story stream. Consumer: Engine stream.

This defines Layer 3 — the dynamic, per-call context the game assembles and
injects so Yua's replies track the real moment. Layers 1 and 2 are static files
(`yua_system_prompt.txt`, `yua_world.txt`); Layer 3 is built at runtime from the
single profile.

## Prompt assembly order

1. `yua_system_prompt.txt` — Layer 1 personality (load already exists)
2. `yua_world.txt` — Layer 2 world  **(NEW: engine must load + concatenate this)**
3. Layer 3 context packet — the block specified below
4. `yua_runtime_rules.txt` — runtime rules
5. The player's message (Type Mode), if any

Never send full conversation history by default.

## Layer 3 fields (assemble from the one profile)

| Field | Source | Why the AI needs it |
| --- | --- | --- |
| `mode` | the AI mode id for this call (see ai_modes.json) | selects tone/intent |
| `presence_state` | `idle` / `focus_active` / `break` | so she doesn't chat mid-focus or grade |
| `time_bucket` | morning / noon / evening / night (real clock) | time-aware warmth |
| `player_nickname` | profile `player_nickname` (nullable) | light personalization; omit if empty |
| `current_task` | profile `last_task_text` (nullable) | reference the real task IF volunteered; never demand one |
| `completed_focus_count` | profile | peer co-accountability ("我们俩都往前挪了一点") |
| `total_focus_seconds` | profile | sense of accumulated time together |
| `return_context` | new session / short return / long return (from `last_seen_at`) | recognize return without implying she waited |
| `yua_openness` | profile int tier | **gate: AI must stay at or below this tier — never warmer/more disclosing than the authored story has reached** |
| `writing_disclosed` | `story_flags.yua_opened_once` (bool) | if false, AI must NOT reveal/describe her writing; if true, she may allude to "that thing" but still not quote it |
| `surfaced_memory` | one validated memory the game chose to surface, or none | the only fact she may echo this turn; if none, she must not imply specific memory |

## Per-mode: which fields matter most

- `AI_MODE_TASK_MIRROR` / `AI_MODE_TASK_CLARIFY`: `current_task`, `presence_state`. Receive/peer-shrink only; never coach.
- `AI_MODE_POST_SESSION`: `completed_focus_count`, `current_task`. Co-accountability, not grading.
- `AI_MODE_BREAK_CHAT`: `player_nickname`, `surfaced_memory`, `yua_openness`. Bounded, not pushy.
- `AI_MODE_MEMORY_ECHO`: `surfaced_memory` (required — if none, do not run this mode), `yua_openness`.
- `AI_MODE_IDLE_AMBIENT`: `time_bucket`, `presence_state`. One short self-directed line.
- `AI_MODE_GREETING`: `time_bucket`, `return_context`, `player_nickname`.

## Hard gates (engine enforces; AI only reads)

- AI never sets a flag, never advances `yua_openness`, never reveals the writing
  project, never invents lore or a memory.
- `surfaced_memory` is chosen and validated game-side. If empty, the memory-echo
  beat does not fire — never fabricate.
- During `focus_active`, do not call the LLM for chat; use a deterministic
  "later" / accountability line from `reactive_lines.json`.
- Every mode has a scripted fallback; AI failure must leave the flow playable.

## Open dependencies (engine)

1. Load `yua_world.txt` and concatenate after the persona (item 2 above).
2. On launch, route to idle co-presence — do NOT auto-open a dialogue node.
   Show the greeting/return line on the first click of Yua, not on connect.
   (Current `_resolve_start_node_id` + `_ready` auto-`_show_node`; needs to land
   on `idle` for returning players and surface greetings on click.)
3. Wire `player_nickname` capture on node `ep00_04` (mirror of task capture):
   typed text → store as `player_nickname` → go to `ep00_close`; if the player
   tries to skip with empty input, confirm once ("确认不输入昵称?") before
   accepting the skip.
4. Preserve node metadata in `_register_node` (`set_flags`, `unlock`, `tags`,
   `speaker`) so the milestone contract gates can fire.
