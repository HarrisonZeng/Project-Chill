extends Node

class AiProvider:
	func is_available() -> bool:
		return false

	func generate_reply_async(request: Dictionary) -> Dictionary:
		return {
			"text": "AI provider is not configured.",
			"success": false,
			"provider": "none"
		}

class MockAiProvider extends AiProvider:
	var service: Node

	func _init(owner: Node) -> void:
		service = owner

	func is_available() -> bool:
		return true

	func generate_reply_async(request: Dictionary) -> Dictionary:
		await service.get_tree().process_frame
		var user_text: String = str(request.get("user_text", ""))
		var response: String = "Mock AI (warm): " + user_text + " - thanks for sharing."
		return {
			"text": response,
			"success": true,
			"provider": "mock"
		}

class PoeAiProvider extends AiProvider:
	var service: Node
	var api_key: String
	var model_name: String

	func _init(owner: Node, key: String, model: String) -> void:
		service = owner
		api_key = key
		model_name = model

	func is_available() -> bool:
		return not api_key.is_empty()

	func generate_reply_async(request: Dictionary) -> Dictionary:
		if api_key.is_empty():
			return {
				"text": "POE API key missing.",
				"success": false,
				"provider": "poe"
			}

		var payload: Dictionary = {
			"model": model_name,
			"messages": _build_messages(request)
		}

		return await service._request_poe(payload, api_key)

	func _build_messages(request: Dictionary) -> Array:
		var messages: Array = []
		var persona: String = str(request.get("persona", ""))
		if not persona.is_empty():
			messages.append({"role": "system", "content": persona})

		var memory_context: String = str(request.get("memory_context", ""))
		if not memory_context.is_empty():
			messages.append({"role": "system", "content": memory_context})

		messages.append({
			"role": "user",
			"content": str(request.get("user_text", ""))
		})

		return messages

const POE_API_URL := "https://api.poe.com/v1/chat/completions"

var provider: AiProvider = null
var http_request: HTTPRequest = null

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)

func set_provider(new_provider: AiProvider) -> void:
	provider = new_provider

func use_mock_provider() -> void:
	provider = MockAiProvider.new(self)

func use_poe_provider(model_name: String) -> void:
	var api_key: String = OS.get_environment("POE_API_KEY")
	provider = PoeAiProvider.new(self, api_key, model_name)

func is_available() -> bool:
	return provider != null and provider.is_available()

func generate_reply_async(request: Dictionary) -> Dictionary:
	if provider == null:
		return {
			"text": "AI provider is not available.",
			"success": false,
			"provider": "none"
		}
	return await provider.generate_reply_async(request)

func _request_poe(payload: Dictionary, api_key: String) -> Dictionary:
	if http_request == null:
		return {
			"text": "HTTP request node missing.",
			"success": false,
			"provider": "poe"
		}

	var headers: Array[String] = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
	]

	var body: String = JSON.stringify(payload)
	var err: int = http_request.request(POE_API_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		return {
			"text": "Failed to start POE request.",
			"success": false,
			"provider": "poe"
		}

	var result: Array = await http_request.request_completed
	var response_code: int = result[1]
	var response_body: PackedByteArray = result[3]

	if response_code < 200 or response_code >= 300:
		return {
			"text": "POE request failed (" + str(response_code) + ").",
			"success": false,
			"provider": "poe"
		}

	var parsed: Variant = JSON.parse_string(response_body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"text": "POE response was not JSON.",
			"success": false,
			"provider": "poe"
		}

	var choices: Array = (parsed as Dictionary).get("choices", [])
	if choices.is_empty():
		return {
			"text": "POE response had no choices.",
			"success": false,
			"provider": "poe"
		}

	var message: Dictionary = choices[0].get("message", {})
	var content: String = str(message.get("content", ""))

	return {
		"text": content,
		"success": true,
		"provider": "poe"
	}
