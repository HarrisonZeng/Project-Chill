extends RefCounted

# NOTE: intentionally no `class_name`. main_scene reaches this via
#   const ProgressionGate = preload("res://scripts/core/progression_gate.gd")
# so the static calls resolve regardless of global-class registration order
# (see the class_name timing caveat in docs/Architecture_Overview.md).

## Deterministic "focus drives story" gate.
##
## This is a PURE selector: every function takes an explicit state Dictionary and
## returns a decision. It reads progression state and writes nothing — the
## coordinator (main_scene) owns persistence and applies whatever this returns.
## Keeping it pure makes the gate trivially testable and keeps the rules in one
## place.
##
## Direction (from AGENTS.md + docs/Milestone_Contract_VS01.md):
##  - Story / relationship milestones advance ONLY from completed focus sessions
##    and accumulated focus time. Focus is the required driver.
##  - Light interactions (clicking Yua, Type Mode, returns) are remembered and may
##    add ambient warmth elsewhere, but they are NOT inputs to beat selection here
##    and never advance yua_openness.
##  - Pure AFK idling advances nothing — there is no idle/time input below.
##  - "Gate" means deterministic eligibility, NOT a player-facing lock or chore
##    checklist. Yua never demands or nags; the coordinator surfaces beats at
##    natural moments (focus completion, a click, a break).
##
## Expected `state` keys (all optional, safe defaults applied):
##   completed_focus_count : int
##   total_focus_seconds   : int
##   return_count          : int
##   intro_seen            : bool
##   story_flags           : Dictionary (string -> value)
##   has_valid_memory      : bool
##   memory_echo_cooldown_active : bool

# Beat identifiers returned by the selectors.
const BEAT_NONE := ""
const BEAT_EP1_PAYOFF := "ep1_payoff"
const BEAT_FOCUS_REPEAT := "focus_repeat"
const BEAT_MEMORY_ECHO := "memory_echo"

# --- PROPOSED thresholds — confirm with owner -------------------------------
# Slice contract: tier 0 -> tier 1 on the first completed focus is enough to
# allow the Ep 1 payoff. Later tiers are placeholders for future episodes.
const EP1_COMPLETED_FOCUS_MIN := 1            # PROPOSED — confirm with owner
const MEMORY_ECHO_RETURN_MIN := 1             # PROPOSED — confirm with owner
const OPENNESS_TIER_SESSIONS := [0, 1, 3, 6]  # PROPOSED — confirm with owner
# ----------------------------------------------------------------------------

# Picks the authored node to show when a focus session completes, or "" when
# there is no special beat (caller should fall back to the generic repeat node).
#
# `episodes` is the metadata array from scripted_nodes.json: each entry is a
# Dictionary with at least { start_node, session_gate }, and MAY add a
# "seen_flag" and/or "unlock" block. Two selection modes, chosen per-episode:
#  - Flag-guarded (episode has "seen_flag" or "unlock"): show whenever the player
#    has reached the gate and the guard says it has not been shown yet. This is
#    the contract-faithful mode (Ep 1 shows while completed>=1 and NOT
#    yua_opened_once).
#  - Legacy index (no metadata): show exactly at the completion that reaches the
#    gate. Preserves the original behavior for episodes without metadata.
static func select_focus_complete_node(state: Dictionary, episodes: Array) -> String:
	var completed := int(state.get("completed_focus_count", 0))
	var intro_seen := bool(state.get("intro_seen", false))
	var flags: Dictionary = state.get("story_flags", {})

	var sorted_eps := _episodes_sorted_by_gate(episodes)
	for ep in sorted_eps:
		var gate := int(ep.get("session_gate", 0))
		var node_id := str(ep.get("start_node", ""))
		if node_id.is_empty():
			continue
		# Story beats require the intro to have played first.
		if not intro_seen:
			continue
		var unlock: Dictionary = ep.get("unlock", {})
		var seen_flag := str(ep.get("seen_flag", ""))
		var flag_guarded := not unlock.is_empty() or not seen_flag.is_empty()
		if flag_guarded:
			if completed < gate:
				continue
			if not seen_flag.is_empty() and bool(flags.get(seen_flag, false)):
				continue
			if not is_unlocked(unlock, state):
				continue
			return node_id  # lowest-gate eligible beat
		else:
			# Legacy: fire only on the completion that exactly reaches this gate.
			if completed == gate:
				return node_id
	return BEAT_NONE

