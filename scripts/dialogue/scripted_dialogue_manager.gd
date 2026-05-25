extends Node

class_name ScriptedDialogueManager

const DEFAULT_FALLBACK_ID := "idle"
const METADATA_KEYS: PackedStringArray = [
	"intro_node",
	"demo_script_version",
	"episodes"
]

var nodes_by_id: Dictionary = {}
var metadata: Dictionary = {}
var fallback_node_id: String = DEFAULT_FALLBACK_ID
var source_path: String = ""

func load_from_path(path: String) -> bool:
	source_path = path
	nodes_by_id.clear()
	metadata.clear()

	if not FileAccess.file_exists(path):
		push_error("ScriptedDialogueManager: Missing dialogue file at %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ScriptedDialogueManager: Unable to open %s" % path)
		return false

	var raw_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ScriptedDialogueManager: Invalid JSON root in %s" % path)
		return false

	_ingest_nodes(parsed)
	if nodes_by_id.is_empty():
		push_warning("ScriptedDialogueManager: No nodes loaded from %s" % path)
		return false

	if not nodes_by_id.has(fallback_node_id):
		var first_id: String = str(nodes_by_id.keys()[0])
		push_warning("ScriptedDialogueManager: Fallback id '%s' missing. Using '%s'." % [fallback_node_id, first_id])
		fallback_node_id = first_id

	return true

func has_dialogue_node(node_id: String) -> bool:
	return nodes_by_id.has(node_id)

func get_dialogue_node(node_id: String) -> Dictionary:
	if nodes_by_id.has(node_id):
		return nodes_by_id[node_id].duplicate(true)
	return _make_missing_node(node_id)

func validate_choice_transition(from_id: String, next_id: String) -> bool:
	if not nodes_by_id.has(from_id):
		push_warning("ScriptedDialogueManager: Missing from-node '%s' for transition." % from_id)
		return false

	if not _choice_exists(from_id, next_id):
		push_warning("ScriptedDialogueManager: Transition '%s' -> '%s' not found in choices." % [from_id, next_id])
		return false

	if not nodes_by_id.has(next_id):
		push_warning("ScriptedDialogueManager: Transition target '%s' is missing." % next_id)
		return false

	return true

func has_metadata(key: String) -> bool:
	return metadata.has(key)

func get_metadata(key: String, default_value = null):
	if not metadata.has(key):
		return default_value
	return metadata[key]

func make_transition_error_node(from_id: String, next_id: String) -> Dictionary:
	var fallback := _resolve_fallback_id()
	var choices: Array = []
	if fallback != "":
		choices.append({"text": "Back to safety", "next": fallback})
	return {
		"id": "_error_transition",
		"line": "Dialogue error: cannot go from '%s' to '%s'. Returning to a safe node." % [from_id, next_id],
		"choices": choices
	}

func _ingest_nodes(root: Dictionary) -> void:
	if root.has("fallback_id"):
		fallback_node_id = str(root.get("fallback_id"))

	for key in METADATA_KEYS:
		if root.has(key):
			metadata[key] = root[key]

	if root.has("nodes"):
		var nodes_data: Variant = root.get("nodes")
		if typeof(nodes_data) == TYPE_ARRAY:
			for node in nodes_data:
				_register_node(node)
		elif typeof(nodes_data) == TYPE_DICTIONARY:
			for node_id in nodes_data.keys():
				var node_entry: Variant = nodes_data[node_id]
				if typeof(node_entry) == TYPE_DICTIONARY:
					var with_id: Dictionary = (node_entry as Dictionary).duplicate(true)
					with_id["id"] = str(node_id)
					_register_node(with_id)
	else:
		for node_id in root.keys():
			var node_entry: Variant = root[node_id]
			if typeof(node_entry) == TYPE_DICTIONARY:
				var with_id: Dictionary = (node_entry as Dictionary).duplicate(true)
				with_id["id"] = str(node_id)
				_register_node(with_id)

