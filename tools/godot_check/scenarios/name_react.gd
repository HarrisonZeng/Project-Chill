const DESC := "Ep0 name reaction: typing a nickname shows a reaction (AI or scripted fallback) that classifies real-name / net-name / 整活名, then continues to ep00_named."

## The harness runs with AI disabled, so this exercises the scripted fallback
## path of _play_name_reaction_then and the node flow around it. The AI path is
## verified separately against the live model (scratchpad/probe_name_react.py:
## 10/10 names classified correctly on MiniMax-M3, 2026-08-20).

func _walk_to_name_node(g) -> void:
	g.wipe_save()
	await g.relaunch()
	await g.click_yua()
	var guard := 0
	while g.node_id() != "ep00_name" and guard < 20:
		await g.click_card()
		guard += 1
	g.check_node("Ep0 reaches the name prompt", "ep00_name")

func _react_for(g, nickname: String) -> String:
	await _walk_to_name_node(g)
	await g.type_reply(nickname)
	await g.settle()
	return g.game.dialogue_text.text

func run(g) -> void:
	# Full flow once (real-name bucket): prompt → typed name → reaction → 继续 → ep00_named
	var r1 := await _react_for(g, "小林")
	g.check("real name → name-react node shows", g.node_id() == "ep00_name_react", "node=%s" % g.node_id())
	g.check("real name → reaction mentions the name or 本名", r1.contains("小林") or r1.contains("本名"), r1)
	g.check("nickname stored", g.game.player_nickname == "小林", g.game.player_nickname)
	g.choose(0)
	await g.settle()
	g.check_node("继续 after reaction → ep00_named", "ep00_named")
	g.check("ep00_named substitutes {name}", g.game.dialogue_text.text.contains("小林"), g.game.dialogue_text.text)

	# Remaining buckets: exercise the classifier directly (same function the flow
	# uses when AI is off/unavailable). Re-walking Ep0 inside one scenario is not
	# supported by the harness session model.
	var r2: String = g.game._scripted_name_reaction("超级无敌暴龙")
	g.check("整活名 → 气势 reaction", r2.contains("气势"), r2)
	var r3: String = g.game._scripted_name_reaction("夜雨声烦2077")
	g.check("net name (digits) → 网名 reaction", r3.contains("网名"), r3)
	var r4: String = g.game._scripted_name_reaction("千早爱音酱")
	g.check("net name (long) → 网名 reaction", r4.contains("网名"), r4)
	var r5: String = g.game._scripted_name_reaction("Harrison")
	g.check("short latin name → real-name reaction", r5.contains("本名"), r5)
