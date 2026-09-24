const DESC := "Yua's notebook: top line follows the story, chores roll on a new real day, one mention reaches the greeting, standing items, persistence."

func _nb(g):
	return g.game.notebook_manager

func _rows(g) -> Array:
	return _nb(g).get_render_items()

func _texts(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		out.append(str(r.get("text", "")))
	return out

func run(g) -> void:
	g.check("notebook manager exists", _nb(g) != null)
	g.check("pools loaded", not _nb(g).pools.is_empty())

	# Nothing before the intro; after it the top line is 我的小项目 and 2–3 chores exist.
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()  # Ep1 opens → the roll ran on this session's first click
	var rows := _rows(g)
	g.check("top line after the intro is 我的小项目", rows.size() > 0 and str(rows[0].get("text", "")) == "我的小项目" and bool(rows[0].get("top", false)), str(_texts(rows)))
	var chores := 0
	for r in rows:
		if not bool(r.get("top", false)) and not r.has("total") and str(r.get("text", "")) != "别打游戏":
			chores += 1
	g.check("2–3 chores on the first roll", chores >= 2 and chores <= 3, str(_texts(rows)))
	g.check("别打游戏 is standing", _texts(rows).has("别打游戏"), str(_texts(rows)))
	g.check("first roll has no mention", _nb(g).pick_mention() == "", _nb(g).pick_mention())
	g.check("panel received her rows", g.game.tasks_ui.yua_items.size() == rows.size(), str(g.game.tasks_ui.yua_items.size()))

	# Ep2 flips the top line to 写一章 as soon as the flag lands.
	await g.play_forward()
	await g.complete_focus()
	g.check_node("session 2 → Ep2", "ep02_01")
	g.check("top line becomes 写一章 at Ep2", str(_rows(g)[0].get("text", "")) == "写一章", str(_texts(_rows(g))))

	# Same day: no second roll, no mention.
	var before := _texts(_rows(g))
	_nb(g).roll_for_today(1, g.flags(), "小雨")
	g.check("same day → no change", _texts(_rows(g)) == before)

	# A new day: deterministic dice → first chore done, second stalled, no_games flips, no top rewrite.
	_nb(g).rng_queue = [0.1, 0.5, 0.9, 0.9, 0.9, 0.9]
	_nb(g).roll_for_today(1, g.flags(), "小雨", "2099-01-15")
	rows = _rows(g)
	var done_count := 0
	var stalled_count := 0
	for r in rows:
		if bool(r.get("top", false)):
			continue
		if bool(r.get("done", false)) and str(r.get("text", "")) != "别打游戏":
			done_count += 1
		if bool(r.get("stalled", false)):
			stalled_count += 1
	g.check("new day: one chore crossed out", done_count >= 1, str(rows))
	g.check("new day: one chore stalled", stalled_count >= 1, str(rows))
	var mention: String = _nb(g).pick_mention()
	g.check("new day: a mention is pending (the done line)", not mention.is_empty(), mention)
	g.check("mention is one sentence-ish, not a list", not mention.contains("\n\n"), mention)
	_nb(g).consume_mention()
	g.check("mention consumed", _nb(g).pick_mention() == "")

	# The greeting ladder speaks the mention (priority 5) when nothing above it applies.
	_nb(g).state["pending_mention"] = "衣服终于收了。给自己记一功，你不用鼓掌。"
	_nb(g).state["mention_date"] = g.game._today_key()
	_nb(g).state["last_roll"] = g.game._today_key()
	_nb(g)._save_state()
	await g.relaunch()
	var today: String = g.game._today_key()
	for sid in ["small_hours", "monday", "friday_night", "finals", "gaokao", "plum_rain", "typhoon", "new_year", "valentine", "spring_festival", "mid_autumn", "mothers_day"]:
		g.game.greeting_fired[sid] = today
	g.game.previous_last_seen_unix = int(Time.get_unix_time_from_system()) - 3600 * 5
	await g.click_yua()
	g.check("greeting is the notebook mention", g.game.last_greeting_id == "notebook", g.game.last_greeting_id)
	g.check("… spoken verbatim", g.line().contains("衣服终于收了"), g.line())
	g.check("… and consumed", _nb(g).pick_mention() == "")

	# 不催{name} appears after Ep5 and is always done.
	g.game.memory_manager.set_story_flag("ep05_seen", true)
	_nb(g).rng_queue = [0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9]
	_nb(g).roll_for_today(1, g.flags(), "小雨", "2099-01-16")
	var found := false
	for r in _rows(g):
		if str(r.get("text", "")) == "不催小雨":
			found = bool(r.get("done", false))
	g.check("不催小雨 standing item, crossed out", found, str(_texts(_rows(g))))

	# Chapter 2 pool once the aquarium flag is set; long goal appears after ep20.
	g.game.memory_manager.set_story_flag("ep13_seen", true)
	g.game.memory_manager.set_story_flag("ep20_seen", true)
	_nb(g).rng_queue = [0.1, 0.1, 0.1, 0.9, 0.9, 0.0, 0.0, 0.0, 0.0]
	_nb(g).roll_for_today(2, g.flags(), "小雨", "2099-01-19")
	var has_long := false
	var has_aq := false
	for r in _rows(g):
		if r.has("total"):
			has_long = true
		if str(r.get("text", "")) in ["周六早班", "洗小七的杯子", "背企鹅讲解词", "给 Hina 带早饭", "晾工作服"]:
			has_aq = true
	g.check("long goal 攒电脑 present after ep20", has_long, str(_texts(_rows(g))))
	g.check("aquarium chores appear in chapter 2", has_aq, str(_texts(_rows(g))))

	# Persistence.
	var saved := _texts(_rows(g))
	await g.relaunch()
	g.check("notebook survives a relaunch", _texts(_rows(g)) == saved, str(_texts(_rows(g))))
