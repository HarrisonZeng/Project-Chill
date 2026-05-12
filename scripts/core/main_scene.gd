extends Control

const FOCUS_DURATION_SECONDS: float = 25.0 * 60.0
const SAVE_PATH := "user://player_profile.json"
const LOOP_VIDEO_PATH := "res://assets/video/yua_idle_loop.ogv"
const FOCUS_COMPLETE_LINE := "Focus block complete. Nice work."
const PERSONA_PATH := "res://data/dialogue/yua_system_prompt.txt"
const RUNTIME_RULES_PATH := "res://data/dialogue/yua_runtime_rules.txt"
const DEFAULT_MODE_CONTEXT := "Scene type: short return-after-task check-in\nReply briefly in 1-3 sentences\nYua should sound gently curious and reserved\nThis is a small side conversation and should return to the main flow soon"
const INPUT_PLACEHOLDER_TEXT := "Type a reply or a todo"
const TYPE_INPUT_PLACEHOLDER_TEXT := "Type your reply in your own words"
const TIMER_INPUT_PLACEHOLDER_TEXT := "15"
const FOCUS_START_LINE := "Focus timer started. Let's keep it gentle."
const FOCUS_STOP_LINE := "Focus timer paused. We can breathe for a moment."
const FOCUS_SET_LINE := "Timer set. I'll keep you company for that block."
const TODO_ADD_LINE := "Added to the list. One small step at a time."
const TODO_EDIT_LINE := "Updated the todo. That feels cleaner now."
const TODO_COMPLETE_LINE := "Marked it done. Nice work."
const DEFAULT_RETURN_CHOICE_TEXT := "Stay a little longer."
const DEMO_SCRIPT_VERSION := 1
const FOCUS_CLICK_LINES: PackedStringArray = [
	"还差一会儿，再撑一下。",
	"我也在。",
	"别看我，去看你的屏幕。",
	"……你是分心了还是确认我在？好，我在。",
	"快了快了，时间真的在走的。",
	"先别想别的事，那个等一会儿再说。",
	"中间分心是正常的，回来就行。",
	"不用做完，先往前推一点。",
	"我假装没看见你点我。你继续。",
	"来都来了，再做一小块。",
	"好的，我知道你需要一点陪伴。行，但你还是要继续。",
	"计时器没停，你也别停。",
	"坐着不动也行，但眼睛看屏幕。",
	"很好，你还在。",
	"……点我干嘛。算了，你继续吧。"
]

@onready var dialogue_text: RichTextLabel = $BottomPanel/DialoguePanel/Margin/VBox/DialogueCard/DialogueMargin/DialogueText
@onready var dialogue_card: PanelContainer = $BottomPanel/DialoguePanel/Margin/VBox/DialogueCard
@onready var choice_list: GridContainer = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/ChoiceList
@onready var player_input: LineEdit = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/PlayerInput
@onready var ai_mode_toggle: CheckButton = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/AIModeToggle
@onready var status_label: Label = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/StatusLabel
@onready var background_node: CanvasItem = $Background
@onready var companion_stage: CanvasItem = $CompanionStage
@onready var video_stage: Control = $VideoStage
@onready var video_player: VideoStreamPlayer = $VideoStage/VideoPlayer
@onready var timer_label: Label = $RightTimerPanel/TimerMargin/TimerVBox/TimerLabel
@onready var timer_minutes_input: LineEdit = $RightTimerPanel/TimerMargin/TimerVBox/TimerInputRow/TimerMinutesInput
@onready var set_timer_button: Button = $RightTimerPanel/TimerMargin/TimerVBox/TimerInputRow/SetTimerButton
@onready var todo_list: ItemList = $RightTodoPanel/TodoMargin/TodoVBox/TodoList
@onready var edit_todo_button: Button = $RightTodoPanel/TodoMargin/TodoVBox/TodoButtons/EditTodoButton
@onready var date_label: Label = $TopLeftHUD/Margin/VBox/DateLabel
@onready var time_label: Label = $TopLeftHUD/Margin/VBox/TimeLabel
@onready var weather_label: Label = $TopLeftHUD/Margin/VBox/WeatherLabel
@onready var music_song_label: Label = $BottomLeftMusicBar/MusicMargin/MusicVBox/SongLabel
@onready var music_progress_bar: ProgressBar = $BottomLeftMusicBar/MusicMargin/MusicVBox/ProgressBar
@onready var music_prev_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PrevButton
@onready var music_play_pause_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PlayPauseButton
@onready var music_next_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/NextButton
@onready var music_voice_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/VoiceButton
@onready var music_mode_button: OptionButton = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PlaybackModeButton
@onready var start_focus_button: Button = $RightTimerPanel/TimerMargin/TimerVBox/StartFocusButton
@onready var stop_focus_button: Button = $RightTimerPanel/TimerMargin/TimerVBox/StopFocusButton
@onready var add_todo_button: Button = $RightTodoPanel/TodoMargin/TodoVBox/TodoButtons/AddTodoButton
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
var saved_music_index: int = 0
var saved_music_paused: bool = true
var saved_music_playback_mode: int = 0
var voice_enabled: bool = true

