extends Node

var ai_service: Node = null

func set_ai_service(service: Node) -> void:
	ai_service = service

func route_player_text_async(player_text: String, ai_mode_enabled: bool, memory_context: String, persona_text: String, runtime_rules: String, mode_context: String, mode_id: String) -> Dictionary:
	if not ai_mode_enabled:
		return {
			"mode": "scripted"
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

		return {
			"mode": "ai",
			"text": str(reply.get("text", "")),
			"success": bool(reply.get("success", false)),
			"fallback_used": false
		}

	return {
		"mode": "ai_fallback",
		"text": "AI mode is unavailable right now. Let's stick to scripted choices.",
		"success": false,
		"fallback_used": true
	}
