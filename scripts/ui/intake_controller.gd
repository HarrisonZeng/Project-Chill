extends Control

# The launch questionnaire (owner spec 2026-09-23): a black screen in the APP's
# voice — never Yua's — that asks a couple of plain questions before the match.
# It runs once, on the first launch only. Everything it learns is stored on the
# profile by main_scene (nickname / role) and read later by the name reaction,
# the greeting selector and the AI context packet.
#
# Copy rules from the owner: no 搭子, no 合拍, nothing that tries to sound
# 有网感. Plain words.
#
# Self-contained per the component contract: main_scene calls start(), listens
# for `finished(answers)`, and never reaches inside. The overlay fades itself
# out and frees itself when done.

signal finished(answers: Dictionary)

const BG := Color(0.101961, 0.070588, 0.062745, 1.0)
const INK := Color(0.960784, 0.921569, 0.862745, 1.0)
const DIM := Color(0.960784, 0.921569, 0.862745, 0.55)
const ACCENT := Color(0.878431, 0.643137, 0.345098, 1.0)

# Step ids, in order. The "fun" question slot is reserved (owner: decide later).
const STEPS := ["welcome", "nickname", "role", "matching", "matched"]

var answers: Dictionary = {"nickname": "", "role": "", "role_text": ""}
var _step: int = -1
var _dots: int = 1
var _dots_timer: float = 0.0
var _matching: bool = false

var _title: Label
var _prompt: Label
var _hint: Label
var _input: LineEdit
var _buttons: HBoxContainer
var _status: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = BG
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var col := VBoxContainer.new()
	col.name = "Col"
	col.custom_minimum_size = Vector2(420, 0)
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)

	_title = _label("Project Chill", 13, DIM)
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_prompt = _label("", 22, INK)
	_prompt.name = "Prompt"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_prompt)

	_hint = _label("", 13, DIM)
	_hint.name = "Hint"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_hint)

	_input = LineEdit.new()
	_input.name = "Input"
	_input.custom_minimum_size = Vector2(320, 40)
	_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_input.max_length = 24
	_input.text_submitted.connect(func(_t): _on_continue())
	col.add_child(_input)

	_buttons = HBoxContainer.new()
	_buttons.name = "Buttons"
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 10)
	col.add_child(_buttons)

	_status = _label("", 15, DIM)
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_status)

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

# Entry point. main_scene calls this once the overlay is in the tree.
func start() -> void:
	_go(0)

# Test hook: answer everything at once and finish without the animation.
func skip_with(nickname: String, role: String, role_text: String = "") -> void:
	answers = {"nickname": nickname.strip_edges(), "role": role, "role_text": role_text.strip_edges()}
	_finish()

func current_step() -> String:
	if _step < 0 or _step >= STEPS.size():
		return ""
	return STEPS[_step]

# --- steps -------------------------------------------------------------------

func _go(index: int) -> void:
	_step = index
	_clear_buttons()
	_input.visible = false
	_hint.text = ""
	_status.text = ""
	match current_step():
		"welcome":
			_prompt.text = "先回答几个问题。"
			_button("开始", _on_continue)
		"nickname":
			_prompt.text = "你的昵称是"
			_hint.text = "留空也可以。"
			_input.visible = true
			_input.text = ""
			_input.placeholder_text = ""
			_input.grab_focus()
			_button("继续", _on_continue)
		"role":
			_prompt.text = "你是来——"
			_button("一起学习", func(): _pick_role("study"))
			_button("一起工作", func(): _pick_role("work"))
			_button("其他", _on_role_other)
		"matching":
			_prompt.text = "正在匹配…"
			_matching = true
			_dots = 1
			var t := get_tree().create_timer(2.4)
			t.timeout.connect(func(): _go(_step + 1))
		"matched":
			_matching = false
			_prompt.text = "已匹配 · Yua"
			_hint.text = "（也是第一次使用）"
			var t := get_tree().create_timer(1.8)
			t.timeout.connect(_finish)

func _on_continue() -> void:
	match current_step():
		"welcome":
			_go(_step + 1)
		"nickname":
			answers["nickname"] = _input.text.strip_edges()
			_go(_step + 1)
		"role":
			# "其他" with a typed answer.
			answers["role"] = "other"
			answers["role_text"] = _input.text.strip_edges()
			_go(_step + 1)

func _pick_role(role: String) -> void:
	answers["role"] = role
	answers["role_text"] = ""
	_go(_step + 1)

func _on_role_other() -> void:
	# Reveal a small free-text field under the same prompt; typing is optional.
	_clear_buttons()
	_hint.text = "一句话就行，不写也行。"
	_input.visible = true
	_input.text = ""
	_input.placeholder_text = ""
	_input.grab_focus()
	_button("继续", _on_continue)

func _finish() -> void:
	if _step >= STEPS.size():
		return
	_step = STEPS.size()
	finished.emit(answers.duplicate(true))
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.6)
	fade.tween_callback(queue_free)

# --- helpers -----------------------------------------------------------------

func _button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 38)
	b.pressed.connect(on_pressed)
	_buttons.add_child(b)
	return b

func _clear_buttons() -> void:
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()

func _process(delta: float) -> void:
	if not _matching:
		return
	_dots_timer += delta
	if _dots_timer >= 0.5:
		_dots_timer = 0.0
		_dots = (_dots % 3) + 1
		_prompt.text = "正在匹配…"
		_hint.text = "·".repeat(_dots)
