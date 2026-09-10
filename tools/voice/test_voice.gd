extends SceneTree
const Voice = preload("res://scripts/audio/voice_manager.gd")
var failures: int = 0
var checks: int = 0

class SubtitleHost extends Node:
	var dialogue_text: RichTextLabel
	var voice_enabled: bool = true
	var focus_running: bool = false
	var ai_features_enabled: bool = false
	var current_node_id: String = "ep00_01"
	var dialogue_beat_index: int = 0
	func _set_dialogue_text(text: String) -> void:
		dialogue_text.text = text

func _initialize() -> void:
	_run.call_deferred()

func expect(ok: bool, name: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL " + name)

func _run() -> void:
	var samples: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/voice_auditions/manifest.json"))
	var total_seconds: float = 0
	var inventory: Array = []
	for sample in samples.samples:
		var stream := load(str(sample.path)) as AudioStream
		var duration := stream.get_length() if stream != null else 0.0
		expect(duration > 0.2 and duration < 90, "audio decodes " + str(sample.id))
		total_seconds += duration
		inventory.append({"id": sample.id, "duration_seconds": duration})
	var report := FileAccess.open("res://tools/voice/audio_validation.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"clips": inventory, "total_seconds": total_seconds}, "  "))
	report.close()
	var voice := Voice.new()
	voice.follow_main_subtitles = false
	root.add_child(voice)
	await process_frame
	var game: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/voice_manifest.json"))
	var entries: Array = game.clips.values()
	var first: Dictionary = entries[0]
	var second: Dictionary = entries[1]
	expect(voice.play_voice_for_line(first.node_id, first.text), "exact script clip plays")
	expect(voice.voice_player.playing, "player started")
	voice.stop_voice()
	expect(not voice.voice_player.playing, "stop interrupts")
	expect(not voice.play_voice_for_line(first.node_id, first.text + " changed"), "stale text not voiced")
	var cache_a := voice.get_runtime_cache_path_for_text("test")
	voice.speech_speed = 1.1
	expect(cache_a != voice.get_runtime_cache_path_for_text("test"), "cache includes delivery")
	voice.voice_id = "different"
	var cache_b := voice.get_runtime_cache_path_for_text("test")
	expect(cache_a != cache_b, "cache includes voice identity")
	voice.set_voice_enabled(false)
	expect(not voice.play_preview(first.path), "mute suppresses playback")
	voice.set_voice_enabled(true)
	var old_serial: int = voice._request_serial
	voice.stop_voice()
	voice._on_synthesized(old_serial, PackedByteArray([0]), "")
	expect(not voice.voice_player.playing, "late response ignored")
	var old_key := OS.get_environment("MINIMAX_API_KEY")
	OS.set_environment("MINIMAX_API_KEY", "")
	voice.runtime_tts_enabled = true
	expect(not voice.play_voice_for_line("unknown", "Uncached test sentence."), "missing key fails closed")
	expect(voice.last_voice_error == "minimax_key_missing", "missing key has useful error")
	OS.set_environment("MINIMAX_API_KEY", old_key)
	voice.queue_free()
	await process_frame

	var host := SubtitleHost.new()
	var label := RichTextLabel.new()
	host.dialogue_text = label
	host.add_child(label)
	root.add_child(host)
	var bridge := Voice.new()
	host.add_child(bridge)
	await process_frame
	await process_frame
	host._set_dialogue_text(first.text)
	await process_frame
	await process_frame
	expect(bridge.voice_player.playing, "visible paragraph voiced")
	host.dialogue_beat_index = 1
	host._set_dialogue_text(second.text)
	await process_frame
	await process_frame
	expect(bridge.voice_player.stream.resource_path == str(second.path), "skip switches to next paragraph")
	host.voice_enabled = false
	await process_frame
	await process_frame
	expect(not bridge.voice_player.playing, "game mute stops existing audio")
	host.voice_enabled = true
	await process_frame
	expect(not bridge.voice_player.playing, "unmute does not replay old paragraph")
	host.dialogue_beat_index = 2
	host._set_dialogue_text(first.text)
	await process_frame
	await process_frame
	label.hide()
	await process_frame
	await process_frame
	expect(not bridge.voice_player.playing, "hidden subtitle stops audio")
	host.queue_free()
	await process_frame
	var audition: Node = load("res://scenes/tools/voice_audition.tscn").instantiate()
	root.add_child(audition)
	await process_frame
	audition._show_filter("English")
	expect(audition._visible.size() == 2, "English comparisons available")
	audition._play(audition._visible[0])
	await process_frame
	expect(audition._voice.voice_player.playing, "audition selection plays")
	audition._progress.value = 1.0
	audition._seek(true)
	expect(audition._voice.voice_player.get_playback_position() >= 0.9, "audition seek works")
	audition._next()
	expect(audition._selected.id == "en_native", "next switches candidate")
	audition._show_filter("Japanese")
	expect(audition._visible.size() == 2, "Japanese comparisons available")
	audition.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("VOICE TESTS: %d/%d passed; %d clips, %.1f seconds" % [checks-failures, checks, samples.samples.size(), total_seconds])
	quit(1 if failures else 0)
