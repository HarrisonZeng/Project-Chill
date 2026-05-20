extends Control

const FOCUS_DURATION_SECONDS: float = 25.0 * 60.0
# Save now lives in one profile owned by memory_manager
# (user://data/saves/player_profile.json). main_scene reads/writes via it.
const LOOP_VIDEO_PATH := "res://assets/video/yua_idle_loop.ogv"
const FOCUS_COMPLETE_LINE := "Focus block complete. Nice work."
const PERSONA_PATH := "res://data/dialogue/yua_system_prompt.txt"
const RUNTIME_RULES_PATH := "res://data/dialogue/yua_runtime_rules.txt"
const DEFAULT_MODE_CONTEXT := "Scene type: short return-after-task check-in\nReply briefly in 1-3 sentences\nYua should sound gently curious and reserved\nThis is a small side conversation and should return to the main flow soon"
const INPUT_PLACEHOLDER_TEXT := "Type a reply"
const TYPE_INPUT_PLACEHOLDER_TEXT := "Type your reply in your own words"
const TIMER_INPUT_PLACEHOLDER_TEXT := "15"
const FOCUS_START_LINE := "Focus timer started. Let's keep it gentle."
const FOCUS_STOP_LINE := "Focus timer paused. We can breathe for a moment."
const FOCUS_SET_LINE := "Timer set. I'll keep you company for that block."
const DEFAULT_RETURN_CHOICE_TEXT := "Stay a little longer."
# These three are loaded from scripted_nodes.json at runtime so adding a new
# episode is JSON-only — no .gd edit needed. The values below are fallback
# defaults used only if the JSON is missing the metadata block.
const DEFAULT_DEMO_SCRIPT_VERSION := 5
const DEFAULT_INTRO_NODE_ID := "ep00_01"
const REACTIVE_LINES_PATH := "res://data/dialogue/reactive_lines.json"
const AI_MODES_PATH := "res://data/dialogue/ai_modes.json"
const QUICK_TEST_SECONDS := 3.0
const TODO_PANEL_MIN_WIDTH := 220.0
const TODO_PANEL_MAX_WIDTH := 560.0
const TODO_PANEL_MIN_HEIGHT := 250.0
const TODO_PANEL_MAX_HEIGHT := 720.0
const TODO_PANEL_MIN_TOP := 110.0
const DEFAULT_DIALOGUE_TYPEWRITER_CHARS_PER_SECOND := 34.0
# Reactive line pools (focus_click etc) live in data/dialogue/reactive_lines.json
# and are loaded at runtime into `reactive_lines`. Add a new pool by adding a
# new key in that JSON — no code change needed unless a brand new trigger is added.

@onready var dialogue_text: RichTextLabel = $BottomPanel/DialoguePanel/Margin/VBox/DialogueCard/DialogueMargin/DialogueText
@onready var dialogue_card: PanelContainer = $BottomPanel/DialoguePanel/Margin/VBox/DialogueCard
@onready var choice_list: GridContainer = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/ChoiceList
@onready var player_input: LineEdit = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/PlayerInput
@onready var ai_mode_toggle: CheckButton = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/AIModeToggle
@onready var status_label: Label = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/StatusLabel
@onready var send_button: Button = $BottomPanel/DialoguePanel/Margin/VBox/ResponseCard/ResponseMargin/ResponseVBox/InputRow/SendButton
@onready var background_node: CanvasItem = $Background
@onready var companion_stage: CanvasItem = $CompanionStage
@onready var video_stage: Control = $VideoStage
@onready var video_player: VideoStreamPlayer = $VideoStage/VideoPlayer
# Stage 2 UI redesign: focus timer + tasks panel + call status pill live in
# OverlayLayer/HUD and OverlayLayer/Tools (see scenes/main/main_scene.tscn).
# These @onready vars are the authoritative bindings.
@onready var call_status: Node = $OverlayLayer/HUD/CallStatusPill
@onready var focus_card: PanelContainer = $OverlayLayer/HUD/FocusCard
@onready var focus_title: Label = $OverlayLayer/HUD/FocusCard/Col/Title
@onready var focus_timer_display: Label = $OverlayLayer/HUD/FocusCard/Col/TimerDisplay
@onready var focus_progress: ProgressBar = $OverlayLayer/HUD/FocusCard/Col/Progress
@onready var focus_task_line: Label = $OverlayLayer/HUD/FocusCard/Col/TaskLine
@onready var focus_chips_box: HBoxContainer = $OverlayLayer/HUD/FocusCard/Col/Chips
@onready var focus_chip_custom: Button = $OverlayLayer/HUD/FocusCard/Col/Chips/ChipCustom
@onready var focus_custom_row: HBoxContainer = $OverlayLayer/HUD/FocusCard/Col/CustomRow
@onready var focus_custom_input: LineEdit = $OverlayLayer/HUD/FocusCard/Col/CustomRow/MinutesInput
@onready var focus_custom_apply: Button = $OverlayLayer/HUD/FocusCard/Col/CustomRow/ApplyButton
@onready var focus_primary_button: Button = $OverlayLayer/HUD/FocusCard/Col/PrimaryRow/StartButton
@onready var tasks_tab: Button = $OverlayLayer/Tools/TasksTab
@onready var tasks_panel: PanelContainer = $OverlayLayer/Tools/TasksPanel
@onready var tasks_title: Label = $OverlayLayer/Tools/TasksPanel/Col/Header/Title
@onready var tasks_close_button: Button = $OverlayLayer/Tools/TasksPanel/Col/Header/CloseButton
@onready var tasks_rows: VBoxContainer = $OverlayLayer/Tools/TasksPanel/Col/Scroll/Rows
@onready var new_task_input: LineEdit = $OverlayLayer/Tools/TasksPanel/Col/NewTaskInput
@onready var tasks_counter: Label = $OverlayLayer/Tools/TasksPanel/Col/Counter
@onready var tasks_resize_handle: Button = $OverlayLayer/Tools/TasksResizeHandle
@onready var music_song_label: Label = $BottomLeftMusicBar/MusicMargin/MusicVBox/SongLabel
@onready var music_progress_bar: ProgressBar = $BottomLeftMusicBar/MusicMargin/MusicVBox/ProgressBar
@onready var music_prev_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PrevButton
@onready var music_play_pause_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PlayPauseButton
@onready var music_next_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/NextButton
@onready var music_voice_button: Button = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/VoiceButton
@onready var music_mode_button: OptionButton = $BottomLeftMusicBar/MusicMargin/MusicVBox/Controls/PlaybackModeButton
@onready var settings_button: Button = $SettingsButton
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var settings_title: Label = $SettingsPanel/SettingsMargin/SettingsVBox/SettingsTitle
@onready var language_button: Button = $SettingsPanel/SettingsMargin/SettingsVBox/LanguageButton
@onready var speed_label: Label = $SettingsPanel/SettingsMargin/SettingsVBox/SpeedLabel
@onready var text_speed_slider: HSlider = $SettingsPanel/SettingsMargin/SettingsVBox/TextSpeedSlider
@onready var speed_value_label: Label = $SettingsPanel/SettingsMargin/SettingsVBox/SpeedValueLabel
@onready var voice_manager: Node = get_node_or_null("VoiceManager")
@onready var bgm_manager: Node = get_node_or_null("BgmManager")

