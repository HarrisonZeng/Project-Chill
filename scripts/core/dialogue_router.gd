extends Node

var ai_service: Node = null
const SCRIPTED_FALLBACK_TEXT := "Let's stay with the scripted choices for now."
const AI_FALLBACK_TEXT := "Mm. I can't reach the AI right now, so let's keep things simple and continue with the buttons."

func set_ai_service(service: Node) -> void:
	ai_service = service

func route_player_text_async(player_text: String, ai_mode_enabled: bool, memory_context: String, persona_text: String, runtime_rules: String, mode_context: String, mode_id: String) -> Dictionary:
	if not ai_mode_enabled:
		return {
			"mode": "scripted",
			"success": true,
			"fallback_used": false,
			"provider": "scripted",
			"text": SCRIPTED_FALLBACK_TEXT
		}

	if ai_service != null and ai_service.is_available():
		var reply: Dictionary = await ai_service.generate_reply_async({
			"user_text": player_text,
			"tone": "warm",
			"memory_context": memory_context,
			"persona": persona_text,
			"runtime_rules": runtime_rules,
			"mode_context": mode_context,
			"mode_id": mode_id
		})

		if not bool(reply.get("success", false)):
			var fallback_text: String = str(reply.get("text", ""))
			if fallback_text.is_empty() or fallback_text == "AI provider is not available.":
				fallback_text = AI_FALLBACK_TEXT
			return {
				"mode": "ai_fallback",
				"text": fallback_text,
				"success": false,
				"fallback_used": true,
				"provider": str(reply.get("provider", "none")),
				"error": str(reply.get("error", "provider_failed"))
			}

		return {
			"mode": "ai",
			"text": str(reply.get("text", "")),
			"success": bool(reply.get("success", false)),
			"fallback_used": bool(reply.get("fallback_used", false)),
			"provider": str(reply.get("provider", "unknown"))
		}

	return {
		"mode": "ai_fallback",
		"text": AI_FALLBACK_TEXT,
		"success": false,
		"fallback_used": true,
		"provider": "none",
		"error": "ai_service_unavailable"
	}
