const DESC := "No English/system/developer text ever reaches the dialogue box as Yua's voice."

## The game is Mandarin-first and the dialogue box is Yua speaking. Status strings,
## provider errors, developer errors and mock replies must never land there.
##
## Every check here failed before 2026-08-19; see docs/Dialogue_Flow_Map.md.

# A run of 3+ ASCII words is prose, not a token like "Ep0" or "15:00".
func _english_prose(text: String) -> String:
	var regex := RegEx.new()
	if regex.compile("[A-Za-z']+(\\s+[A-Za-z']+){2,}") != OK:
		return ""
	var found := regex.search(text)
	if found == null:
		return ""
	return found.get_string()

func run(g) -> void:
	# --- 1. A failed provider call must speak Yua's line, not the service's error.
	# dialogue_router compared the reply against a string that exists nowhere in
	# the codebase, so ai_dialogue_service.FALLBACK_REPLY (English) passed through.
	var router := preload("res://scripts/core/dialogue_router.gd").new()
	var stub := FailingService.new()
	router.set_ai_service(stub)
	router.set_ai_allowed(true)
	g.game.add_child(router)
	g.game.add_child(stub)

	var route: Dictionary = await router.route_player_text_async(
		"在吗", true, "persona", "context", "rules", "AI_MODE_BREAK_CHAT")
	var routed_text := str(route.get("text", ""))
	g.check("a failed provider call does not speak English",
		_english_prose(routed_text).is_empty(),
		"router returned: %s" % routed_text)
	g.check("a failed provider call is marked as a fallback",
		bool(route.get("fallback_used", false)),
		"route was: %s" % str(route))

	# A provider that reports success but returns nothing must still be covered
	# in-voice rather than typing out a blank line.
	stub.mode = "empty_success"
	var route2: Dictionary = await router.route_player_text_async(
		"在吗", true, "persona", "context", "rules", "AI_MODE_BREAK_CHAT")
	g.check("an empty reply does not speak English",
		_english_prose(str(route2.get("text", ""))).is_empty(),
		"router returned: %s" % str(route2.get("text", "")))

	router.queue_free()
	stub.queue_free()

	# --- 2. Setting a timer must not wipe her line and speak English.
	g.game._show_node("idle")
	await g.settle()
	g.game._set_focus_duration_minutes(15)
	await g.settle()
	var after_timer: String = g.full_line()
	g.check("setting a timer leaves no English in the dialogue box",
		_english_prose(after_timer).is_empty(),
		"dialogue box showed: %s" % after_timer)

	# --- 3. A missing node must not print a developer error in her voice.
	g.game._show_node("this_node_does_not_exist")
	await g.settle()
	var missing: String = g.full_line()
	g.check("a missing node does not print a developer error as Yua",
		_english_prose(missing).is_empty(),
		"dialogue box showed: %s" % missing)

	# --- 4. Memory follow-ups are authored lines, not hard-coded English.
	var mm = g.game.memory_manager
	if mm != null and mm.has_method("_follow_up_line_for_tag"):
		for tag in ["ask_about_school", "ask_about_exam", "ask_about_sleep", "ask_about_work"]:
			var follow_up := str(mm._follow_up_line_for_tag(tag))
			g.check("follow-up '%s' is in Yua's voice, not English" % tag,
				_english_prose(follow_up).is_empty(),
				"line was: %s" % follow_up)

	# --- 5. The mock provider (the default with no API key) must answer in Mandarin.
	var service := preload("res://scripts/dialogue/ai_dialogue_service.gd").new()
	g.game.add_child(service)
	service.use_mock_provider()
	var mock_reply: Dictionary = await service.generate_reply_async({
		"user_text": "今天有点累",
		"tone": "warm",
		"persona": "", "context_packet": "", "runtime_rules": "",
		"mode_id": "AI_MODE_BREAK_CHAT"
	})
	g.check("the mock provider replies in Yua's voice, not English",
		_english_prose(str(mock_reply.get("text", ""))).is_empty(),
		"mock replied: %s" % str(mock_reply.get("text", "")))

	# --- 6. Reasoning must be stripped even when the opening tag is missing.
	# MiniMax M-series often send the opening tag as part of the chat template,
	# so only "</think>" comes back and the whole chain-of-thought used to be
	# typed out as Yua's line.
	var strip_cases := [
		["<think>The user greets me. I should reply warmly.</think>嗯，我在。", "嗯，我在。"],
		["The user greets me. I should reply warmly.</think>嗯，我在。", "嗯，我在。"],
		["<THINK>reasoning here</THINK>嗯，我在。", "嗯，我在。"]
	]
	for pair in strip_cases:
		var raw: String = str(pair[0])
		var want: String = str(pair[1])
		var got: String = str(service._strip_reasoning(raw))
		g.check("reasoning stripped from %s" % raw.substr(0, 24), got == want,
			"got '%s', wanted '%s'" % [got, want])

	service.queue_free()


# A provider stand-in that fails the way the real one does.
class FailingService extends Node:
	var mode: String = "fail"

	func is_available() -> bool:
		return true

	func generate_reply_async(_payload: Dictionary) -> Dictionary:
		# Mirrors ai_dialogue_service.FALLBACK_REPLY on the failure paths.
		var fallback := "Mm. I can't reach the AI right now, so let's keep to the scripted choices for now."
		if mode == "empty_success":
			# ai_dialogue_service now reports failure when the reply is empty
			# after stripping reasoning tags; this covers a provider that claims
			# success and still hands back nothing.
			return {"text": "   ", "success": true, "fallback_used": false, "provider": "stub"}
		return {"text": fallback, "success": false, "fallback_used": true, "provider": "stub", "error": "request_failed"}
