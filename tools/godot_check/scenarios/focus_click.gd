const DESC := "During focus: first click answers, further clicks inside the cooldown give '……'."

## Covers Progress.md "User Godot Checks Pending" #2.

func run(g) -> void:
	await g.click_yua()
	await g.play_forward()

	await g.set_focus_minutes(1)
	await g.start_focus()
	g.check("focus is running", g.focus_running())

	await g.click_yua()
	var first: String = g.full_line()
	var pool: Array = []
	for entry in g.game._reactive_pool("focus_click"):
		pool.append(str(g.game._apply_text_tokens(str(entry))))
	g.check("first click during focus gets a real line", pool.has(first),
		"line was not from the focus_click pool: '%s'" % first)

	for i in 4:
		await g.click_yua()
		if not g.check("click %d inside cooldown is quiet" % (i + 2), g.full_line() == "……",
			"expected '……', got '%s'" % g.full_line()):
			return

	# Typed chat must never reach the AI while she is working — it falls back to
	# the same quiet reactive line.
	await g.type_reply("在忙吗")
	g.check("typing during focus stays on the reactive path", g.full_line() == "……",
		"expected '……', got '%s'" % g.full_line())
	g.check("typing during focus does not stop the timer", g.focus_running())
