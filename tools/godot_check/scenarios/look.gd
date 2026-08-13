const DESC := "Screenshot any moment on demand: -Mode shot -Node ep03_01 [-Sessions 3]"

## For looking at the game rather than testing it. Jumps straight to a node and
## captures it, so any authored beat can be seen without playing there by hand:
##
##   check.ps1 -Mode shot -Node ep03_01
##   check.ps1 -Mode shot -Node FOCUS_START_001 -Sessions 5
##
## With no -Node it captures the opening: idle, then the first click.

func run(g) -> void:
	var node_id: String = g.opt("node")
	var sessions: int = int(g.opt("sessions", "0"))

	if node_id.is_empty():
		await g.shot("idle")
		await g.click_yua()
		await g.shot("first-click")
		return

	if not g.has_node_id(node_id):
		g.check("node '%s' exists" % node_id, false, "not found in scripted_nodes.json")
		return

	# The debug jumper sets the session count and intro flag together, which is
	# what makes a mid-story node render with the right surrounding state.
	g.game._debug_timeline_jump(node_id, sessions)
	await g.settle()

	g.check_node("jumped to %s" % node_id, node_id)
	await g.shot(node_id)

	# Capture the choices too — the second beat is usually where the layout gets
	# tight, and that is exactly what needs eyes on it.
	if g.choices().size() > 1:
		await g.choose(0)
		await g.shot(node_id + "-reply")
