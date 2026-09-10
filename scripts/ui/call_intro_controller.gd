extends Control

# The incoming-call overlay (D1): the diegetic "title screen". First launch shows
# 「来电中…」; a returning player gets 「重新连接…」. One tap on 接听 connects —
# that tap is also the user gesture browsers require before audio may play, so
# the mechanic is load-bearing on the web build, not decoration.
#
# Self-contained per the component contract: main_scene calls setup(), listens
# for `answered`, and never reaches inside. The overlay fades itself out and
# frees itself; the optional first-time hint outlives the fade slightly.

signal answered

@onready var name_label: Label = $Center/Col/NameLabel
@onready var status_label: Label = $Center/Col/StatusLabel
@onready var answer_button: Button = $Center/Col/AnswerRow/AnswerButton
@onready var hint_label: Label = $HintLabel

var _is_returning: bool = false
var _show_hint: bool = false
var _dots_timer: float = 0.0
var _dots_count: int = 1
var _connecting: bool = false

func _ready() -> void:
	if answer_button != null:
		answer_button.pressed.connect(_on_answer_pressed)
	if hint_label != null:
		hint_label.visible = false
	_refresh_status()

# is_returning: a previous session exists (shorter "reconnect" wording, no hint).
# show_hint: first-ever launch — after connecting, float one UI hint so a
# reviewer knows Yua is clickable. UI text, not Yua's voice; shown once ever.
func setup(is_returning: bool, show_hint: bool) -> void:
	_is_returning = is_returning
	_show_hint = show_hint
	_refresh_status()
	# Owner decision 2026-09-10: launching the app IS placing the call, and she
	# answers by herself — no button. First launch rings a beat longer so the
	# "来电中" reads; a returning player reconnects almost at once. Audio on the
	# web build still waits for the player's first click (C5); this never
	# blocks on it.
	if answer_button != null:
		answer_button.visible = false
	var ring := get_tree().create_timer(0.7 if _is_returning else 1.4)
	ring.timeout.connect(_on_answer_pressed)

# Test hook: the godot_check harness answers instantly so every scenario keeps
# working without simulating the tap and the fade.
func skip() -> void:
	answered.emit()
	queue_free()

func _process(delta: float) -> void:
	if _connecting:
		return
	_dots_timer += delta
	if _dots_timer >= 0.6:
		_dots_timer = 0.0
		_dots_count = (_dots_count % 3) + 1
		_refresh_status()

func _refresh_status() -> void:
	if status_label == null:
		return
	var base := "重新连接" if _is_returning else "来电中"
	if _connecting:
		base = "连接中"
	status_label.text = base + "…".repeat(_dots_count)

func _on_answer_pressed() -> void:
	if _connecting:
		return
	_connecting = true
	_dots_count = 1
	_refresh_status()
	if answer_button != null:
		answer_button.disabled = true
	var wait := get_tree().create_timer(0.7)
	wait.timeout.connect(_finish_connect)

func _finish_connect() -> void:
	answered.emit()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.8)
	fade.tween_callback(_after_fade)

func _after_fade() -> void:
	if _show_hint and hint_label != null:
		# Keep only the floating hint alive for a few seconds.
		modulate.a = 1.0
		for child in get_children():
			if child != hint_label and child is CanvasItem:
				(child as CanvasItem).visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		hint_label.visible = true
		hint_label.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(hint_label, "modulate:a", 1.0, 0.5)
		t.tween_interval(5.0)
		t.tween_property(hint_label, "modulate:a", 0.0, 0.8)
		t.tween_callback(queue_free)
	else:
		queue_free()