# Convenience wrapper that names the post-focus decision in contract terms.
# Returns one of BEAT_EP1_PAYOFF / BEAT_FOCUS_REPEAT (mapped from the node pick).
static func classify_focus_complete(state: Dictionary, episodes: Array) -> Dictionary:
	var node_id := select_focus_complete_node(state, episodes)
	if node_id.is_empty():
		return {"beat": BEAT_FOCUS_REPEAT, "node": "", "reason": "no_authored_beat_for_state"}
	return {"beat": BEAT_EP1_PAYOFF, "node": node_id, "reason": "focus_reached_authored_beat"}

# Generic evaluator for a JSON `unlock` block (preserved by
# ScriptedDialogueManager). Accepts both the contract spelling and the
# AI_Dialogue_Infrastructure spelling so narrative can use either.
static func is_unlocked(unlock: Dictionary, state: Dictionary) -> bool:
	if unlock == null or unlock.is_empty():
		return true
	var completed := int(state.get("completed_focus_count", 0))
	var total_focus := int(state.get("total_focus_seconds", 0))
	var flags: Dictionary = state.get("story_flags", {})

	if unlock.has("completed_focus_min") and completed < int(unlock["completed_focus_min"]):
		return false
	if unlock.has("completed_sessions_min") and completed < int(unlock["completed_sessions_min"]):
		return false
	if unlock.has("total_focus_seconds_min") and total_focus < int(unlock["total_focus_seconds_min"]):
		return false
	if unlock.has("requires_intro_seen") and bool(unlock["requires_intro_seen"]) and not bool(state.get("intro_seen", false)):
		return false
	if unlock.has("flag_set"):
		if not bool(flags.get(str(unlock["flag_set"]), false)):
			return false
	if unlock.has("flag_not_set"):
		if bool(flags.get(str(unlock["flag_not_set"]), false)):
			return false
	return true

# Memory echo (时刻1) eligibility. SURFACES on a click/break, never forced.
# Fires ONLY when a real, game-validated memory exists — never fabricate one.
static func should_surface_memory_echo(state: Dictionary) -> bool:
	if not bool(state.get("has_valid_memory", false)):
		return false  # no real memory -> stay silent
	if int(state.get("completed_focus_count", 0)) < EP1_COMPLETED_FOCUS_MIN:
		return false  # focus is the driver
	if int(state.get("return_count", 0)) < MEMORY_ECHO_RETURN_MIN:
		return false  # only on a later session
	if bool(state.get("memory_echo_cooldown_active", false)):
		return false
	return true

# Relationship tier derived from focus only (completed sessions). Monotonic;
# the coordinator passes the result to memory_manager.set_yua_openness, which
# refuses to regress. PROPOSED tiers — confirm with owner.
static func openness_tier_for(completed_focus_count: int, _total_focus_seconds: int) -> int:
	var tier := 0
	for i in range(OPENNESS_TIER_SESSIONS.size()):
		if completed_focus_count >= int(OPENNESS_TIER_SESSIONS[i]):
			tier = i
	return tier

# A human-readable milestone label for current_story_milestone. Derived purely
# from deterministic state, so it is always consistent with the save.
static func current_milestone_label(state: Dictionary) -> String:
	var flags: Dictionary = state.get("story_flags", {})
	if bool(flags.get("yua_opened_once", false)):
		return "ep1_payoff_seen"
	if bool(state.get("intro_seen", false)):
		return "intro_seen"
	return "new_player"

static func _episodes_sorted_by_gate(episodes: Array) -> Array:
	var sortable: Array = []
	for entry in episodes:
		if typeof(entry) == TYPE_DICTIONARY:
			sortable.append(entry)
	sortable.sort_custom(func(a, b): return int(a.get("session_gate", 0)) < int(b.get("session_gate", 0)))
	return sortable
