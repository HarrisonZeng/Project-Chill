const DESC := "Opt-in (-Ai): the in-game AI path reaches the real provider — Ep5's typed answer and a free chat come back as model replies, in Chinese, in her voice."

## Costs API credit and needs network, so it runs only with -Ai. Without it,
## the scenario reports what it would have checked and passes vacuously.

func _english_prose(text: String) -> bool:
	var regex := RegEx.new()
	regex.compile("[A-Za-z']+(\\s+[A-Za-z']+){2,}")
	return regex.search(text) != null

func run(g) -> void:
	if not g.game.is_ai_features_enabled():
		g.check("ai_live skipped (run with -Ai to exercise the live provider)", true)
		return
	var svc = g.game.ai_dialogue_service
	g.check("a provider is configured", svc != null and svc.is_available())
	g.check("provider is the direct MiniMax endpoint", svc.provider != null and str(svc.provider.endpoint_url).contains("minimaxi.com"),
		str(svc.provider.endpoint_url) if svc.provider != null else "none")

	# Walk to Ep5 (the first AI-core episode) and type a real answer.
	await g.click_yua()
	await g.play_forward()
	for i in range(4):
		await g.complete_focus()
		await g.play_forward()
	await g.complete_focus()
	g.check_node("session 5 → Ep5", "ep05_01")
	await g.type_reply("在赶一篇论文，导师催得紧")
	# The typed route awaits the model; settle() cannot see the await, so poll.
	for i in range(1100):
		await g.frames(1)
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

	# Free chat through ABORT_REST's 说会儿话 (AI_MODE_BREAK_CHAT).
	g.game._show_node("ABORT_REST")
	await g.settle()
	await g.choose("说会儿话")
	await g.type_reply("今天有点累，不太想动")
	for i in range(1100):
		await g.frames(1)
		if not g.full_line().contains("你说，我听着"):
			break
	await g.settle()
	var chat: String = g.full_line()
	g.check("free chat got a model reply", not chat.contains("你说，我听着") and not chat.contains("卡了一下"), chat)
	g.check("free chat is Chinese", not _english_prose(chat), chat)
	print("    free-chat model reply: %s" % chat.replace("\n", " / "))
