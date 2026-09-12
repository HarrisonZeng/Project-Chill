class_name TasksPanelController
extends Control

# Owns the optional tasks/todo panel under OverlayLayer/Tools: the floating tab
# badge, the panel (title, rows, new-task input, counter), and the drag-resize
# handle. Holds the todo list itself and handles the resize drag via _input.
# Persistence stays in main_scene, which reads/writes this component through the
# accessors below and listens to save_requested.

signal save_requested

const PANEL_MIN_WIDTH := 280.0
const PANEL_MAX_WIDTH := 560.0
const PANEL_MIN_HEIGHT := 250.0
const PANEL_MAX_HEIGHT := 720.0
const PANEL_MIN_TOP := 110.0

@onready var tasks_tab: Button = $TasksTab
@onready var tasks_panel: PanelContainer = $TasksPanel
@onready var tasks_title: Label = $TasksPanel/Col/Header/Title
@onready var tasks_close_button: Button = $TasksPanel/Col/Header/CloseButton
@onready var tasks_rows: VBoxContainer = $TasksPanel/Col/Scroll/Rows
@onready var new_task_input: LineEdit = $TasksPanel/Col/NewTaskInput
@onready var tasks_counter: Label = $TasksPanel/Col/Counter
@onready var tasks_resize_handle: Button = $TasksResizeHandle

var todo_items: Array[Dictionary] = []
var language: String = "en"
var panel_visible: bool = false
var hovered_task_index: int = -1
var resizing: bool = false
var resize_start_mouse_position: Vector2 = Vector2.ZERO
var resize_start_left: float = 0.0
var resize_start_top: float = 0.0

const ICON_CHECK: Texture2D = preload("res://assets/art/ui/icons/check.svg")
const ICON_BOX: Texture2D = preload("res://assets/art/ui/icons/box.svg")
const ICON_CLOSE: Texture2D = preload("res://assets/art/ui/icons/close.svg")
const ICON_PENCIL: Texture2D = preload("res://assets/art/ui/icons/pencil.svg")

func _ready() -> void:
	if new_task_input != null:
		new_task_input.clear_button_enabled = true
	if tasks_tab != null:
		tasks_tab.pressed.connect(_on_tab_pressed)
	if tasks_close_button != null:
		tasks_close_button.pressed.connect(_on_close_pressed)
	if new_task_input != null:
		new_task_input.text_submitted.connect(_on_new_task_submitted)
	if tasks_resize_handle != null:
		tasks_resize_handle.gui_input.connect(_on_resize_handle_input)
	refresh_controls()

func _input(event: InputEvent) -> void:
	if not resizing:
		return
	if event is InputEventMouseMotion:
		var delta := get_global_mouse_position() - resize_start_mouse_position
		_apply_panel_offsets(resize_start_left + delta.x, resize_start_top + delta.y)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			resizing = false
			save_requested.emit()
			get_viewport().set_input_as_handled()

# --- public API used by main_scene ---

func apply_language(lang: String) -> void:
	language = lang
	if tasks_title != null:
		tasks_title.text = UiStrings.t("tasks.title", language)
	if new_task_input != null:
		new_task_input.placeholder_text = UiStrings.t("tasks.new_placeholder", language)
	if tasks_close_button != null:
		tasks_close_button.tooltip_text = UiStrings.t("tasks.close", language)
	if tasks_resize_handle != null:
		tasks_resize_handle.tooltip_text = UiStrings.t("tasks.resize.tooltip", language)
	render_tasks()
	refresh_controls()

func has_todos() -> bool:
	return not todo_items.is_empty()

func seed_default_tasks() -> void:
	add_todo_item("Set one gentle focus block")
	add_todo_item("Write today's calm priority")
	add_todo_item("Try one scripted greeting branch")

func get_todos_payload() -> Array:
	var payload: Array = []
	for item_data in todo_items:
		var clean_text := str(item_data.get("text", "")).strip_edges()
		if clean_text.is_empty():
			continue
		payload.append({"text": clean_text, "completed": bool(item_data.get("completed", false))})
	return payload

