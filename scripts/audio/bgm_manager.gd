extends Node

@export var bgm_player_path: NodePath
@export var playlist: Array[AudioStream] = []
@export var autoplay: bool = false

var bgm_player: AudioStreamPlayer
var current_index: int = 0

func _ready() -> void:
	bgm_player = _resolve_bgm_player()
	if autoplay:
		play_default()

func play_default() -> void:
	play_current()

func play_current() -> void:
	if playlist.is_empty():
		return
	current_index = clampi(current_index, 0, playlist.size() - 1)
	_play_stream(playlist[current_index])

func play_next() -> void:
	if playlist.is_empty():
		return
	current_index = (current_index + 1) % playlist.size()
	_play_stream(playlist[current_index])

func play_previous() -> void:
	if playlist.is_empty():
		return
	current_index = (current_index - 1 + playlist.size()) % playlist.size()
	_play_stream(playlist[current_index])

func pause_bgm() -> void:
	if bgm_player == null:
		return
	bgm_player.stream_paused = true

func resume_bgm() -> void:
	if bgm_player == null:
		return
	if bgm_player.stream == null:
		play_current()
		return
	bgm_player.stream_paused = false
	if not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	if bgm_player == null:
		return
	bgm_player.stop()

func has_stream() -> bool:
	return bgm_player != null and bgm_player.stream != null

func is_playing() -> bool:
	return bgm_player != null and bgm_player.playing and not bgm_player.stream_paused

func get_playback_position() -> float:
	if bgm_player == null:
		return 0.0
	return bgm_player.get_playback_position()

func get_stream_length() -> float:
	if bgm_player == null or bgm_player.stream == null:
		return 0.0
	return bgm_player.stream.get_length()

func seek_to_position(seconds: float) -> void:
	if bgm_player == null or bgm_player.stream == null:
		return
	bgm_player.seek(maxf(0.0, seconds))
	if not bgm_player.playing and not bgm_player.stream_paused:
		bgm_player.play()

func _play_stream(stream: AudioStream) -> void:
	if bgm_player == null or stream == null:
		return
	bgm_player.stream = stream
	bgm_player.stream_paused = false
	bgm_player.play()

func _resolve_bgm_player() -> AudioStreamPlayer:
	if bgm_player_path != NodePath():
		var node := get_node_or_null(bgm_player_path)
		if node is AudioStreamPlayer:
			return node

	var fallback := get_node_or_null("AudioStreamPlayer")
	if fallback is AudioStreamPlayer:
		return fallback

	return null

func has_playlist() -> bool:
	return not playlist.is_empty()

func get_playlist_size() -> int:
	return playlist.size()

func can_step_tracks() -> bool:
	return playlist.size() > 1

func get_current_index() -> int:
	return current_index

func set_current_index(track_index: int) -> void:
	if playlist.is_empty():
		current_index = 0
		return
	current_index = clampi(track_index, 0, playlist.size() - 1)

func get_now_playing_name() -> String:
	if bgm_player == null:
		return "No track loaded"
	if bgm_player.stream == null:
		return "No track loaded"
	if bgm_player.stream.resource_path.is_empty():
		return "Unknown track"
	return bgm_player.stream.resource_path.get_file().get_basename()

func get_transport_state_text() -> String:
	if not has_playlist():
		return "No ambience loaded yet"
	if bgm_player == null or bgm_player.stream == null:
		return "Ambience ready"
	if is_playing():
		return "Ambience playing"
	return "Ambience paused"
