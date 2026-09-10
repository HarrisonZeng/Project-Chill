extends Control
## F6 this scene: local clips only, no API calls and no player-profile writes.
const VoiceManager = preload("res://scripts/audio/voice_manager.gd")
var _voice: Node
var _samples: Array = []
var _visible: Array = []
var _selected: Dictionary = {}
var _list: VBoxContainer
var _title: Label
var _text: Label
var _details: Label
var _status: Label
var _progress: HSlider
var _clock: Label
var _filter: String = "Chinese"
var _dragging: bool = false

func _ready() -> void:
	var theme_font := load("res://assets/fonts/chill_kai_gb.woff2") as Font
	if theme_font != null:
		add_theme_font_override("font", theme_font)
	var background := ColorRect.new()
	background.color = Color("101d23")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 32)
	margin.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.9
	left.add_theme_constant_override("separation", 16)
	columns.add_child(left)
	left.add_child(_label("PROJECT CHILL  /  VOICE STUDY 01", 18, "92cbb9"))
	left.add_child(_label("听见 Yua", 46, "f5eee0"))
	left.add_child(_label("先听音色，再听她说话的方式。", 23, "c3cec9"))
	var art := TextureRect.new()
	art.texture = load("res://assets/art/concepts/yua_daylight_separated/yua_combined_preview_16x9.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(art)
	left.add_child(_label("中文为主 · 英语 / 日语短试听\n原创音色均为合成设计，尚未定稿。", 21, "a9bbb5"))
	left.add_child(_label("不连接 API，也不会改变游戏存档。", 18, "839a95"))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 14)
	columns.add_child(right)
	var filters := HBoxContainer.new()
	right.add_child(filters)
	for entry in [["中文", "Chinese"], ["English", "English"], ["日本語", "Japanese"], ["游戏片段", "game"]]:
		var button := _button(str(entry[0]))
		button.pressed.connect(_show_filter.bind(str(entry[1])))
		filters.add_child(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	_title = _label("选择一个音色", 25, "f5eee0")
	right.add_child(_title)
	_text = _label("", 23, "d8e5de")
	_text.custom_minimum_size.y = 95
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_text)
	_details = _label("", 15, "91aaa0")
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_details)
	_progress = HSlider.new()
	_progress.min_value = 0
	_progress.max_value = 1
	_progress.step = 0.01
	_progress.drag_started.connect(func(): _dragging = true)
	_progress.drag_ended.connect(_seek)
	right.add_child(_progress)
	var controls := HBoxContainer.new()
	right.add_child(controls)
	var replay := _button("重听")
	replay.pressed.connect(func():
		if not _selected.is_empty(): _play(_selected))
	controls.add_child(replay)
	var stop := _button("停止")
	stop.pressed.connect(func(): _voice.stop_voice(); _status.text = "已停止")
	controls.add_child(stop)
	var next := _button("下一个")
	next.pressed.connect(_next)
	controls.add_child(next)
	_clock = _label("0:00 / 0:00", 18, "a9bbb5")
	controls.add_child(_clock)
	var volume_row := HBoxContainer.new()
	right.add_child(volume_row)
	volume_row.add_child(_label("音量", 18, "a9bbb5"))
	var volume := HSlider.new()
	volume.min_value = -30
	volume.max_value = 0
	volume.value = -6
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.value_changed.connect(func(value: float): _voice.volume_db = value; _voice.voice_player.volume_db = value)
	volume_row.add_child(volume)
	_status = _label("点击列表试听 · 耳机更容易比较细节", 18, "92cbb9")
	right.add_child(_status)
	_voice = VoiceManager.new()
	_voice.follow_main_subtitles = false
	_voice.volume_db = -6
	add_child(_voice)
	_voice.voice_failed.connect(func(_id: String, error: String): _status.text = "无法播放：" + error)
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/voice_auditions/manifest.json"))
	if data is Dictionary:
		_samples = data.get("samples", [])
	_show_filter("Chinese")
	if OS.get_cmdline_user_args().has("--voice-shot"):
		for candidate in _samples:
			if str(candidate.id) == "ja_same":
				_show_filter("Japanese")
				_play(candidate)
				_voice.voice_player.volume_db = -80
		await get_tree().create_timer(1.2).timeout
		get_viewport().get_texture().get_image().save_png("res://tools/voice/audition_scene.png")
		_voice.stop_voice()
		await get_tree().create_timer(0.2).timeout
		get_tree().quit()

func _show_filter(language: String) -> void:
	_filter = language
	_visible.clear()
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	for sample in _samples:
		var game := str(sample.id).begins_with("game_")
		if (language == "game" and not game) or (language != "game" and (game or sample.language != language)):
			continue
		_visible.append(sample)
		var button := _button(str(sample.title))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_play.bind(sample))
		_list.add_child(button)

func _play(sample: Dictionary) -> void:
	_selected = sample
	_title.text = str(sample.title)
	_text.text = str(sample.text).replace("<#0.35#>", " ").replace("<#0.3#>", " ").replace("<#0.4#>", " ")
	var settings: Dictionary = sample.get("settings", {})
	_details.text = "语速 %.2f × · %s" % [float(settings.get("speed", 1.0)), str(sample.language)]
	if _voice.play_preview(str(sample.path)):
		_status.text = "正在试听 · " + str(sample.title)

func _next() -> void:
	if _visible.is_empty(): return
	var index := _visible.find(_selected)
	_play(_visible[(index + 1) % _visible.size()])

func _process(_delta: float) -> void:
	if _voice == null or _voice.voice_player.stream == null: return
	var length: float = _voice.voice_player.stream.get_length()
	var position: float = _voice.voice_player.get_playback_position()
	_progress.max_value = length
	if not _dragging: _progress.set_value_no_signal(position)
	_clock.text = "%s / %s" % [_time(position), _time(length)]

func _seek(changed: bool) -> void:
	_dragging = false
	if changed and _voice.voice_player.stream != null:
		_voice.voice_player.play(_progress.value)

func _time(seconds: float) -> String:
	return "%d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func _label(text: String, size: int, color: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 43
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("e6eee8"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("21383d")
	style.set_corner_radius_all(9)
	style.content_margin_left = 16
	style.content_margin_right = 16
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("31544f")
	button.add_theme_stylebox_override("hover", hover)
	return button
