class_name MusicBarController
extends PanelContainer

# Owns the bottom-left music/voice bar (BottomLeftMusicBar): song label,
# progress bar, prev/play-pause/next buttons, the voice toggle, and the
# playback-mode dropdown. Actual audio lives in the injected BgmManager node;
# this component only drives the UI and forwards control intents.
#
# main_scene injects the manager via setup(), pushes saved state via
# start_playback()/set_voice_enabled(), refreshes text via apply_language(),
# and reads back state for saving via get_track_index()/is_paused()/
# get_playback_mode(). Persistence and voice playback stay in main_scene, so
# this component emits save_requested / voice_toggle_requested / status_message
# instead of touching them directly.

signal save_requested
signal voice_toggle_requested
signal status_message(text: String)

@onready var song_label: Label = $MusicMargin/MusicVBox/SongLabel
@onready var progress_bar: ProgressBar = $MusicMargin/MusicVBox/ProgressBar
@onready var prev_button: Button = $MusicMargin/MusicVBox/Controls/PrevButton
@onready var play_pause_button: Button = $MusicMargin/MusicVBox/Controls/PlayPauseButton
@onready var next_button: Button = $MusicMargin/MusicVBox/Controls/NextButton
@onready var voice_button: Button = $MusicMargin/MusicVBox/Controls/VoiceButton
@onready var mode_button: OptionButton = $MusicMargin/MusicVBox/Controls/PlaybackModeButton

var bgm_manager: Node
var language: String = "en"
var bgm_paused: bool = true
var voice_enabled: bool = true
var playback_mode: int = 0

func _ready() -> void:
	if prev_button != null:
		prev_button.pressed.connect(_on_prev_pressed)
	if play_pause_button != null:
		play_pause_button.pressed.connect(_on_play_pause_pressed)
	if next_button != null:
		next_button.pressed.connect(_on_next_pressed)
	if voice_button != null:
		voice_button.pressed.connect(_on_voice_pressed)
	if mode_button != null:
		mode_button.item_selected.connect(_on_mode_selected)
	if progress_bar != null:
		progress_bar.gui_input.connect(_on_progress_input)

func setup(manager: Node) -> void:
	bgm_manager = manager

func start_playback(saved_index: int, saved_paused: bool, saved_mode: int) -> void:
	playback_mode = clampi(saved_mode, 0, 2)
	if bgm_manager == null:
		return
	if bgm_manager.has_method("set_current_index"):
		bgm_manager.call("set_current_index", saved_index)
	if bgm_manager.has_method("set_playback_mode"):
		bgm_manager.call("set_playback_mode", playback_mode)
	if saved_paused:
		if bgm_manager.has_method("pause_bgm"):
			bgm_manager.call("pause_bgm")
		bgm_paused = true
	else:
		if bgm_manager.has_method("play_current"):
			bgm_manager.call("play_current")
		elif bgm_manager.has_method("play_default"):
			bgm_manager.call("play_default")
		bgm_paused = false
	refresh_bar()

func set_voice_enabled(enabled: bool) -> void:
	voice_enabled = enabled
	_refresh_voice_button()

func apply_language(lang: String) -> void:
	language = lang
	refresh_bar()

func get_track_index() -> int:
	if bgm_manager != null and bgm_manager.has_method("get_current_index"):
		return int(bgm_manager.call("get_current_index"))
	return 0

func is_paused() -> bool:
	return bgm_paused

func get_playback_mode() -> int:
	if bgm_manager != null and bgm_manager.has_method("get_playback_mode"):
		return int(bgm_manager.call("get_playback_mode"))
	return playback_mode

func update_progress() -> void:
	if bgm_manager == null or progress_bar == null:
		return
	if not bgm_manager.has_method("get_stream_length"):
		return
	var length := float(bgm_manager.call("get_stream_length"))
	if length <= 0.0:
		progress_bar.value = 0.0
		return
	var playback_position := float(bgm_manager.call("get_playback_position"))
	progress_bar.value = clampf((playback_position / length) * 100.0, 0.0, 100.0)

