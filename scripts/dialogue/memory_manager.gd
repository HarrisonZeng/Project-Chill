extends Node

const SAVE_PATH := "user://data/saves/player_profile.json"
const TEMPLATE_SAVE_PATH := "res://data/saves/player_profile.json"
const SAVE_DIR := "user://data/saves"
const MAX_MEMORIES := 20
const MAX_MEMORY_CONTEXT_ITEMS := 5
const FOLLOW_UP_COOLDOWN_SECONDS := 3 * 24 * 60 * 60

const FOLLOW_UP_RULES := [
	{
		"tag": "ask_about_school",
		"topic": "school",
		"type": "plan",
		"expires_in_days": 7,
		"keywords": ["school", "class", "campus"]
	},
	{
		"tag": "ask_about_exam",
		"topic": "exam",
		"type": "plan",
		"expires_in_days": 14,
		"keywords": ["exam", "test", "midterm", "final"]
	},
	{
		"tag": "ask_about_sleep",
		"topic": "sleep",
		"type": "state",
		"expires_in_days": 3,
		"keywords": ["sleep", "tired", "rest", "insomnia", "nap"]
	},
	{
		"tag": "ask_about_work",
		"topic": "work",
		"type": "plan",
		"expires_in_days": 7,
		"keywords": ["work", "job", "shift", "deadline", "project"]
	}
]

var profile: Dictionary = {}
var last_consumed_follow_up_tag: String = ""

func load_profile() -> void:
	_ensure_save_dir()
	profile = _load_profile_from_disk()
	_normalize_profile()
	profile["last_login_at"] = _now_iso()
	save_profile()

func save_profile() -> void:
	_ensure_save_dir()
	_prune_memory_cache()
	_prune_follow_up_history()
	_refresh_recent_summary()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(profile, "\t"))

func process_player_message(player_text: String) -> Array:
	_ensure_profile_loaded()
	var created_memories: Array = []
	var lower_text: String = player_text.to_lower()

	for rule in FOLLOW_UP_RULES:
		if _rule_matches_text(rule, lower_text):
			var memory: Dictionary = _build_memory_entry(player_text, rule)
			created_memories.append(memory)
			_add_memory(memory)
			_add_follow_up(memory.follow_up_tag)

	if created_memories.size() > 0:
		_refresh_recent_summary()
		save_profile()

	return created_memories

func consume_next_follow_up_line() -> String:
	_ensure_profile_loaded()
	last_consumed_follow_up_tag = ""
	var pending: Array = _normalize_string_array(profile.get("pending_follow_ups", []))

	while not pending.is_empty():
		var tag: String = str(pending.pop_front())
		var line: String = _follow_up_line_for_tag(tag)
		if line.is_empty():
			continue

		profile["pending_follow_ups"] = pending
		profile["last_login_at"] = _now_iso()
		_mark_follow_up_served(tag)
		last_consumed_follow_up_tag = tag
		save_profile()
		return line

	profile["pending_follow_ups"] = pending
	save_profile()
	return ""

func get_last_consumed_follow_up_tag() -> String:
	return last_consumed_follow_up_tag

func get_memory_context(max_items: int = MAX_MEMORY_CONTEXT_ITEMS) -> String:
	_ensure_profile_loaded()
	var facts: Array = _collect_recent_memory_facts(max_items)
	if facts.is_empty():
		return ""

	var lines: Array = []
	for fact in facts:
		lines.append("- " + fact)

	return "Memory summary:\n" + "\n".join(lines)

func _ensure_profile_loaded() -> void:
	if profile.is_empty():
		load_profile()

func _load_profile_from_disk() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		return _load_profile_file(SAVE_PATH)
	if FileAccess.file_exists(TEMPLATE_SAVE_PATH):
		return _load_profile_file(TEMPLATE_SAVE_PATH)
	return _build_default_profile()

func _load_profile_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _build_default_profile()

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	return _build_default_profile()