@onready var scripted_dialogue_manager: ScriptedDialogueManager = ScriptedDialogueManager.new()

var current_node_id: String = "idle"
var focus_duration_seconds: float = FOCUS_DURATION_SECONDS
var focus_time_left: float = FOCUS_DURATION_SECONDS
var focus_running: bool = false
var focus_last_tick_ms: int = 0
var last_saved_second: int = -1
var todo_items: Array[Dictionary] = []
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
var last_seen_unix: int = 0
var ui_language: String = "en"
var dialogue_typewriter_chars_per_second: float = DEFAULT_DIALOGUE_TYPEWRITER_CHARS_PER_SECOND
var suppress_settings_save: bool = false
var resizing_tasks_panel: bool = false
var resize_start_mouse_position: Vector2 = Vector2.ZERO
var resize_start_tasks_left: float = 0.0
var resize_start_tasks_top: float = 0.0
var tasks_panel_visible: bool = false
var hovered_task_index: int = -1
var dialogue_typewriter_active: bool = false
var dialogue_typewriter_timer: float = 0.0
var dialogue_typewriter_total_chars: int = 0
var pending_choice_payloads: Array = []
var current_choice_payloads: Array = []

# Loaded from data/dialogue/* on _ready. See REACTIVE_LINES_PATH / AI_MODES_PATH
# constants and the loader helpers near the bottom of the file.
var intro_node_id: String = DEFAULT_INTRO_NODE_ID
var demo_script_version: int = DEFAULT_DEMO_SCRIPT_VERSION
var episode_start_nodes: PackedStringArray = PackedStringArray()
var episode_metadata: Array = []
var reactive_lines: Dictionary = {}
var ai_modes: Dictionary = {}

func _ready() -> void:
	_wire_signals()
	_configure_visual_mode()
	_configure_companion_controls()
	_setup_memory_profile()  # must exist before _load_persistent_state (single profile store)
	_load_persistent_state()
	_refresh_voice_button()
	_refresh_music_mode_button()
	_load_prompt_assets()
	if todo_items.is_empty():
		_seed_todo_items()
	call_status.refresh(ui_language, focus_running)
	_update_timer_label()
	add_child(scripted_dialogue_manager)
	scripted_dialogue_manager.load_from_path("res://data/dialogue/scripted_nodes.json")
	_load_episode_metadata_from_manager()
	_load_reactive_lines()
	_load_ai_modes()
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
	_highlight_duration_chip(int(round(focus_duration_seconds / 60.0)))
	_refresh_tasks_controls()
	_debug_timeline_setup()  # DEBUG_TIMELINE — remove this line for prod

func _process(delta: float) -> void:
	_update_dialogue_typewriter(delta)
	_update_focus_timer()
	call_status.refresh(ui_language, focus_running)
	_maybe_autosave()
	_update_music_progress()

func _input(event: InputEvent) -> void:
	if not resizing_tasks_panel:
		return

	if event is InputEventMouseMotion:
		var delta := get_global_mouse_position() - resize_start_mouse_position
		_apply_tasks_panel_offsets(resize_start_tasks_left + delta.x, resize_start_tasks_top + delta.y)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			resizing_tasks_panel = false
			_save_persistent_state()
			get_viewport().set_input_as_handled()

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

func _setup_memory_profile() -> void:
	# Single source of truth for save data. main_scene reads/writes its
	# session/UI fields through this profile via get_value/merge_values.
	memory_manager = preload("res://scripts/dialogue/memory_manager.gd").new()
	add_child(memory_manager)
	memory_manager.load_profile()

func _setup_dialogue_services() -> void:
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
	if current_node_id == intro_node_id:
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
	var char_click := get_node_or_null("CompanionStage/CompanionView/CharacterClickArea")
	if char_click != null:
		char_click.pressed.connect(_on_character_clicked)
	var video_click := get_node_or_null("VideoStage/VideoClickArea")
	if video_click != null:
		video_click.pressed.connect(_on_character_clicked)
	if send_button != null:
		send_button.pressed.connect(_on_send_pressed)
	if player_input != null:
		player_input.text_submitted.connect(_on_input_submitted)
	if ai_mode_toggle != null:
		ai_mode_toggle.toggled.connect(_on_ai_mode_toggled)
	if focus_primary_button != null:
		focus_primary_button.pressed.connect(_on_focus_primary_pressed)
	if focus_chip_custom != null:
		focus_chip_custom.pressed.connect(_on_focus_custom_chip_pressed)
	if focus_custom_apply != null:
		focus_custom_apply.pressed.connect(_on_focus_custom_apply_pressed)
	if focus_custom_input != null:
		focus_custom_input.text_submitted.connect(_on_focus_custom_input_submitted)
	if focus_chips_box != null:
		for chip in focus_chips_box.get_children():
			if chip == focus_chip_custom or not chip is Button:
				continue
			var btn := chip as Button
			var minutes := int(btn.text)
			btn.pressed.connect(_on_duration_chip_pressed.bind(minutes))
	if tasks_tab != null:
		tasks_tab.pressed.connect(_on_tasks_tab_pressed)
	if tasks_close_button != null:
		tasks_close_button.pressed.connect(_on_tasks_close_pressed)
	if new_task_input != null:
		new_task_input.text_submitted.connect(_on_new_task_submitted)
	if tasks_resize_handle != null:
		tasks_resize_handle.gui_input.connect(_on_tasks_resize_handle_input)
	settings_button.pressed.connect(_on_settings_button_pressed)
	language_button.pressed.connect(_on_language_button_pressed)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	music_prev_button.pressed.connect(_on_bgm_prev_pressed)
	music_play_pause_button.pressed.connect(_on_bgm_play_pause_pressed)
	music_next_button.pressed.connect(_on_bgm_next_pressed)
	music_voice_button.pressed.connect(_on_voice_button_pressed)
	music_mode_button.item_selected.connect(_on_music_mode_selected)
	music_progress_bar.gui_input.connect(_on_music_progress_input)

