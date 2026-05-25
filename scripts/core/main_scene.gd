extends Control

const FOCUS_DURATION_SECONDS: float = 25.0 * 60.0
# Save now lives in one profile owned by memory_manager
# (user://data/saves/player_profile.json). main_scene reads/writes via it.
const LOOP_VIDEO_PATH := "res://assets/video/yua_idle_loop.ogv"
const FOCUS_COMPLETE_LINE := "Focus block complete. Nice work."
const PERSONA_PATH := "res://data/dialogue/yua_system_prompt.txt"
const WORLD_PATH := "res://data/dialogue/yua_world.txt"
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
const DEFAULT_DIALOGUE_TYPEWRITER_CHARS_PER_SECOND := 34.0
const TASK_PANEL_LAYOUT_VERSION := 3
# Reactive line pools (focus_click etc) live in data/dialogue/reactive_lines.json
# and are loaded at runtime into `reactive_lines`. Add a new pool by adding a
# new key in that JSON — no code change needed unless a brand new trigger is added.

@onready var dialogue_text: RichTextLabel = $BottomPanel/DialoguePanel/DialogueCard/DialogueMargin/DialogueText
@onready var dialogue_card: PanelContainer = $BottomPanel/DialoguePanel/DialogueCard
@onready var response_card: Control = $BottomPanel/DialoguePanel/ResponseCard
@onready var choice_list: Node = $BottomPanel/DialoguePanel/ResponseCard/ChoiceList
@onready var input_row: Control = $BottomPanel/DialoguePanel/InputRow
@onready var player_input: LineEdit = $BottomPanel/DialoguePanel/InputRow/PlayerInput
@onready var ai_mode_toggle: CheckButton = null  # AIModeToggle removed from UI; all uses are null-checked
@onready var status_label: Label = $BottomPanel/DialoguePanel/ResponseCard/StatusLabel
@onready var send_button: Button = $BottomPanel/DialoguePanel/InputRow/SendButton
@onready var chat_history_button: Button = $ChatHistoryButton
@onready var chat_history_panel: Control = $ChatHistoryPanel
@onready var chat_history_rows: VBoxContainer = $ChatHistoryPanel/Margin/VBox/Scroll/HistoryRows
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
@onready var tasks_ui: Node = $OverlayLayer/Tools
@onready var music_bar: Node = $BottomLeftMusicBar
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

# Pure deterministic progression gate (static helpers). Preloaded as a const so
# the static calls resolve without depending on global class_name timing.
const ProgressionGate = preload("res://scripts/core/progression_gate.gd")

var current_node_id: String = "idle"
var focus_duration_seconds: float = FOCUS_DURATION_SECONDS
var focus_time_left: float = FOCUS_DURATION_SECONDS
var focus_running: bool = false
var focus_last_tick_ms: int = 0
var last_saved_second: int = -1
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
# The last_seen_unix value loaded at launch (the PREVIOUS session's stamp). Kept
# separate because _save_persistent_state overwrites last_seen_unix with "now"
# every save, which would otherwise make return detection always read "just now".
var previous_last_seen_unix: int = 0
var ui_language: String = "en"
var dialogue_typewriter_chars_per_second: float = DEFAULT_DIALOGUE_TYPEWRITER_CHARS_PER_SECOND
var chat_history: Array = []
var suppress_settings_save: bool = false
var dialogue_typewriter_active: bool = false
var dialogue_typewriter_timer: float = 0.0
var dialogue_typewriter_total_chars: int = 0
var pending_choice_payloads: Array = []
var current_choice_payloads: Array = []

# --- Vertical Slice 01 progression / co-presence state ----------------------
# Persisted via _save_persistent_state (single profile, owned by memory_manager).
# completed_focus_sessions (above) is persisted under the canonical save key
# `completed_focus_count`; the legacy key is still read on load for migration.
var total_focus_seconds: int = 0
var _focus_seconds_accum: float = 0.0  # sub-second carry for total_focus_seconds
var last_completed_focus_minutes: int = 0  # whole minutes of the just-finished session ({focus_minutes} token)
var focus_started_count: int = 0
var engaged_interaction_count: int = 0
var engaged_time_seconds: int = 0
var last_meaningful_interaction_at: String = ""
var _last_interaction_unix: int = 0
var return_count: int = 0
var yua_openness: int = 0
var current_story_milestone: String = ""
var player_nickname: String = ""
# Privacy / AI on-off backend flag. Settings UI flips it via set_ai_features_enabled.
# When false, dialogue_router makes no AI/network calls at all. Default on (mock).
var ai_features_enabled: bool = true
const ENGAGED_GAP_CAP_SECONDS := 60     # cap a single engaged-time gap (AFK-safe)
const NAME_INPUT_TAG := "name_input"    # narrative tags the Ep0 name node with this

