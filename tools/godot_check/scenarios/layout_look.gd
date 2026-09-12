const DESC := "Photograph the 2026-09-13 layout: settings under the pill, chat card aligned with the music card, tasks notebook: -Mode shot -Scenario layout_look"

func run(g) -> void:
	var game = g.game
	await g.settle()
	await g.shot("layout-idle")

	# Settings open, under the status pill.
	game._on_settings_button_pressed()
	await g.frames(3)
	await g.shot("layout-settings")
	game._on_settings_button_pressed()
	await g.frames(2)

	# Type mode inside the chat card (debug toggle path).
	game._on_type_mode_toggled(true)
	await g.frames(3)
	await g.shot("layout-typemode")
	game._on_type_mode_toggled(false)
	await g.frames(2)

	# Tasks notebook with a few lines, one done.
	var tasks = game.get("tasks_ui")
	g.check("tasks ui present", tasks != null)
	if tasks != null:
		tasks.add_todo_item("看完第三章", false)
		tasks.add_todo_item("回一封邮件", true)
		tasks.add_todo_item("整理桌面", false)
		tasks.set_panel_visible(true)
		tasks.refresh_controls()
		await g.frames(3)
		await g.shot("layout-tasks")
		var rows = game.get_node_or_null("OverlayLayer/Tools/TasksPanel/Col/Scroll/Rows")
		g.check("three task rows", rows != null and rows.get_child_count() == 3)
		if rows != null and rows.get_child_count() == 3:
			var row = rows.get_child(0)
			g.check("row = number, text, pencil, check", row.get_child_count() == 4)
			var field: LineEdit = row.get_child(1)
			g.check("text locked until pencil", not field.editable)
			var pencil: Button = row.get_child(2)
			pencil.pressed.emit()
			await g.frames(1)
			g.check("pencil unlocks the line", field.editable)
			field.text = ""
			field.text_submitted.emit("")
			await g.frames(2)
			g.check("empty line + Enter deletes the task", rows.get_child_count() == 2)
		tasks.set_panel_visible(false)
		tasks.refresh_controls()

	# Card geometry: chat card bottom-aligned with the music card.
	var chat = game.get_node_or_null("BottomPanel/DialoguePanel/DialogueCard")
	var music = game.get_node_or_null("BottomLeftMusicBar")
	if chat != null and music != null:
		var cb: float = chat.get_global_rect().end.y
		var mb: float = music.get_global_rect().end.y
		g.check("chat card bottom == music card bottom (%d vs %d)" % [int(cb), int(mb)], absf(cb - mb) < 1.5)
