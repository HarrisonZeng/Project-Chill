extends SceneTree
const Voice = preload("res://scripts/audio/voice_manager.gd")
var _voice: Node
var _done: bool = false
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	_voice = Voice.new()
	_voice.follow_main_subtitles = false
	_voice.runtime_tts_enabled = true
	root.add_child(_voice)
	_voice.voice_started.connect(_success)
	_voice.voice_failed.connect(_failure)
	create_timer(25).timeout.connect(_on_timeout)
	_voice.play_voice_for_line("runtime_probe", "嗯，我也把文档打开了。")
func _on_timeout() -> void:
	if not _done: _failure("", "test_timeout")
func _success(_id: String, path: String) -> void:
	_done = true
	print("RUNTIME VOICE PASS: MiniMax response decoded, cached and played; seconds=%.2f" % _voice.voice_player.stream.get_length())
	_voice.stop_voice()
	_voice.queue_free()
	await create_timer(0.2).timeout
	quit(0)
func _failure(_id: String, error: String) -> void:
	_done = true
	print("RUNTIME VOICE FAIL: " + error)
	_voice.queue_free()
	await create_timer(0.2).timeout
	quit(1)