# Loaded from data/dialogue/* on _ready. See REACTIVE_LINES_PATH / AI_MODES_PATH
# constants and the loader helpers near the bottom of the file.
var intro_node_id: String = DEFAULT_INTRO_NODE_ID
var demo_script_version: int = DEFAULT_DEMO_SCRIPT_VERSION
var episode_start_nodes: PackedStringArray = PackedStringArray()
var episode_metadata: Array = []
var reactive_lines: Dictionary = {}
var ai_modes: Dictionary = {}

func _ready() -> void:
	music_bar.setup(bgm_manager)
	_wire_signals()
	_configure_visual_mode()
	_configure_companion_controls()
	_setup_memory_profile()  # must exist before _load_persistent_state (single profile store)
	_load_persistent_state()
	_load_prompt_assets()
	call_status.refresh(ui_language, focus_running)
	_update_timer_label()
	add_child(scripted_dialogue_manager)
	scripted_dialogue_manager.load_from_path("res://data/dialogue/scripted_nodes.json")
	_load_episode_metadata_from_manager()
	_load_reactive_lines()
	_load_ai_modes()
	# Co-presence-first: land on idle (Yua quietly working). Do NOT auto-open the
	# greeting/return dialogue — that surfaces on the FIRST click of Yua (see
	# _on_character_clicked). The idle node's line is the gentle "click to talk"
	# hint, not a greeting. Spec: docs/AI_Context_Packet_Spec.md open-dep #2.
	current_node_id = "idle"
	ai_return_node_id = "idle"
	_setup_dialogue_services()
	_show_node("idle")
	_refresh_focus_controls()
	_highlight_duration_chip(int(round(focus_duration_seconds / 60.0)))
	tasks_ui.refresh_controls()
	_debug_timeline_setup()  # DEBUG_TIMELINE — remove this line for prod

func _process(delta: float) -> void:
	_update_dialogue_typewriter(delta)
	_update_focus_timer()
	call_status.refresh(ui_language, focus_running)
	_maybe_autosave()
	music_bar.update_progress()

# Any unhandled left-click (not on a Button / LineEdit / etc.) advances dialogue.
# This is more reliable than wiring gui_input on specific nodes and gives the
# standard visual-novel "click anywhere to continue" feel.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_on_subtitle_clicked()

func _load_prompt_assets() -> void:
	# Layer 1 (personality) + Layer 2 (world facts) form the persona system block,
	# in that order, per docs/AI_Context_Packet_Spec.md. Without Layer 2 the
	# aquarium / writing world facts never reach the model.
	persona_text = _load_text_file(PERSONA_PATH)
	var world_text := _load_text_file(WORLD_PATH)
	if not world_text.strip_edges().is_empty():
		if persona_text.strip_edges().is_empty():
			persona_text = world_text
		else:
			persona_text = persona_text + "\n\n" + world_text
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
	# Honor the persisted privacy flag: when AI is off the router never calls out.
	if dialogue_router.has_method("set_ai_allowed"):
		dialogue_router.call("set_ai_allowed", ai_features_enabled)
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
	tasks_ui.save_requested.connect(_save_persistent_state)
	if dialogue_card != null:
		dialogue_card.mouse_filter = Control.MOUSE_FILTER_STOP
		dialogue_card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		dialogue_card.gui_input.connect(_on_subtitle_input)
	if chat_history_button != null:
		chat_history_button.pressed.connect(_toggle_chat_history)
	var close_history_btn := get_node_or_null("ChatHistoryPanel/Margin/VBox/HeaderRow/CloseHistoryButton")
	if close_history_btn != null:
		close_history_btn.pressed.connect(_toggle_chat_history)
	settings_button.pressed.connect(_on_settings_button_pressed)
	language_button.pressed.connect(_on_language_button_pressed)
	text_speed_slider.value_changed.connect(_on_text_speed_changed)
	music_bar.save_requested.connect(_save_persistent_state)
	music_bar.voice_toggle_requested.connect(_on_voice_toggle_requested)
	music_bar.status_message.connect(_show_system_status)

