extends Node

# Yua's living notebook (docs/Ambient_and_Systems_Draft_v1.md §D; owner idea
# 2026-08-20). The visible evidence that she has a life: a top line that
# follows the story, a few chores from the current chapter, standing jokes, and
# long goals with a progress bar. When a real day has passed since the last
# roll, some lines get crossed out or stalled, and she mentions ONE change at
# the start of the conversation (fed to the greeting selector as priority 5).
#
# Rules kept from the design: script pools only (no AI); one mention per visit,
# never a list; no 查岗 (nothing here is about the player's tasks); crossing out
# is visual, not an achievement. Persisted on the shared profile under
# "yua_notebook"; nothing here advances the story.

const POOLS_PATH := "res://data/dialogue/notebook_pools.json"
const DAILY_MIN := 2
const DAILY_MAX := 3
const DONE_KEEP_DAYS := 2

var pools: Dictionary = {}
var state: Dictionary = {}
var memory_manager: Node = null
# Tests inject a fixed sequence so a roll is deterministic; empty = randf().
var rng_queue: Array = []

func setup(mm: Node) -> void:
	memory_manager = mm
	pools = _load_json(POOLS_PATH)
	_load_state()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("notebook_manager: missing %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

func _load_state() -> void:
	state = {}
	if memory_manager != null:
		var raw = memory_manager.get_value("yua_notebook", {})
		if typeof(raw) == TYPE_DICTIONARY:
			state = (raw as Dictionary).duplicate(true)
	if not state.has("items"):
		state["items"] = []
	if not state.has("long"):
		state["long"] = []
	if not state.has("top"):
		state["top"] = ""
	if not state.has("last_roll"):
		state["last_roll"] = ""
	if not state.has("pending_mention"):
		state["pending_mention"] = ""
	if not state.has("mention_date"):
		state["mention_date"] = ""

func _save_state() -> void:
	if memory_manager != null:
		memory_manager.set_value("yua_notebook", state.duplicate(true))

func _rng() -> float:
	if not rng_queue.is_empty():
		return float(rng_queue.pop_front())
	return randf()

static func today_key() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(now.get("year", 0)), int(now.get("month", 0)), int(now.get("day", 0))]

# --- top line -------------------------------------------------------------------

# The top line follows the story: first matching flag in top_by_flag wins.
func refresh_top_line(flags: Dictionary) -> void:
	var top := ""
	for pair in pools.get("top_by_flag", []):
		if typeof(pair) != TYPE_ARRAY or (pair as Array).size() < 2:
			continue
		if bool(flags.get(str(pair[0]), false)):
			top = str(pair[1])
			break
	if state.get("top", "") != top:
		state["top"] = top
		state["top_done"] = false
		_save_state()

# --- the daily roll ---------------------------------------------------------------

