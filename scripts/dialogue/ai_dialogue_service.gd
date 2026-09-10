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
			return "叮。我这边也刚停。你随意，我先喝口水。"
		if mode_id == "AI_MODE_BREAK_CHAT":
			return "那就先歇一下。我也停一停，杯子都空了。"
		if mode_id == "AI_MODE_CHECKIN":
			return "行，那就这个。我这边也开了。"
		if mode_id == "AI_MODE_PLATFORM_REACT":
			return "这个我不太刷。不过听起来，也是那种一进去就出不来的。"
		# Offline stand-in for the real provider. Mandarin only, in her voice, and
		# never a comment on the player's productivity — she reacts to what they
		# said, then goes back to her own work (audit §5 BLOCK: the English
		# catch-alls here reached Chinese players whenever no key was set).
		if user_text.length() > 80:
			return "一口气说了这么多。我先记住前半段，后半段你歇口气再说。"
		if _looks_like_sensitive_request(user_text):
			return "这个我接不了。换个话题吧，我这杯茶快凉了。"
		if _looks_like_memory_followup(mode_id, user_text):
			return _memory_followup_reply(lowered)
		if lowered.contains("tomorrow") or lowered.contains("later") or lowered.contains("soon") \
				or user_text.contains("明天") or user_text.contains("待会") or user_text.contains("一会"):
			return _goodbye_seed_reply(lowered, user_text)
		if lowered.contains("focus") or lowered.contains("study") or lowered.contains("work on") \
				or user_text.contains("专注") or user_text.contains("学习") or user_text.contains("干活"):
			return "行。那各开各的。我这段也刚起了个头。"
		if lowered.contains("tired") or lowered.contains("stressed") or lowered.contains("overwhelmed") \
				or user_text.contains("累") or user_text.contains("烦") or user_text.contains("崩"):
			return "那就先别硬撑。我这边也卡着呢，一起卡一会儿。"
		return "嗯，听见了。想接着说就说，我这边一边写一边听。"

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

	# The player mentioned something upcoming. She acknowledges it and steps
	# back — no "come back and tell me," no plans for tomorrow (taste log).
	func _goodbye_seed_reply(lowered: String, original: String = "") -> String:
		if lowered.contains("school") or lowered.contains("class") or original.contains("学校") or original.contains("上课"):
			return "明天要上课啊。那今晚别熬太晚。我也是。"
		if lowered.contains("exam") or lowered.contains("test") or original.contains("考试") or original.contains("考"):
			return "有考试。嗯，那这段就当热身。我这边安静着。"
		if lowered.contains("work") or lowered.contains("shift") or original.contains("上班") or original.contains("工作"):
			return "明天要上班。那今天就到这儿，别把电用光。"
		if lowered.contains("sleep") or lowered.contains("rest") or original.contains("睡") or original.contains("休息"):
			return "那就别撑了，去睡。我也快关文档了。"
		return "好，知道了。我记着。"

	func _memory_followup_reply(lowered: String) -> String:
		if lowered.contains("school") or lowered.contains("class"):
			return "学校那边啊。后来怎么样了？不想说也行。"
		if lowered.contains("exam") or lowered.contains("test"):
			return "那场考试……比你想的好一点没？"
		if lowered.contains("work") or lowered.contains("shift"):
			return "工作还是那么忙？听着就累。"
		if lowered.contains("sleep") or lowered.contains("rest"):
			return "那后来睡好了没有？"
		return "哦，对，那件事。后来呢？"

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

		# max_tokens must be generous: MiniMax M-series models spend a <think>
		# reasoning block (stripped client-side) before the visible reply, and a
		# tight budget would starve the actual line.
		var payload: Dictionary = {
			"model": model_name,
			"messages": _build_messages(request),
			"max_tokens": 3000
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
# Direct MiniMax (owner's subscription). NOTE: api.minimaxi.com is the working
# host for this key (api.minimax.io rejects it); M-series models emit <think>
# blocks that _request_chat_completion strips before the text reaches the game.
const MINIMAX_CHAT_COMPLETIONS_URL := "https://api.minimaxi.com/v1/chat/completions"
const MINIMAX_DEFAULT_MODEL := "MiniMax-M3"
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

func use_minimax_provider(model_name: String = MINIMAX_DEFAULT_MODEL) -> void:
	use_minimax_provider_with_key(OS.get_environment("MINIMAX_API_KEY"), model_name)

# Same provider, but with the key handed in rather than read from the
# environment — the browser build has no environment to read. See baked_keys.gd.
func use_minimax_provider_with_key(api_key: String, model_name: String = MINIMAX_DEFAULT_MODEL) -> void:
	use_chat_completion_provider(api_key, model_name, MINIMAX_CHAT_COMPLETIONS_URL)

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
	content = _strip_reasoning(content)
	# An empty reply is a FAILURE, not a success carrying operator English. Saying
	# success here let FALLBACK_REPLY through as if Yua had spoken it; the router
	# now substitutes an in-fiction line instead.
	if content.is_empty():
		last_error = "response_empty"
		return {
			"text": "",
			"success": false,
			"provider": provider_name,
			"error": last_error,
			"fallback_used": true
		}

	return {
		"text": content,
		"success": true,
		"provider": provider_name,
		"fallback_used": false
	}

# MiniMax M-series (and other reasoning models) return their chain-of-thought
# inline before the reply. Strip it so it never reaches the dialogue box.
#
# The opening tag is often part of the chat template and is NOT echoed back, so
# the payload frequently looks like "<reasoning...></think>实际回复" — guarding on
# "<think>" alone let that whole chain-of-thought through as Yua's line. Anything
# before the LAST closing tag is therefore treated as reasoning, whether or not a
# matching opening tag was sent, and variants/casing are covered.
func _strip_reasoning(content: String) -> String:
	var close_regex := RegEx.new()
	if close_regex.compile("(?i)</\\s*(think|thinking|reasoning|thought)\\s*>") == OK:
		var closes: Array = close_regex.search_all(content)
		if not closes.is_empty():
			var last_close: RegExMatch = closes[closes.size() - 1]
			content = content.substr(last_close.get_end())

	# Any complete block that remains (reply first, reasoning after).
	var pair_regex := RegEx.new()
	if pair_regex.compile("(?is)<\\s*(think|thinking|reasoning|thought)\\s*>.*?</\\s*\\1\\s*>") == OK:
		content = pair_regex.sub(content, "", true)

	# An unclosed opening tag means the rest is truncated reasoning — cut it.
	var open_regex := RegEx.new()
	if open_regex.compile("(?i)<\\s*(think|thinking|reasoning|thought)\\s*>") == OK:
		var opened: RegExMatch = open_regex.search(content)
		if opened != null:
			content = content.substr(0, opened.get_start())

	return content.strip_edges()