func _configure_companion_controls() -> void:
	if player_input != null:
		player_input.clear_button_enabled = true
	if focus_custom_input != null:
		focus_custom_input.clear_button_enabled = true
	if dialogue_text != null:
		dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if dialogue_card != null:
		dialogue_card.visible = false
	if text_speed_slider != null:
		text_speed_slider.value = dialogue_typewriter_chars_per_second
	_refresh_ui_language()
	_refresh_focus_controls()
	tasks_ui.refresh_controls()

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
	if player_input == null:
		return
	var type_mode_on := ai_mode_toggle != null and ai_mode_toggle.button_pressed
	if type_mode_on:
		player_input.placeholder_text = _ui_text("type_input_placeholder")
	else:
		player_input.placeholder_text = _ui_text("input_placeholder")
	_update_response_slot_visibility()

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
	if send_button != null: send_button.text = _ui_text("send")
	if ai_mode_toggle != null: ai_mode_toggle.text = _ui_text("type_mode")
	_refresh_input_placeholder()
	music_bar.apply_language(ui_language)
	_update_timer_label()
	call_status.refresh(ui_language, focus_running)
	_refresh_focus_controls()
	tasks_ui.apply_language(ui_language)

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
	_apply_node_flags(node_data)
	var line_text := str(node_data.get("line", ""))
	_set_dialogue_text(line_text)
	_set_status_message("")
	_render_choices(_get_display_choices(node_data))
	_update_response_slot_visibility()
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
		_update_response_slot_visibility(false)
		return

	_render_choices_now(choices)

func _render_choices_now(choices: Array) -> void:
	for child in choice_list.get_children():
		child.queue_free()

	# A single choice means "click to continue" — no button shown; the subtitle
	# card itself is the tap target (see _on_subtitle_clicked).
	if choices.size() <= 1:
		_update_response_slot_visibility(false)
		return

	for choice in choices:
		var choice_button := Button.new()
		choice_button.text = _apply_text_tokens(str(choice.get("text", "Continue")))
		choice_button.custom_minimum_size = Vector2(0, 36)
		choice_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice_button.theme_type_variation = &"ChipButton"
		choice_button.pressed.connect(_on_choice_selected.bind(choice.duplicate(true)))
		choice_list.add_child(choice_button)
	_update_response_slot_visibility(true)

func _clear_choice_buttons() -> void:
	for child in choice_list.get_children():
		child.queue_free()
	_update_response_slot_visibility(false)

func _should_show_type_input() -> bool:
	if current_ai_mode_id != "":
		return true
	if _current_node_has_tag(NAME_INPUT_TAG):
		return true
	# Existing Ep0 name node predates the tag metadata; keep the UI behavior
	# stable even if the JSON is missing tags.
	return current_node_id == "ep00_04"

func _update_response_slot_visibility(has_visible_choices: bool = false) -> void:
	var allow_response_slot := not dialogue_typewriter_active
	var show_choices := allow_response_slot and has_visible_choices and not _should_show_type_input()
	var show_type := allow_response_slot and _should_show_type_input() and not show_choices
	if choice_list != null:
		choice_list.visible = show_choices
	if response_card != null:
		response_card.visible = show_choices
	if input_row != null:
		input_row.visible = show_type
	if show_type and player_input != null and not player_input.has_focus():
		player_input.grab_focus()

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

func _on_subtitle_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	_on_subtitle_clicked()

func _on_subtitle_clicked() -> void:
	# While the typewriter is running, click skips to the full line immediately.
	if dialogue_typewriter_active:
		_finish_dialogue_typewriter()
		return
	# With exactly one choice (a "Continue"-type advance), click the subtitle
	# to auto-select it — no button is shown.
	if current_choice_payloads.size() == 1:
		_on_choice_selected(current_choice_payloads[0].duplicate(true))
		return
	# Terminal node (0 choices, e.g. ep00_close): dismiss the card and enter
	# idle co-presence mode so the player isn't stuck.
	if current_choice_payloads.is_empty() and current_node_id != "idle":
		_hide_dialogue_text()
		current_node_id = "idle"

func _toggle_chat_history() -> void:
	if chat_history_panel == null:
		return
	chat_history_panel.visible = not chat_history_panel.visible
	if chat_history_panel.visible:
		_scroll_history_to_bottom()

