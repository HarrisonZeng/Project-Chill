extends PanelContainer

class_name DialoguePanel

signal message_submitted(text: String)
signal closed

var current_speaker_name := "Companion"

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var memory_label: Label = $MarginContainer/VBoxContainer/MemoryLabel
@onready var transcript: RichTextLabel = $MarginContainer/VBoxContainer/Transcript
@onready var input_line: LineEdit = $MarginContainer/VBoxContainer/Composer/InputLine
@onready var send_button: Button = $MarginContainer/VBoxContainer/Composer/SendButton
@onready var close_button: Button = $MarginContainer/VBoxContainer/Composer/CloseButton


func _ready() -> void:
	visible = false
	send_button.pressed.connect(_submit_text)
	close_button.pressed.connect(close_panel)
	input_line.text_submitted.connect(_on_text_submitted)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()


func is_open() -> bool:
	return visible


func open_dialogue(speaker_name: String, opening_line: String, recent_topics: Array[String]) -> void:
	current_speaker_name = speaker_name
	title_label.text = speaker_name
	visible = true
	transcript.clear()
	set_memory_summary(recent_topics)
	add_message(current_speaker_name, opening_line)
	input_line.clear()
	input_line.grab_focus()


func close_panel() -> void:
	if not visible:
		return

	visible = false
	input_line.release_focus()
	closed.emit()


func add_message(author: String, text: String) -> void:
	transcript.append_text("%s: %s\n\n" % [author, text.strip_edges()])
	transcript.scroll_to_line(maxi(transcript.get_line_count() - 1, 0))


func set_memory_summary(recent_topics: Array[String]) -> void:
	if recent_topics.is_empty():
		memory_label.text = "Recent topics: none yet"
		return

	memory_label.text = "Recent topics: %s" % ", ".join(recent_topics)


func _on_text_submitted(_text: String) -> void:
	_submit_text()


func _submit_text() -> void:
	var text := input_line.text.strip_edges()
	if text.is_empty():
		return

	input_line.clear()
	message_submitted.emit(text)
	input_line.grab_focus()