var memory_manager: Node
var ai_dialogue_service: Node
var dialogue_router: Node
var persona_text: String = ""
var runtime_rules_text: String = ""
var current_ai_mode_id: String = ""
var ai_return_node_id: String = "greeting_01"
var has_seen_intro: bool = false
var demo_script_version_seen: int = 0
var completed_focus_sessions: int = 0
var current_focus_task: String = ""
var focus_click_count: int = 0

func _ready() -> void:
	_wire_signals()
	_configure_visual_mode()
	_configure_companion_controls()
	_load_persistent_state()
	_refresh_voice_button()
	_refresh_music_mode_button()
	_load_prompt_assets()
	if todo_list.item_count == 0:
		_seed_todo_items()
	_update_datetime_labels()
	_update_timer_label()
	add_child(scripted_dialogue_manager)
	scripted_dialogue_manager.load_from_path("res://data/dialogue/scripted_nodes.json")
	if not scripted_dialogue_manager.has_dialogue_node(current_node_id):
		current_node_id = "idle"
	current_node_id = _resolve_start_node_id()
	ai_return_node_id = _safe_node_id()
	_setup_dialogue_services()
	_show_node(current_node_id)
	_maybe_show_follow_up()
	_start_bgm_if_available()
	_refresh_music_bar()
	_refresh_focus_controls()
	_refresh_todo_controls()

func _process(_delta: float) -> void:
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
	add_child(ai_dialogue_service)
	var poe_api_key := OS.get_environment("POE_API_KEY")
	if poe_api_key.is_empty():
		ai_dialogue_service.use_mock_provider()
	else:
		ai_dialogue_service.use_chat_completion_provider(poe_api_key, "minimax-m2.5")

	dialogue_router = preload("res://scripts/core/dialogue_router.gd").new()
	dialogue_router.set_ai_service(ai_dialogue_service)
	add_child(dialogue_router)

func _maybe_show_follow_up() -> void:
	if current_node_id == "first_launch_01":
		return
	var follow_up_line: String = memory_manager.consume_next_follow_up_line()
	if follow_up_line.is_empty():
		return

	var follow_up_tag := ""
	if memory_manager != null and memory_manager.has_method("get_last_consumed_follow_up_tag"):
		follow_up_tag = str(memory_manager.call("get_last_consumed_follow_up_tag"))

	current_node_id = "follow_up"
	_enter_scripted_mode()
	ai_return_node_id = current_node_id
	_set_dialogue_text(follow_up_line)
	_set_status_message("")
	_render_choices(_build_follow_up_choices(follow_up_tag))
	_play_voice_for_line("follow_up", dialogue_text.text)

func _wire_signals() -> void:
	$CompanionStage/CompanionView/CharacterClickArea.pressed.connect(_on_character_clicked)
	$VideoStage/VideoClickArea.pressed.connect(_on_character_clicked)
	$BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/SendButton.pressed.connect(_on_send_pressed)
	player_input.text_submitted.connect(_on_input_submitted)
	ai_mode_toggle.toggled.connect(_on_ai_mode_toggled)
	$RightTimerPanel/TimerMargin/TimerVBox/StartFocusButton.pressed.connect(_on_start_focus_pressed)
	$RightTimerPanel/TimerMargin/TimerVBox/StopFocusButton.pressed.connect(_on_stop_focus_pressed)
	set_timer_button.pressed.connect(_on_set_timer_pressed)
	timer_minutes_input.text_submitted.connect(_on_timer_minutes_submitted)
	$RightTodoPanel/TodoMargin/TodoVBox/TodoButtons/AddTodoButton.pressed.connect(_on_add_todo_pressed)
	edit_todo_button.pressed.connect(_on_edit_todo_pressed)
	todo_list.item_selected.connect(_on_todo_item_selected)
	todo_list.item_activated.connect(_on_todo_item_activated)
	music_prev_button.pressed.connect(_on_bgm_prev_pressed)
	music_play_pause_button.pressed.connect(_on_bgm_play_pause_pressed)
	music_next_button.pressed.connect(_on_bgm_next_pressed)
	music_voice_button.pressed.connect(_on_voice_button_pressed)
	music_mode_button.item_selected.connect(_on_music_mode_selected)
	music_progress_bar.gui_input.connect(_on_music_progress_input)

func _configure_companion_controls() -> void:
	player_input.placeholder_text = INPUT_PLACEHOLDER_TEXT
	player_input.clear_button_enabled = true
	timer_minutes_input.placeholder_text = TIMER_INPUT_PLACEHOLDER_TEXT
	timer_minutes_input.clear_button_enabled = true
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_card.visible = false
	_refresh_voice_button()
	_refresh_music_mode_button()
	_refresh_input_placeholder()
	_refresh_focus_controls()
	_refresh_todo_controls()

