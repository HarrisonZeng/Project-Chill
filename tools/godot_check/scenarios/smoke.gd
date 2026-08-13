const DESC := "Boots the game, opens a conversation, runs one focus session."

func run(g) -> void:
	g.check("lands on idle at launch", g.node_id() == "idle",
		"expected 'idle', got '%s'" % g.node_id())
	g.check("idle line is not blank", not g.line().strip_edges().is_empty())

	await g.click_yua()
	g.check("clicking Yua opens a conversation", g.node_id() != "idle")
	g.check("opener has text", not g.line().strip_edges().is_empty())

	await g.play_forward()

	var before: int = g.sessions()
	await g.complete_focus()
	g.check("focus session completes", not g.focus_running())
	g.check("completed session is counted", g.sessions() == before + 1,
		"expected %d, got %d" % [before + 1, g.sessions()])
