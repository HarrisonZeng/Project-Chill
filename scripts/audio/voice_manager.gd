extends Node

signal voice_started(line_id: String, path: String)
signal voice_missing(line_id: String, expected_path: String)
signal voice_failed(line_id: String, error: String)

const PREGENERATED_DIR := "res://assets/audio/voice_cache"
const RUNTIME_CACHE_DIR := "user://voice_cache"
const RUNTIME_CACHE_EXTENSION := ".ogg"
const PREGENERATED_EXTENSIONS := [".ogg", ".wav", ".mp3"]

@export var voice_player_path: NodePath
@export var runtime_tts_enabled: bool = false
@export var stop_previous_line: bool = true
@export_range(-40.0, 6.0, 0.1) var volume_db: float = -4.0
@export var playback_bus: String = "Master"

var voice_player: AudioStreamPlayer
var last_voice_error: String = ""

func _ready() -> void:
	voice_player = _resolve_voice_player()
	_apply_voice_player_settings()
	_ensure_runtime_cache_dir()

func play_voice_for_line(line_id: String, line_text: String) -> bool:
	var normalized_id := _normalize_line_id(line_id)
	var normalized_text := line_text.strip_edges()

	if normalized_id.is_empty() and normalized_text.is_empty():
		last_voice_error = "line_id_missing"
		emit_signal("voice_failed", line_id, last_voice_error)
		return false

	if stop_previous_line:
		stop_voice()

	var pregen_path := _get_pregenerated_path(normalized_id)
	if pregen_path != "":
		return _play_stream_from_path(normalized_id, pregen_path)

	var runtime_path := _get_runtime_cache_path(normalized_text)
	if FileAccess.file_exists(runtime_path):
		return _play_stream_from_path(normalized_id, runtime_path)

	if not runtime_tts_enabled:
		last_voice_error = "voice_clip_missing"
		emit_signal("voice_missing", normalized_id, _get_expected_pregenerated_path(normalized_id))
		return false

	return synthesize_voice_stub(normalized_text, runtime_path)

func stop_voice() -> void:
	if voice_player != null and voice_player.playing:
		voice_player.stop()

func has_voice_for_line(line_id: String, line_text: String = "") -> bool:
	var normalized_id := _normalize_line_id(line_id)
	if _get_pregenerated_path(normalized_id) != "":
		return true

	var runtime_path := _get_runtime_cache_path(line_text.strip_edges())
	return FileAccess.file_exists(runtime_path)

func get_expected_pregenerated_path(line_id: String) -> String:
	return _get_expected_pregenerated_path(_normalize_line_id(line_id))

func get_runtime_cache_path_for_text(line_text: String) -> String:
	return _get_runtime_cache_path(line_text.strip_edges())

func synthesize_voice_stub(line_text: String, output_path: String) -> bool:
	if line_text.is_empty():
		last_voice_error = "line_text_missing"
		emit_signal("voice_failed", "", last_voice_error)
		return false

	last_voice_error = "runtime_tts_not_configured"
	print("[VoiceManager] Runtime TTS requested, but no TTS provider is configured yet.")
	print("[VoiceManager] Would synthesize: %s" % line_text)
	print("[VoiceManager] Output target: %s" % output_path)
	emit_signal("voice_failed", "", last_voice_error)
	return false

func _get_pregenerated_path(line_id: String) -> String:
	if line_id.is_empty():
		return ""

	for extension in PREGENERATED_EXTENSIONS:
		var candidate := "%s/%s%s" % [PREGENERATED_DIR, line_id, extension]
		if ResourceLoader.exists(candidate):
			return candidate
	return ""

func _get_runtime_cache_path(line_text: String) -> String:
	if line_text.is_empty():
		return ""
	var hash := line_text.sha256_text()
	return "%s/%s%s" % [RUNTIME_CACHE_DIR, hash, RUNTIME_CACHE_EXTENSION]

func _get_expected_pregenerated_path(line_id: String) -> String:
	if line_id.is_empty():
		return PREGENERATED_DIR
	return "%s/%s%s" % [PREGENERATED_DIR, line_id, PREGENERATED_EXTENSIONS[0]]

func _play_stream_from_path(line_id: String, path: String) -> bool:
	if voice_player == null:
		last_voice_error = "voice_player_missing"
		emit_signal("voice_failed", line_id, last_voice_error)
		return false

	var stream := _load_audio_stream(path)
	if stream == null:
		print("[VoiceManager] Failed to load stream: %s" % path)
		last_voice_error = "stream_load_failed"
		emit_signal("voice_failed", line_id, last_voice_error)
		return false

	voice_player.stream = stream
	voice_player.play()
	last_voice_error = ""
	emit_signal("voice_started", line_id, path)
	return true

func _load_audio_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null

	if path.begins_with("res://"):
		var stream: Resource = load(path)
		if stream is AudioStream:
			return stream
		return null

	match path.get_extension().to_lower():
		"ogg":
			return AudioStreamOggVorbis.load_from_file(path)
		"mp3":
			return AudioStreamMP3.load_from_file(path)
		"wav":
			return AudioStreamWAV.load_from_file(path)
		_:
			return null

func _resolve_voice_player() -> AudioStreamPlayer:
	if voice_player_path != NodePath():
		var node := get_node_or_null(voice_player_path)
		if node is AudioStreamPlayer:
			return node

	var fallback := get_node_or_null("AudioStreamPlayer")
	if fallback is AudioStreamPlayer:
		return fallback

	return null

func _apply_voice_player_settings() -> void:
	if voice_player == null:
		return
	voice_player.volume_db = volume_db
	if not playback_bus.is_empty():
		voice_player.bus = playback_bus

func _ensure_runtime_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(RUNTIME_CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(RUNTIME_CACHE_DIR)

func _normalize_line_id(line_id: String) -> String:
	return line_id.strip_edges().replace("/", "_").replace("\\", "_").replace(" ", "_")