func _configure_companion_controls() -> void:
	if player_input != null:
		player_input.clear_button_enabled = true
	if new_task_input != null:
		new_task_input.clear_button_enabled = true
	if focus_custom_input != null:
		focus_custom_input.clear_button_enabled = true
	if dialogue_text != null:
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if dialogue_card != null:
		dialogue_card.visible = false
	if text_speed_slider != null:
		text_speed_slider.value = dialogue_typewriter_chars_per_second
	_refresh_ui_language()
	_refresh_voice_button()
	_refresh_music_mode_button()
	_refresh_focus_controls()
	_refresh_tasks_controls()

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
		player_input.placeholder_text = _ui_text("type_input_placeholder")
	else:
		player_input.placeholder_text = _ui_text("input_placeholder")

func _ui_text(key: String) -> String:
	var zh := ui_language == "zh"
	match key:
		"settings":
			return _zh([35774, 32622]) if zh else "Settings"
		"language":
			return _zh([35821, 35328, 65306, 20013, 25991]) if zh else "Language: EN"
		"text_speed":
			return _zh([25991, 23383, 36895, 24230]) if zh else "Text Speed"
		"chars_per_second":
			return _zh([37, 100, 32, 23383, 47, 31186]) if zh else "%d chars/s"
		"focus_timer":
			return _zh([19987, 27880, 35745, 26102]) if zh else "Focus Timer"
		"focus":
			return _zh([19987, 27880]) if zh else "Focus"
		"minutes":
			return _zh([20998, 38047]) if zh else "Minutes"
		"set":
			return _zh([35774, 32622]) if zh else "Set"
		"start_focus":
			return _zh([24320, 22987, 19987, 27880]) if zh else "Start Focus"
		"reset_focus":
			return _zh([37325, 32622, 19987, 27880]) if zh else "Reset Focus"
		"tasks":
			return _zh([20219, 21153]) if zh else "Tasks"
		"new_task":
			return _zh([26032, 20219, 21153]) if zh else "New task"
		"add_task":
			return _zh([28155, 21152, 20219, 21153]) if zh else "Add Task"
		"edit_selected":
			return _zh([32534, 36753, 36873, 20013]) if zh else "Edit Selected"
		"task_updated":
			return _zh([20219, 21153, 24050, 26356, 26032]) if zh else "Task updated."
		"task_first":
			return _zh([20808, 36755, 20837, 19968, 20010, 20219, 21153, 12290]) if zh else "Type a task first."
		"task_added":
			return _zh([20219, 21153, 24050, 28155, 21152, 12290]) if zh else "Task added."
		"task_complete":
			return _zh([20219, 21153, 24050, 23436, 25104, 12290]) if zh else "Task complete."
		"task_active":
			return _zh([20219, 21153, 24050, 24674, 22797, 12290]) if zh else "Task active."
		"task_removed":
			return _zh([20219, 21153, 24050, 21024, 38500, 12290]) if zh else "Task removed."
		"input_placeholder":
			return _zh([36755, 20837, 22238, 22797]) if zh else "Type a reply"
		"type_input_placeholder":
			return _zh([29992, 20320, 33258, 24049, 30340, 35805, 22238, 22797]) if zh else "Type your reply in your own words"
		"send":
			return _zh([21457, 36865]) if zh else "Send"
		"type_mode":
			return _zh([36755, 20837, 27169, 24335]) if zh else "Type Mode"
		"song":
			return _zh([27468, 26354, 65306]) if zh else "Song: "
		"no_track":
			return _zh([26410, 21152, 36733, 38899, 20048]) if zh else "No track loaded"
		"voice_on":
			return _zh([35821, 38899, 24320]) if zh else "Voice On"
		"voice_off":
			return _zh([35821, 38899, 20851]) if zh else "Voice Off"
		"play":
			return _zh([25773, 25918]) if zh else "Play"
		"pause":
			return _zh([26242, 20572]) if zh else "Pause"
		"loop":
			return _zh([24490, 29615]) if zh else "Loop"
		"seq":
			return _zh([39034, 24207]) if zh else "Seq"
		"random":
			return _zh([38543, 26426]) if zh else "Random"
		"morning":
			return _zh([26089, 26216]) if zh else "Morning"
		"afternoon":
			return _zh([19979, 21320]) if zh else "Afternoon"
		"evening":
			return _zh([20621, 26202]) if zh else "Evening"
		"night":
			return _zh([22812, 26202]) if zh else "Night"
		"mark_done":
			return _zh([26631, 35760, 23436, 25104]) if zh else "Mark done"
		"task_placeholder":
			return _zh([20219, 21153]) if zh else "Task"
		"delete_task":
			return _zh([21024, 38500, 20219, 21153]) if zh else "Delete task"
		"resize_tasks":
			return _zh([25302, 21160, 35843, 25972, 20219, 21153, 26694, 22823, 23567]) if zh else "Drag to resize tasks"
		_:
			return key

func _zh(codes: Array) -> String:
	var text := ""
	for code in codes:
		text += String.chr(int(code))
	return text
func _refresh_ui_language() -> void:
	if settings_button != null: settings_button.text = _ui_text("settings")
	if settings_title != null: settings_title.text = _ui_text("settings")
	if language_button != null: language_button.text = _ui_text("language")
	if speed_label != null: speed_label.text = _ui_text("text_speed")
	if speed_value_label != null: speed_value_label.text = _ui_text("chars_per_second") % int(round(dialogue_typewriter_chars_per_second))
	if focus_custom_input != null: focus_custom_input.placeholder_text = UiStrings.t("focus.custom.placeholder", ui_language)
	if focus_custom_apply != null: focus_custom_apply.text = UiStrings.t("focus.custom.apply", ui_language)
	if focus_chip_custom != null: focus_chip_custom.text = UiStrings.t("focus.custom", ui_language)
	if tasks_title != null: tasks_title.text = UiStrings.t("tasks.title", ui_language)
	if new_task_input != null: new_task_input.placeholder_text = UiStrings.t("tasks.new_placeholder", ui_language)
	if tasks_close_button != null: tasks_close_button.tooltip_text = UiStrings.t("tasks.close", ui_language)
	if tasks_resize_handle != null: tasks_resize_handle.tooltip_text = UiStrings.t("tasks.resize.tooltip", ui_language)
	if send_button != null: send_button.text = _ui_text("send")
	if ai_mode_toggle != null: ai_mode_toggle.text = _ui_text("type_mode")
	_refresh_input_placeholder()
	_refresh_music_mode_button()
	_refresh_voice_button()
	_refresh_music_bar()
	_update_timer_label()
	call_status.refresh(ui_language, focus_running)
	_refresh_focus_controls()
	_render_tasks()
	_refresh_tasks_controls()

