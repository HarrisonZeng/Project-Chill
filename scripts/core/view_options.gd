extends Node
# Player-facing view controls that the original scene had no room for:
#
#   * Settings gains "window view" (day / rain / night) and "Yua" (her stance).
#   * The music bar, the settings button and the dialogue box can each be
#     collapsed, plus one master toggle that clears the whole frame — useful for
#     just sitting with the scene, and for taking screenshots.
#   * Type Mode is now explicit: the type box and Send button only take the
#     reply slot when it is switched on. Otherwise that space belongs to the
#     reply buttons.
#
# Everything is built in code rather than in main_scene.tscn so the scene file
# stays reviewable, and so removing this node restores the original UI exactly.

signal weather_picked(kind: String)
signal stance_picked(kind: String)
signal type_mode_toggled(on: bool)

const STANCES := ["at_player", "at_work"]

# Only offer views whose picture is actually present, so a missing asset drops
# that option from the cycle instead of showing the player a blank window.
static func available_views() -> Array:
	var out: Array = []
	var amb := preload("res://scripts/core/ambient_effects.gd")
	for d in amb.view_defs():
		if not amb.view_texture_path(str(d["key"])).is_empty():
			out.append(str(d["key"]))
	if out.is_empty():
		out.append("rain")
	return out

var _main: Node = null
var _views: Array = []
var _weather := "rain"
var _stance := "at_player"
var _type_on := false

# Collapse state, one flag per collapsible region.
var _music_open := true
var _dialogue_open := true
var _chrome_open := true

var _view_button: Button = null
var _stance_button: Button = null
var _type_button: Button = null
var _music_toggle: Button = null
var _dialogue_toggle: Button = null
var _chrome_toggle: Button = null

func setup(main: Node, weather: String, stance: String) -> void:
	_main = main
	_views = available_views()
	_weather = weather if weather in _views else String(_views[0])
	_stance = stance if stance in STANCES else "at_player"
	_build_settings_rows()
	_build_type_toggle()
	_build_collapse_toggles()
	_refresh_labels()

func get_weather() -> String:
	return _weather

func get_stance() -> String:
	return _stance

func is_type_mode_on() -> bool:
	return _type_on

# ── settings rows ─────────────────────────────────────────────────────────────
func _build_settings_rows() -> void:
	var box := _main.get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox")
	if box == null:
		push_warning("view_options: settings box not found")
		return
	var sep := HSeparator.new()
	box.add_child(sep)

	_view_button = Button.new()
	_view_button.custom_minimum_size = Vector2(0, 32)
	_view_button.pressed.connect(_on_view_pressed)
	box.add_child(_view_button)

	_stance_button = Button.new()
	_stance_button.custom_minimum_size = Vector2(0, 32)
	_stance_button.pressed.connect(_on_stance_pressed)
	box.add_child(_stance_button)
	# The panel was sized and placed for its original three rows: it needs to be
	# taller for the two new ones, and to start below the chat-history button,
	# which otherwise draws on top of the first row.
	var panel := _main.get_node_or_null("SettingsPanel")
	if panel is Control:
		var p := panel as Control
		p.offset_top += 72.0
		p.offset_bottom += 164.0

func _on_view_pressed() -> void:
	var i := _views.find(_weather)
	_weather = String(_views[(i + 1) % _views.size()])
	_refresh_labels()
	weather_picked.emit(_weather)

func _on_stance_pressed() -> void:
	var i := STANCES.find(_stance)
	_stance = STANCES[(i + 1) % STANCES.size()]
	_refresh_labels()
	stance_picked.emit(_stance)

# ── type mode ─────────────────────────────────────────────────────────────────
# Sits in the reply band. Off by default so the reply buttons get the space.
func _build_type_toggle() -> void:
	var card := _main.get_node_or_null("BottomPanel/DialoguePanel/ResponseCard")
	if card == null:
		return
	_type_button = Button.new()
	_type_button.toggle_mode = true
	_type_button.custom_minimum_size = Vector2(96, 32)
	_type_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_type_button.offset_left = -104.0
	_type_button.offset_right = -8.0
	_type_button.offset_top = -40.0
	_type_button.offset_bottom = -8.0
	_type_button.toggled.connect(_on_type_toggled)
	card.add_child(_type_button)

func _on_type_toggled(on: bool) -> void:
	_type_on = on
	_refresh_labels()
	type_mode_toggled.emit(on)