func _normalize_profile() -> void:
	var defaults: Dictionary = _build_default_profile()
	for key in defaults.keys():
		if not profile.has(key):
			profile[key] = defaults[key]

	profile["last_login_at"] = str(profile.get("last_login_at", ""))
	profile["last_node_id"] = str(profile.get("last_node_id", "idle"))
	profile["recent_summary"] = str(profile.get("recent_summary", ""))
	profile["pending_follow_ups"] = _normalize_string_array(profile.get("pending_follow_ups", []))
	profile["follow_up_last_served_at"] = _normalize_follow_up_history(profile.get("follow_up_last_served_at", {}))
	profile["memories"] = _normalize_memories(profile.get("memories", []))
	profile["story_flags"] = _normalize_story_flags(profile.get("story_flags", {}))
	_prune_memory_cache()
	_refresh_recent_summary()

func _add_memory(memory: Dictionary) -> void:
	var memories: Array = _normalize_memories(profile.get("memories", []))
	memories.append(memory)
	profile["memories"] = memories

func _add_follow_up(tag: String) -> void:
	if tag.is_empty():
		return
	if not _can_queue_follow_up(tag):
		return

	var pending: Array = _normalize_string_array(profile.get("pending_follow_ups", []))
	if not pending.has(tag):
		pending.append(tag)
	profile["pending_follow_ups"] = pending

func _build_memory_entry(source_text: String, rule: Dictionary) -> Dictionary:
	return {
		"id": _new_memory_id(),
		"fact": "User mentioned " + rule.topic + ".",
		"topic": rule.topic,
		"type": rule.type,
		"confidence": 0.85,
		"last_seen_at": _now_iso(),
		"follow_up_tag": rule.tag,
		"expires_in_days": rule.expires_in_days,
		"source_message": source_text
	}

func _collect_recent_memory_facts(max_items: int) -> Array:
	var memories: Array = _normalize_memories(profile.get("memories", []))
	var facts: Array = []
	var seen_topics: Dictionary = {}

	for index in range(memories.size() - 1, -1, -1):
		var memory: Dictionary = memories[index]
		var fact: String = str(memory.get("fact", "")).strip_edges()
		if fact.is_empty():
			continue

		var topic: String = str(memory.get("topic", "")).strip_edges()
		var dedupe_key: String = topic if not topic.is_empty() else fact
		if seen_topics.has(dedupe_key):
			continue

		seen_topics[dedupe_key] = true
		facts.append(fact)
		if facts.size() >= max_items:
			break

	facts.reverse()
	return facts

func _can_queue_follow_up(tag: String) -> bool:
	var served_history: Dictionary = _normalize_follow_up_history(profile.get("follow_up_last_served_at", {}))
	var last_served_at: int = int(served_history.get(tag, 0))
	if last_served_at <= 0:
		return true

	return _now_unix() - last_served_at >= FOLLOW_UP_COOLDOWN_SECONDS

func _mark_follow_up_served(tag: String) -> void:
	var served_history: Dictionary = _normalize_follow_up_history(profile.get("follow_up_last_served_at", {}))
	served_history[tag] = _now_unix()
	profile["follow_up_last_served_at"] = served_history

func _follow_up_line_for_tag(tag: String) -> String:
	match tag:
		"ask_about_school":
			return "You mentioned school before. I was a little curious... how did it go?"
		"ask_about_exam":
			return "You had that exam coming up, right? I hope it felt a little kinder than expected."
		"ask_about_sleep":
			return "You seemed tired last time. Did you get any proper rest after that?"
		"ask_about_work":
			return "Last time sounded a little busy. Is work still like that?"
		_:
			return ""

func _build_default_profile() -> Dictionary:
	return {
		"last_login_at": "",
		"last_node_id": "idle",
		"pending_follow_ups": [],
		"follow_up_last_served_at": {},
		"recent_summary": "",
		"memories": [],
		"story_flags": {}
	}