func _refresh_focus_controls() -> void:
	if focus_card != null:
		focus_card.theme_type_variation = &"PanelGlassActive" if focus_running else &"PanelGlass"
	if focus_primary_button != null:
		var icon_key := "focus.icon.stop" if focus_running else "focus.icon.start"
		focus_primary_button.text = UiStrings.t(icon_key, ui_language)
	if focus_title != null:
		var title_key := "focus.title.running" if focus_running else "focus.title.idle"
		focus_title.text = UiStrings.t(title_key, ui_language)
	if focus_timer_display != null:
		var color_token := "honey_amber" if focus_running else "cream"
		focus_timer_display.add_theme_color_override("font_color", get_theme_color(color_token, "Palette"))
	if focus_progress != null:
		focus_progress.visible = focus_running and focus_duration_seconds > 0.0
		if focus_duration_seconds > 0.0:
			focus_progress.max_value = focus_duration_seconds
			focus_progress.value = focus_duration_seconds - focus_time_left
	if focus_task_line != null:
		var task_text := current_focus_task.strip_edges()
		focus_task_line.visible = focus_running and not task_text.is_empty()
		if focus_task_line.visible:
			focus_task_line.text = "%s: %s" % [UiStrings.t("focus.task", ui_language), task_text]

func _refresh_tasks_controls() -> void:
	if tasks_tab != null:
		var pending := 0
		for item in todo_items:
			if not bool(item.get("completed", false)):
				pending += 1
		tasks_tab.text = "📋 %d" % pending
		tasks_tab.tooltip_text = UiStrings.t("tasks.tab.label", ui_language)
	if tasks_panel != null:
		tasks_panel.visible = tasks_panel_visible
	if tasks_resize_handle != null:
		tasks_resize_handle.visible = tasks_panel_visible
		if tasks_panel_visible:
			_update_tasks_resize_handle_position()
	_update_tasks_counter()

func _update_tasks_counter() -> void:
	if tasks_counter == null:
		return
	var total := todo_items.size()
	if total == 0:
		tasks_counter.text = UiStrings.t("tasks.counter_empty", ui_language)
		return
	var done := 0
	for item in todo_items:
		if bool(item.get("completed", false)):
			done += 1
	tasks_counter.text = UiStrings.t("tasks.counter", ui_language) % [total, done]

func _on_focus_primary_pressed() -> void:
	if focus_running:
		_on_stop_focus_pressed()
	else:
		_on_start_focus_pressed()

func _on_duration_chip_pressed(minutes: int) -> void:
	if focus_custom_row != null:
		focus_custom_row.visible = false
	_set_focus_duration_minutes(minutes)

func _on_focus_custom_chip_pressed() -> void:
	if focus_custom_row == null:
		return
	focus_custom_row.visible = not focus_custom_row.visible
	if focus_custom_row.visible and focus_custom_input != null:
		focus_custom_input.grab_focus()

func _on_focus_custom_apply_pressed() -> void:
	var minutes := _parse_minutes_input()
	if minutes <= 0:
		_show_system_status("Enter a number of minutes first.")
		return
	if focus_custom_row != null:
		focus_custom_row.visible = false
	_set_focus_duration_minutes(minutes)

func _on_focus_custom_input_submitted(_submitted_text: String) -> void:
	_on_focus_custom_apply_pressed()

func _set_focus_duration_minutes(minutes: int) -> void:
	focus_duration_seconds = float(minutes) * 60.0
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	_update_timer_label()
	_refresh_focus_controls()
	_highlight_duration_chip(minutes)
	_show_system_status("%s Timer set to %d minutes." % [FOCUS_SET_LINE, minutes])
	_save_persistent_state()

func _highlight_duration_chip(minutes: int) -> void:
	if focus_chips_box == null:
		return
	var matched := false
	for chip in focus_chips_box.get_children():
		if not chip is Button or chip == focus_chip_custom:
			continue
		var btn := chip as Button
		var chip_minutes := int(btn.text)
		var should_press := chip_minutes == minutes
		btn.set_pressed_no_signal(should_press)
		if should_press:
			matched = true
	if focus_chip_custom != null:
		focus_chip_custom.set_pressed_no_signal(not matched)

func _on_tasks_tab_pressed() -> void:
	tasks_panel_visible = not tasks_panel_visible
	_refresh_tasks_controls()
	if tasks_panel_visible and new_task_input != null:
		new_task_input.grab_focus()
	_save_persistent_state()

func _on_tasks_close_pressed() -> void:
	tasks_panel_visible = false
	_refresh_tasks_controls()
	_save_persistent_state()

func _on_tasks_resize_handle_input(event: InputEvent) -> void:
	if tasks_panel == null or tasks_resize_handle == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			resizing_tasks_panel = true
			resize_start_mouse_position = get_global_mouse_position()
			resize_start_tasks_left = tasks_panel.offset_left
			resize_start_tasks_top = tasks_panel.offset_top
			tasks_resize_handle.grab_focus()
		else:
			if resizing_tasks_panel:
				resizing_tasks_panel = false
				_save_persistent_state()
		accept_event()
		return

	if event is InputEventMouseMotion and resizing_tasks_panel:
		var delta := get_global_mouse_position() - resize_start_mouse_position
		_apply_tasks_panel_offsets(resize_start_tasks_left + delta.x, resize_start_tasks_top + delta.y)
		accept_event()

func _apply_tasks_panel_offsets(left_offset: float, top_offset: float) -> void:
	if tasks_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var fixed_right := tasks_panel.offset_right
	var clamped_left := clampf(
		left_offset,
		fixed_right - TODO_PANEL_MAX_WIDTH,
		fixed_right - TODO_PANEL_MIN_WIDTH
	)

	var bottom_px := (tasks_panel.anchor_bottom * viewport_size.y) + tasks_panel.offset_bottom
	var anchor_top_px := tasks_panel.anchor_top * viewport_size.y
	var max_height := minf(TODO_PANEL_MAX_HEIGHT, bottom_px - TODO_PANEL_MIN_TOP)
	var min_top_px := maxf(TODO_PANEL_MIN_TOP, bottom_px - max_height)
	var max_top_px := bottom_px - TODO_PANEL_MIN_HEIGHT
	var requested_top_px := anchor_top_px + top_offset
	var clamped_top_px := clampf(requested_top_px, min_top_px, max_top_px)

	tasks_panel.offset_left = clamped_left
	tasks_panel.offset_top = clamped_top_px - anchor_top_px
	_update_tasks_resize_handle_position()

func _update_tasks_resize_handle_position() -> void:
	if tasks_resize_handle == null or tasks_panel == null:
		return
	tasks_resize_handle.anchor_left = tasks_panel.anchor_left
	tasks_resize_handle.anchor_right = tasks_panel.anchor_left
	tasks_resize_handle.anchor_top = tasks_panel.anchor_top
	tasks_resize_handle.anchor_bottom = tasks_panel.anchor_top
	tasks_resize_handle.offset_left = tasks_panel.offset_left - 12.0
	tasks_resize_handle.offset_top = tasks_panel.offset_top - 6.0
	tasks_resize_handle.offset_right = tasks_panel.offset_left - 4.0
	tasks_resize_handle.offset_bottom = tasks_panel.offset_top + 34.0

