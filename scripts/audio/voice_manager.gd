extends Node

const PREGENERATED_DIR := "res://assets/audio/voice_cache"
const RUNTIME_CACHE_DIR := "user://voice_cache"
const DEFAULT_EXTENSION := ".ogg"

@export var voice_player_path: NodePath

var voice_player: AudioStreamPlayer

func _ready() -> void:
	voice_player = _resolve_voice_player()
	_ensure_runtime_cache_dir()

func play_voice_for_line(line_id: String, line_text: String) -> void:
	if line_id.is_empty():
		return

	var pregen_path := _get_pregenerated_path(line_id)
	if pregen_path != "":
		_play_stream_from_path(pregen_path)
		return

	var runtime_path := _get_runtime_cache_path(line_text)
	if FileAccess.file_exists(runtime_path):
		_play_stream_from_path(runtime_path)
		return

	synthesize_voice_stub(line_text, runtime_path)

func synthesize_voice_stub(line_text: String, output_path: String) -> void:
	if line_text.is_empty():
		return

	print("[VoiceManager] TTS stub called. Would synthesize: %s" % line_text)
	print("[VoiceManager] Output target: %s" % output_path)

func _get_pregenerated_path(line_id: String) -> String:
	var candidate := "%s/%s%s" % [PREGENERATED_DIR, line_id, DEFAULT_EXTENSION]
	if ResourceLoader.exists(candidate):
		return candidate
	return ""

func _get_runtime_cache_path(line_text: String) -> String:
	var hash := line_text.sha256_text()
	return "%s/%s%s" % [RUNTIME_CACHE_DIR, hash, DEFAULT_EXTENSION]

func _play_stream_from_path(path: String) -> void:
	if voice_player == null:
		return

	var stream := load(path)
	if stream == null:
		print("[VoiceManager] Failed to load stream: %s" % path)
		return

	voice_player.stream = stream
	voice_player.play()

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
