extends Node

const SAVE_PATH := "user://data/saves/player_profile.json"
const TEMPLATE_SAVE_PATH := "res://data/saves/player_profile.json"
const SAVE_DIR := "user://data/saves"
# Pre-unification, main_scene wrote session/UI state to this separate file.
# We migrate it into the single profile once, then ignore it.
const LEGACY_MAIN_SAVE_PATH := "user://player_profile.json"
const PROFILE_VERSION := 2
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
# Set by _load_profile_from_disk when the on-disk profile could not be parsed.
# load_profile() copies it into profile["corrupted_save_recovery"] once loaded.
var pending_recovery_meta: Dictionary = {}

func load_profile() -> void:
	_ensure_save_dir()
	profile = _load_profile_from_disk()
	# If the on-disk profile was corrupt, _load_profile_from_disk backed it up and
	# returned a clean default. Record that so the rest of the game (and the owner)
	# can tell a recovery happened.
	if not pending_recovery_meta.is_empty():
		profile["corrupted_save_recovery"] = pending_recovery_meta
		pending_recovery_meta = {}
	# Migrate BEFORE normalize: normalize fills profile_version from defaults,
	# which would otherwise make the migration think it already ran.
	_migrate_legacy_main_save()
	_normalize_profile()
	profile["last_login_at"] = _now_iso()
	save_profile()

# --- Unified profile accessors (used by main_scene for session/UI state) ---

func get_profile() -> Dictionary:
	_ensure_profile_loaded()
	return profile.duplicate(true)

func get_value(key: String, default_value = null):
	_ensure_profile_loaded()
	if not profile.has(key):
		return default_value
	return profile[key]

func set_value(key: String, value) -> void:
	_ensure_profile_loaded()
	profile[key] = value

func merge_values(values: Dictionary) -> void:
	_ensure_profile_loaded()
	for key in values.keys():
		profile[str(key)] = values[key]