func _configure_visual_mode() -> void:
	if video_stage == null or video_player == null:
		return

	var use_video_mode := false
	if ResourceLoader.exists(LOOP_VIDEO_PATH):
		var stream: Resource = load(LOOP_VIDEO_PATH)
		if stream is VideoStream:
			video_player.stream = stream
			video_player.play()
			use_video_mode = true

	video_stage.visible = use_video_mode
	if background_node != null:
		background_node.visible = not use_video_mode
	if companion_stage != null:
		companion_stage.visible = not use_video_mode

func _refresh_input_placeholder() -> void:
	if ai_mode_toggle.button_pressed:
		player_input.placeholder_text = TYPE_INPUT_PLACEHOLDER_TEXT
	else:
		player_input.placeholder_text = INPUT_PLACEHOLDER_TEXT

func _refresh_focus_controls() -> void:
	if start_focus_button != null:
		start_focus_button.disabled = focus_running
	if stop_focus_button != null:
		stop_focus_button.disabled = not focus_running

func _refresh_todo_controls() -> void:
	if edit_todo_button != null:
		edit_todo_button.disabled = todo_list.get_selected_items().is_empty()
	if add_todo_button != null:
		add_todo_button.disabled = false

func _refresh_voice_button() -> void:
	if music_voice_button == null:
		return
	music_voice_button.text = "Voice On" if voice_enabled else "Voice Off"

func _refresh_music_mode_button() -> void:
	if music_mode_button == null:
		return
	var mode := clampi(saved_music_playback_mode, 0, 2)
	music_mode_button.select(mode)

func _seed_todo_items() -> void:
	_add_todo_item("Set one gentle focus block")
	_add_todo_item("Write today's calm priority")
	_add_todo_item("Try one scripted greeting branch")

func _update_datetime_labels() -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	date_label.text = "%04d/%02d/%02d" % [now.year, now.month, now.day]
	time_label.text = "%02d:%02d" % [now.hour, now.minute]
	weather_label.text = _get_time_bucket_label(now.hour)

func _get_time_bucket_label(hour: int) -> String:
	if hour >= 5 and hour < 12:
		return "Morning"
	if hour >= 12 and hour < 17:
		return "Afternoon"
	if hour >= 17 and hour < 22:
		return "Evening"
	return "Night"

func _show_node(node_id: String) -> void:
	_enter_scripted_mode()
	current_node_id = node_id
	var node_data: Dictionary = scripted_dialogue_manager.get_dialogue_node(node_id)
	_show_node_data(node_data)

func _show_node_data(node_data: Dictionary) -> void:
	if node_data.is_empty():
		_set_dialogue_text("Dialogue error: missing node data.")
		_render_choices([])
		return

	current_node_id = str(node_data.get("id", current_node_id))
	var line_text := str(node_data.get("line", ""))
	_set_dialogue_text(line_text)
	_set_status_message("")
	_render_choices(_get_display_choices(node_data))
	_play_voice_for_line(current_node_id, line_text)

func _get_display_choices(node_data: Dictionary) -> Array:
	var node_choices: Array = node_data.get("choices", [])
	if not node_choices.is_empty():
		return node_choices

	if current_node_id == "idle":
		return []
	if current_node_id.begins_with("EXIT_") or current_node_id == "FOCUS_START_001":
		return []

	if scripted_dialogue_manager != null and scripted_dialogue_manager.has_dialogue_node("greeting_01"):
		return [
			{"text": DEFAULT_RETURN_CHOICE_TEXT, "next": "greeting_01", "internal_return": true}
		]

	return []

func _build_follow_up_choices(follow_up_tag: String) -> Array:
	var continue_node := "greeting_01"
	if scripted_dialogue_manager != null and not scripted_dialogue_manager.has_dialogue_node(continue_node):
		continue_node = "return_open_01" if scripted_dialogue_manager.has_dialogue_node("return_open_01") else "TASK_INPUT_001"
	var choices: Array = [
		{"text": "继续", "next": continue_node, "internal_return": true}
	]

	var topic_node_id := _get_follow_up_topic_node_id(follow_up_tag)
	if not topic_node_id.is_empty():
		choices.append({
			"text": _get_follow_up_choice_text(follow_up_tag),
			"next": topic_node_id,
			"internal_return": true
		})

	choices.append({"text": "先坐一会儿", "next": "quiet_end_01", "internal_return": true})
	return choices

