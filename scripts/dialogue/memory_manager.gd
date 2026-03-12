extends Node

const SAVE_PATH := "res://data/saves/player_profile.json"

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

func load_profile() -> void:
	_ensure_save_dir()
	if not FileAccess.file_exists(SAVE_PATH):
		profile = _build_default_profile()
		save_profile()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		profile = _build_default_profile()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		profile = parsed
	else:
		profile = _build_default_profile()

func save_profile() -> void:
	_ensure_save_dir()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(profile, "\t"))

func process_player_message(player_text: String) -> Array:
	var created_memories: Array = []
	var lower_text: String = player_text.to_lower()

	for rule in FOLLOW_UP_RULES:
		for keyword in rule.keywords:
			if lower_text.find(keyword) != -1:
				var memory: Dictionary = _build_memory_entry(player_text, rule)
				created_memories.append(memory)
				_add_memory(memory)
				_add_follow_up(memory.follow_up_tag)
				break

	if created_memories.size() > 0:
		save_profile()

	return created_memories

func consume_next_follow_up_line() -> String:
	var pending: Array = profile.get("pending_follow_ups", [])
	if pending.is_empty():
		return ""

	var tag: String = str(pending.pop_front())
	profile["pending_follow_ups"] = pending
	profile["last_login_at"] = _now_iso()
	save_profile()

	return _follow_up_line_for_tag(tag)

func get_memory_context(max_items: int = 5) -> String:
	var memories: Array = profile.get("memories", [])
	if memories.is_empty():
		return ""

	var start_index: int = maxi(0, memories.size() - max_items)
	var selected: Array = memories.slice(start_index, memories.size())
	var lines: Array = []
	for memory in selected:
		var fact: String = str(memory.get("fact", ""))
		if not fact.is_empty():
			lines.append("- " + fact)

	if lines.is_empty():
		return ""

	return "Memory summary:\n" + "\n".join(lines)

func _add_memory(memory: Dictionary) -> void:
	var memories: Array = profile.get("memories", [])
	memories.append(memory)
	profile["memories"] = memories

func _add_follow_up(tag: String) -> void:
	if tag.is_empty():
		return
	var pending: Array = profile.get("pending_follow_ups", [])
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

func _follow_up_line_for_tag(tag: String) -> String:
	match tag:
		"ask_about_school":
			return "Welcome back. How was school?"
		"ask_about_exam":
			return "Hey, how did your exam go?"
		"ask_about_sleep":
			return "Did you manage to get some rest?"
		"ask_about_work":
			return "How is work going today?"
		_:
			return ""

func _build_default_profile() -> Dictionary:
	return {
		"last_login_at": "",
		"last_node_id": "idle",
		"pending_follow_ups": [],
		"recent_summary": "",
		"memories": []
	}

func _ensure_save_dir() -> void:
	var dir_path: String = "res://data/saves"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

func _now_iso() -> String:
	return Time.get_datetime_string_from_system()

func _new_memory_id() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "mem_%04d%02d%02d_%02d%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]
