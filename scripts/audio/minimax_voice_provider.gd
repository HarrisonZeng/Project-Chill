extends Node
## Desktop-only prototype adapter. Reads a process credential, never a scene key.
## Packaged/web demos use generated clips and do not contact MiniMax.
signal completed(request_id: int, audio: PackedByteArray, error: String)

const ENDPOINT := "https://api.minimaxi.com/v1/t2a_v2"
var _http: HTTPRequest
var _request_id: int = 0

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	_http.body_size_limit = 8 * 1024 * 1024
	add_child(_http)
	_http.request_completed.connect(_on_completed)

func synthesize(request_id: int, text: String, settings: Dictionary) -> bool:
	cancel()
	_request_id = request_id
	if OS.has_feature("web"):
		completed.emit(request_id, PackedByteArray(), "runtime_voice_desktop_only")
		return false
	var key := OS.get_environment("MINIMAX_API_KEY").strip_edges()
	if key.is_empty():
		completed.emit(request_id, PackedByteArray(), "minimax_key_missing")
		return false
	if text.is_empty() or text.length() > 600:
		completed.emit(request_id, PackedByteArray(), "voice_text_length")
		return false
	var voice: Dictionary = settings.get("voice_setting", {}).duplicate(true)
	var payload := {
		"model": settings.get("model", "speech-2.8-hd"),
		"text": text, "stream": false, "output_format": "hex",
		"language_boost": settings.get("language", "auto"),
		"voice_setting": voice,
		"audio_setting": {"sample_rate": 32000, "bitrate": 128000, "format": "mp3", "channel": 1}
	}
	var headers := PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + key])
	var error := _http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		completed.emit(request_id, PackedByteArray(), "voice_request_start_failed")
		return false
	return true

func cancel() -> void:
	if _http != null:
		_http.cancel_request()

func _on_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		completed.emit(_request_id, PackedByteArray(), "voice_network_%d_%d" % [result, response_code])
		return
	var decoded: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not decoded is Dictionary:
		completed.emit(_request_id, PackedByteArray(), "voice_invalid_json")
		return
	var status: Variant = decoded.get("base_resp", {})
	if not status is Dictionary or int(status.get("status_code", -1)) != 0:
		# Do not log raw provider bodies or credentials.
		completed.emit(_request_id, PackedByteArray(), "voice_provider_rejected")
		return
	var data: Variant = decoded.get("data")
	if not data is Dictionary:
		completed.emit(_request_id, PackedByteArray(), "voice_missing_audio")
		return
	var hex := str(data.get("audio", ""))
	if hex.is_empty() or hex.length() % 2 != 0 or not hex.is_valid_hex_number(false):
		completed.emit(_request_id, PackedByteArray(), "voice_invalid_audio")
		return
	completed.emit(_request_id, hex.hex_decode(), "")
