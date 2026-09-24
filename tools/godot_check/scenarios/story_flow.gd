const DESC := "Ep1–Ep15 play through in order with AI off: every episode opens on its session, chips and typed answers land on the right node, remembered values pay off, no dead ends."

## The v12 script (docs/Story_Beat_Sheet_v3.md, chapter 1 + the start of
## chapter 2). AI is off in the harness, so every typed answer here exercises
## the scripted cover of a typed_routes node — the path a player without a key
## (or without network) gets.

func _rem(g, key: String) -> String:
	return str(g.game._remembered_player_value(key))

func run(g) -> void:
	await g.click_yua()
	await g.play_forward()
	g.check("Ep0 finished (intro_seen)", bool(g.flags().get("intro_seen", false)))

	# Ep1
	await g.complete_focus()
	g.check_node("session 1 → Ep1", "ep01_01")
	await g.play_forward()

	# Ep2 — direct reveal, writing_disclosed flips here now.
	await g.complete_focus()
	g.check_node("session 2 → Ep2 我在写小说", "ep02_01")
	g.check("Ep2 says it out loud", g.full_line().contains("我在写小说"), g.full_line())
	g.check("writing_disclosed set at Ep2", bool(g.flags().get("writing_disclosed", false)), str(g.flags()))
	await g.choose("本子上那行")
	g.check("Ep2 notebook line becomes 写一章", g.full_line().contains("写一章"), g.full_line())
	await g.play_forward()

	# Ep3 你听 (was Ep2)
	await g.complete_focus()
	g.check_node("session 3 → Ep3 你听", "ep03_01")
	await g.choose("要有点声音")
	await g.click_card()
	g.check_node("你听 名场面 still reachable", "ep03_listen")
	await g.play_forward()

	# Ep4 第一句
	await g.complete_focus()
	g.check_node("session 4 → Ep4 第一句", "ep04_01")
	g.check("first line is read out", g.full_line().contains("汽笛响第四次"), g.full_line())
	await g.choose("有点文艺")
	g.check("first-line reaction remembered", _rem(g, "first_line_reaction") == "literary", _rem(g, "first_line_reaction"))
	await g.play_forward()

	# Ep5 你最近在忙什么 — first AI-core episode; AI off → scripted cover.
	await g.complete_focus()
	g.check_node("session 5 → Ep5", "ep05_01")
	await g.type_reply("在赶一篇论文")
	g.check_node("typed answer with AI off → scripted cover", "ep05_any")
	g.check("player_project remembered", _rem(g, "player_project") == "在赶一篇论文", _rem(g, "player_project"))
	var said: Array = g.game.memory_manager.get_value("player_said", [])
	g.check("typed answer stored for 「上次你说」", said.size() == 1 and str(said[0].get("text", "")) == "在赶一篇论文", str(said))
	await g.play_forward()

	# Ep6 脑子飞了 (was Ep3)
	await g.complete_focus()
	g.check_node("session 6 → Ep6 脑子飞了", "ep06_01")
	await g.click_card()
	await g.choose("小红书")
	g.check("platform remembered", _rem(g, "player_platform") == "xiaohongshu", _rem(g, "player_platform"))
	await g.play_forward()

	# Ep7 自动门 — typed idea, AI off → scripted cover.
	await g.complete_focus()
	g.check_node("session 7 → Ep7 自动门", "ep07_01")
	await g.choose("别的")
	g.check_node("别的 → ep07_other", "ep07_other")
	await g.type_reply("倒着走进去")
	g.check_node("typed idea with AI off → scripted cover", "ep07_idea")
	g.check("door idea remembered", _rem(g, "door_idea") == "倒着走进去", _rem(g, "door_idea"))
	await g.play_forward()

	# Ep8, Ep9
	await g.complete_focus()
	g.check_node("session 8 → Ep8 主角的毛病", "ep08_01")
	await g.play_forward()
	await g.complete_focus()
	g.check_node("session 9 → Ep9 店长", "ep09_01")
	g.check("Ep9 sets up the shift cut", g.full_line().contains("减一半"), g.full_line())
	await g.play_forward()

	# Ep10 写不动 — keyword route, then the genre chips.
	await g.complete_focus()
	g.check_node("session 10 → Ep10 写不动", "ep10_01")
	await g.type_reply("我一般先睡一觉")
	g.check_node("typed 睡 → keyword route", "ep10_sleep")
	g.check("stuck_method remembered from the keyword", _rem(g, "stuck_method") == "先睡", _rem(g, "stuck_method"))
	await g.click_card()
	g.check_node("then the genre question", "ep10_type")
	await g.choose("推理")
	g.check("novel_genre remembered", _rem(g, "novel_genre") == "推理", _rem(g, "novel_genre"))
	await g.play_forward()

	# Ep11 四张桌子 — branch by remembered platform (小红书 from Ep6).
	await g.complete_focus()
	g.check_node("session 11 → Ep11 四张桌子", "ep11_01")
	await g.choose("那我会被安排在哪桌")
	g.check_node("小红书 → 失恋角 branch", "ep11_xhs")
	await g.play_forward()

	# Ep12 第一章 — gated on 1.5 h of real focus.
	await g.complete_focus()
	g.check("Ep12 is held back without 1.5h of focus", g.node_id() != "ep12_01", g.node_id())
	await g.play_forward()
	# Holistic review 2026-09-24: a locked Ep12 must not be stepped over — short
	# sessions used to reach Ep13 (aquarium) before the first-chapter payoff.
	await g.complete_focus()
	g.check("Ep13 does not jump the locked Ep12", g.node_id() != "ep13_01", g.node_id())
	await g.play_forward()
	g.game.total_focus_seconds = 6000
	await g.complete_focus()
	g.check_node("with the focus time, session 14 → Ep12 第一章", "ep12_01")
	await g.choose("看")
	g.check("chapter one is readable", g.full_line().contains("阿岚"), g.full_line())
	await g.click_card()
	await g.choose("排队的兽")
	g.check("chapter-one reaction remembered", _rem(g, "ch1_reaction") == "兽是企鹅", _rem(g, "ch1_reaction"))
	await g.play_forward()

	# Ep13 水族馆 (chapter 2), Ep14, Ep15
	await g.complete_focus()
	g.check_node("session 15 → Ep13 上岗第一天", "ep13_01")
	g.check("chapter_aquarium flag set", bool(g.flags().get("chapter_aquarium", false)))
	await g.play_forward()
	await g.complete_focus()
	g.check_node("session 16 → Ep14 便利店", "ep14_01")
	await g.choose("黑咖啡")
	g.check("drink pick remembered", _rem(g, "drink_pick") == "黑咖啡蛋白", _rem(g, "drink_pick"))
	await g.play_forward()
	await g.complete_focus()
	g.check_node("session 17 → Ep15 主角没有名字", "ep15_01")
	await g.choose("别的")
	await g.type_reply("阿汽")
	g.check_node("typed name with AI off → scripted cover", "ep15_typed")
	g.check("hero_name remembered", _rem(g, "hero_name") == "阿汽", _rem(g, "hero_name"))
	var stopped: String = await g.play_forward()
	g.check("Ep15 ends cleanly", stopped == "ep15_end", stopped)

	# After the last authored episode, a session ends on the repeat pool.
	await g.complete_focus()
	g.check("after Ep15 a session ends on the FOCUS_DONE pool", g.node_id().begins_with("FOCUS_DONE"), g.node_id())

	# Everything survives a relaunch.
	await g.relaunch()
	g.check("15 episode flags survive a relaunch", bool(g.flags().get("ep15_seen", false)) and bool(g.flags().get("ep02_seen", false)), str(g.flags()))
	g.check("remembered values survive a relaunch", _rem(g, "hero_name") == "阿汽" and _rem(g, "player_project") == "在赶一篇论文")
