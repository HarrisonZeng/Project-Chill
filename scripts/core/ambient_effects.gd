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

# What she can see out of her window. Each view names its picture and how the
# room should respond to it — rain on the glass, a colour cast, how much the
# dust catches the light. `alt` is the older filename, so a view still resolves
# if the newer painted set has not been generated yet.
# Per view: the painting outside, the rain/overcast on the glass, a whole-frame
# tint, dust density, which ROOM lighting to use ("day" art or the lamp-lit
# "night" repaint), and a modulate for Yua so she is lit like the room she is
# in rather than in flat daylight against a night window.
static func view_defs() -> Array:
	return [
		{"key": "rain", "tex": "view_city_rain.png", "alt": "outside_rain.png",
			"rain": 0.8, "overcast": 0.62, "tint": Color(0.44, 0.50, 0.66, 0.10), "dust": 0.30,
			"room": "day", "yua": Color(0.93, 0.95, 1.0)},
		{"key": "clear", "tex": "view_city_day.png", "alt": "outside_day.png",
			"rain": 0.0, "overcast": 0.0, "tint": Color(0, 0, 0, 0), "dust": 0.55,
			"room": "day", "yua": Color.WHITE},
		{"key": "sunset", "tex": "view_city_sunset.png", "alt": "",
			"rain": 0.0, "overcast": 0.0, "tint": Color(0.85, 0.55, 0.30, 0.12), "dust": 0.70,
			"room": "day", "yua": Color(1.0, 0.94, 0.86)},
		{"key": "night", "tex": "view_city_night.png", "alt": "outside_night.png",
			"rain": 0.0, "overcast": 0.0, "tint": Color(0.20, 0.26, 0.48, 0.10), "dust": 0.22,
			"room": "night", "yua": Color(0.80, 0.84, 0.98)},
		{"key": "seaside", "tex": "view_seaside.png", "alt": "",
			"rain": 0.0, "overcast": 0.0, "tint": Color(0.55, 0.72, 0.80, 0.07), "dust": 0.50,
			"room": "day", "yua": Color.WHITE},
		{"key": "treetops", "tex": "view_treetops.png", "alt": "",
			"rain": 0.0, "overcast": 0.0, "tint": Color(0.40, 0.60, 0.35, 0.10), "dust": 0.45,
			"room": "day", "yua": Color(0.96, 1.0, 0.94)},
	]

# Room art per lighting state. The night files are Codex EDITS of the day
# master (glass mask identical, desk mask within 1%), so swapping them moves
# nothing — only the light changes.
const ROOM_TEX_BY_LIGHT := {
	"day": ["res://assets/art/backgrounds/room_layer.png", "res://assets/art/backgrounds/desk_front.png"],
	"night": ["res://assets/art/backgrounds/room_layer_night.png", "res://assets/art/backgrounds/desk_front_night.png"],
}
var _room_light := ""
# Everything that should be lit like the room: the companion stage and the
# hands overlay above the desk. Registered by main_scene once they exist.
var _lit_like_room: Array = []

## Path for a view, preferring the newer painting and falling back to the older
## one. Empty when neither exists, which is how callers know to skip the view.
static func view_texture_path(key: String) -> String:
	for d in view_defs():
		if d["key"] != key:
			continue
		var newer: String = "res://assets/art/backgrounds/" + str(d["tex"])
		if ResourceLoader.exists(newer):
			return newer
		var older: String = str(d["alt"])
		if not older.is_empty():
			older = "res://assets/art/backgrounds/" + older
			if ResourceLoader.exists(older):
				return older
		return ""
	return ""

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
	_build_rain_audio()
	_place_layers()
	set_weather(weather)

func set_weather(kind: String) -> void:
	for d in view_defs():
		if d["key"] != kind:
			continue
		var path := view_texture_path(kind)
		if not path.is_empty() and _background is TextureRect:
			(_background as TextureRect).texture = load(path)
		var mat := _background.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("intensity", d["rain"])
			mat.set_shader_parameter("overcast", d["overcast"])
		if _tint != null:
			_tint.color = d["tint"]
		if _dust != null:
			_dust.modulate.a = d["dust"]
		_set_room_light(str(d["room"]))
		for n in _lit_like_room:
			if is_instance_valid(n) and n is CanvasItem:
				(n as CanvasItem).modulate = d["yua"]
		_set_rain_audio(float(d["rain"]))
		return
	push_warning("ambient_effects: unknown view '%s'" % kind)

func register_lit_like_room(node: CanvasItem) -> void:
	if node != null and not _lit_like_room.has(node):
		_lit_like_room.append(node)

func _set_room_light(light: String) -> void:
	if light == _room_light:
		return
	if not ROOM_TEX_BY_LIGHT.has(light):
		return
	var paths: Array = ROOM_TEX_BY_LIGHT[light]
	# Only switch if both files exist; otherwise stay on whatever is showing.
	if not (ResourceLoader.exists(paths[0]) and ResourceLoader.exists(paths[1])):
		return
	if is_instance_valid(_room):
		_room.texture = load(paths[0])
	if is_instance_valid(_front):
		_front.texture = load(paths[1])
	_room_light = light

