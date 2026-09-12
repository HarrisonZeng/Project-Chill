extends Node
## Optional voice playback. Existing MainScene hooks remain compatible.
## The small subtitle bridge follows paragraph changes without editing the shared
## coordinator. Standalone scenes can use play_voice_for_line directly.
signal voice_started(line_id: String, path: String)
signal voice_missing(line_id: String, expected_path: String)
signal voice_failed(line_id: String, error: String)

const Provider = preload("res://scripts/audio/minimax_voice_provider.gd")

# HARD KILL SWITCH (owner, 2026-09-13): the audition-grade MiniMax clips are not
# good enough to ship, so Yua's voice is OFF everywhere — pre-generated cache,
# runtime TTS, and the per-save `voice_enabled` toggle are all ignored while this
# is false. Flip to true when a voice is actually cast (Demo_Art_Checklist §E).
# The audition tool (scenes/tools/voice_audition.tscn) is unaffected.
const VOICE_FEATURE_ENABLED := false
const PREGENERATED_DIR := "res://assets/audio/voice_cache"
const MANIFEST_PATH := "res://data/dialogue/voice_manifest.json"
const RUNTIME_CACHE_DIR := "user://voice_cache"
const RUNTIME_CACHE_EXTENSION := ".mp3"
const PREGENERATED_EXTENSIONS := [".ogg", ".wav", ".mp3"]

@export var voice_player_path: NodePath
@export var runtime_tts_enabled: bool = false
@export var stop_previous_line: bool = true
@export_range(-40.0, 6.0, 0.1) var volume_db: float = -4.0
@export var playback_bus: String = "Master"
@export var voice_id: String = "Chinese (Mandarin)_Warm_Girl"
@export var speech_model: String = "speech-2.8-hd"
@export var language_boost: String = "auto"
@export_range(0.5, 2.0, 0.01) var speech_speed: float = 1.0
@export_range(-12, 12, 1) var speech_pitch: int = 0
@export var speech_emotion: String = ""
@export var follow_main_subtitles: bool = true

var voice_player: AudioStreamPlayer
var last_voice_error: String = ""
var _provider: Node
var _clips: Dictionary = {}
var _main: Node
var _subtitle: RichTextLabel
var _last_stamp: String = ""
var _request_serial: int = 0
var _pending_path: String = ""
var _pending_line: String = ""
var _enabled: bool = true

func _ready() -> void:
	voice_player = _resolve_voice_player()
	if voice_player == null:
		voice_player = AudioStreamPlayer.new()
		add_child(voice_player)
	_apply_voice_player_settings()
	_ensure_runtime_cache_dir()
	_load_manifest()
	_provider = Provider.new()
	add_child(_provider)
	_provider.completed.connect(_on_synthesized)
	_bind_main.call_deferred()

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if value is Dictionary and value.get("clips") is Dictionary:
		_clips = value["clips"]
		# A provisional voice for this audition pack; no final casting decision.
		voice_id = str(value.get("provisional_voice_id", voice_id))

func _bind_main() -> void:
	if not VOICE_FEATURE_ENABLED:
		_enabled = false
		set_process(false)
		return
	var parent := get_parent()
	if follow_main_subtitles and parent != null and parent.has_method("_set_dialogue_text"):
		_main = parent
		_subtitle = parent.get("dialogue_text") as RichTextLabel
	set_process(_subtitle != null)

func _process(_delta: float) -> void:
	if not is_instance_valid(_subtitle) or not is_instance_valid(_main):
		return
	var allowed := bool(_main.get("voice_enabled"))
	if _enabled != allowed:
		set_voice_enabled(allowed)
	var text := _subtitle.text.strip_edges() if _subtitle.is_visible_in_tree() else ""
	var node_id := str(_main.get("current_node_id"))
	if not _pending_path.is_empty() and (bool(_main.get("focus_running")) or not bool(_main.get("ai_features_enabled"))):
		stop_voice()
	var stamp := "%s|%s|%s" % [node_id, str(_main.get("dialogue_beat_index")), text]
	if stamp == _last_stamp:
		return
	_last_stamp = stamp
	stop_voice()
	if not _enabled or text.is_empty() or node_id == "idle":
		return
	# Cached authored audio works offline. New network synthesis is opt-in,
	# also respects the existing AI privacy toggle and never runs during focus.
	var network_allowed := not bool(_main.get("focus_running")) and bool(_main.get("ai_features_enabled"))
	_play_line(node_id, text, network_allowed, true)

func set_voice_enabled(value: bool) -> void:
	_enabled = value
	if not value:
		stop_voice()

func play_voice_for_line(line_id: String, line_text: String) -> bool:
	if not VOICE_FEATURE_ENABLED or not _enabled or line_id == "idle":
		return false
	if _subtitle != null:
		# The coordinator calls with whole-node text; _process follows only the
		# visible paragraph. It also catches advance, hide, and mute operations.
		return true
	return _play_line(line_id, line_text.strip_edges(), true, false)

