extends Node

var ai_service: Node = null
# Privacy / on-off hook. When false, the router NEVER touches the AI service, so
# no network call can happen. The settings UI flips this via main_scene; the
# backend flag itself lives here so the guarantee is enforced at the routing
# boundary, not just in the UI. Defaults to allowed (mock provider is harmless).
var ai_allowed: bool = true
const SCRIPTED_FALLBACK_TEXT := "Let's stay with the scripted choices for now."
const AI_FALLBACK_TEXT := "Mm. I can't reach the AI right now, so let's keep things simple and continue with the buttons."
const AI_DISABLED_TEXT := "Type Mode is off right now, so let's keep to the buttons. You can turn it back on in settings."

func set_ai_service(service: Node) -> void:
	ai_service = service

# Privacy hook the settings UI controls (via main_scene). When off, route_*
# short-circuits to a scripted reply with no provider call.
func set_ai_allowed(value: bool) -> void:
	ai_allowed = value

func is_ai_allowed() -> bool:
	return ai_allowed

# Prompt assembly (docs/AI_Context_Packet_Spec.md): persona_text is Layer 1+2
# (personality + world); context_packet is the Layer 3 per-call block (mode tone,
# presence/time/nickname/focus/return/openness/writing gates + surfaced_memory).
# The service builds messages in order: persona, context_packet, runtime_rules, user.
func route_player_text_async(player_text: String, ai_mode_enabled: bool, persona_text: String, context_packet: String, runtime_rules: String, mode_id: String) -> Dictionary:
	# Hard privacy gate: if AI is disabled, return a scripted reply and DO NOT
	# reach the AI service. This is the "no network calls when off" guarantee.
	if not ai_allowed:
		return {
			"mode": "scripted",
			"success": true,
			"fallback_used": false,
			"provider": "disabled",
			"text": AI_DISABLED_TEXT
		}

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
			"persona": persona_text,
			"context_packet": context_packet,
			"runtime_rules": runtime_rules,
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
