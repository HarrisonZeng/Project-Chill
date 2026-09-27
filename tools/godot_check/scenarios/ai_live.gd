const DESC := "Opt-in (-Ai): the in-game AI path reaches the real provider — Ep5's typed answer and a free chat come back as model replies, in Chinese, in her voice."

## Costs API credit and needs network, so it runs only with -Ai. Without it,
## the scenario reports what it would have checked and passes vacuously.

func _english_prose(text: String) -> bool:
	var regex := RegEx.new()
	regex.compile("[A-Za-z']+(\\s+[A-Za-z']+){2,}")
	return regex.search(text) != null

# Beats are re-joined with blank lines; compare text without line breaks.
func _squash(text: String) -> String:
	return text.replace("
", "").replace(" ", "").strip_edges()

# Sleep ~50 ms of real time without spending the harness frame budget.
func _nap(g) -> void:
	await g.game.get_tree().create_timer(0.05).timeout

func run(g) -> void:
	if not g.game.is_ai_features_enabled():
		g.check("ai_live skipped (run with -Ai to exercise the live provider)", true)
		return
	var svc = g.game.ai_dialogue_service
	g.check("a provider is configured", svc != null and svc.is_available())
	g.check("provider is the direct MiniMax endpoint", svc.provider != null and str(svc.provider.endpoint_url).contains("minimaxi.com"),
		str(svc.provider.endpoint_url) if svc.provider != null else "none")

	# Ep0 name reaction, end to end (2026-09-25): the real questionnaire, wired
	# the way _setup_launch_flow wires it, asks the model at the nickname step;
	# Ep0 then says that line at «我看了一眼资料». Waits by the clock, not frames.
	var intake: Control = load("res://scenes/ui/intake.tscn").instantiate()
	g.game.add_child(intake)
	await g.frames(2)
	intake.nickname_entered.connect(g.game._prefetch_name_reaction)
	intake.finished.connect(g.game._on_intake_finished)
	var t0 := Time.get_ticks_msec()
	intake.call("start")
	intake.call("_on_continue")
	(intake.get_node("Center/Col/Input") as LineEdit).text = "夜雨声烦"
	intake.call("_on_continue")
	g.check("the nickname step asked the model", str(g.game._name_react_prefetch.get("name", "")) == "夜雨声烦")
	intake.call("_pick_role", "study")
	while not bool(g.game._name_react_prefetch.get("done", false)) and Time.get_ticks_msec() - t0 < 20000:
		await _nap(g)
	var took_s := (Time.get_ticks_msec() - t0) / 1000.0
	var name_route: Dictionary = g.game._name_react_prefetch.get("route", {})
	var name_line: String = g.game._name_reaction_from_route(name_route)
	g.check("name reaction came back from the model (%.1f s)" % took_s, not name_line.is_empty(), str(name_route))
	g.check("name reaction is Chinese, not English prose", not _english_prose(name_line), name_line)
	g.check("name reaction has no stage directions", not name_line.contains("（") and not name_line.contains("*"), name_line)
	print("    name reaction (%.1f s): %s" % [took_s, name_line.replace("\n", " / ")])
	while is_instance_valid(intake) and intake.call("current_step") != "":
		await _nap(g)  # matching → matched → finished
	g.check("questionnaire handed the name to the game", g.game.player_nickname == "夜雨声烦", g.game.player_nickname)

	# Walk Ep0 to the reaction beat: it must be the model's line, shown at once.
	await g.click_yua()
	var guard := 0
	while g.node_id() != "ep00_name_react" and guard < 20:
		await g.click_card()
		guard += 1
	g.check("Ep0 says the questionnaire-time model line", _squash(g.full_line()) == _squash(name_line), g.full_line())

	# Walk to Ep5 (the first AI-core episode) and type a real answer.
	await g.play_forward()
	for i in range(4):
		await g.complete_focus()
		await g.play_forward()
	await g.complete_focus()
	g.check_node("session 5 → Ep5", "ep05_01")
	await g.type_reply("在赶一篇论文，导师催得紧")
	# The typed route awaits the model; settle() cannot see the await, so poll —
	# by the clock, a little past the game's own 16 s give-up (a frame count
	# ran out first on slow replies and read her question back as the reply).
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 20000:
		await _nap(g)
		if g.node_id() != "ep05_01" or g.choices().size() > 0:
			break
	await g.settle()
	var reply: String = g.full_line()
	g.check("Ep5 typed answer got a model reply (not the scripted cover)", g.node_id() != "ep05_any", g.node_id())
	g.check("reply is not blank", not reply.strip_edges().is_empty())
	g.check("reply is Chinese, not English prose", not _english_prose(reply), reply)
	g.check("reply has no stage directions", not reply.contains("（") and not reply.contains("*"), reply)
	g.check("reply leaves a 继续 chip back into the script", g.choices().size() == 1, str(g.choices()))
	print("    Ep5 model reply: %s" % reply.replace("\n", " / "))
	await g.click_card()
	g.check_node("继续 → authored ending", "ep05_end")

	# Ep3 (sounds): the 自己写 answer goes to AI_MODE_SOUND, which knows the
	# question she asked (2026-09-26 — it used to be the generic break chat).
	g.game._show_node("ep03_01")
	await g.settle()
	await g.choose("我说说我的")
	await g.type_reply("我一般开着雨声的白噪音")
	var t3 := Time.get_ticks_msec()
	while g.game._is_awaiting_reply() and Time.get_ticks_msec() - t3 < 20000:
		await _nap(g)
	await g.settle()
	var sound: String = g.full_line()
	g.check("Ep3 answer got a model reply (not the scripted cover)", g.node_id() == "ep03_01" and g.choices() == ["继续"], "node=%s" % g.node_id())
	g.check("Ep3 reply is Chinese", not _english_prose(sound), sound)
	g.check("Ep3 reply doesn't pre-empt 你听", not sound.contains("你听"), sound)
	print("    Ep3 sound reply: %s" % sound.replace("\n", " / "))
	await g.click_card()
	g.check_node("继续 → 你听", "ep03_listen")

	# Free chat through ABORT_REST's 说会儿话 (AI_MODE_BREAK_CHAT).
	g.game._show_node("ABORT_REST")
	await g.settle()
	await g.choose("说会儿话")
	await g.type_reply("今天有点累，不太想动")
	var t2 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 30000:
		await _nap(g)
		if not g.full_line().contains("你说，我听着"):
			break
	await g.settle()
	var chat: String = g.full_line()
	g.check("free chat got a model reply", not chat.contains("你说，我听着") and not chat.contains("卡了一下"), chat)
	g.check("free chat is Chinese", not _english_prose(chat), chat)
	print("    free-chat model reply: %s" % chat.replace("\n", " / "))