func _refresh_voice_button() -> void:
	if music_voice_button == null:
		return
	music_voice_button.text = _ui_text("voice_on") if voice_enabled else _ui_text("voice_off")

func _refresh_music_mode_button() -> void:
	if music_mode_button == null:
		return
	music_mode_button.set_item_text(0, _ui_text("loop"))
	music_mode_button.set_item_text(1, _ui_text("seq"))
	music_mode_button.set_item_text(2, _ui_text("random"))
	var mode := clampi(saved_music_playback_mode, 0, 2)
	music_mode_button.select(mode)

func _seed_todo_items() -> void:
	_add_todo_item("Set one gentle focus block")
	_add_todo_item("Write today's calm priority")
	_add_todo_item("Try one scripted greeting branch")

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
	current_choice_payloads = choices.duplicate(true)
	if dialogue_typewriter_active:
		pending_choice_payloads = choices.duplicate(true)
		_clear_choice_buttons()
		return

	_render_choices_now(choices)

func _render_choices_now(choices: Array) -> void:
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

func _clear_choice_buttons() -> void:
	for child in choice_list.get_children():
		child.queue_free()

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

func _show_todo_status(_text: String) -> void:
	# No-op since the toast label was removed; the bottom counter on the new
	# tasks panel replaces this feedback. Kept as a no-op so any straggling
	# callers do not crash.
	pass

func _set_dialogue_text(text: String) -> void:
	if dialogue_text == null:
		return
	dialogue_text.text = text
	_start_dialogue_typewriter(text)
	if dialogue_card != null:
		dialogue_card.visible = not text.strip_edges().is_empty()

func _hide_dialogue_text() -> void:
	dialogue_typewriter_active = false
	dialogue_typewriter_timer = 0.0
	dialogue_typewriter_total_chars = 0
	pending_choice_payloads.clear()
	if dialogue_text != null:
		dialogue_text.text = ""
		dialogue_text.visible_characters = -1
	if dialogue_card != null:
		dialogue_card.visible = false

func _start_dialogue_typewriter(text: String) -> void:
	pending_choice_payloads.clear()
	_clear_choice_buttons()

	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		dialogue_typewriter_active = false
		dialogue_text.visible_characters = -1
		return

	dialogue_typewriter_active = true
	dialogue_typewriter_timer = 0.0
	dialogue_typewriter_total_chars = text.length()
	dialogue_text.visible_characters = 0

func _update_dialogue_typewriter(delta: float) -> void:
	if not dialogue_typewriter_active or dialogue_text == null:
		return

	dialogue_typewriter_timer += delta
	var visible_count := int(floor(dialogue_typewriter_timer * dialogue_typewriter_chars_per_second))
	dialogue_text.visible_characters = mini(visible_count, dialogue_typewriter_total_chars)

	if dialogue_text.visible_characters >= dialogue_typewriter_total_chars:
		_finish_dialogue_typewriter()

func _finish_dialogue_typewriter() -> void:
	if dialogue_text != null:
		dialogue_text.visible_characters = -1
	dialogue_typewriter_active = false

	var choices_to_show := pending_choice_payloads
	if choices_to_show.is_empty() and not current_choice_payloads.is_empty() and not focus_running:
		choices_to_show = current_choice_payloads
	pending_choice_payloads = []
	if not choices_to_show.is_empty():
		_render_choices_now(choices_to_show)

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
		var click_intro_id := intro_node_id if scripted_dialogue_manager.has_dialogue_node(intro_node_id) else "return_open_01"
		_show_node(click_intro_id)
		return

	_set_status_message("")
	if current_ai_mode_id.is_empty():
		_set_dialogue_text("我在。先选一个回复，或者在下面写你自己的话。")
	else:
		_set_dialogue_text("我在。想继续自己写就继续，不想的话也可以回到按钮。")
	_play_voice_for_line("prompt_pick_response", dialogue_text.text)

func _show_focus_click_line() -> void:
	var pool: PackedStringArray = _reactive_pool("focus_click")
	if pool.is_empty():
		return
	focus_click_count += 1
	var line_index := randi() % pool.size()
	if focus_click_count > 3:
		_set_dialogue_text("……")
	else:
		_set_dialogue_text(pool[line_index])
	_set_status_message("")
	_play_voice_for_line("focus_click_%02d" % focus_click_count, dialogue_text.text)

func _on_choice_selected(choice_data: Dictionary) -> void:
	_apply_choice_flags(choice_data)
	var next_node_id := str(choice_data.get("next", "greeting_01"))
	var internal_return := bool(choice_data.get("internal_return", false))
	if internal_return:
		_return_to_scripted_node(next_node_id)
		return
	if next_node_id == "EXIT_DONE" and _should_use_night_exit():
		next_node_id = "EXIT_NIGHT"
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

func _apply_choice_flags(choice_data: Dictionary) -> void:
	if memory_manager == null:
		return
	var flag_data = choice_data.get("set_flag", null)
	if typeof(flag_data) != TYPE_DICTIONARY:
		return
	if not memory_manager.has_method("set_story_flag"):
		return
	for key in flag_data.keys():
		memory_manager.call("set_story_flag", str(key), flag_data[key])

func _should_use_night_exit() -> bool:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var hour := int(now.get("hour", 12))
	return hour >= 22 or hour < 2

func _handle_special_choice(next_node_id: String) -> bool:
	match next_node_id:
		"ACTION_DEMO_TASK":
			_capture_focus_task("整理一个小任务，先推进一点点")
			return true
		"ACTION_SET_TIMER_1":
			_set_focus_seconds_from_script(QUICK_TEST_SECONDS, "3 秒试玩，够看一眼效果。")
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
		"ACTION_QUICK_FOCUS":
			_start_quick_focus_from_script()
			return true
		_:
			return false

func _set_focus_seconds_from_script(seconds: float, yua_line: String) -> void:
	focus_duration_seconds = maxf(seconds, 1.0)
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	_update_timer_label()
	_refresh_focus_controls()
	_highlight_duration_chip(int(round(focus_duration_seconds / 60.0)))
	_save_persistent_state()
	current_node_id = "FOCUS_READY_001"
	_set_dialogue_text("%s\n\n%s" % [yua_line, "准备好了就开始。"])
	_set_status_message("Timer set to %s." % _format_time_label(focus_time_left))
	_render_choices([
		{"text": "开始专注", "next": "ACTION_START_FOCUS"},
		{"text": "换个任务", "next": "TASK_INPUT_001"}
	])
	_play_voice_for_line("timer_set_quick", dialogue_text.text)

