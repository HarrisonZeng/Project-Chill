extends Node

class AiProvider:
	var provider_name: String = "base"

	func is_available() -> bool:
		return false

	func generate_reply_async(request: Dictionary) -> Dictionary:
		return {
			"text": "AI provider is not configured.",
			"success": false,
			"provider": provider_name,
			"error": "provider_not_configured"
		}

class MockAiProvider extends AiProvider:
	var service: Node

	func _init(owner: Node) -> void:
		service = owner
		provider_name = "mock"

	func is_available() -> bool:
		return true

	func generate_reply_async(request: Dictionary) -> Dictionary:
		await service.get_tree().process_frame
		var user_text: String = str(request.get("user_text", ""))
		var mode_id: String = str(request.get("mode_id", ""))
		var response: String = _mock_reply_for(user_text, mode_id)
		return {
			"text": response,
			"success": true,
			"provider": provider_name,
			"fallback_used": false
		}

	func _mock_reply_for(user_text: String, mode_id: String) -> String:
		var lowered := user_text.to_lower()
		if user_text.is_empty():
			return _calm_opening(mode_id)
		if mode_id == "AI_MODE_TASK_CLARIFY":
			return "这个可以切小一点。先选最容易开始的那一块，做完再看下一步。"
		if mode_id == "AI_MODE_POST_SESSION":
			return "刚才那段推进到哪里了？不用总结得很漂亮，说实话就行。"
		if mode_id == "AI_MODE_BREAK_CHAT":
			return "那就先歇一下。不是逃跑，是给下一段留一点电。"
		if mode_id == "AI_MODE_CHECKIN":
			return "听起来可以。把它缩成一个小目标，我们就能开计时了。"
		if user_text.length() > 80:
			return "Mm. That sounds like a lot. Want to keep it small?"
		if _looks_like_sensitive_request(user_text):
			return "Mm. I can't help with that, but we can keep things gentle and simple here."
		if _looks_like_memory_followup(mode_id, user_text):
			return _memory_followup_reply(lowered)
		if lowered.contains("tomorrow") or lowered.contains("later") or lowered.contains("soon"):
			return _goodbye_seed_reply(lowered)
		if lowered.contains("focus") or lowered.contains("study") or lowered.contains("work on"):
			return "All right. Start small, then. I'll still be here when you come back."
		if lowered.contains("tired") or lowered.contains("stressed") or lowered.contains("overwhelmed"):
			return "Mm. Then let's make this smaller, not heavier. One step is enough."
		return "Mm. I hear you. You can tell me a little more if you want."

	func _calm_opening(mode_id: String) -> String:
		if mode_id == "AI_MODE_MEMORY_FOLLOWUP":
			return "回来了。上次那件事，后来怎么样？"
		if mode_id == "AI_MODE_TASK_CLARIFY":
			return "你先随便说大概，我帮你切小一点。"
		if mode_id == "AI_MODE_POST_SESSION":
			return "刚才那段，感觉怎么样？"
		if mode_id == "AI_MODE_BREAK_CHAT":
			return "嗯，先休息一下。我在。"
		return "我在。"

	func _goodbye_seed_reply(lowered: String) -> String:
		if lowered.contains("school") or lowered.contains("class"):
			return "School tomorrow? Then try not to let the night get too loud. Come back and tell me how it went."
		if lowered.contains("exam") or lowered.contains("test"):
			return "An exam tomorrow, then. I'll be quietly rooting for you."
		if lowered.contains("work") or lowered.contains("shift"):
			return "Work tomorrow? Then save a little energy for yourself too."
		if lowered.contains("sleep") or lowered.contains("rest"):
			return "Then let's not keep you too long. Rest first, and we can talk again after."
		return "All right. Tell me again when you come back, if you feel like it."

	func _memory_followup_reply(lowered: String) -> String:
		if lowered.contains("school") or lowered.contains("class"):
			return "Mm. School stayed with you, then. How did it feel in the end?"
		if lowered.contains("exam") or lowered.contains("test"):
			return "That exam again... was it kinder than you expected?"
		if lowered.contains("work") or lowered.contains("shift"):
			return "Work still sounds a little heavy. Has it eased up at all?"
		if lowered.contains("sleep") or lowered.contains("rest"):
			return "Then I hope you gave yourself at least a little rest."
		return "Oh. Right, that too. How did it go?"

	func _looks_like_sensitive_request(user_text: String) -> bool:
		var lowered := user_text.to_lower()
		return lowered.contains("sexual") or lowered.contains("nude") or lowered.contains("explicit")

	func _looks_like_memory_followup(mode_id: String, user_text: String) -> bool:
		if mode_id == "AI_MODE_MEMORY_FOLLOWUP":
			return true
		var lowered := user_text.to_lower()
		return lowered.contains("school") or lowered.contains("exam") or lowered.contains("work") or lowered.contains("sleep")