# ── collapsing ────────────────────────────────────────────────────────────────
func _build_collapse_toggles() -> void:
	_music_toggle = _small_button(Vector2(28, 24))
	_music_toggle.pressed.connect(_on_music_collapse)
	var bar := _main.get_node_or_null("BottomLeftMusicBar")
	if bar is Control:
		var b := bar as Control
		_main.add_child(_music_toggle)
		_music_toggle.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_music_toggle.offset_left = b.offset_left
		_music_toggle.offset_right = b.offset_left + 28.0
		_music_toggle.offset_top = b.offset_top - 26.0
		_music_toggle.offset_bottom = b.offset_top - 2.0

	_dialogue_toggle = _small_button(Vector2(28, 24))
	_dialogue_toggle.pressed.connect(_on_dialogue_collapse)
	_main.add_child(_dialogue_toggle)
	_dialogue_toggle.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_dialogue_toggle.offset_left = -44.0
	_dialogue_toggle.offset_right = -16.0
	_dialogue_toggle.offset_top = -232.0
	_dialogue_toggle.offset_bottom = -208.0

	# Master toggle: clears every piece of chrome at once.
	_chrome_toggle = _small_button(Vector2(32, 28))
	_chrome_toggle.pressed.connect(_on_chrome_collapse)
	_main.add_child(_chrome_toggle)
	_chrome_toggle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_chrome_toggle.offset_left = 28.0
	_chrome_toggle.offset_right = 60.0
	_chrome_toggle.offset_top = 108.0
	_chrome_toggle.offset_bottom = 136.0

func _small_button(size: Vector2) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.focus_mode = Control.FOCUS_NONE
	return b

func _on_music_collapse() -> void:
	_music_open = not _music_open
	_apply_collapse()

func _on_dialogue_collapse() -> void:
	_dialogue_open = not _dialogue_open
	_apply_collapse()

func _on_chrome_collapse() -> void:
	_chrome_open = not _chrome_open
	# The master toggle drives the individual ones, so re-opening restores
	# everything rather than leaving pieces hidden with no way back.
	_music_open = _chrome_open
	_dialogue_open = _chrome_open
	_apply_collapse()

func _apply_collapse() -> void:
	_set_visible("BottomLeftMusicBar", _music_open and _chrome_open)
	_set_visible("BottomPanel/DialoguePanel", _dialogue_open and _chrome_open)
	_set_visible("SettingsButton", _chrome_open)
	_set_visible("OverlayLayer/HUD/FocusCard", _chrome_open)
	_set_visible("OverlayLayer/HUD/CallStatusPill", _chrome_open)
	_set_visible("OverlayLayer/Tools", _chrome_open)
	if not _chrome_open:
		_set_visible("SettingsPanel", false)
	if _music_toggle != null:
		_music_toggle.visible = _chrome_open
	if _dialogue_toggle != null:
		_dialogue_toggle.visible = _chrome_open
	_refresh_labels()

func _set_visible(path: String, on: bool) -> void:
	var n := _main.get_node_or_null(path)
	if n is CanvasItem:
		(n as CanvasItem).visible = on

# ── labels ────────────────────────────────────────────────────────────────────
func _refresh_labels() -> void:
	var zh: bool = _main.get("ui_language") == "zh"
	if _view_button != null:
		var names := {
			"rain": "雨天" if zh else "Rain",
			"clear": "晴天" if zh else "Clear",
			"sunset": "黄昏" if zh else "Sunset",
			"night": "夜晚" if zh else "Night",
			"seaside": "海边" if zh else "Seaside",
			"treetops": "树梢" if zh else "Treetops",
		}
		var view_name: String = str(names.get(_weather, _weather))
		_view_button.text = ("窗外：%s" % view_name) if zh else ("Window: %s" % view_name)
	if _stance_button != null:
		var stance_name: String = {
			"at_player": "看着我" if zh else "Looking at me",
			"at_work": "看屏幕" if zh else "At her screen",
		}[_stance]
		_stance_button.text = ("由亚：%s" % stance_name) if zh else ("Yua: %s" % stance_name)
	if _type_button != null:
		_type_button.text = ("打字" if zh else "Type") if not _type_on else ("完成" if zh else "Done")
	if _music_toggle != null:
		_music_toggle.text = "▾" if _music_open else "▴"
	if _dialogue_toggle != null:
		_dialogue_toggle.text = "▾" if _dialogue_open else "▴"
	if _chrome_toggle != null:
		_chrome_toggle.text = "◱" if _chrome_open else "◰"

func apply_language() -> void:
	_refresh_labels()