func _get_follow_up_topic_node_id(follow_up_tag: String) -> String:
	var node_map := {
		"ask_about_school": "memory_school_followup",
		"ask_about_exam": "memory_exam_followup",
		"ask_about_sleep": "memory_sleep_followup",
		"ask_about_work": "memory_work_followup"
	}
	var node_id := str(node_map.get(follow_up_tag, ""))
	if node_id.is_empty():
		return ""
	if scripted_dialogue_manager != null and scripted_dialogue_manager.has_dialogue_node(node_id):
		return node_id
	return ""

func _get_follow_up_choice_text(follow_up_tag: String) -> String:
	match follow_up_tag:
		"ask_about_school":
			return "Talk about school"
		"ask_about_exam":
			return "Talk about the exam"
		"ask_about_sleep":
			return "Talk about rest"
		"ask_about_work":
			return "Talk about work"
		_:
			return "Talk about it"

func _render_choices(choices: Array) -> void:
	for child in choice_list.get_children():
		child.queue_free()

	for choice in choices:
		var choice_button := Button.new()
		choice_button.text = str(choice.get("text", "Continue"))
		choice_button.custom_minimum_size = Vector2(0, 28)
		choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_choice_button(choice_button)
		choice_button.pressed.connect(_on_choice_selected.bind(choice.duplicate(true)))
		choice_list.add_child(choice_button)

func _enter_scripted_mode() -> void:
	current_ai_mode_id = ""
	if ai_mode_toggle != null and ai_mode_toggle.button_pressed:
		ai_mode_toggle.button_pressed = false
	_refresh_input_placeholder()

func _set_status_message(text: String) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.visible = not text.is_empty()

func _show_system_status(text: String) -> void:
	_hide_dialogue_text()
	_set_status_message(text)

func _set_dialogue_text(text: String) -> void:
	if dialogue_text == null:
		return
	dialogue_text.text = text
	if dialogue_card != null:
		dialogue_card.visible = not text.strip_edges().is_empty()

func _hide_dialogue_text() -> void:
	if dialogue_text != null:
		dialogue_text.text = ""
	if dialogue_card != null:
		dialogue_card.visible = false

func _style_choice_button(choice_button: Button) -> void:
	var normal_style := _make_choice_style(Color(0.24, 0.17, 0.19, 0.84), Color(1.0, 0.84, 0.72, 0.24))
	var hover_style := _make_choice_style(Color(0.34, 0.24, 0.25, 0.9), Color(1.0, 0.88, 0.76, 0.42))
	var pressed_style := _make_choice_style(Color(0.42, 0.28, 0.28, 0.94), Color(1.0, 0.84, 0.72, 0.52))

	choice_button.add_theme_stylebox_override("normal", normal_style)
	choice_button.add_theme_stylebox_override("hover", hover_style)
	choice_button.add_theme_stylebox_override("pressed", pressed_style)
	choice_button.add_theme_stylebox_override("focus", hover_style)

func _make_choice_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	return style

func _on_character_clicked() -> void:
	if focus_running:
		_show_focus_click_line()
		return

	if current_node_id == "idle":
		_show_node("first_launch_01" if scripted_dialogue_manager.has_dialogue_node("first_launch_01") else "return_open_01")
		return

	_set_status_message("")
	if current_ai_mode_id.is_empty():
		_set_dialogue_text("我在。先选一个回复，或者在下面写你自己的话。")
	else:
		_set_dialogue_text("我在。想继续自己写就继续，不想的话也可以回到按钮。")
	_play_voice_for_line("prompt_pick_response", dialogue_text.text)

func _show_focus_click_line() -> void:
	if FOCUS_CLICK_LINES.is_empty():
		return
	focus_click_count += 1
	var line_index := randi() % FOCUS_CLICK_LINES.size()
	if focus_click_count > 3:
		_set_dialogue_text("……")
	else:
		_set_dialogue_text(FOCUS_CLICK_LINES[line_index])
	_set_status_message("")
	_play_voice_for_line("focus_click_%02d" % focus_click_count, dialogue_text.text)

func _on_choice_selected(choice_data: Dictionary) -> void:
	var next_node_id := str(choice_data.get("next", "greeting_01"))
	var internal_return := bool(choice_data.get("internal_return", false))
	if internal_return:
		_return_to_scripted_node(next_node_id)
		return
	if _handle_special_choice(next_node_id):
		return
	if next_node_id.begins_with("AI_MODE_"):
		_handle_ai_mode_choice(next_node_id)
		return
	if not scripted_dialogue_manager.validate_choice_transition(current_node_id, next_node_id):
		var error_node := scripted_dialogue_manager.make_transition_error_node(current_node_id, next_node_id)
		_show_node_data(error_node)
		return
	_show_node(next_node_id)

