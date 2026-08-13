const DESC := "Ep1 then Ep2 across two focus sessions, and the flags survive a restart."

## Covers Progress.md "User Godot Checks Pending" #3 — the silent bug where
## episode flags were never persisted, so Ep1 replayed forever. The relaunch in
## the middle is the point: an in-memory-only pass would hide exactly that.

func run(g) -> void:
	await g.click_yua()
	await g.play_forward()

	await g.complete_focus()
	g.check_node("first session shows Ep1", "ep01_01")
	await g.play_forward()

	# Quit to desktop and come back — the failure mode was flags living only in
	# memory, which looks correct until the game restarts.
	await g.relaunch()
	g.check("session count survives a restart", g.sessions() == 1,
		"expected 1, got %d" % g.sessions())
	g.check("ep01_seen survives a restart", bool(g.flags().get("ep01_seen", false)),
		"story flags after restart: %s" % str(g.flags()))

	await g.click_yua()
	g.check("returning player does not replay the intro", g.node_id() != "ep00_01")
	await g.play_forward()

	await g.complete_focus()
	g.check("second session shows Ep2, not Ep1 again", g.node_id() == "ep02_01",
		"expected 'ep02_01', got '%s'" % g.node_id())