func _play_line(line_id: String, text: String, network_allowed: bool, exact_only: bool) -> bool:
	if not VOICE_FEATURE_ENABLED or text.is_empty():
		return false
	if stop_previous_line:
		stop_voice()
	var path := _get_exact_path(text)
	if path.is_empty() and not exact_only:
		path = _get_pregenerated_path(_normalize_line_id(line_id))
	if not path.is_empty():
		return _play_stream_from_path(line_id, path)
	var runtime_path := _get_runtime_cache_path(text)
	if FileAccess.file_exists(runtime_path):
		return _play_stream_from_path(line_id, runtime_path)
	if not runtime_tts_enabled or not network_allowed:
		last_voice_error = "voice_clip_missing"
		voice_missing.emit(line_id, get_expected_pregenerated_path(line_id))
		return false
	# Authored UI instructions, placeholders and stage directions aren't speech.
	if text.contains("{") or text.contains("（") or text == "……":
		return false
	_pending_path = runtime_path
	_pending_line = line_id
	return bool(_provider.synthesize(_request_serial, text, _voice_settings()))

func _voice_settings() -> Dictionary:
	var voice := {"voice_id": voice_id, "speed": speech_speed, "vol": 1.0, "pitch": speech_pitch}
	if not speech_emotion.is_empty():
		voice["emotion"] = speech_emotion
	return {"model": speech_model, "language": language_boost, "voice_setting": voice}

func _on_synthesized(serial: int, audio: PackedByteArray, error: String) -> void:
	if serial != _request_serial or not _enabled:
		return
	if not error.is_empty():
		last_voice_error = error
		voice_failed.emit(_pending_line, error)
		return
	# Decode before caching so a provider error can never poison the cache.
	var stream := AudioStreamMP3.new()
	stream.data = audio
	if stream.get_length() <= 0.0:
		last_voice_error = "voice_invalid_mp3"
		voice_failed.emit(_pending_line, last_voice_error)
		return
	var file := FileAccess.open(_pending_path, FileAccess.WRITE)
	if file == null:
		last_voice_error = "voice_cache_write_failed"
		voice_failed.emit(_pending_line, last_voice_error)
		return
	file.store_buffer(audio)
	file.close()
	var finished_path := _pending_path
	var finished_line := _pending_line
	_pending_path = ""
	_pending_line = ""
	_play_stream_from_path(finished_line, finished_path)

func stop_voice() -> void:
	_request_serial += 1
	_pending_path = ""
	_pending_line = ""
	if _provider != null:
		_provider.cancel()
	if voice_player != null:
		voice_player.stop()

func has_voice_for_line(line_id: String, line_text: String = "") -> bool:
	return not _get_exact_path(line_text.strip_edges()).is_empty() or not _get_pregenerated_path(_normalize_line_id(line_id)).is_empty() or FileAccess.file_exists(_get_runtime_cache_path(line_text.strip_edges()))

func get_expected_pregenerated_path(line_id: String) -> String:
	return "%s/%s.ogg" % [PREGENERATED_DIR, _normalize_line_id(line_id)]

func get_runtime_cache_path_for_text(text: String) -> String:
	return _get_runtime_cache_path(text.strip_edges())

func _get_runtime_cache_path(text: String) -> String:
	if text.is_empty():
		return ""
	var signature := JSON.stringify(_voice_settings()) + "|" + text
	return "%s/%s%s" % [RUNTIME_CACHE_DIR, signature.sha256_text(), RUNTIME_CACHE_EXTENSION]

func _get_exact_path(text: String) -> String:
	var entry: Variant = _clips.get(text.sha256_text())
	if entry is Dictionary and str(entry.get("text", "")) == text:
		var path := str(entry.get("path", ""))
		if path.begins_with(PREGENERATED_DIR + "/") and ResourceLoader.exists(path):
			return path
	return ""

func _get_pregenerated_path(line_id: String) -> String:
	if line_id.is_empty():
		return ""
	for extension in PREGENERATED_EXTENSIONS:
		var path := "%s/%s%s" % [PREGENERATED_DIR, line_id, extension]
		if ResourceLoader.exists(path):
			return path
	return ""

func play_preview(path: String) -> bool:
	stop_voice()
	return _play_stream_from_path("audition", path) if _enabled else false

func _play_stream_from_path(line_id: String, path: String) -> bool:
	var stream := _load_audio_stream(path)
	if stream == null:
		last_voice_error = "stream_load_failed"
		voice_failed.emit(line_id, last_voice_error)
		return false
	_apply_voice_player_settings()
	voice_player.stream = stream
	voice_player.play()
	last_voice_error = ""
	voice_started.emit(line_id, path)
	return true

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if path.begins_with("res://"):
		return load(path) as AudioStream
	match path.get_extension().to_lower():
		"mp3": return AudioStreamMP3.load_from_file(path)
		"ogg": return AudioStreamOggVorbis.load_from_file(path)
		"wav": return AudioStreamWAV.load_from_file(path)
	return null

func _resolve_voice_player() -> AudioStreamPlayer:
	if voice_player_path != NodePath():
		return get_node_or_null(voice_player_path) as AudioStreamPlayer
	return get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer

func _apply_voice_player_settings() -> void:
	if voice_player == null:
		return
	voice_player.volume_db = volume_db
	voice_player.bus = playback_bus

func _ensure_runtime_cache_dir() -> void:
	DirAccess.make_dir_recursive_absolute(RUNTIME_CACHE_DIR)

func _normalize_line_id(line_id: String) -> String:
	return line_id.strip_edges().replace("/", "_").replace("\\", "_").replace(" ", "_")

func _exit_tree() -> void:
	stop_voice()
	if voice_player != null:
		voice_player.stream = null