func _handle_special_choice(next_node_id: String) -> bool:
	match next_node_id:
		"ACTION_DEMO_TASK":
			_capture_focus_task("整理一个小任务，先推进一点点")
			return true
		"ACTION_SET_TIMER_1":
			_set_focus_minutes_from_script(1, "1 分钟试玩，刚好够看一眼效果。")
			return true
		"ACTION_SET_TIMER_15":
			_set_focus_minutes_from_script(15, "十五分钟，很理智的选择。短的先赢。")
			return true
		"ACTION_SET_TIMER_25":
			_set_focus_minutes_from_script(25, "二十五分钟……标准番茄钟。经典之选。")
			return true
		"ACTION_SET_TIMER_45":
			_set_focus_minutes_from_script(45, "四十五分钟……你还挺有自信的。好，我陪你。")
			return true
		"ACTION_START_FOCUS":
			_start_focus_from_script()
			return true
		_:
			return false

func _set_focus_minutes_from_script(minutes: int, yua_line: String) -> void:
	focus_duration_seconds = float(minutes) * 60.0
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	timer_minutes_input.text = str(minutes)
	_update_timer_label()
	_refresh_focus_controls()
	_save_persistent_state()
	current_node_id = "FOCUS_READY_001"
	_set_dialogue_text("%s\n\n%s" % [yua_line, "准备好了就开始。"])
	_set_status_message("Timer set to %d minute%s." % [minutes, "" if minutes == 1 else "s"])
	_render_choices([
		{"text": "开始专注", "next": "ACTION_START_FOCUS"},
		{"text": "换个任务", "next": "TASK_INPUT_001"}
	])
	_play_voice_for_line("timer_set_%d" % minutes, dialogue_text.text)

func _start_focus_from_script() -> void:
	focus_running = true
	focus_click_count = 0
	if focus_time_left <= 0.0:
		focus_time_left = focus_duration_seconds
	focus_last_tick_ms = Time.get_ticks_msec()
	_update_timer_label()
	_refresh_focus_controls()
	_show_node("FOCUS_START_001")
	_set_status_message("Focus started. %s left." % _format_time_label(focus_time_left))
	_save_persistent_state()

func _on_ai_mode_toggled(pressed: bool) -> void:
	if not pressed:
		current_ai_mode_id = ""
	_refresh_input_placeholder()

func _handle_ai_mode_choice(mode_id: String) -> void:
	if not ai_mode_toggle.button_pressed:
		ai_mode_toggle.button_pressed = true
	current_ai_mode_id = mode_id
	ai_return_node_id = _safe_node_id()
	if ai_return_node_id == "idle":
		ai_return_node_id = "TASK_INPUT_001"
	_set_dialogue_text("Type Mode 开着。你可以用自己的话写。")
	_set_status_message("Typed replies use your own words. The buttons stay as guided replies.")
	_render_choices([
		{"text": "回到按钮回复", "next": ai_return_node_id, "internal_return": true}
	])
	player_input.grab_focus()

func _return_to_scripted_node(node_id: String) -> void:
	var target_node_id := node_id
	if target_node_id.is_empty() or not scripted_dialogue_manager.has_dialogue_node(target_node_id):
		target_node_id = _safe_node_id()
	if target_node_id == "idle":
		if scripted_dialogue_manager.has_dialogue_node("return_open_01"):
			target_node_id = "return_open_01"
		elif scripted_dialogue_manager.has_dialogue_node("TASK_INPUT_001"):
			target_node_id = "TASK_INPUT_001"

	current_ai_mode_id = ""
	ai_return_node_id = target_node_id
	ai_mode_toggle.button_pressed = false
	_set_status_message("")
	_show_node(target_node_id)

func _on_send_pressed() -> void:
	_handle_player_text(player_input.text)

func _on_input_submitted(submitted_text: String) -> void:
	_handle_player_text(submitted_text)

func _handle_player_text(raw_text: String) -> void:
	var text := raw_text.strip_edges()
	if text.is_empty():
		return

	player_input.clear()

	if not ai_mode_toggle.button_pressed and current_node_id == "TASK_INPUT_001":
		_capture_focus_task(text)
		return

	if ai_mode_toggle.button_pressed:
		_set_status_message("Yua is thinking...")
		memory_manager.process_player_message(text)
		var memory_context: String = memory_manager.get_memory_context()
		var mode_id := current_ai_mode_id if not current_ai_mode_id.is_empty() else current_node_id
		var mode_context := _get_mode_context_for_node(mode_id)
		var route: Dictionary = await dialogue_router.route_player_text_async(
			text,
			true,
			memory_context,
			persona_text,
			runtime_rules_text,
			mode_context,
			mode_id
		)
		_handle_ai_route(route)
		return

	_set_dialogue_text("现在是按钮回复模式。要自己写的话，可以打开 Type Mode。")
	_set_status_message("Use the buttons, or switch to Type Mode.")
	_play_voice_for_line("scripted_mode_hint", dialogue_text.text)