func load_todos(items) -> void:
	todo_items.clear()
	for todo in items:
		var todo_data: Dictionary = todo
		add_todo_item(str(todo_data.get("text", "")), bool(todo_data.get("completed", false)))

func get_panel_left() -> float:
	return tasks_panel.offset_left if tasks_panel != null else 0.0

func get_panel_top() -> float:
	return tasks_panel.offset_top if tasks_panel != null else 0.0

func apply_panel_offsets(left_offset: float, top_offset: float) -> void:
	_apply_panel_offsets(left_offset, top_offset)

func is_panel_visible() -> bool:
	return panel_visible

func set_panel_visible(visible: bool) -> void:
	panel_visible = visible
	refresh_controls()

func refresh_controls() -> void:
	if tasks_tab != null:
		var pending := 0
		for item in todo_items:
			if not bool(item.get("completed", false)):
				pending += 1
		# Journal restyle: the notebook icon carries the meaning, the number rides
		# beside it. Empty list shows just the icon.
		tasks_tab.text = ("%d" % pending) if pending > 0 else ""
		tasks_tab.tooltip_text = UiStrings.t("tasks.tab.label", language)
		tasks_tab.tooltip_text = UiStrings.t("tasks.tab.label", language)
	if tasks_panel != null:
		tasks_panel.visible = panel_visible
	if tasks_resize_handle != null:
		tasks_resize_handle.visible = panel_visible
		if panel_visible:
			_update_resize_handle_position()
	_update_counter()

# --- internals ---

func _update_counter() -> void:
	if tasks_counter == null:
		return
	var total := todo_items.size()
	if total == 0:
		tasks_counter.text = UiStrings.t("tasks.counter_empty", language)
		return
	var done := 0
	for item in todo_items:
		if bool(item.get("completed", false)):
			done += 1
	tasks_counter.text = UiStrings.t("tasks.counter", language) % [total, done]

func add_todo_item(text: String, completed: bool = false) -> void:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return
	todo_items.append({"text": clean_text, "completed": completed})
	render_tasks()

