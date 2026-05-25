# Engine Handoff — Vertical Slice 01

Owner: Narrative & Story stream. Consumer: Engine stream.

One place that says what the Engine needs to wire so the authored content
(`data/dialogue/*.json`, the prompt `.txt` files) actually runs. Narrative owns
the data; the Engine owns `main_scene.gd` / UI / services and implements against
this. The two detailed specs are linked below — this doc is the punch list.

Detailed specs:
- `docs/Milestone_Contract_VS01.md` — flags, beat triggers, node→flag map
- `docs/AI_Context_Packet_Spec.md` — prompt assembly order + Layer 3 fields

---

## A. Round 2 — current asks (these are the live ones)

All in `scripts/core/main_scene.gd`. Items A0 are DONE (engine already extended
the episode table to 14 and bumped the version). Three new ones:

### A1. Delete the legacy click line; clicking Yua should re-enter the conversation
In `_on_character_clicked()` (~line 835–861), when the current node is NOT
`idle`, it prints:
```
_set_dialogue_text("我在。先选一个回复，或者在下面写你自己的话。")   # ~line 858
```
**Delete that fallback.** The problem: episode nodes end on a terminal node
(empty `choices`), so `current_node_id` is no longer `idle`, and the next click
hits this meta line instead of re-engaging.

Fix: after showing a **terminal node** (a node whose `choices` is empty), reset
`current_node_id = "idle"` (or otherwise mark the conversation closed) so the
next click runs the existing idle branch (`_resolve_start_node_id` →
greeting / return / next available beat). Net behavior: clicking Yua always
resolves a real line (greeting/return, or ambient), **never** the "先选一个回复"
text. Keep the in-AI-mode branch (line 859–860) as-is.

### A2. Debug panel: number box + Go + Next Ep (replaces the per-episode buttons)
In `_debug_timeline_setup()` (~line 1676) the per-episode button row is now 15
buttons wide (Ep0 + 14) — too wide. Replace the loop that adds one `Button` per
`_debug_timeline_entries()` with:
- a `LineEdit` (numeric, placeholder "EP")
- a **Go** button → parse the int `N`; jump via the existing
  `_debug_timeline_jump(node_id, session_count)` where `node_id = "ep%02d_01" % N`
  (and `N == 0` → `intro_node_id`), `session_count = N`.
- a **Next Ep** button → `N = completed_focus_sessions + 1`, same jump.
Keep the **Reset Save** button and the `_debug_timeline_jump` helper unchanged.

### A3. `{focus_minutes}` token substitution
`ep01_01` choice 1 reads `"很充实，这 {focus_minutes} 分钟值了！"`. When rendering
choice/line text, replace `{focus_minutes}` with the length (in whole minutes) of
the focus session that just completed. Fallback if no value / can't substitute:
strip the token (and the stray " 分钟" reads fine as "很充实，这分钟值了！" is awkward
— prefer substituting, or replace the whole token-bearing phrase with
"很充实，坐得住！"). Only this one choice uses the token today.

### A0 (already done — FYI)
- `EPISODE_START_NODES` extended to `ep01_01 … ep14_01` (so Ep7–14 fire).
- `DEMO_SCRIPT_VERSION` bumped to 7 (replays the rewritten Ep0).

Everything below is pre-existing / verify.

---

## B. Already wired (confirmed this pass — no action, just FYI)

- `_register_node` now preserves `set_flags` / `tags` / `unlock` / `speaker`
  (the old metadata blocker is resolved). Node-level `set_flags` and the
  `name_input` tag are honored.
- Nickname capture is live: the Ep0 name node is tagged `name_input`
  (`ep00_name`), and typing there stores `player_nickname` and advances to
  `ep00_close`. **Note:** that node no longer has a "skip" choice — nickname is
  now required. Please confirm empty/whitespace input is rejected gracefully
  (re-prompt, don't dead-end).
- Type input works via a choice whose `next` is an `AI_MODE_*` id — flips Type
  Mode on, stores the message through `memory_manager`, runs the AI. The new
  type points are on `ep01_01`, `ep04_01`, `ep07_01`, `ep11_01`, `ep13_01`,
  `ep14_01`.

---

## C. Still open from the specs (verify or implement)

From `docs/AI_Context_Packet_Spec.md`:

1. **Load `yua_world.txt`** (Layer 2) and concatenate after
   `yua_system_prompt.txt` (Layer 1), before the Layer 3 packet. Verify this is
   actually loaded — last I checked only Layer 1 was loaded, so all the
   aquarium/writing world facts never reach the model.
2. **Launch into idle co-presence, not an auto-opened dialogue.** On connect,
   land on `idle` (Yua working); show the greeting/return line only when the
   player clicks Yua.
3. **Assemble the Layer 3 context packet** (mode, presence_state, time_bucket,
   player_nickname, current_task, focus counts, return_context, the
   `yua_openness` / `writing_disclosed` gates, and `surfaced_memory`). The
   memory-echo "she speaks first" beat needs a proactively generated AI line
   using `surfaced_memory` — only when a real validated memory exists.

From `docs/Milestone_Contract_VS01.md`:

4. **`yua_openness` advances only on completed focus** — never on clicks or Type
   Mode. (Used later to gate how open Yua is; not load-bearing for Ep1–14, which
   are gated purely by focus count.)

---

## D. Note on the deferred payoff

The old Ep1 "payoff" node that set `yua_opened_once` (she opened the writing
file) has been **removed from the slice** — that heavy beat is intentionally
deferred to a later episode (CWYL-style slow burn). So `yua_opened_once` is not
set by any node in the current JSON; it stays false for now. The contract still
documents the flag for when the deferred beat is authored. No gate should hard-
require `yua_opened_once` in this slice.
