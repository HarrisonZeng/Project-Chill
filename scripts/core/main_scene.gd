extends Control

const FOCUS_DURATION_SECONDS: float = 25.0 * 60.0
const SAVE_PATH := "user://player_profile.json"
const FOCUS_COMPLETE_LINE := "Focus block complete. Nice work."
const PERSONA_PATH := "res://data/dialogue/yua_system_prompt.txt"
const RUNTIME_RULES_PATH := "res://data/dialogue/yua_runtime_rules.txt"
const DEFAULT_MODE_CONTEXT := "Scene type: short return-after-task check-in\nReply briefly in 1-3 sentences\nYua should sound gently curious and reserved\nThis is a small side conversation and should return to the main flow soon"

@onready var dialogue_text: RichTextLabel = $BottomPanel/DialoguePanel/Margin/VBox/DialogueCard/DialogueMargin/DialogueText
@onready var choice_list: VBoxContainer = $BottomPanel/DialoguePanel/Margin/VBox/ChoiceList
@onready var player_input: LineEdit = $BottomPanel/DialoguePanel/Margin/VBox/InputRow/PlayerInput
@onready var ai_mode_toggle: CheckButton = $BottomPanel/DialoguePanel/Margin/VBox/InputRow/AIModeToggle
@onready var timer_label: Label = $RightTimerPanel/TimerMargin/TimerVBox/TimerLabel
@onready var timer_minutes_input: LineEdit = $RightTimerPanel/TimerMargin/TimerVBox/TimerInputRow/TimerMinutesInput
@onready var set_timer_button: Button = $RightTimerPanel/TimerMargin/TimerVBox/TimerInputRow/SetTimerButton
@onready var todo_list: ItemList = $RightTodoPanel/TodoMargin/TodoVBox/TodoList
@onready var edit_todo_button: Button = $RightTodoPanel/TodoMargin/TodoVBox/TodoButtons/EditTodoButton
@onready var date_label: Label = $TopLeftHUD/Margin/VBox/DateLabel
@onready var time_label: Label = $TopLeftHUD/Margin/VBox/TimeLabel
@onready var music_song_label: Label = $BottomLeftMusicBar/MusicMargin/MusicVBox/TopRow/SongLabel
@onready var music_progress_bar: ProgressBar = $BottomLeftMusicBar/MusicMargin/MusicVBox/ProgressBar
@onready var music_prev_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/TopRow/Controls/PrevButton
@onready var music_play_pause_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/TopRow/Controls/PlayPauseButton
@onready var music_next_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/TopRow/Controls/NextButton
@onready var voice_manager: Node = get_node_or_null("VoiceManager")
@onready var bgm_manager: Node = get_node_or_null("BgmManager")

@onready var scripted_dialogue_manager: ScriptedDialogueManager = ScriptedDialogueManager.new()

var current_node_id: String = "idle"
var focus_duration_seconds: float = FOCUS_DURATION_SECONDS
var focus_time_left: float = FOCUS_DURATION_SECONDS
var focus_running: bool = false
var focus_last_tick_ms: int = 0
var last_saved_second: int = -1
var bgm_paused: bool = true

var memory_manager: Node
var ai_dialogue_service: Node
var dialogue_router: Node
var persona_text: String = ""
var runtime_rules_text: String = ""

func _ready() -> void:
	_wire_signals()
	_load_persistent_state()
	_load_prompt_assets()
	if todo_list.item_count == 0:
		_seed_todo_items()
	_update_datetime_labels()
	_update_timer_label()
	add_child(scripted_dialogue_manager)
	scripted_dialogue_manager.load_from_path("res://data/dialogue/scripted_nodes.json")
	if not scripted_dialogue_manager.has_dialogue_node(current_node_id):
		current_node_id = "idle"
	_setup_dialogue_services()
	_show_node(current_node_id)
	_maybe_show_follow_up()
	_start_bgm_if_available()
	_refresh_music_bar()

func _process(delta: float) -> void:
	_update_focus_timer()
	_maybe_autosave()
	_update_music_progress()

func _load_prompt_assets() -> void:
	persona_text = _load_text_file(PERSONA_PATH)
	runtime_rules_text = _load_text_file(RUNTIME_RULES_PATH)

func _load_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content