func _capture_focus_task(task_text: String) -> void:
	current_focus_task = task_text.strip_edges()
	if current_focus_task.is_empty():
		return
	memory_manager.process_player_message(current_focus_task)
	_add_todo_item(current_focus_task)
	todo_list.select(todo_list.item_count - 1)
	_refresh_todo_controls()
	current_node_id = "TASK_INPUT_002"
	_set_dialogue_text("……好。\n\n“%s”。\n\n不是很大，但很实际。这种任务我最喜欢，完成了有感觉。\n\n选个时长吧。" % current_focus_task)
	_set_status_message("Task captured.")
	_render_choices([
		{"text": "1 分钟试玩", "next": "ACTION_SET_TIMER_1"},
		{"text": "15 分钟", "next": "ACTION_SET_TIMER_15"},
		{"text": "25 分钟", "next": "ACTION_SET_TIMER_25"},
		{"text": "45 分钟", "next": "ACTION_SET_TIMER_45"}
	])
	_play_voice_for_line("task_captured", dialogue_text.text)
	_save_persistent_state()

func _speak_companion_line(line_id: String, text: String) -> void:
	_set_dialogue_text(text)
	_set_status_message("")
	_play_voice_for_line(line_id, text)

func _get_mode_context_for_node(node_id: String) -> String:
	match node_id:
		"AI_MODE_TASK_CLARIFY":
			return "Scene type: task clarification before a focus session\nReply in Simplified Chinese, 1-2 short sentences\nYua helps the player shrink a vague task into one concrete next step\nDo not continue casual chat; gently return toward choosing a timer"
		"AI_MODE_POST_SESSION":
			return "Scene type: short post-focus reflection\nReply in Simplified Chinese, 1-3 short sentences\nYua asks how the task went or acknowledges progress without sounding like a therapist\nDo not unlock story or escalate intimacy"
		"AI_MODE_BREAK_CHAT":
			return "Scene type: limited break chat after earned rest or aborted focus\nReply in Simplified Chinese, 1-3 short sentences\nYua can be warm and lightly teasing, but should keep the chat bounded and easy to leave"
		"AI_MODE_CHECKIN":
			return "Scene type: pre-focus check-in\nReply in Simplified Chinese, 1-2 short sentences\nHelp name one concrete task and nudge toward starting the timer"
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
	var route_text := str(route.get("text", ""))
	if route_text.is_empty():
		route_text = "嗯。那先用按钮走吧，简单一点。"

	_set_dialogue_text(route_text)
	_set_status_message("")
	var ai_fallback_used := bool(route.get("fallback_used", false)) or not bool(route.get("success", false))
	var choices: Array = [
		{"text": "回到按钮回复", "next": ai_return_node_id, "internal_return": true}
	]
	if not ai_fallback_used and not current_ai_mode_id.is_empty():
		choices.append({"text": "再写一句", "next": current_ai_mode_id})
	_render_choices(choices)
	var voice_line_id := "ai_fallback" if ai_fallback_used else ""
	_play_voice_for_line(voice_line_id, dialogue_text.text)

func _on_start_focus_pressed() -> void:
	_start_focus_from_script()

func _on_stop_focus_pressed() -> void:
	var was_running := focus_running
	focus_running = false
	focus_time_left = focus_duration_seconds
	_update_timer_label()
	_refresh_focus_controls()
	if was_running and scripted_dialogue_manager.has_dialogue_node("ABORT_001"):
		_show_node("ABORT_001")
	else:
		_show_system_status(FOCUS_STOP_LINE)
	_save_persistent_state()

func _on_set_timer_pressed() -> void:
	var minutes := _parse_minutes_input()
	if minutes <= 0:
		_show_system_status("Enter a number of minutes first, then press Set.")
		return

	focus_duration_seconds = float(minutes) * 60.0
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	_update_timer_label()
	_refresh_focus_controls()
	_show_system_status("%s Timer set to %d minutes." % [FOCUS_SET_LINE, minutes])
	_save_persistent_state()

func _on_timer_minutes_submitted(_submitted_text: String) -> void:
	_on_set_timer_pressed()

func _update_timer_label() -> void:
	var rounded_seconds := maxi(0, int(ceil(focus_time_left)))
	var minutes := int(rounded_seconds / 60.0)
	var seconds := rounded_seconds % 60
	timer_label.text = "Focus %02d:%02d" % [minutes, seconds]

func _format_time_label(seconds_left: float) -> String:
	var rounded_seconds := maxi(0, int(ceil(seconds_left)))
	var minutes := int(rounded_seconds / 60.0)
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
		_show_system_status("Type a task in the text box first, then press Add.")
		return

	_add_todo_item(todo_text)
	todo_list.select(todo_list.item_count - 1)
	player_input.clear()
	_refresh_todo_controls()
	_show_system_status(TODO_ADD_LINE + " " + todo_text)
	_save_persistent_state()