func render_tasks() -> void:
	if tasks_rows == null:
		return
	for child in tasks_rows.get_children():
		tasks_rows.remove_child(child)
		child.free()
	hovered_task_index = -1

	if todo_items.is_empty():
		var ghost := Label.new()
		ghost.text = UiStrings.t("tasks.empty", language)
		ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ghost.add_theme_color_override("font_color", Color(0.462745, 0.352941, 0.270588, 0.6))  # soft ink on paper
		ghost.add_theme_font_size_override("font_size", 13)
		tasks_rows.add_child(ghost)
		_update_counter()
		return

	for index in range(todo_items.size()):
		var data := todo_items[index]
		var completed := bool(data.get("completed", false))
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 32)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(_on_task_row_mouse_entered.bind(index))
		row.mouse_exited.connect(_on_task_row_mouse_exited.bind(index))

		# Notebook line (owner, 2026-09-13): a number on the left, the task text,
		# then two small boxes on the right — a pencil to edit, a check to
		# complete. No delete box: clear the text while editing and press Enter.
		var number := Label.new()
		number.text = "%d." % (index + 1)
		number.custom_minimum_size = Vector2(26, 28)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 14)
		number.add_theme_color_override("font_color", Color(0.462745, 0.352941, 0.270588, 0.55 if completed else 0.9))
		row.add_child(number)

		var text_field := LineEdit.new()
		text_field.text = str(data.get("text", ""))
		text_field.custom_minimum_size = Vector2(0, 28)
		text_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_field.placeholder_text = UiStrings.t("tasks.task_placeholder", language)
		text_field.flat = true
		# Read-only until the pencil is pressed, so a stray click does not put
		# a caret in a task.
		text_field.editable = false
		text_field.selecting_enabled = false
		text_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_field.text_changed.connect(_on_todo_text_changed.bind(index))
		text_field.text_submitted.connect(_on_todo_text_submitted.bind(text_field))
		text_field.focus_exited.connect(_on_todo_edit_finished.bind(text_field))
		# The line is read-only most of the time, and a read-only LineEdit draws
		# with font_uneditable_color (near-invisible by default) — so set both.
		var ink := Color(0.462745, 0.352941, 0.270588, 0.5) if completed else get_theme_color("espresso_brown", "Palette")
		text_field.add_theme_color_override("font_color", ink)
		text_field.add_theme_color_override("font_uneditable_color", ink)
		row.add_child(text_field)

		# Pencil and check packed side by side at the right edge (owner,
		# 2026-09-13), so the text gets the width instead of the gaps.
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 0)
		actions.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(actions)
		# The theme's button style carries 14 px of side padding for text
		# chips; on a bare icon that padding is what kept the pair apart.
		var bare := StyleBoxEmpty.new()

		var edit_button := Button.new()
		edit_button.icon = ICON_PENCIL
		edit_button.text = ""
		edit_button.flat = true
		edit_button.custom_minimum_size = Vector2(26, 28)
		edit_button.focus_mode = Control.FOCUS_NONE
		edit_button.tooltip_text = UiStrings.t("tasks.edit", language)
		edit_button.pressed.connect(_on_todo_edit_pressed.bind(text_field))
		edit_button.expand_icon = true
		for st in ["normal", "hover", "pressed", "focus"]:
			edit_button.add_theme_stylebox_override(st, bare)
		actions.add_child(edit_button)

		var done_toggle := Button.new()
		done_toggle.toggle_mode = true
		done_toggle.flat = true
		done_toggle.custom_minimum_size = Vector2(26, 28)
		done_toggle.icon = ICON_CHECK if completed else ICON_BOX
		done_toggle.text = ""
		done_toggle.button_pressed = completed
		done_toggle.focus_mode = Control.FOCUS_NONE
		done_toggle.tooltip_text = UiStrings.t("tasks.mark_done", language)
		done_toggle.toggled.connect(_on_todo_completed_toggled.bind(index))
		done_toggle.expand_icon = true
		for st in ["normal", "hover", "pressed", "focus"]:
			done_toggle.add_theme_stylebox_override(st, bare)
		actions.add_child(done_toggle)

		tasks_rows.add_child(row)

	_update_counter()

func _on_tab_pressed() -> void:
	panel_visible = not panel_visible
	refresh_controls()
	if panel_visible and new_task_input != null:
		new_task_input.grab_focus()
	save_requested.emit()

func _on_close_pressed() -> void:
	panel_visible = false
	refresh_controls()
	save_requested.emit()

func _on_new_task_submitted(_submitted_text: String) -> void:
	_add_task_from_input()

func _add_task_from_input() -> void:
	if new_task_input == null:
		return
	var task_text := new_task_input.text.strip_edges()
	if task_text.is_empty():
		return
	add_todo_item(task_text)
	new_task_input.clear()
	refresh_controls()
	save_requested.emit()

func _on_resize_handle_input(event: InputEvent) -> void:
	if tasks_panel == null or tasks_resize_handle == null:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			resizing = true
			resize_start_mouse_position = get_global_mouse_position()
			resize_start_left = tasks_panel.offset_left
			resize_start_top = tasks_panel.offset_top
			tasks_resize_handle.grab_focus()
		else:
			if resizing:
				resizing = false
				save_requested.emit()
		accept_event()
		return

	if event is InputEventMouseMotion and resizing:
		var delta := get_global_mouse_position() - resize_start_mouse_position
		_apply_panel_offsets(resize_start_left + delta.x, resize_start_top + delta.y)
		accept_event()

