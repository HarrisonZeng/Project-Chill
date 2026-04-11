extends Area2D

class_name Companion

signal interaction_requested

@export var companion_name := "Mika"
@export_multiline var default_opening := "I'm glad you're here. What feels worth talking about tonight?"

var interaction_enabled := true
var player_in_range := false

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt_label.text = "Press E to chat"
	prompt_label.visible = false


func _process(_delta: float) -> void:
	if player_in_range and interaction_enabled and Input.is_action_just_pressed("interact"):
		interaction_requested.emit()


func set_interaction_enabled(value: bool) -> void:
	interaction_enabled = value
	prompt_label.visible = player_in_range and interaction_enabled


func get_opening_line(memory_system: Node) -> String:
	var recent_topics := _read_recent_topics(memory_system)
	if recent_topics.is_empty():
		return default_opening

	return "Welcome back. Last time you mentioned %s. How does that feel now?" % _format_topics(recent_topics)


func build_reply(player_message: String, memory_system: Node) -> String:
	var lowered := player_message.to_lower()
	if lowered.contains("tired") or lowered.contains("stress") or lowered.contains("overwhelm"):
		return "Then let's keep this gentle. You do not need to solve everything tonight."

	if lowered.contains("good") or lowered.contains("better") or lowered.contains("happy"):
		return "I like hearing that. We can stay with that feeling for a moment and let it be enough."

	if lowered.contains("work") or lowered.contains("school") or lowered.contains("study"):
		return "That sounds like a lot to carry. What part of it feels heaviest?"

	if lowered.contains("friend") or lowered.contains("family") or lowered.contains("relationship"):
		return "Relationships can stay with us long after the moment passes. What are you hoping for there?"

	var recent_topics := _read_recent_topics(memory_system)
	if recent_topics.is_empty():
		return "Thanks for sharing that with me. I am listening."

	return "Thanks for telling me. I will remember %s, and we can come back to it anytime." % _format_topics(recent_topics)


func _read_recent_topics(memory_system: Node) -> Array[String]:
	if memory_system == null or not memory_system.has_method("get_recent_topics"):
		return []

	var recent_topics: Array[String] = memory_system.get_recent_topics(3)
	return recent_topics


func _format_topics(topics: Array[String]) -> String:
	if topics.is_empty():
		return ""

	if topics.size() == 1:
		return topics[0]

	if topics.size() == 2:
		return "%s and %s" % [topics[0], topics[1]]

	var leading_topics := topics.slice(0, topics.size() - 1)
	return "%s, and %s" % [", ".join(leading_topics), topics[topics.size() - 1]]


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = interaction_enabled


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
