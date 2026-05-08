extends Node

const PREGENERATED_DIR := "res://assets/audio/voice_cache"
const RUNTIME_CACHE_DIR := "user://voice_cache"
const DEFAULT_EXTENSION := ".ogg"

@export var voice_player_path: NodePath

var voice_player: AudioStreamPlayer
var last_voice_error: String = ""

func _ready() -> void:
	voice_player = _resolve_voice_player()
	_ensure_runtime_cache_dir()

func play_voice_for_line(line_id: String, line_text: String) -> bool:
	if line_id.is_empty():
		last_voice_error = "line_id_missing"
		return false

	var pregen_path := _get_pregenerated_path(line_id)
	if pregen_path != "":
		return _play_stream_from_path(pregen_path)

	var runtime_path := _get_runtime_cache_path(line_text)
	if FileAccess.file_exists(runtime_path):
		return _play_stream_from_path(runtime_path)

	return synthesize_voice_stub(line_text, runtime_path)

func synthesize_voice_stub(line_text: String, output_path: String) -> bool:
	if line_text.is_empty():
		last_voice_error = "line_text_missing"
		return false

	last_voice_error = "tts_stub_only"
	print("[VoiceManager] TTS stub called. Would synthesize: %s" % line_text)
	print("[VoiceManager] Output target: %s" % output_path)
	return true

func _get_pregenerated_path(line_id: String) -> String:
	var candidate := "%s/%s%s" % [PREGENERATED_DIR, line_id, DEFAULT_EXTENSION]
	if ResourceLoader.exists(candidate):
		return candidate
	return ""

func _get_runtime_cache_path(line_text: String) -> String:
	var hash := line_text.sha256_text()
	return "%s/%s%s" % [RUNTIME_CACHE_DIR, hash, DEFAULT_EXTENSION]

func _play_stream_from_path(path: String) -> bool:
	if voice_player == null:
		last_voice_error = "voice_player_missing"
		return false

	var stream := load(path)
	if stream == null:
		print("[VoiceManager] Failed to load stream: %s" % path)
		last_voice_error = "stream_load_failed"
		return false

	voice_player.stream = stream
	voice_player.play()
	last_voice_error = ""
	return true

func _resolve_voice_player() -> AudioStreamPlayer:
	if voice_player_path != NodePath():
		var node := get_node_or_null(voice_player_path)
		if node is AudioStreamPlayer:
			return node

	var fallback := get_node_or_null("AudioStreamPlayer")
	if fallback is AudioStreamPlayer:
		return fallback

	return null

func _ensure_runtime_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(RUNTIME_CACHE_DIR):
		DirAccess.make_dir_recursive_absolute(RUNTIME_CACHE_DIR)
