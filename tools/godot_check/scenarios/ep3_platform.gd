const DESC := "Ep3 (脑子飞了): real 3-session unlock, confession → platform question; chips, typed keywords, AI-off cover, remembered answer, P.S. ending."

## Ep3 canon (2026-09-06). The platform question is the first node that routes a
## TYPED answer through authored keywords (node "typed_routes"); an unknown
## answer takes one bounded AI beat, or a scripted cover when AI is off — which
## is what the harness runs with, so the cover path is what gets exercised here.
##
## Order matters: the progression walk runs first on the fresh save, because
## jumping straight to ep03_01 sets ep03_seen, and relaunch() saves before it
## wipes — so a direct jump would make the episode look already-seen.

func _open_ask(g) -> void:
	g.game._show_node("ep03_ask")
	await g.settle()

func _remembered(g) -> String:
	return str(g.game._remembered_player_value("player_platform"))

func run(g) -> void:
	# Progression: the third completed focus opens Ep3 for real, and it plays out.
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	g.check_node("first session → Ep1", "ep01_01")
	await g.play_forward()
	await g.complete_focus()
	g.check_node("second session → Ep2", "ep02_01")
	await g.play_forward()
	await g.complete_focus()
	g.check_node("third session → Ep3", "ep03_01")
	g.check("Ep3 opens with the 战力 confession", g.full_line().contains("霸王龙和剑齿象"), g.full_line())
	g.check("ep03_seen is set when Ep3 opens", bool(g.flags().get("ep03_seen", false)), str(g.flags()))
	await g.click_card()
	g.check_node("继续 → the platform question", "ep03_ask")
	g.check("four answer chips", g.choices().size() == 4, str(g.choices()))

	# Chip path: reply, remembered value, P.S. ending.
	var picked: bool = await g.choose("B 站")
	g.check("B 站 chip can be taken", picked)
	g.check_node("B 站 → ep03_bili", "ep03_bili")
	g.check("B 站 reply calls back the 战力 video", g.full_line().contains("弹幕"), g.full_line())
	g.check("platform remembered from the chip", _remembered(g) == "bilibili", _remembered(g))
	await g.click_card()
	g.check_node("继续 → ending", "ep03_end")
	g.check("ending drops the answer", g.full_line().contains("答案是不能"), g.full_line())
	g.check("ending is terminal", g.choices().is_empty(), str(g.choices()))

	# Typed keyword path.
	await _open_ask(g)
	await g.type_reply("我一般刷油管")
	g.check_node("typed 油管 → ep03_yt", "ep03_yt")
	g.check("typed platform remembered", _remembered(g) == "youtube", _remembered(g))
	await g.click_card()
	g.check_node("油管 → 继续 → ending", "ep03_end")

	await _open_ask(g)
	await g.type_reply("不刷，我不怎么看这些")
	g.check_node("typed 不刷 → ep03_none", "ep03_none")

	await _open_ask(g)
	await g.type_reply("Bilibili 和小红书都刷")
	g.check_node("first matching rule wins (B 站 before 小红书)", "ep03_bili")

	await _open_ask(g)
	await g.type_reply("主要打游戏")
	g.check_node("typed 游戏 → ep03_game", "ep03_game")

	# 别的 chip → unknown answer; AI is off in the harness → scripted cover.
	await _open_ask(g)
	picked = await g.choose("别的")
	g.check("别的 chip can be taken", picked)
	g.check_node("别的 → ep03_other", "ep03_other")
	g.check("ep03_other keeps a click-through (no dead end)", g.choices().size() == 1, str(g.choices()))
	await g.type_reply("Reddit")
	g.check_node("unknown platform with AI off → scripted cover", "ep03_any")
	g.check("unknown answer remembered verbatim", _remembered(g) == "Reddit", _remembered(g))
	await g.click_card()
	g.check_node("cover → 继续 → ending", "ep03_end")

	# The remembered answer and the episode flag survive a restart.
	await g.relaunch()
	g.check("player_platform survives a restart", _remembered(g) == "Reddit", _remembered(g))
	g.check("ep03_seen survives a restart", bool(g.flags().get("ep03_seen", false)), str(g.flags()))
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	g.check("Ep3 does not replay on the fourth session", g.node_id() != "ep03_01", g.node_id())