func _append_history_entry(text: String) -> void:
	chat_history.append(text)
	if chat_history_rows == null:
		return
	var entry := Label.new()
	entry.text = text
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_theme_color_override("font_color", Color(0.901961, 0.811765, 0.682353, 0.88))
	entry.add_theme_font_size_override("font_size", 13)
	chat_history_rows.add_child(entry)
	_scroll_history_to_bottom()

func _scroll_history_to_bottom() -> void:
	var scroll := get_node_or_null("ChatHistoryPanel/Margin/VBox/Scroll")
	if not (scroll is ScrollContainer):
		return
	await get_tree().process_frame
	(scroll as ScrollContainer).scroll_vertical = 999999

func _show_todo_status(_text: String) -> void:
	# No-op since the toast label was removed; the bottom counter on the new
	# tasks panel replaces this feedback. Kept as a no-op so any straggling
	# callers do not crash.
	pass

func _set_dialogue_text(text: String) -> void:
	if dialogue_text == null:
		return
	text = _apply_text_tokens(text)
	dialogue_text.text = text
	_start_dialogue_typewriter(text)
	if dialogue_card != null:
		dialogue_card.visible = not text.strip_edges().is_empty()
	if not text.strip_edges().is_empty():
		_append_history_entry(text)

# Substitutes authored text tokens at render time. Today only {focus_minutes}:
# the whole-minute length of the just-completed focus session. When there's no
# usable value (e.g. the 3-second test chip), swap the known token-bearing phrase
# for a clean fallback and strip any stray token so no "{focus_minutes}" leaks.
func _apply_text_tokens(text: String) -> String:
	if not text.contains("{focus_minutes}"):
		return text
	if last_completed_focus_minutes > 0:
		return text.replace("{focus_minutes}", str(last_completed_focus_minutes))
	return text.replace("很充实，这 {focus_minutes} 分钟值了！", "很充实，坐得住！").replace("{focus_minutes}", "")

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
	else:
		_update_response_slot_visibility(false)

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

	# A click that opens talk is a light interaction: remembered + ambient warmth,
	# never story progress. (Clicks during focus go to the reactive pool above.)
	_note_meaningful_interaction()

	# If a line is still typing, reveal it fully first — don't act on the click yet.
	# (Prevents a click from skipping past a terminal payoff line into a re-engage.)
	if dialogue_typewriter_active:
		_finish_dialogue_typewriter()
		return

	# Re-enter the conversation whenever it's closed: either truly idle, OR sitting
	# on a finished terminal node (an episode/greeting that ended with empty choices).
	# Resolve a real line — greeting / return / next available beat — then surface
	# any pending memory follow-up. This is the fix for the old dead-end where
	# clicking Yua after an episode hit a legacy "先选一个回复" meta line.
	if current_node_id == "idle" or current_choice_payloads.is_empty():
		current_node_id = "idle"
		var start_id := _resolve_start_node_id()
		if start_id == "idle" or not scripted_dialogue_manager.has_dialogue_node(start_id):
			start_id = intro_node_id if scripted_dialogue_manager.has_dialogue_node(intro_node_id) else "return_open_01"
		_show_node(start_id)
		_maybe_show_follow_up()
		return

	# Single "continue"-type choice: clicking Yua advances it, same as tapping the
	# card (keeps the 1-choice intro nodes responsive to a Yua click).
	if current_choice_payloads.size() == 1:
		_on_choice_selected(current_choice_payloads[0].duplicate(true))
		return

	# Multi-choice mid-conversation. In Type Mode, nudge gently toward the
	# input/buttons; otherwise leave the visible choices to stand on their own
	# (no meta line — clicking Yua must never dead-end).
	if not current_ai_mode_id.is_empty():
		_set_status_message("")
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

# Apply node-level `set_flags` (preserved by ScriptedDialogueManager) when a node
# is shown. This is how authored milestones mark themselves, e.g. ep00_close sets
# `intro_seen`. AI never reaches this path — only authored nodes set flags.
func _apply_node_flags(node_data: Dictionary) -> void:
	if memory_manager == null or not memory_manager.has_method("set_story_flag"):
		return
	var flags = node_data.get("set_flags", {})
	if typeof(flags) != TYPE_DICTIONARY:
		return
	for key in flags.keys():
		memory_manager.call("set_story_flag", str(key), flags[key])

