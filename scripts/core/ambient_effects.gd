extends Node
# Ambient scene layer. Splits the single painted background into depth layers so
# the room reads as a place rather than a photo with effects stamped on it:
#
#   Background    the outside view; the rain shader lives here
#   RoomLayer     the room, transparent where the glass is  <- weather shows
#                 through the window's real shape, so no rectangle
#   CompanionStage  Yua (existing node)
#   DeskFront     monitor, keyboard, plush, plant, chair    <- she sits behind
#   WeatherTint   whole-frame grade
#   DustMotes     in the air, nearest the camera
#
# The room and desk layers are cut from the same painting by
# tools/art/bg_tool.gd, so their seams are invisible. Everything here is
# decorative: no game state is touched, all layers ignore the mouse, and
# deleting the AmbientEffects node restores the flat look.

const RAIN_SHADER := preload("res://assets/shaders/window_rain.gdshader")
const ROOM_TEX := "res://assets/art/backgrounds/room_layer.png"
const FRONT_TEX := "res://assets/art/backgrounds/desk_front.png"
# The view through the window, as its own full-frame picture. Generated as a
# stand-in by tools/art/bg_tool.gd --mode=outside; replace this file with a
# properly drawn view (or a night / rainy variant) and it is picked up with no
# code change. If it is missing, the original painting is used instead.
const OUTSIDE_TEX := "res://assets/art/backgrounds/outside_day.png"
# Real painted views of the world outside, one per condition. These are
# free-standing backdrops seen through the window, so unlike the room layers
# they do not have to line up with the original painting — any good picture
# works. Weather now changes what is actually out there, not just the tint.
const OUTSIDE_BY_WEATHER := {
	"rain": "res://assets/art/backgrounds/outside_rain.png",
	"clear": "res://assets/art/backgrounds/outside_day.png",
	"night": "res://assets/art/backgrounds/outside_night.png",
}

var _room: TextureRect = null
var _front: TextureRect = null
var _tint: ColorRect = null
var _dust: CPUParticles2D = null
var _background: CanvasItem = null
var _room_home := Vector2.ZERO  # where the room and desk layers stay pinned
var _bg_home := Vector2.ZERO    # outside layer's resting position; drift is relative to it

# The window only reveals the upper part of the frame, but a painted view puts
# its horizon near the middle — so unshifted, the player sees nothing but sky.
# Lifting the outside layer brings the skyline and treetops into the glass.
# Measured against the window band: the panes end around y=505 of 1024.
const OUTSIDE_LIFT_PX := 308.0

func setup(background: CanvasItem, companion_stage: CanvasItem, weather: String = "rain") -> void:
	_background = background
	var root := background.get_parent()
	if root == null:
		return
	_use_outside_picture()
	_apply_rain_shader()
	_room = _add_layer(root, "RoomLayer", ROOM_TEX, background.get_index() + 1)
	# Desk goes directly in front of Yua so she is occluded by it.
	var stage_idx: int = companion_stage.get_index() if companion_stage != null else background.get_index() + 2
	_front = _add_layer(root, "DeskFront", FRONT_TEX, stage_idx + 1)
	_build_tint(root)
	_build_dust(root)
	_start_breathing()
	set_weather(weather)

func set_weather(kind: String) -> void:
	_use_outside_picture(kind)
	var mat := _background.material as ShaderMaterial
	match kind:
		"rain":
			if mat != null:
				mat.set_shader_parameter("intensity", 0.8)
				mat.set_shader_parameter("overcast", 0.62)
			if _tint != null:
				_tint.color = Color(0.44, 0.50, 0.66, 0.10)
			if _dust != null:
				_dust.modulate.a = 0.3
		_:  # "clear"
			if mat != null:
				mat.set_shader_parameter("intensity", 0.0)
				mat.set_shader_parameter("overcast", 0.0)
			if _tint != null:
				_tint.color = Color(0, 0, 0, 0)
			if _dust != null:
				_dust.modulate.a = 0.55

