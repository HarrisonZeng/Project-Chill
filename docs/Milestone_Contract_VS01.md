# Milestone Contract — Vertical Slice 01

Owner: Narrative & Story stream. Consumer: Engine stream.

This is the concrete gate spec the Engine implements against. It names every
story flag the narrative invents, what triggers each authored beat (in terms of
real save fields), and which nodes set which flags. Narrative authors this; the
beats do not fire in-game until the Engine wires the gates and fixes the
metadata blocker (see bottom).

Scope = Vertical Slice 01 only: Ep 0 (first meeting), Ep 1 (first payoff beat),
and the memory-echo moment. No later episodes are in scope yet.

## Save fields this contract relies on

Canonical names follow `docs/Vertical_Slice_01_Spec.md`. Current code var in
parentheses where it differs — Engine should reconcile to one profile:

- `completed_focus_count` (currently `completed_focus_sessions`) — int
- `total_focus_seconds` — int
- `return_count` / return rhythm — int
- `story_flags` — dict of string -> bool (already persisted by memory_manager)
- `player_nickname` — string, nullable (NEW; see Ep 0)
- `memories` / validated memory entries — already persisted by memory_manager
- `yua_openness` — int tier (NEW; relationship progress, advanced by focus only)

## Story flags (name + meaning)

| Flag | Meaning | Set by |
| --- | --- | --- |
| `intro_seen` | Ep 0 first-meeting intro has played through to the end. | final Ep 0 node |
| `yua_opened_once` | Ep 1 payoff beat has shown (Yua admitted she opened the thing she avoids). | Ep 1 payoff node |

Stored value (not a flag):

| Value | Meaning | Set by |
| --- | --- | --- |
| `player_nickname` | The handle the player chose. Empty/null if they declined. Used by AI for light personalization. | Ep 0 name node |

## Beat triggers

All beats are co-presence-first: they SURFACE at a natural moment (player clicks
Yua, or a break after focus). None are forced cutscenes. None are gated on light
interaction; focus is the only driver of story beats.

| Beat | Fires when | Notes |
| --- | --- | --- |
| Ep 0 intro | first launch AND NOT `intro_seen` | The matched-first-timer opening. Ends by setting `intro_seen` (and `player_nickname` if entered). |
| Ep 1 payoff | `completed_focus_count >= 1` AND `intro_seen` AND NOT `yua_opened_once` | Surfaces at the next natural break/click after the first completed focus. Sets `yua_opened_once`. This is the slice's payoff: "because you stayed, I moved." |
| Memory echo (时刻1) | a valid captured memory exists AND `completed_focus_count >= 1` AND it is a later session (`return_count >= 1`) AND echo cooldown clear | Surfaces on click/break, short, optional. **If no real memory exists, it never fires — never fabricate one.** |

`yua_openness` advances only on completed focus / accumulated focus time, never
on clicks or Type Mode. Exact tier thresholds: PROPOSED later; for the slice,
tier 0 → tier 1 on first completed focus is enough to allow the Ep 1 payoff.

## Node → flag map (for the JSON)

Narrative authors these in `scripted_nodes.json` using `set_flags` / `unlock` /
`tags` / `speaker` on the relevant nodes:

- Ep 0 final node: `set_flags: ["intro_seen"]`
- Ep 0 name node: writes `player_nickname` (value, via a dedicated action, not a flag)
- Ep 1 payoff node: `unlock: { completed_focus_min: 1, flag_not_set: "yua_opened_once" }`, `set_flags: ["yua_opened_once"]`

## Fail-safe rules (must hold)

- Memory echo fires ONLY with a real, game-validated memory. No memory → skip
  silently. A fabricated callback is worse than none.
- Every AI-flavored beat has an authored fallback line; AI failure must leave the
  beat playable (or cleanly skipped) with scripted text.
- AI never sets a flag, never advances `yua_openness`, never reveals the writing
  project. It only reads progression state as input.

## Known blocker (dependency, not a narrative bug)

`ScriptedDialogueManager._register_node` currently keeps only `id`, `line`, and
`choices`, discarding `unlock`, `set_flags`, `tags`, and `speaker`. Until the
Engine preserves those fields, the JSON metadata above is design-complete but
not runtime-live. This contract is what the Engine should gate against once that
fix lands.
