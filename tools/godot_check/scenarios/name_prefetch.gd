const DESC := "Her reaction to the questionnaire nickname is fetched right away and used in Ep0: a ready line shows at once, a late one is waited for, the offline mock never stands in for it, AI off makes no call."

## Owner ask 2026-09-25: generate Yua's AI reaction to the 昵称 at the
## questionnaire and use it in the intro. The intake emits nickname_entered;
## main_scene fires AI_MODE_NAME_REACT into _name_react_prefetch; Ep0's
## ACTION_NAME_REACT reads it. No network here — routes are stubbed or mocked.

func _model_route(text: String) -> Dictionary:
	return {"mode": "ai", "success": true, "fallback_used": false, "provider": "minimax", "text": text}

# Jump to «我看了一眼资料» with the profile name set, then take its 继续.
func _react(g, nickname: String) -> void:
	g.game.player_nickname = nickname
	g.game._show_node("ep00_react")
	await g.settle()
	await g.click_card()

func run(g) -> void:
	# --- The questionnaire tells main_scene the moment a name is typed.
	var scene: PackedScene = load("res://scenes/ui/intake.tscn")
	var intake: Control = scene.instantiate()
	g.game.add_child(intake)
	await g.frames(2)
	var heard: Array = []
	intake.nickname_entered.connect(func(n): heard.append(n))
	intake.call("start")
	intake.call("_on_continue")  # welcome → nickname
	await g.frames(1)
	(intake.get_node("Center/Col/Input") as LineEdit).text = " 小林 "
	intake.call("_on_continue")
	await g.frames(1)
	g.check("nickname_entered fires on the nickname step", heard == ["小林"], str(heard))
	g.check("…before the questionnaire is over", intake.call("current_step") == "role", str(intake.call("current_step")))
	intake.queue_free()
	await g.frames(2)

	# --- AI off (the harness default): no request is made at all.
	g.game._prefetch_name_reaction("小林")
	g.check("AI off → no prefetch request", g.game._name_react_prefetch.is_empty(), str(g.game._name_react_prefetch))

	# --- Model line already waiting → Ep0 says it at once, no «小林……» wait beat.
	g.game._name_react_prefetch = {"name": "小林", "done": true, "route": _model_route("小林？……念起来挺利落的。"), "started_ms": Time.get_ticks_msec()}
	await _react(g, "小林")
	g.check_node("reaction beat shows", "ep00_name_react")
	g.check("the prefetched model line is used", g.full_line() == "小林？……念起来挺利落的。", g.full_line())
	g.check("then 继续", g.choices() == ["继续"], str(g.choices()))
	await g.click_card()
	g.check_node("继续 → ep00_named", "ep00_named")

	# --- Still on its way → she holds on «小林……», then says the model line.
	var box := {"name": "小林", "done": false, "route": {}, "started_ms": Time.get_ticks_msec()}
	g.game._name_react_prefetch = box
	await _react(g, "小林")
	g.check("waiting beat while the model answers", g.full_line().begins_with("小林……"), g.full_line())
	box["route"] = _model_route("小林……哦，是本名吧。那我就直接这么叫了。")
	box["done"] = true
	await g.frames(3)
	await g.settle()
	g.check("the late model line replaces the wait", g.full_line() == "小林……哦，是本名吧。那我就直接这么叫了。", g.full_line())

	# --- Still waiting and the player clicks on: the intro continues, and the
	# reply that lands afterwards must not overwrite where they are now.
	var slow := {"name": "小林", "done": false, "route": {}, "started_ms": Time.get_ticks_msec()}
	g.game._name_react_prefetch = slow
	await _react(g, "小林")
	g.check("a click is possible while she waits", g.choices() == ["继续"], str(g.choices()))
	await g.click_card()
	g.check_node("the click continues the intro", "ep00_named")
	slow["route"] = _model_route("迟到的一句。")
	slow["done"] = true
	await g.frames(3)
	await g.settle()
	g.check("a late reply does not overwrite the next scene", not g.full_line().contains("迟到"), g.full_line())
	g.check_node("still on ep00_named", "ep00_named")

	# --- Prefetch for a different name (edited profile) is ignored.
	g.game._name_react_prefetch = {"name": "别人", "done": true, "route": _model_route("不该出现的一句。"), "started_ms": Time.get_ticks_msec()}
	await _react(g, "小林")
	g.check("another name's line is never used", not g.full_line().contains("不该出现"), g.full_line())

	# --- The real plumbing, with the offline mock as the provider: the request
	# is made and completes, but the mock's catch-all is not a reaction to a
	# name, so the scripted classifier speaks instead.
	var svc = g.game.ai_dialogue_service
	var real_provider = svc.provider
	svc.use_mock_provider()
	g.game.set_ai_features_enabled(true)
	g.game._name_react_prefetch = {}
	g.game._prefetch_name_reaction("小林")
	for i in 60:
		await g.frames(1)
		if bool(g.game._name_react_prefetch.get("done", false)):
			break
	g.game.set_ai_features_enabled(false)
	svc.provider = real_provider
	g.check("AI on → the request goes out at the questionnaire", str(g.game._name_react_prefetch.get("name", "")) == "小林")
	g.check("…and completes", bool(g.game._name_react_prefetch.get("done", false)))
	await _react(g, "小林")
	g.check("mock reply is not used as her name reaction", g.full_line().contains("本名"), g.full_line())