func _on_edit_todo_pressed() -> void:
	var selected := todo_list.get_selected_items()
	if selected.is_empty():
		_show_system_status("Select a todo, type the new text, then press Update.")
		return

	var new_text := player_input.text.strip_edges()
	if new_text.is_empty():
		_show_system_status("Type the updated todo text before pressing Update.")
		return

	var index := int(selected[0])
	var data := _get_todo_data(index)
	data.text = new_text
	todo_list.set_item_metadata(index, data)
	todo_list.set_item_text(index, _format_todo_text(new_text, bool(data.get("completed", false))))
	if bool(data.get("completed", false)):
		todo_list.set_item_custom_fg_color(index, Color(0.4, 0.8, 0.5))
	_refresh_todo_controls()
	_show_system_status(TODO_EDIT_LINE)
	_save_persistent_state()

func _on_todo_item_selected(_index: int) -> void:
	_refresh_todo_controls()

func _on_todo_item_activated(index: int) -> void:
	if index < 0 or index >= todo_list.item_count:
		return

	var data := _get_todo_data(index)
	if data.get("completed", false):
		todo_list.remove_item(index)
		_show_system_status("Removed the completed todo.")
	else:
		data.completed = true
		todo_list.set_item_metadata(index, data)
		todo_list.set_item_text(index, _format_todo_text(str(data.get("text", "")), true))
		todo_list.set_item_custom_fg_color(index, Color(0.4, 0.8, 0.5))
		_show_system_status(TODO_COMPLETE_LINE)

	_refresh_todo_controls()
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
		completed_focus_sessions += 1
		_show_focus_complete_node()
		_refresh_focus_controls()
		_save_persistent_state()

	_update_timer_label()

func _show_focus_complete_node() -> void:
	if completed_focus_sessions == 1 and scripted_dialogue_manager.has_dialogue_node("FOCUS_DONE_001"):
		_show_node("FOCUS_DONE_001")
		return
	if completed_focus_sessions == 2 and scripted_dialogue_manager.has_dialogue_node("REL_001"):
		_show_node("REL_001")
		return
	if scripted_dialogue_manager.has_dialogue_node("FOCUS_DONE_REPEAT"):
		_show_node("FOCUS_DONE_REPEAT")
		return
	_show_system_status(FOCUS_COMPLETE_LINE)

func _safe_node_id() -> String:
	if scripted_dialogue_manager != null and scripted_dialogue_manager.has_dialogue_node(current_node_id):
		return current_node_id
	return "idle"

func _resolve_start_node_id() -> String:
	if scripted_dialogue_manager == null:
		return current_node_id

	if demo_script_version_seen < DEMO_SCRIPT_VERSION and scripted_dialogue_manager.has_dialogue_node("first_launch_01"):
		demo_script_version_seen = DEMO_SCRIPT_VERSION
		has_seen_intro = true
		return "first_launch_01"

	if not has_seen_intro and scripted_dialogue_manager.has_dialogue_node("first_launch_01"):
		has_seen_intro = true
		return "first_launch_01"

	if has_seen_intro and scripted_dialogue_manager.has_dialogue_node("return_open_01"):
		return "return_open_01"

	return current_node_id

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
		"last_node_id": _safe_node_id(),
		"has_seen_intro": has_seen_intro,
		"demo_script_version_seen": demo_script_version_seen,
		"completed_focus_sessions": completed_focus_sessions,
		"current_focus_task": current_focus_task,
		"music_track_index": saved_music_index,
		"music_paused": bgm_paused,
		"music_playback_mode": saved_music_playback_mode,
		"voice_enabled": voice_enabled
	}

	if bgm_manager != null and bgm_manager.has_method("get_current_index"):
		payload["music_track_index"] = int(bgm_manager.call("get_current_index"))
		saved_music_index = int(payload["music_track_index"])
	if bgm_manager != null and bgm_manager.has_method("get_playback_mode"):
		payload["music_playback_mode"] = int(bgm_manager.call("get_playback_mode"))
		saved_music_playback_mode = int(payload["music_playback_mode"])
	saved_music_paused = bgm_paused

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
	has_seen_intro = bool(data.get("has_seen_intro", false))
	demo_script_version_seen = int(data.get("demo_script_version_seen", 0))
	completed_focus_sessions = int(data.get("completed_focus_sessions", 0))
	current_focus_task = str(data.get("current_focus_task", ""))
	current_ai_mode_id = ""
	ai_return_node_id = current_node_id
	saved_music_index = int(data.get("music_track_index", 0))
	saved_music_paused = bool(data.get("music_paused", true))
	saved_music_playback_mode = int(data.get("music_playback_mode", 0))
	voice_enabled = bool(data.get("voice_enabled", true))
	focus_last_tick_ms = Time.get_ticks_msec()
	last_saved_second = int(focus_time_left)

	todo_list.clear()
	for todo in data.get("todos", []):
		var todo_data: Dictionary = todo
		_add_todo_item(str(todo_data.get("text", "")), bool(todo_data.get("completed", false)))
	_refresh_todo_controls()

