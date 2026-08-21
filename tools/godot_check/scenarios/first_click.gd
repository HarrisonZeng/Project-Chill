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

	# Script v10 canon: the intro ENDS by picking a duration that starts focus
	# immediately («选完就得开始了»). play_forward() takes the last choice (60 min),
	# so we land inside a running session. Stop it — the idle-click regression is
	# about the settled, non-focus state.
	if g.game.focus_running:
		g.game._on_stop_focus_pressed()
		await g.settle()
		g.check("intro's duration pick started a focus session (v10 canon)", true)
		# Stopping opens the guilt-free ABORT_001 dialogue; play it out (it ends
		# on a terminal / rest node) so we test clicks against a settled state.
		await g.play_forward()
		await g.settle()

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
