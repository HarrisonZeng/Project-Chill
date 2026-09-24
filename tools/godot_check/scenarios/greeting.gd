const DESC := "Greeting selector: priority ladder (special > away > door report > 上次你说 > notebook > return > regular), role gating, once-per-day firing, and the game speaks it on the first click."

## The selector is pure, so most of this feeds it hand-made states. The last
## part checks the game actually uses it and persists what it fired.

const Sel = preload("res://scripts/core/greeting_selector.gd")

func _pools(g) -> Dictionary:
	return g.game.greeting_pools

func _base(overrides: Dictionary) -> Dictionary:
	var s := {
		"now": {"year": 2026, "month": 10, "day": 14, "weekday": 3, "hour": 9},
		"now_unix": 1792000000, "days_since": 0, "elapsed_seconds": 4000, "returns_today": 1,
		"chapter": 1, "role": "study", "fired": {}, "first_focus_unix": 0,
		"door_idea": "", "door_reported": false, "notebook_mention": "", "callback": {},
		"ai_enabled": true, "rng": 0.0,
	}
	for k in overrides.keys():
		s[k] = overrides[k]
	return s

func run(g) -> void:
	var pools := _pools(g)
	g.check("greeting pools loaded", not pools.is_empty())

	# 7 · regular, bucket × chapter
	var d := Sel.pick(_base({}), pools)
	g.check("weekday morning, chapter 1 → regular bookshop morning", d.get("id", "") == "regular_1_morning", str(d))
	d = Sel.pick(_base({"chapter": 2, "now": {"year": 2026, "month": 10, "day": 14, "weekday": 3, "hour": 22}}), pools)
	g.check("chapter 2 night → aquarium night line", d.get("id", "") == "regular_2_night", str(d))
	g.check("… and it is an aquarium line", str(d.get("line", "")).contains("水族馆") or str(d.get("line", "")).contains("鱼"), str(d))
	d = Sel.pick(_base({"chapter": 4, "now": {"year": 2026, "month": 10, "day": 14, "weekday": 3, "hour": 12}}), pools)
	g.check("chapter 4 noon has its own line", d.get("id", "") == "regular_4_noon", str(d))
	g.check("bucket boundaries", Sel.bucket_for_hour(5) == "morning" and Sel.bucket_for_hour(14) == "noon" and Sel.bucket_for_hour(19) == "evening" and Sel.bucket_for_hour(3) == "night")

	# 6 · same-day returns
	d = Sel.pick(_base({"elapsed_seconds": 600}), pools)
	g.check("back within 30 min → short return", d.get("id", "") == "return_short", str(d))
	d = Sel.pick(_base({"returns_today": 2}), pools)
	g.check("second launch today → same_day_2", d.get("id", "") == "same_day_2", str(d))
	d = Sel.pick(_base({"returns_today": 4}), pools)
	g.check("fourth launch today → same_day_3", d.get("id", "") == "same_day_3", str(d))

	# 2 · away
	d = Sel.pick(_base({"days_since": 4, "returns_today": 1, "elapsed_seconds": 4 * 86400}), pools)
	g.check("4 days away → away_3", d.get("id", "") == "away_3", str(d))
	d = Sel.pick(_base({"days_since": 9, "elapsed_seconds": 9 * 86400}), pools)
	g.check("9 days away → away_7", d.get("id", "") == "away_7", str(d))
	d = Sel.pick(_base({"days_since": 40, "elapsed_seconds": 40 * 86400}), pools)
	g.check("40 days away → away_30", d.get("id", "") == "away_30", str(d))
	g.check("away lines never ask where the player was", not str(d.get("line", "")).contains("你去哪"), str(d))

	# 3 · door report beats everything below it, only on a later day
	d = Sel.pick(_base({"door_idea": "倒着走", "days_since": 1, "elapsed_seconds": 86400, "rng": 0.5}), pools)
	g.check("door idea on a later day → door report", d.get("kind", "") == "door_report", str(d))
	g.check("door report names the idea", str(d.get("line", "")).contains("倒着走"), str(d))
	d = Sel.pick(_base({"door_idea": "倒着走", "days_since": 0}), pools)
	g.check("door report waits for a new day", d.get("kind", "") != "door_report", str(d))
	d = Sel.pick(_base({"door_idea": "倒着走", "door_reported": true, "days_since": 2, "elapsed_seconds": 2 * 86400}), pools)
	g.check("door report fires once", d.get("kind", "") != "door_report", str(d))

	# 4 · 上次你说 needs AI; 5 · notebook
	var cb := {"key": "player_project", "text": "在赶论文", "unix": 1, "echoed": false}
	d = Sel.pick(_base({"callback": cb}), pools)
	g.check("callback with AI on → callback kind", d.get("kind", "") == "callback", str(d))
	g.check("callback fallback line carries the words", str(d.get("line", "")).contains("上次"), str(d))
	d = Sel.pick(_base({"callback": cb, "ai_enabled": false, "notebook_mention": "衣服终于收了。"}), pools)
	g.check("callback with AI off falls to the notebook mention", d.get("kind", "") == "notebook" and str(d.get("line", "")) == "衣服终于收了。", str(d))

	# 1 · special dates, role gating, once per day / per year
	var gk := {"year": 2026, "month": 6, "day": 7, "weekday": 0, "hour": 9}
	d = Sel.pick(_base({"now": gk, "role": "study"}), pools)
	g.check("高考 day, student → gaokao", d.get("id", "") == "gaokao", str(d))
	d = Sel.pick(_base({"now": gk, "role": "work"}), pools)
	g.check("高考 day, worker → not gaokao", d.get("id", "") != "gaokao", str(d))
	d = Sel.pick(_base({"now": gk, "role": "study", "fired": {"gaokao": "2026-06-07"}}), pools)
	g.check("gaokao does not fire twice the same day", d.get("id", "") != "gaokao", str(d))
	d = Sel.pick(_base({"now": {"year": 2027, "month": 2, "day": 7, "weekday": 0, "hour": 9}}), pools)
	g.check("lunar range → spring festival", d.get("id", "") == "spring_festival", str(d))
	d = Sel.pick(_base({"now": {"year": 2026, "month": 10, "day": 12, "weekday": 1, "hour": 9}, "role": "work"}), pools)
	g.check("Monday, worker → monday", d.get("id", "") == "monday", str(d))
	d = Sel.pick(_base({"now": {"year": 2026, "month": 10, "day": 12, "weekday": 1, "hour": 9}, "role": "work", "fired": {"monday": "2026-10-05"}}), pools)
	g.check("monday respects the 14-day gap", d.get("id", "") != "monday", str(d))
	d = Sel.pick(_base({"now": {"year": 2026, "month": 10, "day": 14, "weekday": 3, "hour": 3}}), pools)
	g.check("3 am → small hours", d.get("id", "") == "small_hours", str(d))
	d = Sel.pick(_base({"first_focus_unix": 1792000000 - 101 * 86400}), pools)
	g.check("101 days after the first focus → days_100", d.get("id", "") == "days_100", str(d))
	d = Sel.pick(_base({"now": {"year": 2026, "month": 8, "day": 3, "weekday": 1, "hour": 9}, "rng": 0.5}), pools)
	g.check("typhoon is a rare roll, not every August day", d.get("id", "") != "typhoon", str(d))
	d = Sel.pick(_base({"now": {"year": 2026, "month": 8, "day": 3, "weekday": 1, "hour": 9}, "rng": 0.01}), pools)
	g.check("… but it can land", d.get("id", "") == "typhoon", str(d))

	# --- The game uses it: a returning player's first click speaks a selected line.
	await g.click_yua()
	await g.play_forward()
	await g.complete_focus()
	await g.play_forward()
	await g.relaunch()
	# Fake a visit 5 days ago so the away line is deterministic, and pre-fire the
	# specials that depend on the real clock (this runs at any hour / date).
	g.game.previous_last_seen_unix = int(Time.get_unix_time_from_system()) - 5 * 86400
	var today: String = g.game._today_key()
	for sid in ["small_hours", "monday", "friday_night", "finals", "gaokao", "plum_rain", "typhoon", "new_year", "valentine", "spring_festival", "mid_autumn", "mothers_day"]:
		g.game.greeting_fired[sid] = today
	await g.click_yua()
	g.check("returning player: the selector speaks", g.node_id() == "greeting", g.node_id())
	g.check("… an away_3 line", g.game.last_greeting_id == "away_3", g.game.last_greeting_id)
	g.check("… with no chips (co-presence)", g.choices().is_empty(), str(g.choices()))
	g.check("returns_today counted", g.game.returns_today >= 1, str(g.game.returns_today))
	g.check("first_focus_unix stamped after the first focus", g.game.first_focus_unix > 0)
	# Special firing persists across a relaunch.
	g.game.greeting_fired["gaokao"] = "2026-06-07"
	await g.relaunch()
	g.check("greeting_fired survives a relaunch", str(g.game.greeting_fired.get("gaokao", "")) == "2026-06-07", str(g.game.greeting_fired))
