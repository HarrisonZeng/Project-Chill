extends Node

class_name SaveManager

const SAVE_PATH := "user://project_chill_save.json"


func save_game(player_position: Vector2, memory_state: Dictionary) -> void:
	var payload := {
		"player_position": {
			"x": player_position.x,
			"y": player_position.y
		},
		"memory": memory_state
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to open the save file for writing.")
		return

	file.store_string(JSON.stringify(payload, "  "))


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var json_text := FileAccess.get_file_as_string(SAVE_PATH)
	if json_text.is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save data exists but could not be parsed.")
		return {}

	return parsed
