extends Node

class_name MemorySystem

const STOP_WORDS := [
	"a",
	"about",
	"am",
	"and",
	"are",
	"at",
	"be",
	"but",
	"for",
	"from",
	"have",
	"i",
	"it",
	"just",
	"like",
	"my",
	"of",
	"on",
	"or",
	"so",
	"that",
	"the",
	"this",
	"to",
	"was",
	"with",
	"you"
]

@export var max_topics := 10

var recent_topics: Array[String] = []


func remember_text(text: String) -> Array[String]:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return []

	var topics := _extract_topics(clean_text)
	if topics.is_empty():
		topics.append(_fallback_topic(clean_text))

	for topic in topics:
		_remember_topic(topic)

	return topics


func get_recent_topics(limit: int = 5) -> Array[String]:
	if recent_topics.is_empty() or limit <= 0:
		return []

	var result: Array[String] = []
	var start_index := maxi(recent_topics.size() - limit, 0)
	for index in range(start_index, recent_topics.size()):
		result.append(recent_topics[index])

	return result


func to_dict() -> Dictionary:
	return {
		"recent_topics": recent_topics.duplicate()
	}


func load_from_dict(data: Dictionary) -> void:
	recent_topics.clear()

	if not data.has("recent_topics"):
		return

	var saved_topics: Variant = data["recent_topics"]
	if typeof(saved_topics) != TYPE_ARRAY:
		return

	for item in saved_topics:
		if typeof(item) == TYPE_STRING:
			_remember_topic(item)


func _extract_topics(text: String) -> Array[String]:
	var normalized := text.to_lower()
	for symbol in [".", ",", "!", "?", ";", ":", "\"", "'", "(", ")", "[", "]"]:
		normalized = normalized.replace(symbol, " ")

	var topics: Array[String] = []
	for word in normalized.split(" ", false):
		var topic := word.strip_edges()
		if topic.length() < 4:
			continue
		if STOP_WORDS.has(topic):
			continue
		if topics.has(topic):
			continue

		topics.append(topic)
		if topics.size() == 3:
			break

	return topics


func _fallback_topic(text: String) -> String:
	var words := text.split(" ", false)
	if words.is_empty():
		return "quiet moment"

	var topic := " ".join(words.slice(0, mini(words.size(), 3)))
	return topic.left(32)


func _remember_topic(topic: String) -> void:
	var clean_topic := topic.strip_edges()
	if clean_topic.is_empty():
		return

	if recent_topics.has(clean_topic):
		recent_topics.erase(clean_topic)

	recent_topics.append(clean_topic)
	while recent_topics.size() > max_topics:
		recent_topics.remove_at(0)
