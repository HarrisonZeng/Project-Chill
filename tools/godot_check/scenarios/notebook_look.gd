const DESC := "Photograph the tasks panel with her notebook section: -Mode shot -Scenario notebook_look"

func run(g) -> void:
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	await g.play_forward()
	await g.complete_focus()  # Ep2 → top line 写一章
	await g.play_forward()
	# Make her side look lived-in: a crossed-out chore, a stalled one, and a
	# long goal with progress.
	var nb = g.game.notebook_manager
	g.game.memory_manager.set_story_flag("ep05_seen", true)
	g.game.memory_manager.set_story_flag("ep20_seen", true)
	nb.rng_queue = [0.1, 0.5, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9]
	nb.roll_for_today(1, g.flags(), "小林", "2099-02-02")
	nb.rng_queue = [0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9]
	nb.roll_for_today(1, g.flags(), "小林", "2099-02-03")
	g.game._refresh_yua_notebook()
	g.game.tasks_ui.add_todo_item("看完第三章")
	g.game.tasks_ui.add_todo_item("回邮件", true)
	g.game.tasks_ui.set_panel_visible(true)
	g.game.tasks_ui.refresh_controls()
	await g.frames(4)
	await g.shot("notebook-panel")
	g.check("her section rendered", g.game.tasks_ui.yua_items.size() >= 4, str(g.game.tasks_ui.yua_items.size()))
