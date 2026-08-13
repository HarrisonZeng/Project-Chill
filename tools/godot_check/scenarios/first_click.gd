const DESC := "Ep0 plays once; later clicks give presence lines, never a restart or re-greet."

## Covers the two regressions in Progress.md "User Godot Checks Pending" #1:
## EP0 must not restart on repeated clicks, and there must be no greeting spam.

func run(g) -> void:
	await g.click_yua()
	g.check("fresh save opens the intro", g.node_id() == "ep00_01",
		"expected 'ep00_01', got '%s'" % g.node_id())

	var landing: String = await g.play_forward()
	g.check("intro plays through to a terminal node", landing != "ep00_01",
		"intro never advanced past its first node")

	# The regression: clicking her after the intro settles used to replay Ep0 or
	# re-greet. Expected behaviour is a short presence line and nothing else.
	var lines: Array = []
	for i in 5:
		await g.click_yua()
		lines.append(g.full_line())
		if not g.check("click %d does not restart Ep0" % (i + 1), g.node_id() != "ep00_01"):
			return

	# Compare against tokenised pool text — what reaches the screen has {name} and
	# {focus_minutes} already substituted.
	var idle_pool: Array = []
	for pool_name in ["idle_click_prefocus", "idle_click"]:
		for entry in g.game._reactive_pool(pool_name):
			idle_pool.append(str(g.game._apply_text_tokens(str(entry))))

	var from_pool := 0
	for spoken in lines:
		if idle_pool.has(str(spoken)):
			from_pool += 1
	g.check("repeat clicks give presence lines", from_pool == lines.size(),
		"%d of %d clicks returned a line outside the idle_click pools" % [lines.size() - from_pool, lines.size()])
