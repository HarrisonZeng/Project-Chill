const DESC := "Calendar card on the left stamps days you focused together, marks festivals/first day, survives a relaunch; her notebook is its own card above the player's tasks and clear of the timer."

## Owner 2026-09-24: "Yua's notebook separate, on top of the player's, as a
## separate window" + "on the left, a calendar in the current art style".

func _today() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func run(g) -> void:
	var cal = g.game.calendar_ui
	g.check("calendar node exists", cal != null)
	if cal == null:
		return
	g.check("calendar card shows by default", cal.is_card_visible() and cal.card.visible)

	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	var today := _today()
	g.check("a completed session stamps today", bool(cal.day_info(today).get("focus", false)), str(g.game.focus_days))
	g.check("today is the first-focus day", (cal.day_info(today).get("marks", []) as Array).size() >= 1, str(cal.day_info(today)))
	g.check("festival marks come through (中秋 2026-09-25)", "中秋" in cal.day_info("2026-09-25").get("marks", []), str(cal.day_info("2026-09-25")))
	g.check("an untouched day carries nothing", not bool(cal.day_info("2026-03-11").get("focus", true)) and (cal.day_info("2026-03-11").get("marks", [1]) as Array).is_empty())

	# Toggle off, relaunch: the choice and the stamps are remembered.
	cal.calendar_button.pressed.emit()
	await g.frames(2)
	g.check("the button folds the card", not cal.card.visible)
	await g.relaunch()
	cal = g.game.calendar_ui
	g.check("folded state survives a relaunch", not cal.is_card_visible())
	g.check("stamps survive a relaunch", bool(cal.day_info(today).get("focus", false)), str(g.game.focus_days))
	cal.calendar_button.pressed.emit()
	await g.frames(2)
	g.check("the button opens it again", cal.card.visible)

	# Her notebook: its own card, above the player's, not inside their list.
	await g.play_forward()
	g.game._refresh_yua_notebook()
	var tasks = g.game.tasks_ui
	tasks.set_panel_visible(true)
	await g.frames(4)
	g.check("her card is visible with the tasks panel", tasks.is_her_panel_visible())
	var her: Control = tasks.her_panel
	var mine: Control = tasks.tasks_panel
	g.check("her card sits above the player's", her.get_global_rect().end.y <= mine.get_global_rect().position.y, "%s vs %s" % [her.get_global_rect(), mine.get_global_rect()])
	var timer_card: Control = g.game.focus_card
	g.check("her card clears the timer card", her.get_global_rect().position.y >= timer_card.get_global_rect().end.y, "%s vs %s" % [her.get_global_rect(), timer_card.get_global_rect()])
	g.check("her rows are not in the player's list", tasks.her_rows.get_child_count() == tasks.yua_items.size() and tasks.yua_items.size() > 0, "%d rows / %d items" % [tasks.her_rows.get_child_count(), tasks.yua_items.size()])
	tasks.set_panel_visible(false)
	await g.frames(2)
	g.check("closing tasks closes her card too", not tasks.is_her_panel_visible())