# Swap the Background node's texture for the dedicated outside picture. Done at
# runtime rather than in the .tscn so the scene still previews the original
# painting in the editor.
func _use_outside_picture(weather: String = "") -> void:
	if not (_background is TextureRect):
		return
	# Prefer a painted view for this weather; fall back to the generic outside
	# layer, and finally leave the original painting in place.
	var path: String = OUTSIDE_BY_WEATHER.get(weather, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		path = OUTSIDE_TEX
	if not ResourceLoader.exists(path):
		push_warning("ambient_effects: no outside picture — run bg_tool.gd --mode=outside")
		return
	(_background as TextureRect).texture = load(path)

func _apply_rain_shader() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = RAIN_SHADER
	_background.material = mat

func _add_layer(root: Node, node_name: String, tex_path: String, at_index: int) -> TextureRect:
	if not ResourceLoader.exists(tex_path):
		push_warning("ambient_effects: missing %s — run tools/art/bg_tool.gd --mode=slice" % tex_path)
		return null
	var tr := TextureRect.new()
	tr.name = node_name
	tr.texture = load(tex_path)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# These layers are the same painting as the Background, so they must occupy
	# the EXACT same rect or the shared pixels show up twice, slightly offset.
	# Anchors alone don't guarantee that (the texture's own minimum size can push
	# the height past the viewport), so the rect is copied every frame instead.
	if _background is TextureRect:
		tr.expand_mode = (_background as TextureRect).expand_mode
		tr.stretch_mode = (_background as TextureRect).stretch_mode
	root.add_child(tr)
	root.move_child(tr, clampi(at_index, 0, root.get_child_count() - 1))
	return tr

func _build_tint(root: Node) -> void:
	_tint = ColorRect.new()
	_tint.name = "WeatherTint"
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_tint)
	var anchor: Node = _front if _front != null else _room
	if anchor != null:
		root.move_child(_tint, clampi(anchor.get_index() + 1, 0, root.get_child_count() - 1))

func _build_dust(root: Node) -> void:
	_dust = CPUParticles2D.new()
	_dust.name = "DustMotes"
	_dust.position = Vector2(700, 330)
	_dust.amount = 18
	_dust.lifetime = 11.0
	_dust.preprocess = 11.0  # already drifting on the first visible frame
	_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust.emission_rect_extents = Vector2(420, 250)
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
	root.add_child(_dust)
	if _tint != null:
		root.move_child(_dust, clampi(_tint.get_index() + 1, 0, root.get_child_count() - 1))

func _process(_delta: float) -> void:
	_sync_layers()

# Keep the cut layers exactly on top of the Background's rect.
func _sync_layers() -> void:
	if not (is_instance_valid(_background) and _background is Control):
		return
	var bg := _background as Control
	# Pinned to the outside layer's RESTING position, not its live one — the
	# outside drifts for parallax and the room must stay put, or the whole frame
	# slides together and the depth effect disappears.
	for layer in [_room, _front]:
		if not is_instance_valid(layer):
			continue
		if layer.position != _room_home:
			layer.position = _room_home
		if layer.size != bg.size:
			layer.size = bg.size
		layer.pivot_offset = bg.size / 2.0
	bg.pivot_offset = bg.size / 2.0

func _start_breathing() -> void:
	# Depth cue: the view through the window drifts more than the room does, the
	# way a distant view shifts against a fixed frame. The room and desk layers
	# are driven from the SAME value — they share pixels, so any mismatch would
	# show the desk twice, slightly offset.
	for c in [_background, _room, _front]:
		if c is Control:
			var ctl := c as Control
			ctl.pivot_offset = ctl.size / 2.0
	if _background is Control:
		_room_home = (_background as Control).position
		_bg_home = _room_home - Vector2(0.0, OUTSIDE_LIFT_PX)
		(_background as Control).position = _bg_home
	var tw := create_tween().set_loops()
	tw.tween_method(_set_breath, 0.0, 1.0, 16.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_set_breath, 1.0, 0.0, 16.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _set_breath(k: float) -> void:
	# The outside is now its own picture that extends past the window, so it can
	# drift properly against the fixed frame instead of only breathing in place.
	if is_instance_valid(_background) and _background is Control:
		var bg := _background as Control
		bg.scale = Vector2.ONE * (1.0 + 0.022 * k)
		bg.position = _bg_home + Vector2(-10.0 * k, -4.0 * k)
	var room_scale := Vector2.ONE * (1.0 + 0.004 * k)
	if is_instance_valid(_room):
		_room.scale = room_scale
	if is_instance_valid(_front):
		_front.scale = room_scale