func _current_node_has_tag(tag: String) -> bool:
	if scripted_dialogue_manager == null:
		return false
	var node_data: Dictionary = scripted_dialogue_manager.get_dialogue_node(current_node_id)
	var tags: Array = node_data.get("tags", [])
	return tags.has(tag)

# Light interaction bookkeeping. Remembered + small ambient warmth, but it NEVER
# advances yua_openness or story flags — those come from focus only (see
# docs/Milestone_Contract_VS01.md and AGENTS.md). Called only on real, player-
# initiated interactions (a click that opens talk, a Type Mode send, a task
# entry), so pure AFK idling never bumps these counters.
func _note_meaningful_interaction() -> void:
	var now_unix := int(Time.get_unix_time_from_system())
	engaged_interaction_count += 1
	if _last_interaction_unix > 0:
		var gap := now_unix - _last_interaction_unix
		if gap > 0:
			engaged_time_seconds += mini(gap, ENGAGED_GAP_CAP_SECONDS)
	_last_interaction_unix = now_unix
	last_meaningful_interaction_at = Time.get_datetime_string_from_system()
	_save_persistent_state()

# Capture the nickname the player types at the Ep0 name node (tagged NAME_INPUT_TAG
# in the JSON). Stored as a value, not a flag (contract: player_nickname, nullable).
# Then advance via the node's authored first choice so its set_flags still apply.
func _capture_player_nickname(nickname: String) -> void:
	var clean := nickname.strip_edges()
	if clean.is_empty():
		return
	player_nickname = clean
	_note_meaningful_interaction()
	var node_data: Dictionary = scripted_dialogue_manager.get_dialogue_node(current_node_id)
	var choices: Array = node_data.get("choices", [])
	var next_id := ""
	if not choices.is_empty() and typeof(choices[0]) == TYPE_DICTIONARY:
		next_id = str((choices[0] as Dictionary).get("next", ""))
	if next_id.is_empty() or not scripted_dialogue_manager.has_dialogue_node(next_id):
		next_id = "ep00_close" if scripted_dialogue_manager.has_dialogue_node("ep00_close") else _safe_node_id()
	_show_node(next_id)

# Relationship progress is advanced ONLY here (on a completed focus). Monotonic.
func _apply_focus_completion_progress() -> void:
	# Whole-minute length of the session that just finished, for the {focus_minutes}
	# token (e.g. ep01_01's "这 {focus_minutes} 分钟值了"). 0 for the 3-sec test chip.
	last_completed_focus_minutes = int(round(focus_duration_seconds / 60.0))
	var tier := ProgressionGate.openness_tier_for(completed_focus_sessions, total_focus_seconds)
	yua_openness = maxi(yua_openness, tier)

# Snapshot of deterministic progression state for ProgressionGate. Note: no idle
# or light-interaction inputs — only focus, returns, flags, and memory presence.
func _build_progression_state() -> Dictionary:
	var flags: Dictionary = {}
	var memory_has := false
	if memory_manager != null:
		if memory_manager.has_method("get_story_flags"):
			flags = memory_manager.call("get_story_flags")
		if memory_manager.has_method("has_valid_memory"):
			memory_has = bool(memory_manager.call("has_valid_memory"))
	return {
		"completed_focus_count": completed_focus_sessions,
		"total_focus_seconds": total_focus_seconds,
		"return_count": return_count,
		"intro_seen": bool(flags.get("intro_seen", false)) or has_seen_intro,
		"story_flags": flags,
		"has_valid_memory": memory_has,
		"memory_echo_cooldown_active": false
	}

# Settings UI privacy hook (exposes the backend flag the UI session can flip).
func set_ai_features_enabled(enabled: bool) -> void:
	ai_features_enabled = enabled
	if dialogue_router != null and dialogue_router.has_method("set_ai_allowed"):
		dialogue_router.call("set_ai_allowed", ai_features_enabled)
	_save_persistent_state()