func _setup_dialogue_services() -> void:
	memory_manager = preload("res://scripts/dialogue/memory_manager.gd").new()
	add_child(memory_manager)
	memory_manager.load_profile()

	ai_dialogue_service = preload("res://scripts/dialogue/ai_dialogue_service.gd").new()
	ai_dialogue_service.use_poe_provider("minimax-m2.5")
	add_child(ai_dialogue_service)

	dialogue_router = preload("res://scripts/core/dialogue_router.gd").new()
	dialogue_router.set_ai_service(ai_dialogue_service)
	add_child(dialogue_router)

func _maybe_show_follow_up() -> void:
	var follow_up_line: String = memory_manager.consume_next_follow_up_line()
	if follow_up_line.is_empty():
		return

	current_node_id = "follow_up"
	dialogue_text.text = follow_up_line
	_render_choices([
		{"text": "Continue", "next": "greeting_01"}
	])
	_play_voice_for_line("follow_up", dialogue_text.text)

func _wire_signals() -> void:
	$CompanionStage/CompanionView/CharacterClickArea.pressed.connect(_on_character_clicked)
	$BottomPanel/DialoguePanel/Margin/VBox/InputRow/SendButton.pressed.connect(_on_send_pressed)
	player_input.text_submitted.connect(_on_input_submitted)
	$RightTimerPanel/TimerMargin/TimerVBox/StartFocusButton.pressed.connect(_on_start_focus_pressed)
	$RightTimerPanel/TimerMargin/TimerVBox/StopFocusButton.pressed.connect(_on_stop_focus_pressed)
	set_timer_button.pressed.connect(_on_set_timer_pressed)
	timer_minutes_input.text_submitted.connect(_on_timer_minutes_submitted)
	$RightTodoPanel/TodoMargin/TodoVBox/TodoButtons/AddTodoButton.pressed.connect(_on_add_todo_pressed)
	edit_todo_button.pressed.connect(_on_edit_todo_pressed)
	todo_list.item_activated.connect(_on_todo_item_activated)
	music_prev_button.pressed.connect(_on_bgm_prev_pressed)
	music_play_pause_button.pressed.connect(_on_bgm_play_pause_pressed)
	music_next_button.pressed.connect(_on_bgm_next_pressed)
	music_progress_bar.gui_input.connect(_on_music_progress_input)

func _seed_todo_items() -> void:
	_add_todo_item("Set up background art")
	_add_todo_item("Import character image")
	_add_todo_item("Write 5 scripted greeting branches")

func _update_datetime_labels() -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	date_label.text = "%04d/%02d/%02d" % [now.year, now.month, now.day]
	time_label.text = "%02d:%02d" % [now.hour, now.minute]

func _show_node(node_id: String) -> void:
	current_node_id = node_id
	var node_data: Dictionary = scripted_dialogue_manager.get_dialogue_node(node_id)
	_show_node_data(node_data)

func _show_node_data(node_data: Dictionary) -> void:
	if node_data.is_empty():
		dialogue_text.text = "Dialogue error: missing node data."
		_render_choices([])
		return

	current_node_id = str(node_data.get("id", current_node_id))
	var line_text := str(node_data.get("line", ""))
	dialogue_text.text = line_text
	_render_choices(node_data.get("choices", []))
	_play_voice_for_line(current_node_id, line_text)

func _render_choices(choices: Array) -> void:
	for child in choice_list.get_children():
		child.queue_free()

	for choice in choices:
		var choice_button := Button.new()
		choice_button.text = str(choice.get("text", "Continue"))
		choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice_button.pressed.connect(_on_choice_selected.bind(str(choice.get("next", "greeting_01"))))
		choice_list.add_child(choice_button)

func _on_character_clicked() -> void:
	if current_node_id == "idle":
		_show_node("greeting_01")
		return

	dialogue_text.text = "I am here. You can pick a response below or type in AI mode."
	_play_voice_for_line("prompt_pick_response", dialogue_text.text)

func _on_choice_selected(next_node_id: String) -> void:
	if next_node_id.begins_with("AI_MODE_"):
		_handle_ai_mode_choice(next_node_id)
		return
	if not scripted_dialogue_manager.validate_choice_transition(current_node_id, next_node_id):
		var error_node := scripted_dialogue_manager.make_transition_error_node(current_node_id, next_node_id)
		_show_node_data(error_node)
		return
	_show_node(next_node_id)