# Called once per conversation opening. Does nothing twice on the same day.
# `chapter` 1..5 picks the chore pool; `flags` gates standing/long items.
func roll_for_today(chapter: int, flags: Dictionary, nickname: String, today: String = "") -> void:
	if today.is_empty():
		today = today_key()
	refresh_top_line(flags)
	var first_time: bool = str(state.get("last_roll", "")).is_empty()
	if state.get("last_roll", "") == today:
		return
	var mention := ""
	var items: Array = state["items"]

	if not first_time:
		# 1 · roll one or two existing chores: done / stalled / nothing
		var rolled := 0
		for i in items.size():
			var it: Dictionary = items[i]
			if bool(it.get("done", false)) or bool(it.get("standing", false)) or rolled >= 2:
				continue
			var r := _rng()
			if r < 0.4:
				it["done"] = true
				it["done_date"] = today
				if mention.is_empty():
					mention = str(it.get("done_line", ""))
			elif r < 0.8:
				it["stalled"] = true
				if mention.is_empty():
					mention = str(it.get("stalled_line", ""))
			items[i] = it
			rolled += 1
		# 2 · 别打游戏 flips half the time
		for i in items.size():
			var it: Dictionary = items[i]
			if str(it.get("key", "")) == "no_games" and _rng() < 0.5:
				it["done"] = not bool(it.get("done", false))
				items[i] = it
				if mention.is_empty():
					var sd: Dictionary = pools.get("standing", {}).get("no_games", {})
					mention = str(sd.get("done" if it["done"] else "undone", ""))
		# 3 · the top line gets crossed out and rewritten now and then (not after 写完)
		if not bool(flags.get("ep47_seen", false)) and not str(state.get("top", "")).is_empty() and _rng() < 0.25:
			state["top_rewritten_date"] = today
			var lines: Array = pools.get("top_rewrite_lines", [])
			if not lines.is_empty():
				mention = str(lines[int(floor(_rng() * lines.size())) % lines.size()])
		# 4 · long goals move by her working days, not the player's
		for i in (state["long"] as Array).size():
			var lg: Dictionary = state["long"][i]
			if bool(lg.get("done", false)):
				continue
			var spec: Dictionary = pools.get("long", {}).get(str(lg.get("key", "")), {})
			if not str(spec.get("done_flag", "")).is_empty() and bool(flags.get(str(spec.get("done_flag")), false)):
				lg["done"] = true
				lg["progress"] = int(lg.get("total", 5))
				mention = str(spec.get("done", mention))
			elif int(lg.get("progress", 0)) < int(lg.get("total", 5)):
				lg["progress"] = int(lg.get("progress", 0)) + 1
				if mention.is_empty():
					mention = str(spec.get("progress", ""))
			state["long"][i] = lg
		# 5 · rent: cross off when the month's line is still open
		for i in items.size():
			var it: Dictionary = items[i]
			if str(it.get("key", "")) == "rent" and not bool(it.get("done", false)):
				it["done"] = true
				it["done_date"] = today
				items[i] = it
				mention = str(pools.get("rent", {}).get("done", mention))
		# 6 · 不催{name}: always done; mentioned rarely
		if mention.is_empty():
			for it in items:
				if str(it.get("key", "")) == "no_nag" and _rng() < 0.2:
					mention = str(pools.get("standing", {}).get("no_nag", {}).get("mention", ""))
		# tidy: drop chores that have been done for a while
		var kept: Array = []
		for it in items:
			if bool(it.get("done", false)) and not bool(it.get("standing", false)) and str(it.get("key", "")) != "rent":
				if _days_between(str(it.get("done_date", today)), today) >= DONE_KEEP_DAYS:
					continue
			kept.append(it)
		items = kept

	# top-up: keep 2–3 open chores from the current chapter + life pools
	_ensure_standing(items, flags, nickname)
	_ensure_long(flags)
	_ensure_rent(items, today)
	var open_count := 0
	for it in items:
		if not bool(it.get("done", false)) and not bool(it.get("standing", false)) and str(it.get("key", "")) != "rent":
			open_count += 1
	var guard := 0
	while open_count < DAILY_MIN and guard < 12:
		guard += 1
		var pick := _pick_new_chore(items, chapter)
		if pick.is_empty():
			break
		pick["added"] = today
		items.append(pick)
		open_count += 1
	state["items"] = items
	state["last_roll"] = today
	if not first_time and not mention.is_empty():
		state["pending_mention"] = mention.replace("{name}", nickname if not nickname.is_empty() else "你")
		state["mention_date"] = today
	_save_state()

func _pick_new_chore(items: Array, chapter: int) -> Dictionary:
	var have: Dictionary = {}
	for it in items:
		have[str(it.get("key", ""))] = true
	var candidates: Array = []
	var ch_pool: Array = pools.get("chapter_pools", {}).get(str(maxi(1, chapter)), [])
	for c in ch_pool:
		if typeof(c) == TYPE_DICTIONARY and not have.has(str(c.get("key", ""))):
			candidates.append(c)
	for c in pools.get("life_pool", []):
		if typeof(c) == TYPE_DICTIONARY and not have.has(str(c.get("key", ""))):
			candidates.append(c)
	if candidates.is_empty():
		return {}
	var src: Dictionary = candidates[int(floor(_rng() * candidates.size())) % candidates.size()]
	return {"key": str(src.get("key", "")), "text": str(src.get("text", "")), "done": false, "stalled": false,
			"done_line": str(src.get("done", "")), "stalled_line": str(src.get("stalled", ""))}

