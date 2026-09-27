const DESC := "The reply box opens wherever she asks for words (Ep0 随手来一句, Ep3 自己写, typed-answer beats, 说会儿话) and stays shut at plain choice beats and after a typed answer's one AI beat."

## Owner report 2026-09-25: «text box doesn't pop up when prompted like in ep0
## and the ep about sounds». The box rule only knew the Ep0 name ask and the
## task ask, so every 自己写 chip left her saying «你说，我听着» with nothing to
## type in. The harness never noticed because type_reply() used to send text
## without looking for the box; it now fails when the box is hidden.

func _at(g, node_id: String) -> void:
	g.game._show_node(node_id)
	await g.settle()

func run(g) -> void:
	# Plain choice beat: chips only (owner rule 2026-09-10).
	await _at(g, "ep01_01")
	g.check("plain choice beat: no box", not g.type_box_open(), "node=%s" % g.node_id())

	# Ep0 «你也随手来一句？不来也行» — box beside the two chips; a typed line is the task.
	await _at(g, "ep00_tools")
	g.check("Ep0 随手来一句: box open", g.type_box_open())
	await g.shot("ep00_tools-box")
	g.check("Ep0 随手来一句: both chips still there", g.choices().size() == 2, str(g.choices()))
	await g.type_reply("整理笔记")
	g.check_node("a line typed there becomes the task", "TASK_INPUT_002")
	g.check("the task is echoed back", g.full_line().contains("整理笔记"), g.full_line())

	# Ep3, the sounds one: the 自己写 chip must leave a box to answer in.
	await _at(g, "ep03_01")
	g.check("Ep3 question: box open beside the chips", g.type_box_open())
	await g.choose("我说说我的")
	g.check("Ep3 自己写: she asks", g.full_line().contains("你说"), g.full_line())
	g.check("Ep3 自己写: box open", g.type_box_open())
	g.check("Ep3 自己写: no chips", g.choices().is_empty(), str(g.choices()))
	await g.shot("ep03_ziji-box")
	await g.type_reply("要一点雨声")
	g.check_node("AI off → the authored 你听 beat", "ep03_listen")
	g.check("你听 beat: box shut again", not g.type_box_open())

	# Typed-answer beats whose only chip is a skip/继续 (Ep5, every 别的（自己写） node).
	for id in ["ep05_01", "ep06_other", "ep07_other", "ep10_other", "ep15_other"]:
		await _at(g, id)
		g.check("%s: box open" % id, g.type_box_open())

	# 说会儿话 after a stopped timer: box open, and it stays open to keep chatting.
	await _at(g, "ABORT_REST")
	await g.choose("说会儿话")
	g.check("说会儿话: box open", g.type_box_open())
	await g.type_reply("有点累")
	g.check("说会儿话: box still open after her reply", g.type_box_open())

	# A typed answer gets ONE AI beat, then only 继续 back into the script. The
	# offline mock stands in for the model so the AI path runs with no network.
	var svc = g.game.ai_dialogue_service
	var real_provider = svc.provider
	svc.use_mock_provider()
	g.game.set_ai_features_enabled(true)
	await _at(g, "ep05_01")
	await g.type_reply("在赶论文")
	for i in 120:
		await g.frames(1)
		if g.choices().size() > 0:
			break
	await g.settle()
	g.game.set_ai_features_enabled(false)
	svc.provider = real_provider
	g.check("AI beat stays on Ep5 (not the scripted cover)", g.node_id() == "ep05_01", g.node_id())
	g.check("after the AI beat: only 继续", g.choices() == ["继续"], str(g.choices()))
	g.check("after the AI beat: box shut", not g.type_box_open())
	await g.click_card()
	g.check_node("继续 → the authored next node", "ep05_end")