func _handle_ai_mode_choice(mode_id: String) -> void:
	if not ai_mode_toggle.button_pressed:
		ai_mode_toggle.button_pressed = true
	dialogue_text.text = "AI mode: type your response below."
	_render_choices([
		{"text": "Back to scripted choices", "next": "greeting_01"}
	])

func _on_send_pressed() -> void:
	_handle_player_text(player_input.text)

func _on_input_submitted(submitted_text: String) -> void:
	_handle_player_text(submitted_text)

func _handle_player_text(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	if text.is_empty():
		return

	player_input.clear()

	if ai_mode_toggle.button_pressed:
		dialogue_text.text = "Thinking..."
		memory_manager.process_player_message(text)
		var memory_context: String = memory_manager.get_memory_context()
		var mode_context := _get_mode_context_for_node(current_node_id)
		var route: Dictionary = await dialogue_router.route_player_text_async(
			text,
			true,
			memory_context,
			persona_text,
			runtime_rules_text,
			mode_context,
			current_node_id
		)
		_handle_ai_route(route)
		return

	dialogue_text.text = "Scripted mode is active. Use response buttons or toggle AI mode for free text."
	_play_voice_for_line("scripted_mode_hint", dialogue_text.text)

func _get_mode_context_for_node(node_id: String) -> String:
	match node_id:
		"AI_MODE_SHORT_GREETING":
			return "Scene type: short greeting\nReply briefly in 1-3 sentences\nYua should sound gentle and slightly reserved\nThis is a small side conversation and should return to the main flow soon"
		"AI_MODE_SHORT_CHECKIN":
			return "Scene type: short return-after-task check-in\nReply briefly in 1-3 sentences\nYua should sound gently curious and reserved\nThis is a small side conversation and should return to the main flow soon"
		"AI_MODE_SHORT_STRESS":
			return "Scene type: brief stress check-in\nReply briefly in 1-3 sentences\nYua should offer comfort plus light encouragement\nDo not overanalyze\nKeep the emotional depth light and safe"
		"AI_MODE_SHORT_COMFORT":
			return "Scene type: brief comfort scene\nReply briefly in 1-3 sentences\nYua should offer comfort plus light encouragement\nDo not overanalyze\nKeep the emotional depth light and safe"
		"AI_MODE_SHORT_PLAYFUL":
			return "Scene type: light playful exchange\nReply briefly in 1-3 sentences\nYua can tease gently, but stay subtle and warm\nDo not become overly flirty\nReturn to the main flow soon"
		"AI_MODE_MEMORY_FOLLOWUP":
			return "Scene type: memory follow-up\nReply briefly in 1-3 sentences\nUse memory naturally and indirectly\nDo not repeat the memory too many times\nKeep the tone soft and low-pressure"
		_:
			return DEFAULT_MODE_CONTEXT

func _handle_ai_route(route: Dictionary) -> void:
	dialogue_text.text = str(route.get("text", ""))
	_render_choices([
		{"text": "Back to scripted choices", "next": "greeting_01"},
		{"text": "Try another AI reply", "next": current_node_id}
	])
	_play_voice_for_line("ai_response", dialogue_text.text)

func _on_start_focus_pressed() -> void:
	focus_running = true
	if focus_time_left <= 0.0:
		focus_time_left = focus_duration_seconds
	focus_last_tick_ms = Time.get_ticks_msec()
	_update_timer_label()
	dialogue_text.text = "Focus timer started: %s." % _format_time_label(focus_time_left)
	_save_persistent_state()

func _on_stop_focus_pressed() -> void:
	focus_running = false
	focus_time_left = focus_duration_seconds
	_update_timer_label()
	dialogue_text.text = "Focus timer reset."
	_save_persistent_state()

func _on_set_timer_pressed() -> void:
	var minutes := _parse_minutes_input()
	if minutes <= 0:
		dialogue_text.text = "Enter a number of minutes (ex: 15), then press Set."
		return

	focus_duration_seconds = float(minutes) * 60.0
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	_update_timer_label()
	dialogue_text.text = "Timer set to %d minutes." % minutes
	_save_persistent_state()

func _on_timer_minutes_submitted(submitted_text: String) -> void:
	_on_set_timer_pressed()

func _update_timer_label() -> void:
	var rounded_seconds := maxi(0, int(ceil(focus_time_left)))
	var minutes := rounded_seconds / 60
	var seconds := rounded_seconds % 60
	timer_label.text = "Focus %02d:%02d" % [minutes, seconds]

func _format_time_label(seconds_left: float) -> String:
	var rounded_seconds := maxi(0, int(ceil(seconds_left)))
	var minutes := rounded_seconds / 60
	var seconds := rounded_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _parse_minutes_input() -> int:
	var text := timer_minutes_input.text.strip_edges()
	if text.is_empty():
		return -1
	if not text.is_valid_int():
		return -1
	return int(text)

func _on_add_todo_pressed() -> void:
	var todo_text := player_input.text.strip_edges()
	if todo_text.is_empty():
		dialogue_text.text = "Type a task in the text box, then press Add."
		return

	_add_todo_item(todo_text)
	player_input.clear()
	dialogue_text.text = "Added todo: " + todo_text
	_save_persistent_state()

func _on_edit_todo_pressed() -> void:
	var selected := todo_list.get_selected_items()
	if selected.is_empty():
		dialogue_text.text = "Select a todo, type the new text, then press Edit."
		return

	var new_text := player_input.text.strip_edges()
	if new_text.is_empty():
		dialogue_text.text = "Type the updated todo text before pressing Edit."
		return

	var index := int(selected[0])
	var data := _get_todo_data(index)
	data.text = new_text
	todo_list.set_item_metadata(index, data)
	todo_list.set_item_text(index, _format_todo_text(new_text, bool(data.get("completed", false))))
	if bool(data.get("completed", false)):
		todo_list.set_item_custom_fg_color(index, Color(0.4, 0.8, 0.5))
	dialogue_text.text = "Updated todo."
	_save_persistent_state()

func _on_todo_item_activated(index: int) -> void:
	if index < 0 or index >= todo_list.item_count:
		return

	var data := _get_todo_data(index)
	if data.get("completed", false):
		todo_list.remove_item(index)
		dialogue_text.text = "Removed completed todo."
	else:
		data.completed = true
		todo_list.set_item_metadata(index, data)
		todo_list.set_item_text(index, _format_todo_text(str(data.get("text", "")), true))
		todo_list.set_item_custom_fg_color(index, Color(0.4, 0.8, 0.5))
		dialogue_text.text = "Marked todo complete."

	_save_persistent_state()

func _add_todo_item(text: String, completed: bool = false) -> void:
	var display_text := _format_todo_text(text, completed)
	var index := todo_list.add_item(display_text)
	var data := {"text": text, "completed": completed}
	todo_list.set_item_metadata(index, data)
	if completed:
		todo_list.set_item_custom_fg_color(index, Color(0.4, 0.8, 0.5))

func _format_todo_text(text: String, completed: bool) -> String:
	if completed:
		return "[Done] " + text
	return text

func _get_todo_data(index: int) -> Dictionary:
	var data: Dictionary = todo_list.get_item_metadata(index)
	if data.is_empty():
		data = {"text": todo_list.get_item_text(index), "completed": false}
	return data

func _update_focus_timer() -> void:
	if not focus_running:
		return

	var now_ms := Time.get_ticks_msec()
	if focus_last_tick_ms == 0:
		focus_last_tick_ms = now_ms
	var elapsed_ms: int = maxi(0, now_ms - focus_last_tick_ms)
	focus_last_tick_ms = now_ms
	focus_time_left -= float(elapsed_ms) / 1000.0

	if focus_time_left <= 0.0:
		focus_time_left = 0.0
		focus_running = false
		dialogue_text.text = FOCUS_COMPLETE_LINE
		_save_persistent_state()

	_update_timer_label()

func _safe_node_id() -> String:
	if scripted_dialogue_manager != null and scripted_dialogue_manager.has_dialogue_node(current_node_id):
		return current_node_id
	return "idle"

func _maybe_autosave() -> void:
	var current_second := int(focus_time_left)
	if focus_running and current_second != last_saved_second:
		last_saved_second = current_second
		_save_persistent_state()

func _save_persistent_state() -> void:
	var todo_payload: Array = []
	for index in range(todo_list.item_count):
		var item_data: Dictionary = todo_list.get_item_metadata(index)
		if item_data.is_empty():
			item_data = {"text": todo_list.get_item_text(index), "completed": false}
		todo_payload.append(item_data)

	var payload := {
		"focus_time_left": focus_time_left,
		"focus_duration_seconds": focus_duration_seconds,
		"focus_running": focus_running,
		"todos": todo_payload,
		"last_node_id": _safe_node_id()
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func _load_persistent_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	file.close()

	var parse_result: Variant = JSON.parse_string(content)
	if typeof(parse_result) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parse_result
	focus_duration_seconds = float(data.get("focus_duration_seconds", FOCUS_DURATION_SECONDS))
	focus_time_left = float(data.get("focus_time_left", focus_duration_seconds))
	focus_running = bool(data.get("focus_running", false))
	current_node_id = str(data.get("last_node_id", "idle"))
	focus_last_tick_ms = Time.get_ticks_msec()

	todo_list.clear()
	for todo in data.get("todos", []):
		var todo_data: Dictionary = todo
		_add_todo_item(str(todo_data.get("text", "")), bool(todo_data.get("completed", false)))

func _play_voice_for_line(line_id: String, text: String) -> void:
	if voice_manager == null:
		return

	if voice_manager.has_method("play_voice_for_line"):
		voice_manager.call("play_voice_for_line", line_id, text)

func _start_bgm_if_available() -> void:
	if bgm_manager == null:
		return
	bgm_paused = true

func _on_bgm_prev_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_previous"):
		bgm_manager.call("play_previous")
		bgm_paused = false
		_refresh_music_bar()

func _on_bgm_next_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_next"):
		bgm_manager.call("play_next")
		bgm_paused = false
		_refresh_music_bar()

func _on_bgm_play_pause_pressed() -> void:
	if bgm_manager == null:
		return

	var has_stream := false
	if bgm_manager.has_method("has_stream"):
		has_stream = bool(bgm_manager.call("has_stream"))

	if not has_stream:
		if bgm_manager.has_method("play_default"):
			bgm_manager.call("play_default")
		bgm_paused = false
		_refresh_music_bar()
		return

	if bgm_paused:
		if bgm_manager.has_method("resume_bgm"):
			bgm_manager.call("resume_bgm")
		bgm_paused = false
	else:
		if bgm_manager.has_method("pause_bgm"):
			bgm_manager.call("pause_bgm")
		bgm_paused = true

	_refresh_music_bar()

func _refresh_music_bar() -> void:
	if music_song_label == null or music_progress_bar == null:
		return

	var song_name := "No track loaded"
	if bgm_manager != null and bgm_manager.has_method("get_now_playing_name"):
		song_name = str(bgm_manager.call("get_now_playing_name"))

	music_song_label.text = song_name
	var is_playing := false
	if bgm_manager != null and bgm_manager.has_method("is_playing"):
		is_playing = bool(bgm_manager.call("is_playing"))
	bgm_paused = not is_playing
	music_play_pause_button.text = "Play" if bgm_paused else "Pause"

func _update_music_progress() -> void:
	if bgm_manager == null or music_progress_bar == null:
		return
	if not bgm_manager.has_method("get_stream_length"):
		return
	var length := float(bgm_manager.call("get_stream_length"))
	if length <= 0.0:
		music_progress_bar.value = 0.0
		return
	var position := float(bgm_manager.call("get_playback_position"))
	music_progress_bar.value = clampf((position / length) * 100.0, 0.0, 100.0)

func _on_music_progress_input(event: InputEvent) -> void:
	if bgm_manager == null:
		return
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if not bgm_manager.has_method("get_stream_length") or not bgm_manager.has_method("seek_to_position"):
		return
	var length := float(bgm_manager.call("get_stream_length"))
	if length <= 0.0:
		return
	var bar_width := music_progress_bar.size.x
	if bar_width <= 0.0:
		return
	var percent := clampf(mouse_event.position.x / bar_width, 0.0, 1.0)
	bgm_manager.call("seek_to_position", length * percent)
	_update_music_progress()
