const DESC := "Photograph the UI chrome in its open states: tasks panel, settings, type mode, focus running."

## The journal restyle (owner pick B, 2026-09-10) lives in the theme and a few
## node properties. A still of the idle frame shows the resting chrome; this
## walks the states a still cannot reach and photographs each, so a restyle can
## be judged whole instead of one panel at a time.
##
##   check.ps1 -Mode shot -Scenario chrome

func run(g) -> void:
	var game = g.game
	await g.settle()
	await g.shot("chrome-idle")

	# Tasks panel open (same width as the timer card is the owner's ask).
	var tasks = game.get("tasks_ui")
	if tasks != null and tasks.has_method("set_panel_visible"):
		tasks.set_panel_visible(true)
		if tasks.has_method("add_todo_item"):
			tasks.add_todo_item("把桌面收一下", false)
			tasks.add_todo_item("回一封邮件", true)
		if tasks.has_method("render_tasks"):
			tasks.render_tasks()
		if tasks.has_method("refresh_controls"):
			tasks.refresh_controls()
		await g.settle()
		await g.shot("chrome-tasks")
		var panel = game.get_node_or_null("OverlayLayer/Tools/TasksPanel")
		var timer = game.get_node_or_null("OverlayLayer/HUD/FocusCard")
		if panel != null and timer != null:
			g.check("tasks panel is as wide as the timer card",
				absf(panel.size.x - timer.size.x) < 2.0,
				"tasks %.0f vs timer %.0f" % [panel.size.x, timer.size.x])
		tasks.set_panel_visible(false)
		if tasks.has_method("refresh_controls"):
			tasks.refresh_controls()

	# Settings panel open.
	var settings = game.get_node_or_null("SettingsPanel")
	if settings != null:
		settings.visible = true
		await g.settle()
		await g.shot("chrome-settings")
		settings.visible = false

	# Type mode on: the type box should appear only now.
	var input_row = game.get_node_or_null("BottomPanel/DialoguePanel/InputRow")
	g.check("type box hidden while Type Mode is off", input_row != null and not input_row.visible)
	if game.has_method("_on_type_mode_toggled"):
		game._on_type_mode_toggled(true)
		await g.settle()
		g.check("type box shown once Type Mode is on", input_row != null and input_row.visible)
		await g.shot("chrome-typemode")
		game._on_type_mode_toggled(false)
		await g.settle()