func set_story_flag(key: String, value) -> void:
	if key.is_empty():
		return
	_ensure_profile_loaded()
	var flags: Dictionary = _normalize_story_flags(profile.get("story_flags", {}))
	flags[key] = value
	profile["story_flags"] = flags
	save_profile()

func get_story_flag(key: String, default_value = null):
	_ensure_profile_loaded()
	var flags: Dictionary = _normalize_story_flags(profile.get("story_flags", {}))
	if not flags.has(key):
		return default_value
	return flags[key]

func get_story_flags() -> Dictionary:
	_ensure_profile_loaded()
	return _normalize_story_flags(profile.get("story_flags", {})).duplicate(true)

func _normalize_story_flags(raw_value) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}
	var flags: Dictionary = {}
	for key in raw_value.keys():
		flags[str(key)] = raw_value[key]
	return flags

func _ensure_save_dir() -> void:
	var dir_path: String = ProjectSettings.globalize_path(SAVE_DIR)
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

func _normalize_string_array(raw_value: Variant) -> Array:
	var items: Array = []
	if typeof(raw_value) != TYPE_ARRAY:
		return items

	for value in raw_value:
		var text: String = str(value).strip_edges()
		if not text.is_empty() and not items.has(text):
			items.append(text)

	return items

func _normalize_follow_up_history(raw_value: Variant) -> Dictionary:
	var history: Dictionary = {}
	if typeof(raw_value) != TYPE_DICTIONARY:
		return history

	for key in raw_value.keys():
		history[str(key)] = int(raw_value[key])

	return history

func _normalize_memories(raw_value: Variant) -> Array:
	var memories: Array = []
	if typeof(raw_value) != TYPE_ARRAY:
		return memories

	for raw_memory in raw_value:
		if typeof(raw_memory) != TYPE_DICTIONARY:
			continue

		memories.append({
			"id": str(raw_memory.get("id", _new_memory_id())),
			"fact": str(raw_memory.get("fact", "")),
			"topic": str(raw_memory.get("topic", "")),
			"type": str(raw_memory.get("type", "")),
			"confidence": float(raw_memory.get("confidence", 0.85)),
			"last_seen_at": str(raw_memory.get("last_seen_at", _now_iso())),
			"follow_up_tag": str(raw_memory.get("follow_up_tag", "")),
			"expires_in_days": float(raw_memory.get("expires_in_days", 7)),
			"source_message": str(raw_memory.get("source_message", ""))
		})

	return memories

func _prune_memory_cache() -> void:
	var memories: Array = _normalize_memories(profile.get("memories", []))
	if memories.size() > MAX_MEMORIES:
		memories = memories.slice(memories.size() - MAX_MEMORIES, memories.size())
	profile["memories"] = memories

func _prune_follow_up_history() -> void:
	var allowed_tags: Dictionary = {}
	for rule in FOLLOW_UP_RULES:
		allowed_tags[str(rule.tag)] = true

	var history: Dictionary = _normalize_follow_up_history(profile.get("follow_up_last_served_at", {}))
	for key in history.keys():
		if not allowed_tags.has(str(key)):
			history.erase(key)

	profile["follow_up_last_served_at"] = history

func _refresh_recent_summary() -> void:
	var facts: Array = _collect_recent_memory_facts(3)
	if facts.is_empty():
		profile["recent_summary"] = ""
		return

	profile["recent_summary"] = "Recent memory: " + "; ".join(facts)

func _rule_matches_text(rule: Dictionary, lower_text: String) -> bool:
	for keyword in rule.keywords:
		if lower_text.find(str(keyword)) != -1:
			return true

	return false

func _now_iso() -> String:
	return Time.get_datetime_string_from_system()

func _now_unix() -> int:
	return Time.get_unix_time_from_system()

func _new_memory_id() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var millis: int = Time.get_ticks_msec() % 1000
	var suffix: int = randi() % 1000
	return "mem_%04d%02d%02d_%02d%02d%02d_%03d_%03d" % [now.year, now.month, now.day, now.hour, now.minute, now.second, millis, suffix]