func _play_voice_for_line(line_id: String, text: String) -> void:
	if not voice_enabled:
		return
	if voice_manager == null:
		return

	if voice_manager.has_method("play_voice_for_line"):
		voice_manager.call("play_voice_for_line", line_id, text)

func _start_bgm_if_available() -> void:
	if bgm_manager == null:
		return
	if bgm_manager.has_method("set_current_index"):
		bgm_manager.call("set_current_index", saved_music_index)
	if bgm_manager.has_method("set_playback_mode"):
		bgm_manager.call("set_playback_mode", saved_music_playback_mode)
	if saved_music_paused:
		if bgm_manager.has_method("pause_bgm"):
			bgm_manager.call("pause_bgm")
		bgm_paused = true
	else:
		if bgm_manager.has_method("play_current"):
			bgm_manager.call("play_current")
		elif bgm_manager.has_method("play_default"):
			bgm_manager.call("play_default")
		bgm_paused = false
	_refresh_music_bar()

func _on_bgm_prev_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_previous"):
		bgm_manager.call("play_previous")
		bgm_paused = false
		_refresh_music_bar()
		_save_persistent_state()

func _on_bgm_next_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_next"):
		bgm_manager.call("play_next")
		bgm_paused = false
		_refresh_music_bar()
		_save_persistent_state()

func _on_voice_button_pressed() -> void:
	voice_enabled = not voice_enabled
	_refresh_voice_button()
	_show_system_status("Voice lines are on." if voice_enabled else "Voice lines are off.")
	_save_persistent_state()

func _on_music_mode_selected(index: int) -> void:
	saved_music_playback_mode = clampi(index, 0, 2)
	if bgm_manager != null and bgm_manager.has_method("set_playback_mode"):
		bgm_manager.call("set_playback_mode", saved_music_playback_mode)
	_refresh_music_mode_button()
	_save_persistent_state()

func _on_bgm_play_pause_pressed() -> void:
	if bgm_manager == null:
		return

	var has_stream := false
	if bgm_manager.has_method("has_stream"):
		has_stream = bool(bgm_manager.call("has_stream"))
	var has_playlist := true
	if bgm_manager.has_method("has_playlist"):
		has_playlist = bool(bgm_manager.call("has_playlist"))

	if not has_playlist:
		_refresh_music_bar()
		_show_system_status("There is no ambience loaded yet, but the controls are ready.")
		return

	if not has_stream:
		if bgm_manager.has_method("play_current"):
			bgm_manager.call("play_current")
		elif bgm_manager.has_method("play_default"):
			bgm_manager.call("play_default")
		bgm_paused = false
		_refresh_music_bar()
		_save_persistent_state()
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
	_save_persistent_state()

func _refresh_music_bar() -> void:
	if music_song_label == null or music_progress_bar == null:
		return

	var song_name := "No track loaded"
	if bgm_manager != null and bgm_manager.has_method("get_now_playing_name"):
		song_name = str(bgm_manager.call("get_now_playing_name"))

	music_song_label.text = "Song: " + song_name
	var is_playing := false
	if bgm_manager != null and bgm_manager.has_method("is_playing"):
		is_playing = bool(bgm_manager.call("is_playing"))
	bgm_paused = not is_playing
	music_play_pause_button.text = "Play" if bgm_paused else "Pause"
	_refresh_voice_button()
	if bgm_manager != null and bgm_manager.has_method("get_playback_mode"):
		saved_music_playback_mode = int(bgm_manager.call("get_playback_mode"))
	_refresh_music_mode_button()
	var has_playlist := false
	if bgm_manager != null and bgm_manager.has_method("has_playlist"):
		has_playlist = bool(bgm_manager.call("has_playlist"))
	if music_prev_button != null:
		var can_step_tracks := has_playlist
		if bgm_manager != null and bgm_manager.has_method("can_step_tracks"):
			can_step_tracks = bool(bgm_manager.call("can_step_tracks"))
		music_prev_button.disabled = not can_step_tracks
	if music_next_button != null:
		var can_step_next := has_playlist
		if bgm_manager != null and bgm_manager.has_method("can_step_tracks"):
			can_step_next = bool(bgm_manager.call("can_step_tracks"))
		music_next_button.disabled = not can_step_next
	if music_play_pause_button != null:
		music_play_pause_button.disabled = not has_playlist

func _update_music_progress() -> void:
	if bgm_manager == null or music_progress_bar == null:
		return
	if not bgm_manager.has_method("get_stream_length"):
		return
	var length := float(bgm_manager.call("get_stream_length"))
	if length <= 0.0:
		music_progress_bar.value = 0.0
		return
	var playback_position := float(bgm_manager.call("get_playback_position"))
	music_progress_bar.value = clampf((playback_position / length) * 100.0, 0.0, 100.0)

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
