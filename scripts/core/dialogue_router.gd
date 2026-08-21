extends Node

var ai_service: Node = null
# Privacy / on-off hook. When false, the router NEVER touches the AI service, so
# no network call can happen. The settings UI flips this via main_scene; the
# backend flag itself lives here so the guarantee is enforced at the routing
# boundary, not just in the UI. Defaults to allowed (mock provider is harmless).
var ai_allowed: bool = true
# All three are IN-FICTION lines in Yua's voice — she never names UI (buttons /
# settings / Type Mode) and never says she is an AI. Rationale in
# docs/Yua_Taste_Log.md (汇报/UI-speak vetoes) and Type_Mode_Design.md §0.
const SCRIPTED_FALLBACK_TEXT := "嗯，我在。你先忙，我这边也接着写。"
# Provider call failed: treat it as the call connection hiccuping.
const AI_FALLBACK_TEXT := "唔……刚才这边卡了一下，没听清。\n\n再说一遍？"
# AI switched off in settings: she is simply absorbed in her own work.
const AI_DISABLED_TEXT := "……嗯？抱歉，我这段写得正入神。\n\n你先忙你的，我一会儿抬头。"

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

		# A failed call NEVER speaks the provider's own words. The service returns
		# English operator text on every failure path, and it used to reach the
		# dialogue box because this compared against a string that exists nowhere
		# in the codebase. Yua always covers a failure in her own voice; the raw
		# provider text is kept under "error_text" for diagnostics only.
		if not bool(reply.get("success", false)):
			return {
				"mode": "ai_fallback",
				"text": AI_FALLBACK_TEXT,
				"success": false,
				"fallback_used": true,
				"provider": str(reply.get("provider", "none")),
				"error": str(reply.get("error", "provider_failed")),
				"error_text": str(reply.get("text", ""))
			}

		# A "successful" empty reply is still a failure — say something in-voice
		# rather than typing out a blank line.
		var reply_text: String = str(reply.get("text", "")).strip_edges()
		if reply_text.is_empty():
			return {
				"mode": "ai_fallback",
				"text": AI_FALLBACK_TEXT,
				"success": false,
				"fallback_used": true,
				"provider": str(reply.get("provider", "unknown")),
				"error": "response_empty"
			}

		return {
			"mode": "ai",
			"text": reply_text,
			"success": true,
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