# One-time pull of legacy main_scene save fields into the single profile.
func _migrate_legacy_main_save() -> void:
	if int(profile.get("profile_version", 1)) >= PROFILE_VERSION:
		return
	if FileAccess.file_exists(LEGACY_MAIN_SAVE_PATH):
		var file: FileAccess = FileAccess.open(LEGACY_MAIN_SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				var legacy: Dictionary = parsed
				# Legacy file only holds session/UI keys, so merging is safe;
				# it never carries memories/story_flags that would clobber.
				for key in legacy.keys():
					profile[str(key)] = legacy[key]
	profile["profile_version"] = PROFILE_VERSION

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
	# The real user profile gets corruption recovery; the res:// template is a
	# read-only first-run seed, so a bad template is a dev error, not user data.
	if FileAccess.file_exists(SAVE_PATH):
		return _load_user_profile_with_recovery(SAVE_PATH)
	if FileAccess.file_exists(TEMPLATE_SAVE_PATH):
		return _load_profile_file(TEMPLATE_SAVE_PATH)
	return _build_default_profile()

func _load_user_profile_with_recovery(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		# An existing file we cannot open (locked/permissions). Don't destroy it;
		# start clean in memory but record that recovery happened.
		pending_recovery_meta = _make_recovery_meta(path, "open_failed", "")
		push_warning("memory_manager: could not open profile at %s; starting clean." % path)
		return _build_default_profile()

	var raw_text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	# Parse failure on the real user profile == corruption. Back up the bad bytes
	# under a timestamped name, then start a clean profile flagged for recovery so
	# the player never gets stuck on an unreadable save.
	var backup_path: String = _backup_corrupt_file(path, raw_text)
	pending_recovery_meta = _make_recovery_meta(path, "json_parse_failed", backup_path)
	push_warning("memory_manager: corrupt profile at %s backed up to %s; starting clean." % [path, backup_path])
	return _build_default_profile()

func _load_profile_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _build_default_profile()

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed

	return _build_default_profile()

func _backup_corrupt_file(path: String, raw_text: String) -> String:
	# path is e.g. user://data/saves/player_profile.json
	# -> user://data/saves/player_profile.corrupt-YYYYMMDD-HHMMSS.json
	var backup_path: String = "%s.corrupt-%s.json" % [path.get_basename(), _timestamp_slug()]
	var out: FileAccess = FileAccess.open(backup_path, FileAccess.WRITE)
	if out == null:
		return ""
	out.store_string(raw_text)
	out.close()
	return backup_path

func _make_recovery_meta(path: String, reason: String, backup_path: String) -> Dictionary:
	return {
		"recovered_at": _now_iso(),
		"reason": reason,
		"original_path": path,
		"backup_path": backup_path
	}

func _timestamp_slug() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d-%02d%02d%02d" % [now.year, now.month, now.day, now.hour, now.minute, now.second]

func _normalize_profile() -> void:
	var defaults: Dictionary = _build_default_profile()
	for key in defaults.keys():
		if not profile.has(key):
			profile[key] = defaults[key]

	profile["profile_version"] = int(profile.get("profile_version", PROFILE_VERSION))
	profile["last_login_at"] = str(profile.get("last_login_at", ""))
	profile["last_node_id"] = str(profile.get("last_node_id", "idle"))
	profile["recent_summary"] = str(profile.get("recent_summary", ""))
	profile["pending_follow_ups"] = _normalize_string_array(profile.get("pending_follow_ups", []))
	profile["follow_up_last_served_at"] = _normalize_follow_up_history(profile.get("follow_up_last_served_at", {}))
	profile["memories"] = _normalize_memories(profile.get("memories", []))
	profile["story_flags"] = _normalize_story_flags(profile.get("story_flags", {}))
	# --- Vertical Slice 01 progression / co-presence fields ---
	profile["last_seen_at"] = str(profile.get("last_seen_at", ""))
	profile["last_meaningful_interaction_at"] = str(profile.get("last_meaningful_interaction_at", ""))
	profile["return_count"] = int(profile.get("return_count", 0))
	profile["engaged_interaction_count"] = int(profile.get("engaged_interaction_count", 0))
	profile["engaged_time_seconds"] = int(profile.get("engaged_time_seconds", 0))
	profile["focus_started_count"] = int(profile.get("focus_started_count", 0))
	# Reconcile to the canonical name; migrate the legacy var spelling once.
	profile["completed_focus_count"] = int(profile.get("completed_focus_count", profile.get("completed_focus_sessions", 0)))
	profile["total_focus_seconds"] = int(profile.get("total_focus_seconds", 0))
	profile["current_story_milestone"] = str(profile.get("current_story_milestone", ""))
	profile["yua_openness"] = int(profile.get("yua_openness", 0))
	profile["player_nickname"] = str(profile.get("player_nickname", ""))
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
		"profile_version": PROFILE_VERSION,
		"last_login_at": "",
		"last_node_id": "idle",
		"pending_follow_ups": [],
		"follow_up_last_served_at": {},
		"recent_summary": "",
		"memories": [],
		"story_flags": {},
		# --- Vertical Slice 01 progression / co-presence fields ---
		"last_seen_at": "",
		"last_meaningful_interaction_at": "",
		"return_count": 0,
		"engaged_interaction_count": 0,
		"engaged_time_seconds": 0,
		"focus_started_count": 0,
		"completed_focus_count": 0,
		"total_focus_seconds": 0,
		"current_story_milestone": "",
		"yua_openness": 0,
		"player_nickname": ""
		# corrupted_save_recovery is intentionally absent here — it only appears
		# after a recovery actually happens (see _load_user_profile_with_recovery).
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

# --- Relationship / nickname accessors (domain save concepts) ---------------

func get_player_nickname() -> String:
	_ensure_profile_loaded()
	return str(profile.get("player_nickname", ""))

func set_player_nickname(nickname: String) -> void:
	_ensure_profile_loaded()
	profile["player_nickname"] = nickname.strip_edges()
	save_profile()

func get_yua_openness() -> int:
	_ensure_profile_loaded()
	return int(profile.get("yua_openness", 0))

func set_yua_openness(value: int) -> void:
	# Relationship progress is monotonic for the slice — it never regresses, and
	# (per the milestone contract) it is advanced ONLY by completed focus, never
	# by clicks or Type Mode. Callers enforce the focus-only rule.
	_ensure_profile_loaded()
	profile["yua_openness"] = maxi(int(profile.get("yua_openness", 0)), value)
	save_profile()

# True only when at least one real, game-validated memory exists. The memory-echo
# beat must consult this and stay silent otherwise — never fabricate a callback.
func has_valid_memory() -> bool:
	_ensure_profile_loaded()
	return _normalize_memories(profile.get("memories", [])).size() > 0

# The single most-recent validated memory fact to surface this turn, or "" if
# there is none. This is the ONLY memory the AI may echo (see AI_Context_Packet_Spec).
func get_surfaced_memory_fact() -> String:
	_ensure_profile_loaded()
	var facts: Array = _collect_recent_memory_facts(1)
	if facts.is_empty():
		return ""
	return str(facts[0])

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