func _apply_panel_offsets(left_offset: float, top_offset: float) -> void:
	if tasks_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var fixed_right := tasks_panel.offset_right
	var clamped_left := clampf(
		left_offset,
		fixed_right - PANEL_MAX_WIDTH,
		fixed_right - PANEL_MIN_WIDTH
	)

	var bottom_px := (tasks_panel.anchor_bottom * viewport_size.y) + tasks_panel.offset_bottom
	var anchor_top_px := tasks_panel.anchor_top * viewport_size.y
	var max_height := minf(PANEL_MAX_HEIGHT, bottom_px - PANEL_MIN_TOP)
	var min_top_px := maxf(PANEL_MIN_TOP, bottom_px - max_height)
	var max_top_px := bottom_px - PANEL_MIN_HEIGHT
	var requested_top_px := anchor_top_px + top_offset
	var clamped_top_px := clampf(requested_top_px, min_top_px, max_top_px)

	tasks_panel.offset_left = clamped_left
	tasks_panel.offset_top = clamped_top_px - anchor_top_px
	_update_resize_handle_position()

func _update_resize_handle_position() -> void:
	if tasks_resize_handle == null or tasks_panel == null:
		return
	tasks_resize_handle.anchor_left = tasks_panel.anchor_left
	tasks_resize_handle.anchor_right = tasks_panel.anchor_left
	tasks_resize_handle.anchor_top = tasks_panel.anchor_top
	tasks_resize_handle.anchor_bottom = tasks_panel.anchor_top
	tasks_resize_handle.offset_left = tasks_panel.offset_left - 12.0
	tasks_resize_handle.offset_top = tasks_panel.offset_top - 6.0
	tasks_resize_handle.offset_right = tasks_panel.offset_left - 4.0
	tasks_resize_handle.offset_bottom = tasks_panel.offset_top + 34.0

func _on_task_row_mouse_entered(index: int) -> void:
	hovered_task_index = index
	_update_task_row_delete_visibility(index, true)

func _on_task_row_mouse_exited(index: int) -> void:
	if hovered_task_index == index:
		hovered_task_index = -1
	_update_task_row_delete_visibility(index, false)

func _update_task_row_delete_visibility(index: int, visible: bool) -> void:
	if tasks_rows == null:
		return
	if index < 0 or index >= tasks_rows.get_child_count():
		return
	var row := tasks_rows.get_child(index)
	if not row.has_meta("delete_button"):
		return
	var btn: Button = row.get_meta("delete_button")
	if btn != null:
		btn.visible = visible

# Pencil: unlock the line for typing and put the caret at the end.
func _on_todo_edit_pressed(text_field: LineEdit) -> void:
	if text_field == null:
		return
	if text_field.editable:
		_lock_task_line(text_field)
		return
	text_field.editable = true
	text_field.selecting_enabled = true
	text_field.mouse_filter = Control.MOUSE_FILTER_STOP
	text_field.grab_focus()
	text_field.caret_column = text_field.text.length()

# Enter while editing: an empty line means "delete this task"; anything else
# is kept and the line locks again.
func _on_todo_text_submitted(new_text: String, text_field: LineEdit) -> void:
	if text_field == null or tasks_rows == null:
		return
	if new_text.strip_edges().is_empty():
		var row := text_field.get_parent()
		var index := tasks_rows.get_children().find(row)
		_on_todo_delete_pressed(index)
		return
	_lock_task_line(text_field)
	save_requested.emit()

func _on_todo_edit_finished(text_field: LineEdit) -> void:
	if text_field != null and text_field.editable:
		_lock_task_line(text_field)

func _lock_task_line(text_field: LineEdit) -> void:
	text_field.editable = false
	text_field.selecting_enabled = false
	text_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text_field.has_focus():
		text_field.release_focus()

func _on_todo_text_changed(new_text: String, index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items[index]["text"] = new_text
	save_requested.emit()

func _on_todo_completed_toggled(completed: bool, index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items[index]["completed"] = completed
	render_tasks()
	refresh_controls()
	save_requested.emit()

func _on_todo_delete_pressed(index: int) -> void:
	if index < 0 or index >= todo_items.size():
		return
	todo_items.remove_at(index)
	render_tasks()
	refresh_controls()
	save_requested.emit()

func _on_todo_delete_pressed_from_button(button: Button) -> void:
	if tasks_rows == null or button == null:
		return
	var row := button.get_parent()
	if row == null:
		return
	var index := tasks_rows.get_children().find(row)
	_on_todo_delete_pressed(index)