# ── rain audio ───────────────────────────────────────────────────────────────
# Follows the same per-view "rain" amount that drives the drops on the glass, so
# the sound and the picture can never disagree. Fades rather than cuts, and
# stops the player entirely once silent so it costs nothing on dry days.
const RAIN_LOOP := "res://assets/audio/rain_loop.wav"
const RAIN_DB_AT_FULL := -16.0   # sits under the music, never over it
var _rain_player: AudioStreamPlayer = null
var _rain_tween: Tween = null
# Ambient sound waits for the player's first click. Browsers refuse to play
# audio before a user gesture, so on the web this is the only way it can start
# cleanly; on desktop it means the room fades in with the first touch rather
# than blaring on boot. It also keeps an untouched boot silent, which the check
# harness relies on.
var _audio_unlocked := false
var _rain_wanted := 0.0

func _input(event: InputEvent) -> void:
	if _audio_unlocked:
		return
	var is_click: bool = event is InputEventMouseButton and event.pressed
	var is_key: bool = event is InputEventKey and event.pressed
	if is_click or is_key:
		_audio_unlocked = true
		set_process_input(false)
		_set_rain_audio(_rain_wanted)

func _build_rain_audio() -> void:
	if not ResourceLoader.exists(RAIN_LOOP):
		return
	_rain_player = AudioStreamPlayer.new()
	_rain_player.name = "RainAmbience"
	_rain_player.stream = load(RAIN_LOOP)
	_rain_player.volume_db = -80.0
	_rain_player.bus = "Master"
	add_child(_rain_player)

# ── focus chime ──────────────────────────────────────────────────────────────
const FOCUS_CHIME := "res://assets/audio/focus_chime.wav"
var _chime_player: AudioStreamPlayer = null

var _chime_stream: AudioStream = null

func play_focus_chime() -> void:
	if _chime_player == null:
		if not ResourceLoader.exists(FOCUS_CHIME):
			return
		_chime_stream = load(FOCUS_CHIME)
		_chime_player = AudioStreamPlayer.new()
		_chime_player.name = "FocusChime"
		_chime_player.volume_db = -6.0
		_chime_player.finished.connect(_on_chime_finished)
		add_child(_chime_player)
	# Attach the stream per play and detach when done: a finished one-shot
	# otherwise keeps its playback registered until the player is freed, which
	# shows up as a leaked AudioStreamPlayback at exit.
	_chime_player.stream = _chime_stream
	_chime_player.play()

func _on_chime_finished() -> void:
	if is_instance_valid(_chime_player):
		_chime_player.stream = null

# A player still playing when the tree is torn down keeps its playback alive in
# the audio server past exit, which the headless harness reports as a leak.
# Stop everything on the way out.
func _exit_tree() -> void:
	if _rain_tween != null and _rain_tween.is_valid():
		_rain_tween.kill()
	for p in [_rain_player, _chime_player]:
		if is_instance_valid(p):
			p.stop()
			p.stream = null

func _set_rain_audio(amount: float) -> void:
	_rain_wanted = amount
	if _rain_player == null or not _audio_unlocked:
		return
	if _rain_tween != null and _rain_tween.is_valid():
		_rain_tween.kill()
	if amount <= 0.01:
		_rain_tween = create_tween()
		_rain_tween.tween_property(_rain_player, "volume_db", -80.0, 1.2)
		_rain_tween.tween_callback(_rain_player.stop)
		return
	if not _rain_player.playing:
		_rain_player.volume_db = -80.0
		_rain_player.play()
	var target := RAIN_DB_AT_FULL + linear_to_db(clampf(amount, 0.05, 1.0))
	_rain_tween = create_tween()
	_rain_tween.tween_property(_rain_player, "volume_db", target, 1.5)

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
	# The room and desk sit exactly where the painting does; only the outside
	# layer is offset, and only vertically. Scale is held at 1 because these two
	# layers share pixels and any resampling of them shimmers.
	for layer in [_room, _front]:
		if not is_instance_valid(layer):
			continue
		if layer.position != _room_home:
			layer.position = _room_home
		if layer.size != bg.size:
			layer.size = bg.size
		if layer.scale != Vector2.ONE:
			layer.scale = Vector2.ONE
		if layer.pivot_offset != bg.size / 2.0:
			layer.pivot_offset = bg.size / 2.0
	if bg.pivot_offset != bg.size / 2.0:
		bg.pivot_offset = bg.size / 2.0

# Layers are placed once and then left alone.
#
# There used to be a slow "breathing" zoom here, with the view drifting further
# than the room as a depth cue. It had to go: the room and desk layers are cut
# from the same painting, so they carry identical pixels in the places they
# overlap. Scaling them — even by the 0.4% that drift used — resampled that
# shared content slightly differently every frame, and the whole picture
# shimmered along every edge. Any future motion has to move the outside layer
# ONLY, never the two that share pixels.
func _place_layers() -> void:
	for c in [_background, _room, _front]:
		if c is Control:
			var ctl := c as Control
			ctl.pivot_offset = ctl.size / 2.0
			ctl.scale = Vector2.ONE
	if _background is Control:
		_room_home = (_background as Control).position
		_bg_home = _room_home - Vector2(0.0, OUTSIDE_LIFT_PX)
		(_background as Control).position = _bg_home
