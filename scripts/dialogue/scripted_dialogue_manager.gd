extends Node

class_name ScriptedDialogueManager

const DEFAULT_FALLBACK_ID := "idle"

var nodes_by_id: Dictionary = {}
var fallback_node_id: String = DEFAULT_FALLBACK_ID
var source_path: String = ""

func load_from_path(path: String) -> bool:
	source_path = path
	nodes_by_id.clear()

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
	nodes_by_id[node_id] = {
		"id": node_id,
		"line": str(node_data.get("line", "")),
		"choices": _sanitize_choices(node_data.get("choices", []))
	}

func _sanitize_choices(raw_choices: Variant) -> Array:
	var cleaned: Array = []
	if typeof(raw_choices) != TYPE_ARRAY:
		return cleaned
	for choice in raw_choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var text := str(choice.get("text", "Continue"))
		var next := str(choice.get("next", ""))
		cleaned.append({"text": text, "next": next})
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