func _ensure_standing(items: Array, flags: Dictionary, nickname: String) -> void:
	var have: Dictionary = {}
	for it in items:
		have[str(it.get("key", ""))] = true
	var standing: Dictionary = pools.get("standing", {})
	if standing.has("no_games") and not have.has("no_games"):
		items.append({"key": "no_games", "text": str(standing["no_games"].get("text", "别打游戏")), "done": false, "stalled": false, "standing": true})
	var nag: Dictionary = standing.get("no_nag", {})
	if not nag.is_empty() and not have.has("no_nag") and bool(flags.get(str(nag.get("after_flag", "ep05_seen")), false)):
		var label := str(nag.get("text", "不催{name}")).replace("{name}", nickname if not nickname.is_empty() else "你")
		items.append({"key": "no_nag", "text": label, "done": true, "stalled": false, "standing": true})

func _ensure_long(flags: Dictionary) -> void:
	var have: Dictionary = {}
	for lg in state["long"]:
		have[str(lg.get("key", ""))] = true
	var specs: Dictionary = pools.get("long", {})
	for key in specs.keys():
		var spec: Dictionary = specs[key]
		if have.has(str(key)):
			continue
		if bool(flags.get(str(spec.get("after_flag", "")), false)):
			(state["long"] as Array).append({"key": str(key), "text": str(spec.get("text", "")), "progress": 0, "total": int(spec.get("total", 5)), "done": false})

func _ensure_rent(items: Array, today: String) -> void:
	var day := int(today.substr(8, 2))
	if day < 1 or day > 3:
		return
	var month := today.substr(0, 7)
	for it in items:
		if str(it.get("key", "")) == "rent" and str(it.get("month", "")) == month:
			return
	items.append({"key": "rent", "text": str(pools.get("rent", {}).get("text", "房租")), "done": false, "stalled": false, "month": month})

# --- mention ------------------------------------------------------------------------

# The one change she can bring up today, or "" (already said / nothing new).
func pick_mention(_chapter: int = 0, _nickname: String = "") -> String:
	# Valid for the day it was rolled (the roll date, so an injected test date
	# behaves like a real one); a later roll overwrites it.
	if str(state.get("mention_date", "")) != str(state.get("last_roll", "")):
		return ""
	return str(state.get("pending_mention", ""))

func consume_mention() -> void:
	state["pending_mention"] = ""
	_save_state()

# --- rendering ---------------------------------------------------------------------

# Rows for the panel: {text, done, stalled, progress, total}. Top line first.
func get_render_items() -> Array:
	var rows: Array = []
	var top := str(state.get("top", ""))
	if not top.is_empty():
		rows.append({"text": top, "done": bool(state.get("top_done", false)), "stalled": false, "top": true})
	for lg in state["long"]:
		rows.append({"text": str(lg.get("text", "")), "done": bool(lg.get("done", false)), "stalled": false,
			"progress": int(lg.get("progress", 0)), "total": int(lg.get("total", 5))})
	for it in state["items"]:
		rows.append({"text": str(it.get("text", "")), "done": bool(it.get("done", false)), "stalled": bool(it.get("stalled", false))})
	return rows

func _days_between(a: String, b: String) -> int:
	var pa := a.split("-")
	var pb := b.split("-")
	if pa.size() != 3 or pb.size() != 3:
		return 0
	var ua := Time.get_unix_time_from_datetime_dict({"year": int(pa[0]), "month": int(pa[1]), "day": int(pa[2]), "hour": 12, "minute": 0, "second": 0})
	var ub := Time.get_unix_time_from_datetime_dict({"year": int(pb[0]), "month": int(pb[1]), "day": int(pb[2]), "hour": 12, "minute": 0, "second": 0})
	return int(abs(ub - ua) / 86400)
