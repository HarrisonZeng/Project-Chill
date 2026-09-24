extends RefCounted

# The first thing Yua says when the player opens a conversation, chosen by a
# priority ladder (docs/Ambient_and_Systems_Draft_v1.md §B):
#
#   1 special date       (春节 / 中秋 / 高考 / 台风 / 100 天 / 凌晨 …)
#   2 away ≥ 30 / 7 / 3 days
#   3 door report        (she tried the player's Ep7 idea; one-shot)
#   4 「上次你说」         (AI callback on something the player typed ≥ 3 days ago)
#   5 notebook mention   (one changed line from her notebook)
#   6 same-day return    (≤ 30 min, or the 2nd / 3rd+ time today)
#   7 regular            (time bucket × current chapter)
#
# PURE: pick() reads a state Dictionary and the pools and returns a decision;
# the coordinator (main_scene) owns persistence, applies the side effects the
# decision names, and speaks the line. Keeping it pure keeps it testable and
# keeps the rules in one place.
#
# state keys (all optional, safe defaults):
#   now: {year, month, day, weekday(0=Sun), hour}
#   days_since: int           whole days since the previous visit (0 = same day / unknown)
#   elapsed_seconds: int      seconds since the previous visit (-1 = unknown)
#   returns_today: int        how many launches today INCLUDING this one
#   chapter: int              1..5 (0 = intro not seen)
#   role: String              "study" / "work" / "other" / ""
#   fired: Dictionary         special id -> "YYYY-MM-DD" it last fired
#   first_focus_unix: int     0 = never
#   now_unix: int
#   door_idea: String / door_reported: bool
#   notebook_mention: String  "" = nothing to mention
#   callback: Dictionary      {} or the player_said entry to echo
#   ai_enabled: bool
#   rng: float                0..1, injected so tests are deterministic

const BUCKETS := ["morning", "noon", "evening", "night"]

static func bucket_for_hour(hour: int) -> String:
	if hour >= 5 and hour < 11:
		return "morning"
	if hour >= 11 and hour < 15:
		return "noon"
	if hour >= 15 and hour < 20:
		return "evening"
	return "night"

static func date_key(now: Dictionary) -> String:
	return "%04d-%02d-%02d" % [int(now.get("year", 0)), int(now.get("month", 0)), int(now.get("day", 0))]

static func pick(state: Dictionary, pools: Dictionary) -> Dictionary:
	var rng := float(state.get("rng", randf()))
	var now: Dictionary = state.get("now", {})
	var chapter := maxi(1, int(state.get("chapter", 1)))

	# 1 · special date
	var special := _pick_special(state, pools, rng)
	if not special.is_empty():
		return special

	# 2 · away for days
	var days := int(state.get("days_since", 0))
	if days >= 30:
		var l := _one(pools.get("away_30", []), rng)
		if not l.is_empty():
			return {"kind": "away", "id": "away_30", "line": l}
	if days >= 7:
		var l7 := _one(pools.get("away_7", []), rng)
		if not l7.is_empty():
			return {"kind": "away", "id": "away_7", "line": l7}
	if days >= 3:
		var l3 := _one(pools.get("away_3", []), rng)
		if not l3.is_empty():
			return {"kind": "away", "id": "away_3", "line": l3}

	# 3 · door report (Ep7 idea, first visit on a later day)
	var idea := str(state.get("door_idea", "")).strip_edges()
	if not idea.is_empty() and not bool(state.get("door_reported", false)) and days >= 1:
		var door: Dictionary = pools.get("door_report", {})
		var outcomes := ["open", "half", "no"]
		var outcome: String = outcomes[int(floor(rng * 3.0)) % 3]
		var l := _one(door.get(outcome, []), rng).replace("{idea}", idea)
		if not l.is_empty():
			return {"kind": "door_report", "id": "door_" + outcome, "line": l, "door_result": outcome}

	# 4 · 「上次你说」 — AI echo of something typed ≥ 3 days ago
	var cb: Dictionary = state.get("callback", {})
	if not cb.is_empty() and bool(state.get("ai_enabled", false)):
		var said := str(cb.get("text", ""))
		var fb := _one(pools.get("callback_fallback", []), rng).replace("{said}", said)
		return {"kind": "callback", "id": "callback", "line": fb, "said": cb}

	# 5 · notebook mention
	var mention := str(state.get("notebook_mention", "")).strip_edges()
	if not mention.is_empty():
		return {"kind": "notebook", "id": "notebook", "line": mention}

	# 6 · same-day return
	var elapsed := int(state.get("elapsed_seconds", -1))
	var returns_today := int(state.get("returns_today", 1))
	if elapsed >= 0 and elapsed <= 30 * 60:
		var ls := _one(pools.get("return_short", []), rng)
		if not ls.is_empty():
			return {"kind": "return", "id": "return_short", "line": ls}
	if days == 0 and returns_today >= 3:
		var l3p := _one(pools.get("same_day_3", []), rng)
		if not l3p.is_empty():
			return {"kind": "return", "id": "same_day_3", "line": l3p}
	if days == 0 and returns_today == 2:
		var l2 := _one(pools.get("same_day_2", []), rng)
		if not l2.is_empty():
			return {"kind": "return", "id": "same_day_2", "line": l2}

	# 7 · regular: bucket × chapter (fall back to chapter 1, then any bucket)
	var bucket := bucket_for_hour(int(now.get("hour", 12)))
	var regular: Dictionary = pools.get("regular", {})
	for ch in [str(chapter), "1"]:
		var by_bucket: Dictionary = regular.get(ch, {})
		var l := _one(by_bucket.get(bucket, []), rng)
		if not l.is_empty():
			return {"kind": "regular", "id": "regular_%s_%s" % [ch, bucket], "line": l}
	return {}

