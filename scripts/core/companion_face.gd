extends Node
# Gives Yua's still portrait a face that moves: she blinks on her own, and can
# hold an expression for a moment (a smile when clicked, for now).
#
# How it works: the Portrait TextureRect stays as-is. Two overlay TextureRects
# are added on top of it with the same rect and stretch, each holding a
# variant of the SAME drawing with only the face changed — the variants were
# checked to line up with the base to ~0.003 mean difference, so fading one in
# over the base changes only the face. Nothing is ever moved or scaled, so this
# cannot produce the layer shimmer that motion on the room did.
#
#   set_stance(stance)          which base drawing is up ("at_player"/"at_work")
#   show_expression(name, secs) fade an expression in, hold, fade out
#   blink_now()                 one blink, e.g. tied to a line starting
#
# Variants are looked up as assets/art/character/yua_<name>.png and simply
# skipped if the file does not exist, so adding an expression is a file drop.

const CHAR_DIR := "res://assets/art/character/"

var _portrait: TextureRect = null
var _blink_layer: TextureRect = null
var _expr_layer: TextureRect = null
var _stance := "at_player"
var _blink_timer: Timer = null
var _rng := RandomNumberGenerator.new()
var _expr_tween: Tween = null
var _blinking := false

func setup(portrait: TextureRect) -> void:
	_portrait = portrait
	_rng.randomize()
	_blink_layer = _make_overlay("BlinkLayer")
	_expr_layer = _make_overlay("ExpressionLayer")
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_on_blink_timer)
	add_child(_blink_timer)
	set_stance(_stance)
	_schedule_blink()

func set_stance(stance: String) -> void:
	_stance = stance
	# Blink art exists per stance; without it she simply doesn't blink in that
	# stance rather than blinking with the wrong face.
	_blink_layer.texture = _variant_for("blink")
	_blink_layer.modulate.a = 0.0
	_expr_layer.modulate.a = 0.0

func blink_now() -> void:
	if _blinking or _blink_layer.texture == null:
		return
	_blinking = true
	var tw := create_tween()
	tw.tween_property(_blink_layer, "modulate:a", 1.0, 0.06)
	tw.tween_interval(0.09)
	tw.tween_property(_blink_layer, "modulate:a", 0.0, 0.11)
	tw.tween_callback(func(): _blinking = false)

func show_expression(expr_name: String, hold_seconds: float = 2.5) -> void:
	var tex := _variant_for(expr_name)
	if tex == null:
		return
	if _expr_tween != null and _expr_tween.is_valid():
		_expr_tween.kill()
	_expr_layer.texture = tex
	_expr_tween = create_tween()
	_expr_tween.tween_property(_expr_layer, "modulate:a", 1.0, 0.25)
	_expr_tween.tween_interval(hold_seconds)
	_expr_tween.tween_property(_expr_layer, "modulate:a", 0.0, 0.45)

# ── internals ────────────────────────────────────────────────────────────────
func _make_overlay(overlay_name: String) -> TextureRect:
	var t := TextureRect.new()
	t.name = overlay_name
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Same placement rules as the portrait, so the overlay lands exactly on it
	# however the stage is resized.
	t.anchor_left = _portrait.anchor_left
	t.anchor_top = _portrait.anchor_top
	t.anchor_right = _portrait.anchor_right
	t.anchor_bottom = _portrait.anchor_bottom
	t.offset_left = _portrait.offset_left
	t.offset_top = _portrait.offset_top
	t.offset_right = _portrait.offset_right
	t.offset_bottom = _portrait.offset_bottom
	t.grow_horizontal = _portrait.grow_horizontal
	t.grow_vertical = _portrait.grow_vertical
	t.expand_mode = _portrait.expand_mode
	t.stretch_mode = _portrait.stretch_mode
	t.modulate.a = 0.0
	_portrait.get_parent().add_child(t)
	_portrait.get_parent().move_child(t, _portrait.get_index() + 1)
	return t

func _variant_for(expr_name: String) -> Texture2D:
	# Stance-specific variant first (yua_at_work_blink), then the plain one,
	# which is drawn on the at_player base and only valid there.
	var candidates: Array = []
	if _stance == "at_player":
		candidates.append(CHAR_DIR + "yua_%s.png" % expr_name)
	else:
		candidates.append(CHAR_DIR + "yua_%s_%s.png" % [_stance, expr_name])
	for p in candidates:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _schedule_blink() -> void:
	# Humans blink every 3–6 s at rest, sometimes twice in a row.
	_blink_timer.start(_rng.randf_range(3.2, 6.4))

func _on_blink_timer() -> void:
	blink_now()
	if _rng.randf() < 0.18:
		var tw := create_tween()
		tw.tween_interval(0.35)
		tw.tween_callback(blink_now)
	_schedule_blink()