class PoeAiProvider extends AiProvider:
	var service: Node
	var api_key: String
	var model_name: String
	var endpoint_url: String

	func _init(owner: Node, key: String, model: String, url: String = "") -> void:
		service = owner
		api_key = key
		model_name = model
		endpoint_url = url
		provider_name = "poe"

	func is_available() -> bool:
		return not api_key.is_empty()

	func generate_reply_async(request: Dictionary) -> Dictionary:
		if api_key.is_empty():
			return {
				"text": "",
				"success": false,
				"provider": provider_name,
				"error": "api_key_missing"
			}

		var payload: Dictionary = {
			"model": model_name,
			"messages": _build_messages(request)
		}

		var timeout_seconds: float = float(request.get("timeout_seconds", 20.0))
		return await service._request_chat_completion(payload, api_key, endpoint_url, provider_name, timeout_seconds)

	func _build_messages(request: Dictionary) -> Array:
		# Prompt assembly order (docs/AI_Context_Packet_Spec.md):
		#   1. persona  = Layer 1 personality + Layer 2 world
		#   2. context_packet = Layer 3 per-call context block
		#   3. runtime_rules
		#   4. the player's message
		var messages: Array = []
		var persona: String = str(request.get("persona", ""))
		if not persona.is_empty():
			messages.append({"role": "system", "content": persona})

		var context_packet: String = str(request.get("context_packet", ""))
		if not context_packet.is_empty():
			messages.append({"role": "system", "content": context_packet})

		var runtime_rules: String = str(request.get("runtime_rules", ""))
		if not runtime_rules.is_empty():
			messages.append({"role": "system", "content": runtime_rules})

		messages.append({
			"role": "user",
			"content": str(request.get("user_text", ""))
		})

		return messages

const DEFAULT_CHAT_COMPLETIONS_URL := "https://api.poe.com/v1/chat/completions"
const FALLBACK_REPLY := "Mm. I can't reach the AI right now, so let's keep to the scripted choices for now."

var provider: AiProvider = null
var http_request: HTTPRequest = null
var last_error: String = ""

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)

func set_provider(new_provider: AiProvider) -> void:
	provider = new_provider

func use_mock_provider() -> void:
	provider = MockAiProvider.new(self)

func use_poe_provider(model_name: String) -> void:
	use_chat_completion_provider(OS.get_environment("POE_API_KEY"), model_name, DEFAULT_CHAT_COMPLETIONS_URL)

func use_chat_completion_provider(api_key: String, model_name: String, endpoint_url: String = DEFAULT_CHAT_COMPLETIONS_URL) -> void:
	provider = PoeAiProvider.new(self, api_key, model_name, endpoint_url)

func is_available() -> bool:
	return provider != null and provider.is_available()

func get_last_error() -> String:
	return last_error

func get_fallback_reply() -> String:
	return FALLBACK_REPLY

func generate_reply_async(request: Dictionary) -> Dictionary:
	if provider == null:
		last_error = "provider_missing"
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": "none",
			"error": last_error,
			"fallback_used": true
		}

	var reply: Dictionary = await provider.generate_reply_async(request)
	if not bool(reply.get("success", false)):
		last_error = str(reply.get("error", "provider_failed"))
		if str(reply.get("text", "")).is_empty():
			reply["text"] = FALLBACK_REPLY
		reply["fallback_used"] = true
	else:
		last_error = ""

	if not reply.has("provider"):
		reply["provider"] = "unknown"

	return reply

func _request_chat_completion(payload: Dictionary, api_key: String, endpoint_url: String, provider_name: String, timeout_seconds: float) -> Dictionary:
	if http_request == null:
		last_error = "http_request_missing"
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var headers: Array[String] = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var body: String = JSON.stringify(payload)
	http_request.timeout = maxf(timeout_seconds, 1.0)

	var request_url: String = endpoint_url if not endpoint_url.is_empty() else DEFAULT_CHAT_COMPLETIONS_URL
	var err: int = http_request.request(request_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		last_error = "request_failed_%s" % str(err)
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var result: Array = await http_request.request_completed
	if int(result[0]) != HTTPRequest.RESULT_SUCCESS:
		last_error = "request_result_%s" % str(result[0])
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code < 200 or response_code >= 300:
		last_error = "http_%s" % str(response_code)
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var parsed: Variant = JSON.parse_string(response_body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "response_not_json"
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var choices: Array = (parsed as Dictionary).get("choices", [])
	if choices.is_empty():
		last_error = "response_no_choices"
		return {
			"text": FALLBACK_REPLY,
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	var message: Dictionary = choices[0].get("message", {})
	var content: String = str(message.get("content", ""))
	if content.is_empty():
		last_error = "response_empty"
		content = FALLBACK_REPLY

	return {
		"text": content,
		"success": true,
		"provider": provider_name,
		"fallback_used": false
	}
