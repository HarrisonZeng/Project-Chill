extends Node2D

@onready var player: PlayerController = $Player
@onready var companion: Companion = $Companion
@onready var memory_system: MemorySystem = $MemorySystem
@onready var save_manager: SaveManager = $SaveManager
@onready var dialogue_panel: DialoguePanel = $HUD/DialoguePanel
@onready var status_label: Label = $HUD/StatusLabel


func _ready() -> void:
	_ensure_input_actions()
	companion.interaction_requested.connect(_on_companion_interaction_requested)
	dialogue_panel.message_submitted.connect(_on_dialogue_message_submitted)
	dialogue_panel.closed.connect(_on_dialogue_closed)
	_load_state()
	_refresh_status()


func _on_companion_interaction_requested() -> void:
	if dialogue_panel.is_open():
		return

	player.set_controls_enabled(false)
	companion.set_interaction_enabled(false)
	var opening_line := companion.get_opening_line(memory_system)
	dialogue_panel.open_dialogue(companion.companion_name, opening_line, memory_system.get_recent_topics(5))
	_refresh_status()


func _on_dialogue_message_submitted(player_message: String) -> void:
	dialogue_panel.add_message("You", player_message)
	memory_system.remember_text(player_message)
	var reply := companion.build_reply(player_message, memory_system)
	dialogue_panel.add_message(companion.companion_name, reply)
	dialogue_panel.set_memory_summary(memory_system.get_recent_topics(5))
	_save_state()
	_refresh_status()


func _on_dialogue_closed() -> void:
	player.set_controls_enabled(true)
	companion.set_interaction_enabled(true)
	_save_state()
	_refresh_status()


func _ensure_input_actions() -> void:
	var actions := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E]
	}

	for action_name in actions.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		for keycode in actions[action_name]:
			if _action_has_key(action_name, keycode):
				continue

			var event := InputEventKey.new()
			event.physical_keycode = keycode
			event.keycode = keycode
			InputMap.action_add_event(action_name, event)


func _action_has_key(action_name: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true

	return false


func _load_state() -> void:
	var data := save_manager.load_game()
	if data.is_empty():
		return

	var player_position_data: Variant = data.get("player_position", {})
	if typeof(player_position_data) == TYPE_DICTIONARY:
		player.global_position = Vector2(
			player_position_data.get("x", player.global_position.x),
			player_position_data.get("y", player.global_position.y)
		)

	var memory_data: Variant = data.get("memory", {})
	if typeof(memory_data) == TYPE_DICTIONARY:
		memory_system.load_from_dict(memory_data)


func _save_state() -> void:
	save_manager.save_game(player.global_position, memory_system.to_dict())


func _refresh_status() -> void:
	var instructions := "WASD or arrow keys to move. Press E near %s to talk." % companion.companion_name
	if dialogue_panel.is_open():
		instructions = "Dialogue open. Type a message, press Enter to send, or press Esc to close."

	var recent_topics := memory_system.get_recent_topics(3)
	var memory_summary := "Recent topics: none yet"
	if not recent_topics.is_empty():
		memory_summary = "Recent topics: %s" % ", ".join(recent_topics)

	status_label.text = "%s\n%s" % [instructions, memory_summary]