# --- special dates ------------------------------------------------------------

static func _pick_special(state: Dictionary, pools: Dictionary, rng: float) -> Dictionary:
	var now: Dictionary = state.get("now", {})
	if now.is_empty():
		return {}
	var today := date_key(now)
	var fired: Dictionary = state.get("fired", {})
	var role := str(state.get("role", ""))
	var specials: Array = pools.get("special", [])
	for raw in specials:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var sp: Dictionary = raw
		var id := str(sp.get("id", ""))
		if id.is_empty():
			continue
		# Audience gate.
		var want_role := str(sp.get("role", ""))
		if not want_role.is_empty() and want_role != role:
			continue
		# Already fired recently?
		var last := str(fired.get(id, ""))
		var gap_days := int(sp.get("min_gap_days", 1))
		if not last.is_empty():
			if last == today:
				continue
			if gap_days > 1 and _days_between(last, today) < gap_days:
				continue
		if not _special_matches(sp, state, now, rng):
			continue
		var line := _one(sp.get("lines", []), rng)
		if line.is_empty():
			continue
		return {"kind": "special", "id": id, "line": line, "fire_key": today}
	return {}

static func _special_matches(sp: Dictionary, state: Dictionary, now: Dictionary, rng: float) -> bool:
	var today := date_key(now)
	var md := "%02d-%02d" % [int(now.get("month", 0)), int(now.get("day", 0))]
	# explicit date ranges "YYYY-MM-DD..YYYY-MM-DD" (lunar festivals, pre-computed)
	if sp.has("dates"):
		for r in sp.get("dates", []):
			var parts := str(r).split("..")
			var a := parts[0]
			var b := parts[1] if parts.size() > 1 else parts[0]
			if today >= a and today <= b:
				return true
		return false
	if sp.has("month_day"):
		for x in sp.get("month_day", []):
			if str(x) == md:
				return true
		return false
	if sp.has("month_day_range"):
		for r in sp.get("month_day_range", []):
			var parts := str(r).split("..")
			var a := parts[0]
			var b := parts[1] if parts.size() > 1 else parts[0]
			# ranges may wrap the year end (12-15..01-20)
			if a <= b:
				if md >= a and md <= b:
					return true
			else:
				if md >= a or md <= b:
					return true
		return false
	if sp.has("rule"):
		match str(sp.get("rule")):
			"second_sunday_may":
				if int(now.get("month", 0)) != 5 or int(now.get("weekday", -1)) != 0:
					return false
				var day := int(now.get("day", 0))
				return day >= 8 and day <= 14
		return false
	if sp.has("weekday"):
		if int(now.get("weekday", -1)) != int(sp.get("weekday")):
			return false
		if sp.has("hour_min") and int(now.get("hour", 0)) < int(sp.get("hour_min")):
			return false
		return true
	if sp.has("hour_range"):
		var hr: Array = sp.get("hour_range", [0, 0])
		var h := int(now.get("hour", 12))
		return h >= int(hr[0]) and h < int(hr[1])
	if sp.has("month"):
		if int(now.get("month", 0)) != int(sp.get("month")):
			return false
		return rng < float(sp.get("chance", 1.0))
	if sp.has("months"):
		# JSON numbers arrive as floats and `in` compares strictly by type.
		var month := int(now.get("month", 0))
		var listed := false
		for m in sp.get("months", []):
			if int(m) == month:
				listed = true
		if not listed:
			return false
		return rng < float(sp.get("chance", 1.0))
	if sp.has("since_first_focus_days"):
		var first := int(state.get("first_focus_unix", 0))
		if first <= 0:
			return false
		var elapsed_days := int((int(state.get("now_unix", 0)) - first) / 86400)
		var want := int(sp.get("since_first_focus_days"))
		# a small window so a missed day still gets it
		return elapsed_days >= want and elapsed_days <= want + 6
	if sp.has("nickname_changed"):
		return bool(state.get("nickname_changed", false))
	return false

# --- helpers --------------------------------------------------------------------

static func _one(pool, rng: float) -> String:
	if typeof(pool) != TYPE_ARRAY or (pool as Array).is_empty():
		return ""
	var arr: Array = pool
	var idx := int(floor(rng * arr.size())) % arr.size()
	return str(arr[idx])

static func _days_between(a: String, b: String) -> int:
	var da := _parse(a)
	var db := _parse(b)
	if da.is_empty() or db.is_empty():
		return 999
	var ua := Time.get_unix_time_from_datetime_dict(da)
	var ub := Time.get_unix_time_from_datetime_dict(db)
	return int(abs(ub - ua) / 86400)

static func _parse(d: String) -> Dictionary:
	var p := d.split("-")
	if p.size() != 3:
		return {}
	return {"year": int(p[0]), "month": int(p[1]), "day": int(p[2]), "hour": 12, "minute": 0, "second": 0}