func is_ai_features_enabled() -> bool:
	return ai_features_enabled

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
	focus_started_count += 1
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
	if ai_mode_toggle != null and not ai_mode_toggle.button_pressed:
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
	if ai_mode_toggle != null:
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

	# Ep0 name node: a typed line becomes the player's nickname (a value, not a
	# flag). Narrative tags that node with NAME_INPUT_TAG.
	var type_mode_on := ai_mode_toggle != null and ai_mode_toggle.button_pressed
	if not type_mode_on and _current_node_has_tag(NAME_INPUT_TAG):
		_capture_player_nickname(text)
		return

	if not type_mode_on and current_node_id == "TASK_INPUT_001":
		_capture_focus_task(text)
		return

	if type_mode_on:
		# Presence hard gate: never call the LLM for chat during active focus —
		# use a deterministic reactive "later" line instead (AI_Context_Packet_Spec).
		if focus_running:
			_show_focus_click_line()
			return
		_note_meaningful_interaction()
		_set_status_message("Yua is thinking...")
		memory_manager.process_player_message(text)
		var mode_id := current_ai_mode_id if not current_ai_mode_id.is_empty() else current_node_id
		var context_packet := _build_context_packet(mode_id)
		var route: Dictionary = await dialogue_router.route_player_text_async(
			text,
			true,
			persona_text,
			context_packet,
			runtime_rules_text,
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
	_note_meaningful_interaction()
	memory_manager.process_player_message(current_focus_task)
	tasks_ui.add_todo_item(current_focus_task)
	tasks_ui.refresh_controls()
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

# --- Layer 3 context packet (docs/AI_Context_Packet_Spec.md) ----------------
# Assembled per-call from the single profile + the live moment. Injected after
# persona (Layer 1+2), before runtime rules. The AI only READS these — engine
# enforces the gates; the AI never sets a flag, advances openness, reveals the
# writing project, or invents a memory.
func _build_context_packet(mode_id: String) -> String:
	var sections: Array = []

	# Mode tone/intent (from ai_modes.json).
	var mode_tone := _get_mode_context_for_node(mode_id)
	if not mode_tone.strip_edges().is_empty():
		sections.append(mode_tone)

	# Structured per-call fields.
	var fields: Array = []
	fields.append("mode=%s" % mode_id)
	fields.append("presence_state=%s" % _presence_state_for_mode(mode_id))
	fields.append("time_bucket=%s" % _time_bucket())
	if not player_nickname.strip_edges().is_empty():
		fields.append("player_nickname=%s" % player_nickname)
	if not current_focus_task.strip_edges().is_empty():
		fields.append("current_task=%s" % current_focus_task)
	fields.append("completed_focus_count=%d" % completed_focus_sessions)
	fields.append("total_focus_seconds=%d" % total_focus_seconds)
	fields.append("return_context=%s" % _return_context())
	fields.append("yua_openness=%d" % yua_openness)
	var writing_disclosed := false
	if memory_manager != null and memory_manager.has_method("get_story_flag"):
		writing_disclosed = bool(memory_manager.call("get_story_flag", "yua_opened_once", false))
	fields.append("writing_disclosed=%s" % ("true" if writing_disclosed else "false"))
	var surfaced := _select_surfaced_memory()
	fields.append("surfaced_memory=%s" % ("none" if surfaced.is_empty() else surfaced))
	sections.append("[context]\n" + "\n".join(fields))

	# Restate the hard gates compactly so the model honors them.
	sections.append("[rules] Echo surfaced_memory only if it is not 'none'; never invent a memory. "
		+ "Do not reveal or describe the writing project unless writing_disclosed=true. "
		+ "Never act warmer/more disclosing than yua_openness allows. Never say you are an AI.")

	return "\n\n".join(sections)

func _presence_state_for_mode(mode_id: String) -> String:
	if focus_running:
		return "focus_active"
	if mode_id == "AI_MODE_BREAK_CHAT" or mode_id == "AI_MODE_POST_SESSION":
		return "break"
	return "idle"

func _time_bucket() -> String:
	var hour := int(Time.get_datetime_dict_from_system().get("hour", 12))
	if hour >= 6 and hour < 11:
		return "morning"
	if hour >= 11 and hour < 17:
		return "noon"
	if hour >= 17 and hour < 20:
		return "evening"
	return "night"

func _return_context() -> String:
	if previous_last_seen_unix <= 0:
		return "new_session"
	var elapsed := int(Time.get_unix_time_from_system()) - previous_last_seen_unix
	if elapsed < 0:
		return "new_session"
	if elapsed <= 30 * 60:
		return "short_return"
	return "long_return"

# One validated memory the game chooses to surface, or "" if none. Never invents.
func _select_surfaced_memory() -> String:
	if memory_manager == null or not memory_manager.has_method("get_surfaced_memory_fact"):
		return ""
	return str(memory_manager.call("get_surfaced_memory_fact"))

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


func _update_focus_timer() -> void:
	if not focus_running:
		return

	var now_ms := Time.get_ticks_msec()
	if focus_last_tick_ms == 0:
		focus_last_tick_ms = now_ms
	var elapsed_ms: int = maxi(0, now_ms - focus_last_tick_ms)
	focus_last_tick_ms = now_ms
	focus_time_left -= float(elapsed_ms) / 1000.0

	# Accumulate real focused time — the deterministic driver of the story.
	_focus_seconds_accum += float(elapsed_ms) / 1000.0
	if _focus_seconds_accum >= 1.0:
		var whole_seconds := int(floor(_focus_seconds_accum))
		total_focus_seconds += whole_seconds
		_focus_seconds_accum -= float(whole_seconds)

	if focus_time_left <= 0.0:
		focus_time_left = 0.0
		focus_running = false
		completed_focus_sessions += 1
		_apply_focus_completion_progress()
		_show_focus_complete_node()
		_refresh_focus_controls()
		_save_persistent_state()

	_update_timer_label()

func _show_focus_complete_node() -> void:
	# Focus is the only driver of story beats. The gate picks the eligible authored
	# beat deterministically from saved state + the JSON episode metadata; it never
	# forces — this fires at the natural moment a focus session ends.
	var state := _build_progression_state()
	var beat_node := ProgressionGate.select_focus_complete_node(state, episode_metadata)
	if not beat_node.is_empty() and scripted_dialogue_manager.has_dialogue_node(beat_node):
		current_story_milestone = ProgressionGate.current_milestone_label(state)
		_show_node(beat_node)
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
	# Use the PREVIOUS session's stamp, not last_seen_unix (which saves overwrite
	# with "now" during this session — see previous_last_seen_unix).
	if previous_last_seen_unix <= 0:
		return false
	var now_unix := int(Time.get_unix_time_from_system())
	var elapsed := now_unix - previous_last_seen_unix
	return elapsed >= 0 and elapsed <= 30 * 60

func _maybe_autosave() -> void:
	var current_second := int(focus_time_left)
	if focus_running and current_second != last_saved_second:
		last_saved_second = current_second
		_save_persistent_state()

func _save_persistent_state() -> void:
	# Keep the milestone label consistent with deterministic state on every save.
	current_story_milestone = ProgressionGate.current_milestone_label(_build_progression_state())
	var payload := {
		"focus_time_left": focus_time_left,
		"focus_duration_seconds": focus_duration_seconds,
		"focus_running": focus_running,
		"todos": tasks_ui.get_todos_payload(),
		"last_node_id": _safe_node_id(),
		"has_seen_intro": has_seen_intro,
		"demo_script_version_seen": demo_script_version_seen,
		"completed_focus_count": completed_focus_sessions,
		"current_focus_task": current_focus_task,
		"total_focus_seconds": total_focus_seconds,
		"last_completed_focus_minutes": last_completed_focus_minutes,
		"focus_started_count": focus_started_count,
		"engaged_interaction_count": engaged_interaction_count,
		"engaged_time_seconds": engaged_time_seconds,
		"last_meaningful_interaction_at": last_meaningful_interaction_at,
		"return_count": return_count,
		"current_story_milestone": current_story_milestone,
		"yua_openness": yua_openness,
		"player_nickname": player_nickname,
		"ai_features_enabled": ai_features_enabled,
		"last_seen_at": Time.get_datetime_string_from_system(),
		"last_seen_unix": int(Time.get_unix_time_from_system()),
		"music_track_index": music_bar.get_track_index(),
		"music_paused": music_bar.is_paused(),
		"music_playback_mode": music_bar.get_playback_mode(),
		"voice_enabled": voice_enabled,
		"ui_language": ui_language,
		"dialogue_typewriter_chars_per_second": dialogue_typewriter_chars_per_second,
		"task_panel_layout_version": TASK_PANEL_LAYOUT_VERSION,
		"todo_panel_left": tasks_ui.get_panel_left(),
		"todo_panel_top": tasks_ui.get_panel_top(),
		"tasks_panel_visible": tasks_ui.is_panel_visible()
	}

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
	# Canonical save key is completed_focus_count; fall back to the legacy name.
	completed_focus_sessions = int(data.get("completed_focus_count", data.get("completed_focus_sessions", 0)))
	current_focus_task = str(data.get("current_focus_task", ""))
	last_seen_unix = int(data.get("last_seen_unix", 0))
	previous_last_seen_unix = last_seen_unix  # snapshot before saves overwrite it
	total_focus_seconds = int(data.get("total_focus_seconds", 0))
	last_completed_focus_minutes = int(data.get("last_completed_focus_minutes", 0))
	focus_started_count = int(data.get("focus_started_count", 0))
	engaged_interaction_count = int(data.get("engaged_interaction_count", 0))
	engaged_time_seconds = int(data.get("engaged_time_seconds", 0))
	last_meaningful_interaction_at = str(data.get("last_meaningful_interaction_at", ""))
	return_count = int(data.get("return_count", 0))
	yua_openness = int(data.get("yua_openness", 0))
	current_story_milestone = str(data.get("current_story_milestone", ""))
	player_nickname = str(data.get("player_nickname", ""))
	ai_features_enabled = bool(data.get("ai_features_enabled", true))
	# Count this launch as a return once, if we've met Yua before.
	if has_seen_intro and last_seen_unix > 0:
		return_count += 1
	current_ai_mode_id = ""
	ai_return_node_id = current_node_id
	var loaded_music_index := int(data.get("music_track_index", 0))
	var loaded_music_paused := bool(data.get("music_paused", true))
	var loaded_music_mode := int(data.get("music_playback_mode", 0))
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
	var can_restore_task_panel_layout := int(data.get("task_panel_layout_version", 0)) == TASK_PANEL_LAYOUT_VERSION
	if can_restore_task_panel_layout and (data.has("todo_panel_left") or data.has("todo_panel_top")):
		tasks_ui.apply_panel_offsets(
			float(data.get("todo_panel_left", tasks_ui.get_panel_left())),
			float(data.get("todo_panel_top", tasks_ui.get_panel_top()))
		)
	tasks_ui.set_panel_visible(bool(data.get("tasks_panel_visible", false)))
	focus_last_tick_ms = Time.get_ticks_msec()
	last_saved_second = int(focus_time_left)

	tasks_ui.load_todos(data.get("todos", []))
	_refresh_ui_language()
	tasks_ui.refresh_controls()
	music_bar.start_playback(loaded_music_index, loaded_music_paused, loaded_music_mode)
	music_bar.set_voice_enabled(voice_enabled)

func _play_voice_for_line(line_id: String, text: String) -> void:
	if not voice_enabled:
		return
	if voice_manager == null:
		return

	if voice_manager.has_method("play_voice_for_line"):
		voice_manager.call("play_voice_for_line", line_id, text)

func _on_voice_toggle_requested() -> void:
	voice_enabled = not voice_enabled
	music_bar.set_voice_enabled(voice_enabled)
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
var _debug_ep_input: LineEdit = null

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

	# Compact jumper: type an episode number (0 = intro) and Go, or Next Ep.
	# Replaces the old 15-button row (Ep0 + 14 episodes was too wide).
	var ep_input := LineEdit.new()
	ep_input.placeholder_text = "EP"
	ep_input.custom_minimum_size = Vector2(44, 24)
	ep_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ep_input.text_submitted.connect(func(_submitted): _debug_timeline_go())
	hbox.add_child(ep_input)
	_debug_ep_input = ep_input

	var go_button := Button.new()
	go_button.text = "Go"
	go_button.custom_minimum_size = Vector2(0, 24)
	go_button.pressed.connect(_debug_timeline_go)
	hbox.add_child(go_button)

	var next_button := Button.new()
	next_button.text = "Next Ep"
	next_button.custom_minimum_size = Vector2(0, 24)
	next_button.pressed.connect(_debug_timeline_next)
	hbox.add_child(next_button)

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

func _debug_timeline_go() -> void:
	if _debug_ep_input == null:
		return
	var text := _debug_ep_input.text.strip_edges()
	if text.is_empty() or not text.is_valid_int():
		_set_status_message("DEBUG: enter an episode number (0 = intro).")
		return
	_debug_jump_to_episode(int(text))

func _debug_timeline_next() -> void:
	_debug_jump_to_episode(completed_focus_sessions + 1)

# N == 0 -> intro; otherwise epNN_01. session_count = N. Reuses _debug_timeline_jump
# (which validates the node exists and falls back with a status message if not).
func _debug_jump_to_episode(n: int) -> void:
	var episode_index := maxi(n, 0)
	var node_id := intro_node_id if episode_index == 0 else ("ep%02d_01" % episode_index)
	_debug_timeline_jump(node_id, episode_index)

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