func _set_focus_minutes_from_script(minutes: int, yua_line: String) -> void:
	focus_duration_seconds = float(minutes) * 60.0
	focus_time_left = focus_duration_seconds
	focus_running = false
	focus_last_tick_ms = 0
	_update_timer_label()
	_refresh_focus_controls()
	_highlight_duration_chip(minutes)
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

func _start_quick_focus_from_script() -> void:
	if current_focus_task.strip_edges().is_empty():
		current_focus_task = "继续刚才那件事"
	_set_dialogue_text("那就不重新报任务了。\n\n我们继续做自己的事。")
	_start_focus_from_script()

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
	_refresh_tasks_controls()
	current_node_id = "TASK_INPUT_002"
	_set_dialogue_text("……好。\n\n“%s”。\n\n不是很大，但很实际。这种任务我最喜欢，完成了有感觉。\n\n选个时长吧。" % current_focus_task)
	_set_status_message("Task captured.")
	_render_choices([
		{"text": "3 秒试玩", "next": "ACTION_SET_TIMER_1"},
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
	if ai_modes.has(node_id):
		return str(ai_modes[node_id])
	if ai_modes.has("default"):
		return str(ai_modes["default"])
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

func _update_timer_label() -> void:
	if focus_timer_display == null:
		return
	var rounded_seconds := maxi(0, int(ceil(focus_time_left)))
	var minutes := int(rounded_seconds / 60.0)
	var seconds := rounded_seconds % 60
	focus_timer_display.text = "%02d:%02d" % [minutes, seconds]
	if focus_progress != null and focus_duration_seconds > 0.0:
		focus_progress.max_value = focus_duration_seconds
		focus_progress.value = focus_duration_seconds - focus_time_left

func _format_time_label(seconds_left: float) -> String:
	var rounded_seconds := maxi(0, int(ceil(seconds_left)))
	var minutes := int(rounded_seconds / 60.0)
	var seconds := rounded_seconds % 60
	return "%02d:%02d" % [minutes, seconds]

func _parse_minutes_input() -> int:
	if focus_custom_input == null:
		return -1
	var text := focus_custom_input.text.strip_edges()
	if text.is_empty():
		return -1
	if not text.is_valid_int():
		return -1
	return int(text)

func _on_new_task_submitted(_submitted_text: String) -> void:
	_add_task_from_input()

func _add_task_from_input() -> void:
	if new_task_input == null:
		return
	var task_text := new_task_input.text.strip_edges()
	if task_text.is_empty():
		return
	_add_todo_item(task_text)
	new_task_input.clear()
	_refresh_tasks_controls()
	_save_persistent_state()

func _add_todo_item(text: String, completed: bool = false) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return
	todo_items.append({"text": clean_text, "completed": completed})
	_render_tasks()

func _render_tasks() -> void:
	if tasks_rows == null:
		return
	for child in tasks_rows.get_children():
		child.queue_free()
	hovered_task_index = -1

	if todo_items.is_empty():
		var ghost := Label.new()
		ghost.text = UiStrings.t("tasks.empty", ui_language)
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.add_theme_color_override("font_color", Color(0.901961, 0.811765, 0.682353, 0.5))
		ghost.add_theme_font_size_override("font_size", 13)
		tasks_rows.add_child(ghost)
		_update_tasks_counter()
		return

	for index in range(todo_items.size()):
		var data := todo_items[index]
		var completed := bool(data.get("completed", false))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 32)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.mouse_entered.connect(_on_task_row_mouse_entered.bind(index))
		row.mouse_exited.connect(_on_task_row_mouse_exited.bind(index))

		var done_toggle := Button.new()
		done_toggle.toggle_mode = true
		done_toggle.flat = true
		done_toggle.custom_minimum_size = Vector2(24, 24)
		done_toggle.text = "●" if completed else "◯"
		done_toggle.button_pressed = completed
		done_toggle.tooltip_text = UiStrings.t("tasks.mark_done", ui_language)
		done_toggle.add_theme_font_size_override("font_size", 18)
		var done_color := get_theme_color("sage", "Palette") if completed else get_theme_color("sand", "Palette")
		done_toggle.add_theme_color_override("font_color", done_color)
		done_toggle.add_theme_color_override("font_hover_color", get_theme_color("honey_amber", "Palette"))
		done_toggle.toggled.connect(_on_todo_completed_toggled.bind(index))
		row.add_child(done_toggle)

		var text_field := LineEdit.new()
		text_field.text = str(data.get("text", ""))
		text_field.custom_minimum_size = Vector2(0, 28)
		text_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_field.placeholder_text = UiStrings.t("tasks.task_placeholder", ui_language)
		text_field.flat = true
		text_field.text_changed.connect(_on_todo_text_changed.bind(index))
		if completed:
			text_field.add_theme_color_override("font_color", Color(0.901961, 0.811765, 0.682353, 0.55))
		else:
			text_field.add_theme_color_override("font_color", get_theme_color("cream", "Palette"))
		row.add_child(text_field)

		var delete_button := Button.new()
		delete_button.text = "✕"
		delete_button.custom_minimum_size = Vector2(24, 24)
		delete_button.flat = true
		delete_button.visible = false
		delete_button.tooltip_text = UiStrings.t("tasks.delete", ui_language)
		delete_button.add_theme_font_size_override("font_size", 14)
		delete_button.add_theme_color_override("font_color", get_theme_color("brick_warm", "Palette"))
		delete_button.add_theme_color_override("font_hover_color", get_theme_color("cream", "Palette"))
		delete_button.pressed.connect(_on_todo_delete_pressed.bind(index))
		row.add_child(delete_button)
		row.set_meta("delete_button", delete_button)

		tasks_rows.add_child(row)

	_update_tasks_counter()

func _on_task_row_mouse_entered(index: int) -> void:
	hovered_task_index = index
	_update_task_row_delete_visibility(index, true)

func _on_task_row_mouse_exited(index: int) -> void:
	if hovered_task_index == index:
		hovered_task_index = -1
	_update_task_row_delete_visibility(index, false)

func _update_task_row_delete_visibility(index: int, visible: bool) -> void:
	if tasks_rows == null:
		return
	if index < 0 or index >= tasks_rows.get_child_count():
		return
	var row := tasks_rows.get_child(index)
	if not row.has_meta("delete_button"):
		return
	var btn: Button = row.get_meta("delete_button")
	if btn != null:
		btn.visible = visible

func _on_todo_text_changed(new_text: String, index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items[index]["text"] = new_text
	_save_persistent_state()

func _on_todo_completed_toggled(completed: bool, index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items[index]["completed"] = completed
	_render_tasks()
	_refresh_tasks_controls()
	_save_persistent_state()

func _on_todo_delete_pressed(index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items.remove_at(index)
	_render_tasks()
	_refresh_tasks_controls()
	_save_persistent_state()

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
	var episode_index: int = completed_focus_sessions - 1
	if episode_index >= 0 and episode_index < episode_start_nodes.size():
		var ep_node_id: String = episode_start_nodes[episode_index]
		if scripted_dialogue_manager.has_dialogue_node(ep_node_id):
			_show_node(ep_node_id)
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

	if demo_script_version_seen < demo_script_version and scripted_dialogue_manager.has_dialogue_node(intro_node_id):
		demo_script_version_seen = demo_script_version
		has_seen_intro = true
		completed_focus_sessions = 0
		current_focus_task = ""
		return intro_node_id

	if not has_seen_intro and scripted_dialogue_manager.has_dialogue_node(intro_node_id):
		has_seen_intro = true
		return intro_node_id

	if has_seen_intro and _should_use_short_return_node() and scripted_dialogue_manager.has_dialogue_node("return_open_short"):
		return "return_open_short"

	var time_greeting_id := _pick_time_greeting_node_id()
	if has_seen_intro and not time_greeting_id.is_empty():
		return time_greeting_id

	if has_seen_intro and scripted_dialogue_manager.has_dialogue_node("return_open_01"):
		return "return_open_01"

	return current_node_id

func _pick_time_greeting_node_id() -> String:
	if scripted_dialogue_manager == null:
		return ""
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var hour := int(now.get("hour", 12))
	var bucket := "night"
	if hour >= 6 and hour < 11:
		bucket = "morning"
	elif hour >= 11 and hour < 14:
		bucket = "noon"
	elif hour >= 17 and hour < 20:
		bucket = "evening"
	elif hour >= 20 or hour < 2:
		bucket = "night"
	else:
		return ""
	var candidates: Array[String] = []
	for index in range(1, 9):
		var node_id := "greeting_%s_%02d" % [bucket, index]
		if scripted_dialogue_manager.has_dialogue_node(node_id):
			candidates.append(node_id)
	if candidates.is_empty():
		return ""
	return candidates[randi() % candidates.size()]

func _should_use_short_return_node() -> bool:
	if last_seen_unix <= 0:
		return false
	var now_unix := int(Time.get_unix_time_from_system())
	var elapsed := now_unix - last_seen_unix
	return elapsed >= 0 and elapsed <= 30 * 60

func _maybe_autosave() -> void:
	var current_second := int(focus_time_left)
	if focus_running and current_second != last_saved_second:
		last_saved_second = current_second
		_save_persistent_state()

func _save_persistent_state() -> void:
	var todo_payload: Array = []
	for item_data in todo_items:
		var clean_text := str(item_data.get("text", "")).strip_edges()
		if clean_text.is_empty():
			continue
		todo_payload.append({
			"text": clean_text,
			"completed": bool(item_data.get("completed", false))
		})

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
		"last_seen_unix": int(Time.get_unix_time_from_system()),
		"music_track_index": saved_music_index,
		"music_paused": bgm_paused,
		"music_playback_mode": saved_music_playback_mode,
		"voice_enabled": voice_enabled,
		"ui_language": ui_language,
		"dialogue_typewriter_chars_per_second": dialogue_typewriter_chars_per_second,
		"todo_panel_left": tasks_panel.offset_left if tasks_panel != null else 0.0,
		"todo_panel_top": tasks_panel.offset_top if tasks_panel != null else 0.0,
		"tasks_panel_visible": tasks_panel_visible
	}

	if bgm_manager != null and bgm_manager.has_method("get_current_index"):
		payload["music_track_index"] = int(bgm_manager.call("get_current_index"))
		saved_music_index = int(payload["music_track_index"])
	if bgm_manager != null and bgm_manager.has_method("get_playback_mode"):
		payload["music_playback_mode"] = int(bgm_manager.call("get_playback_mode"))
		saved_music_playback_mode = int(payload["music_playback_mode"])
	saved_music_paused = bgm_paused

	# Write session/UI fields into the single shared profile, then persist it.
	if memory_manager == null:
		return
	memory_manager.merge_values(payload)
	memory_manager.save_profile()

func _load_persistent_state() -> void:
	if memory_manager == null:
		return
	var data: Dictionary = memory_manager.get_profile()
	if data.is_empty():
		return

	focus_duration_seconds = float(data.get("focus_duration_seconds", FOCUS_DURATION_SECONDS))
	focus_time_left = float(data.get("focus_time_left", focus_duration_seconds))
	focus_running = bool(data.get("focus_running", false))
	current_node_id = str(data.get("last_node_id", "idle"))
	has_seen_intro = bool(data.get("has_seen_intro", false))
	demo_script_version_seen = int(data.get("demo_script_version_seen", 0))
	completed_focus_sessions = int(data.get("completed_focus_sessions", 0))
	current_focus_task = str(data.get("current_focus_task", ""))
	last_seen_unix = int(data.get("last_seen_unix", 0))
	current_ai_mode_id = ""
	ai_return_node_id = current_node_id
	saved_music_index = int(data.get("music_track_index", 0))
	saved_music_paused = bool(data.get("music_paused", true))
	saved_music_playback_mode = int(data.get("music_playback_mode", 0))
	voice_enabled = bool(data.get("voice_enabled", true))
	ui_language = str(data.get("ui_language", "en"))
	if ui_language != "zh":
		ui_language = "en"
	dialogue_typewriter_chars_per_second = clampf(
		float(data.get("dialogue_typewriter_chars_per_second", DEFAULT_DIALOGUE_TYPEWRITER_CHARS_PER_SECOND)),
		text_speed_slider.min_value,
		text_speed_slider.max_value
	)
	suppress_settings_save = true
	text_speed_slider.value = dialogue_typewriter_chars_per_second
	suppress_settings_save = false
	if tasks_panel != null and (data.has("todo_panel_left") or data.has("todo_panel_top")):
		_apply_tasks_panel_offsets(
			float(data.get("todo_panel_left", tasks_panel.offset_left)),
			float(data.get("todo_panel_top", tasks_panel.offset_top))
		)
	tasks_panel_visible = bool(data.get("tasks_panel_visible", false))
	focus_last_tick_ms = Time.get_ticks_msec()
	last_saved_second = int(focus_time_left)

	todo_items.clear()
	for todo in data.get("todos", []):
		var todo_data: Dictionary = todo
		_add_todo_item(str(todo_data.get("text", "")), bool(todo_data.get("completed", false)))
	_refresh_ui_language()
	_refresh_tasks_controls()

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
	_save_persistent_state()

func _on_settings_button_pressed() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_language_button_pressed() -> void:
	ui_language = "zh" if ui_language == "en" else "en"
	_refresh_ui_language()
	_save_persistent_state()

func _on_text_speed_changed(value: float) -> void:
	dialogue_typewriter_chars_per_second = value
	if speed_value_label != null:
		speed_value_label.text = _ui_text("chars_per_second") % int(round(dialogue_typewriter_chars_per_second))
	if suppress_settings_save:
		return
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
	if song_name == "No track loaded":
		song_name = _ui_text("no_track")

	music_song_label.text = _ui_text("song") + song_name
	var is_playing := false
	if bgm_manager != null and bgm_manager.has_method("is_playing"):
		is_playing = bool(bgm_manager.call("is_playing"))
	bgm_paused = not is_playing
	music_play_pause_button.text = _ui_text("play") if bgm_paused else _ui_text("pause")
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

## ---------------------------------------------------------------------------
## Loaders for data/dialogue/* metadata. Keeping them in one block so future
## "we want X data-driven" changes have a clear home.
## ---------------------------------------------------------------------------

func _load_episode_metadata_from_manager() -> void:
	if scripted_dialogue_manager == null:
		return
	if scripted_dialogue_manager.has_metadata("intro_node"):
		intro_node_id = str(scripted_dialogue_manager.get_metadata("intro_node"))
	if scripted_dialogue_manager.has_metadata("demo_script_version"):
		demo_script_version = int(scripted_dialogue_manager.get_metadata("demo_script_version"))
	episode_metadata.clear()
	episode_start_nodes = PackedStringArray()
	if not scripted_dialogue_manager.has_metadata("episodes"):
		return
	var raw_eps = scripted_dialogue_manager.get_metadata("episodes")
	if typeof(raw_eps) != TYPE_ARRAY:
		return
	# Sort by session_gate so episode_start_nodes[i] is the i+1-th completed session's episode.
	var sortable: Array = []
	for entry in raw_eps:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var ep_dict: Dictionary = entry
		if not ep_dict.has("start_node") or not ep_dict.has("session_gate"):
			continue
		sortable.append(ep_dict)
	sortable.sort_custom(func(a, b): return int(a.get("session_gate", 0)) < int(b.get("session_gate", 0)))
	for ep_dict in sortable:
		episode_metadata.append(ep_dict)
		episode_start_nodes.append(str(ep_dict.get("start_node", "")))

func _load_reactive_lines() -> void:
	reactive_lines = _load_json_dict(REACTIVE_LINES_PATH)

func _load_ai_modes() -> void:
	ai_modes = _load_json_dict(AI_MODES_PATH)

func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("main_scene: missing data file %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("main_scene: %s root is not a JSON object" % path)
		return {}
	return parsed

func _reactive_pool(category: String) -> PackedStringArray:
	var raw = reactive_lines.get(category, [])
	if typeof(raw) != TYPE_ARRAY:
		return PackedStringArray()
	var out := PackedStringArray()
	for item in raw:
		out.append(str(item))
	return out

# ============================================================================
# DEBUG TIMELINE — dev-only episode jumper.
# To remove for production:
#   1. delete the `_debug_timeline_setup()` call in _ready()
#   2. delete everything between this marker and the END DEBUG TIMELINE marker.
# ============================================================================
const DEBUG_TIMELINE_ENABLED := true
var _debug_timeline_panel: PanelContainer = null

func _debug_timeline_entries() -> Array:
	# Build from intro_node_id + episode_metadata (loaded from scripted_nodes.json).
	# Adding a new episode in JSON automatically adds a button here — no .gd edit.
	var out: Array = [
		{"label": "Ep 0 (intro)", "node": intro_node_id, "session_count": 0}
	]
	for ep in episode_metadata:
		if typeof(ep) != TYPE_DICTIONARY:
			continue
		var ep_dict: Dictionary = ep
		var label_text: String = str(ep_dict.get("label", str(ep_dict.get("id", "Ep ?"))))
		var node_id: String = str(ep_dict.get("start_node", ""))
		var session_count: int = int(ep_dict.get("session_gate", 0))
		if node_id.is_empty():
			continue
		out.append({"label": label_text, "node": node_id, "session_count": session_count})
	return out

func _debug_timeline_setup() -> void:
	if not DEBUG_TIMELINE_ENABLED:
		return
	if _debug_timeline_panel != null:
		return
	var panel := PanelContainer.new()
	panel.name = "DebugTimelinePanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = 1000  # Force draw on top of video / companion stage.
	# Top-center thin horizontal bar — avoids existing UI on left/right.
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -300.0
	panel.offset_right = 300.0
	panel.offset_top = 8.0
	panel.offset_bottom = 48.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.05, 0.05, 0.95)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color(1, 0.6, 0.2, 1.0)
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	margin.add_child(hbox)

	var title := Label.new()
	title.text = "DEBUG"
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	hbox.add_child(title)

	for entry in _debug_timeline_entries():
		var button := Button.new()
		var label_text := str(entry.get("label", "Ep ?"))
		var node_id := str(entry.get("node", ""))
		var session_count := int(entry.get("session_count", 0))
		button.text = label_text
		button.custom_minimum_size = Vector2(0, 24)
		button.pressed.connect(_debug_timeline_jump.bind(node_id, session_count))
		hbox.add_child(button)

	var reset_button := Button.new()
	reset_button.text = "Reset Save"
	reset_button.custom_minimum_size = Vector2(0, 24)
	reset_button.tooltip_text = "Delete save files (restart game to take effect)"
	reset_button.pressed.connect(_debug_timeline_reset_save)
	hbox.add_child(reset_button)

	add_child(panel)
	panel.move_to_front()
	_debug_timeline_panel = panel
	print_rich("[color=orange][DEBUG TIMELINE][/color] panel added at top-center. children=%d" % get_child_count())

func _debug_timeline_jump(node_id: String, session_count: int) -> void:
	if node_id.is_empty():
		return
	if scripted_dialogue_manager == null or not scripted_dialogue_manager.has_dialogue_node(node_id):
		_set_status_message("DEBUG: node '%s' not found." % node_id)
		return
	# Stop any running timer so we drop cleanly into the chosen scene.
	if focus_running:
		focus_running = false
		focus_time_left = focus_duration_seconds
		_update_timer_label()
		_refresh_focus_controls()
	completed_focus_sessions = session_count
	has_seen_intro = node_id != intro_node_id
	_enter_scripted_mode()
	_show_node(node_id)
	_set_status_message("DEBUG: jumped to %s (sessions=%d)" % [node_id, session_count])
	_save_persistent_state()

func _debug_timeline_reset_save() -> void:
	var paths := [
		"user://player_profile.json",
		"user://data/saves/player_profile.json"
	]
	for path in paths:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_set_status_message("DEBUG: save cleared. Restart the game.")
# ============================================================================
# END DEBUG TIMELINE
# ============================================================================