func _register_node(node_data: Variant) -> void:
	if typeof(node_data) != TYPE_DICTIONARY:
		return
	var node_id := str(node_data.get("id", ""))
	if node_id.is_empty():
		return
	# Preserve milestone metadata (speaker/tags/set_flags/unlock) alongside the
	# original id/line/choices behavior. Without this, JSON-authored gate metadata
	# (e.g. ep00_close set_flags ["intro_seen"], Ep1 payoff unlock) is dropped and
	# the progression gate has nothing to read. See docs/Milestone_Contract_VS01.md.
	nodes_by_id[node_id] = {
		"id": node_id,
		"line": str(node_data.get("line", "")),
		"choices": _sanitize_choices(node_data.get("choices", [])),
		"speaker": str(node_data.get("speaker", "")),
		"tags": _sanitize_tags(node_data.get("tags", [])),
		"set_flags": _sanitize_set_flags(node_data.get("set_flags", {})),
		"unlock": _sanitize_unlock(node_data.get("unlock", {}))
	}

func _sanitize_tags(raw_tags: Variant) -> Array:
	var cleaned: Array = []
	if typeof(raw_tags) != TYPE_ARRAY:
		return cleaned
	for tag in raw_tags:
		var text := str(tag).strip_edges()
		if not text.is_empty() and not cleaned.has(text):
			cleaned.append(text)
	return cleaned

func _sanitize_set_flags(raw_flags: Variant) -> Dictionary:
	# Accept either ["flag_a", "flag_b"] (each set to true) or {"flag_a": value}.
	# Normalizes to one shape — a Dictionary of flag_name -> value — so the
	# coordinator can apply node-level flags without re-checking the JSON form.
	var cleaned: Dictionary = {}
	if typeof(raw_flags) == TYPE_ARRAY:
		for flag in raw_flags:
			var key := str(flag).strip_edges()
			if not key.is_empty():
				cleaned[key] = true
	elif typeof(raw_flags) == TYPE_DICTIONARY:
		for key in raw_flags.keys():
			var key_str := str(key).strip_edges()
			if not key_str.is_empty():
				cleaned[key_str] = raw_flags[key]
	return cleaned

func _sanitize_unlock(raw_unlock: Variant) -> Dictionary:
	var cleaned: Dictionary = {}
	if typeof(raw_unlock) != TYPE_DICTIONARY:
		return cleaned
	for key in raw_unlock.keys():
		cleaned[str(key)] = raw_unlock[key]
	return cleaned

func _sanitize_choices(raw_choices: Variant) -> Array:
	var cleaned: Array = []
	if typeof(raw_choices) != TYPE_ARRAY:
		return cleaned
	for choice in raw_choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var text := str(choice.get("text", "Continue"))
		var next := str(choice.get("next", ""))
		var entry: Dictionary = {"text": text, "next": next}
		var set_flag_value = choice.get("set_flag", null)
		if typeof(set_flag_value) == TYPE_DICTIONARY:
			entry["set_flag"] = set_flag_value.duplicate(true)
		cleaned.append(entry)
	return cleaned

func _choice_exists(from_id: String, next_id: String) -> bool:
	var node_data: Variant = nodes_by_id.get(from_id, null)
	if typeof(node_data) != TYPE_DICTIONARY:
		return false
	var choices: Array = node_data.get("choices", [])
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		if str(choice.get("next", "")) == next_id:
			return true
	return false

func _make_missing_node(node_id: String) -> Dictionary:
	var fallback := _resolve_fallback_id()
	var choices: Array = []
	if fallback != "":
		choices.append({"text": "Back to safety", "next": fallback})
	return {
		"id": "_missing_node",
		"line": "Dialogue error: missing node '%s'. Returning to a safe node." % node_id,
		"choices": choices
	}

func _resolve_fallback_id() -> String:
	if nodes_by_id.has(fallback_node_id):
		return fallback_node_id
	if nodes_by_id.is_empty():
		return ""
	return str(nodes_by_id.keys()[0])
