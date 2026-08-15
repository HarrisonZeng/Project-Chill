extends Node
# Ambient scene layer: weather in the window, a room-wide grade, dust motes in
# the light, and a slow breathing zoom on the background — so the single
# painted background reads as a live place instead of a still image.
#
# Everything here is decorative: every node ignores the mouse, nothing touches
# game state, and removing the AmbientEffects node restores the old look.

# Window glass area of Background_temp.png mapped to the 1600x900 design
# resolution. Children are parented to the background so the breathing zoom
# moves them together with the painting.
const WINDOW_RECT := Rect2(300, 0, 694, 410)

const RAIN_SHADER := preload("res://assets/shaders/window_rain.gdshader")

var _rain: ColorRect = null
var _tint: ColorRect = null
var _dust: CPUParticles2D = null
var _background: CanvasItem = null

func setup(background: CanvasItem, weather: String = "rain") -> void:
	_background = background
	_build_rain()
	_build_tint()
	_build_dust()
	_start_breathing()
	set_weather(weather)

func set_weather(kind: String) -> void:
	match kind:
		"rain":
			_rain.visible = true
			(_rain.material as ShaderMaterial).set_shader_parameter("intensity", 0.7)
			_tint.color = Color(0.45, 0.52, 0.68, 0.07)
			_dust.modulate.a = 0.35
		_:  # "clear"
			_rain.visible = false
			_tint.color = Color(0, 0, 0, 0)
			_dust.modulate.a = 0.6

func _build_rain() -> void:
	_rain = ColorRect.new()
	_rain.name = "WindowRain"
	_rain.position = WINDOW_RECT.position
	_rain.size = WINDOW_RECT.size
	_rain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = RAIN_SHADER
	_rain.material = mat
	_background.add_child(_rain)

func _build_dust() -> void:
	# Slow motes drifting in the window light. CPUParticles so the web build's
	# compatibility renderer handles it identically to desktop.
	_dust = CPUParticles2D.new()
	_dust.name = "DustMotes"
	_dust.position = Vector2(640, 300)
	_dust.amount = 16
	_dust.lifetime = 10.0
	_dust.preprocess = 10.0  # already drifting on the first visible frame
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(340, 240)
	_dust.direction = Vector2(0, 1)
	_dust.spread = 180.0
	_dust.gravity = Vector2(0, 1.5)
	_dust.initial_velocity_min = 2.0
	_dust.initial_velocity_max = 7.0
	_dust.scale_amount_min = 0.5
	_dust.scale_amount_max = 1.4
	var tex := GradientTexture2D.new()
	tex.width = 8
	tex.height = 8
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	tex.gradient = grad
	_dust.texture = tex
	_background.add_child(_dust)

func _build_tint() -> void:
	# Whole-room grade, above the background painting but below Yua and the UI
	# (background children draw before the next sibling). Weather sets its color.
	_tint = ColorRect.new()
	_tint.name = "WeatherTint"
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.anchors_preset = Control.PRESET_FULL_RECT
	_tint.anchor_right = 1.0
	_tint.anchor_bottom = 1.0
	_background.add_child(_tint)

func _start_breathing() -> void:
	# A ~1% zoom in and out over half a minute. Below conscious notice, but the
	# stillness of a static screenshot is gone.
	if not _background is Control:
		return
	var bg := _background as Control
	bg.pivot_offset = bg.size / 2.0
	var tw := create_tween().set_loops()
	tw.tween_property(bg, "scale", Vector2(1.012, 1.012), 16.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(bg, "scale", Vector2.ONE, 16.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