func refresh_bar() -> void:
	if song_label == null or progress_bar == null:
		return
	var song_name := "No track loaded"
	if bgm_manager != null and bgm_manager.has_method("get_now_playing_name"):
		song_name = str(bgm_manager.call("get_now_playing_name"))
	if song_name == "No track loaded":
		song_name = UiStrings.t("music.no_track", language)
	song_label.text = UiStrings.t("music.song_prefix", language) + song_name

	var is_playing := false
	if bgm_manager != null and bgm_manager.has_method("is_playing"):
		is_playing = bool(bgm_manager.call("is_playing"))
	bgm_paused = not is_playing
	if play_pause_button != null:
		play_pause_button.text = UiStrings.t("music.play", language) if bgm_paused else UiStrings.t("music.pause", language)
	_refresh_voice_button()
	if bgm_manager != null and bgm_manager.has_method("get_playback_mode"):
		playback_mode = int(bgm_manager.call("get_playback_mode"))
	_refresh_mode_button()

	var has_playlist := false
	if bgm_manager != null and bgm_manager.has_method("has_playlist"):
		has_playlist = bool(bgm_manager.call("has_playlist"))
	var can_step := has_playlist
	if bgm_manager != null and bgm_manager.has_method("can_step_tracks"):
		can_step = bool(bgm_manager.call("can_step_tracks"))
	if prev_button != null:
		prev_button.disabled = not can_step
	if next_button != null:
		next_button.disabled = not can_step
	if play_pause_button != null:
		play_pause_button.disabled = not has_playlist

func _refresh_voice_button() -> void:
	if voice_button == null:
		return
	voice_button.text = UiStrings.t("voice.on", language) if voice_enabled else UiStrings.t("voice.off", language)

func _refresh_mode_button() -> void:
	if mode_button == null:
		return
	mode_button.set_item_text(0, UiStrings.t("music.mode.loop", language))
	mode_button.set_item_text(1, UiStrings.t("music.mode.seq", language))
	mode_button.set_item_text(2, UiStrings.t("music.mode.random", language))
	mode_button.select(clampi(playback_mode, 0, 2))

func _on_prev_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_previous"):
		bgm_manager.call("play_previous")
		bgm_paused = false
		refresh_bar()
		save_requested.emit()

func _on_next_pressed() -> void:
	if bgm_manager != null and bgm_manager.has_method("play_next"):
		bgm_manager.call("play_next")
		bgm_paused = false
		refresh_bar()
		save_requested.emit()

func _on_play_pause_pressed() -> void:
	if bgm_manager == null:
		return
	var has_stream := false
	if bgm_manager.has_method("has_stream"):
		has_stream = bool(bgm_manager.call("has_stream"))
	var has_playlist := true
	if bgm_manager.has_method("has_playlist"):
		has_playlist = bool(bgm_manager.call("has_playlist"))

	if not has_playlist:
		refresh_bar()
		status_message.emit("There is no ambience loaded yet, but the controls are ready.")
		return

	if not has_stream:
		if bgm_manager.has_method("play_current"):
			bgm_manager.call("play_current")
		elif bgm_manager.has_method("play_default"):
			bgm_manager.call("play_default")
		bgm_paused = false
		refresh_bar()
		save_requested.emit()
		return

	if bgm_paused:
		if bgm_manager.has_method("resume_bgm"):
			bgm_manager.call("resume_bgm")
		bgm_paused = false
	else:
		if bgm_manager.has_method("pause_bgm"):
			bgm_manager.call("pause_bgm")
		bgm_paused = true
	refresh_bar()
	save_requested.emit()

func _on_mode_selected(index: int) -> void:
	playback_mode = clampi(index, 0, 2)
	if bgm_manager != null and bgm_manager.has_method("set_playback_mode"):
		bgm_manager.call("set_playback_mode", playback_mode)
	_refresh_mode_button()
	save_requested.emit()

func _on_voice_pressed() -> void:
	voice_toggle_requested.emit()

func _on_progress_input(event: InputEvent) -> void:
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
	var bar_width := progress_bar.size.x
	if bar_width <= 0.0:
		return
	var percent := clampf(mouse_event.position.x / bar_width, 0.0, 1.0)
	bgm_manager.call("seek_to_position", length * percent)
	update_progress()
