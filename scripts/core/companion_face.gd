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

# Her forearms and hands, drawn ABOVE the desk. The desk layer sits in front of
# her (so it hides her lap); this puts her hands back on top of the keyboard.
# It is a cut of the same character image (measured 0.0000 against it), so it
# lands on the portrait exactly — the only thing that differs is where it sits
# in the tree, which has to be after DeskFront rather than inside CompanionView.
var _hands_layer: TextureRect = null

# Motion on top of the frames. Everything here is a texture swap or a fade —
# nothing is ever moved or scaled (see the shimmer note above).
#   set_working(on)   while true, her hands alternate between the two typing
#                     frames in short irregular bursts, like real typing
#   show_pose(name,s) swap the BASE drawing (and its hands cut) for a pose such
#                     as "drink" or "chin" and swap back after s seconds. Poses
#                     move an arm, so they cannot be additive overlays — the old
#                     hand would still show through underneath.
#   idle life         every 20–45 s at rest she does one small thing: glances
#                     at her screen, out of the window, or sips her tea.
var _working := false
var _type_timer: Timer = null
var _type_frame_b := false
var _typing_base_backup: Texture2D = null
var _idle_timer: Timer = null
var _pose_active := false
var _pose_tween: Tween = null

func setup(portrait: TextureRect, above_desk_parent: Node = null, above_desk_index: int = -1) -> void:
	_portrait = portrait
	_rng.randomize()
	_blink_layer = _make_overlay("BlinkLayer")
	_expr_layer = _make_overlay("ExpressionLayer")
	if above_desk_parent != null:
		_hands_layer = TextureRect.new()
		_hands_layer.name = "HandsLayer"
		_hands_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hands_layer.expand_mode = _portrait.expand_mode
		_hands_layer.stretch_mode = _portrait.stretch_mode
		above_desk_parent.add_child(_hands_layer)
		if above_desk_index >= 0:
			above_desk_parent.move_child(_hands_layer, mini(above_desk_index, above_desk_parent.get_child_count() - 1))
		# Match the portrait's on-screen rect now and whenever layout changes.
		_portrait.item_rect_changed.connect(_sync_hands_rect)
		_sync_hands_rect.call_deferred()
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_on_blink_timer)
	add_child(_blink_timer)
	_type_timer = Timer.new()
	_type_timer.one_shot = true
	_type_timer.timeout.connect(_on_type_timer)
	add_child(_type_timer)
	_idle_timer = Timer.new()
	_idle_timer.one_shot = true
	_idle_timer.timeout.connect(_on_idle_timer)
	add_child(_idle_timer)
	set_stance(_stance)
	_schedule_blink()
	_schedule_idle()

func set_stance(stance: String) -> void:
	_stance = stance
	# Blink art exists per stance; without it she simply doesn't blink in that
	# stance rather than blinking with the wrong face.
	_blink_layer.texture = _variant_for("blink")
	_blink_layer.modulate.a = 0.0
	_expr_layer.modulate.a = 0.0
	if _hands_layer != null:
		_hands_layer.texture = _variant_for("hands")

func hands_layer() -> CanvasItem:
	return _hands_layer

func _sync_hands_rect() -> void:
	if _hands_layer == null or not is_instance_valid(_portrait):
		return
	var r := _portrait.get_global_rect()
	_hands_layer.global_position = r.position
	_hands_layer.size = r.size

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

# ── motion ───────────────────────────────────────────────────────────────────
func set_working(on: bool) -> void:
	if on == _working:
		return
	_working = on
	if on:
		_type_timer.start(_rng.randf_range(0.2, 0.6))
	else:
		_type_timer.stop()
		if _type_frame_b and _typing_base_backup != null and not _pose_active:
			_portrait.texture = _typing_base_backup
		_type_frame_b = false
		if _hands_layer != null and not _pose_active:
			_hands_layer.texture = _variant_for("hands")

func _on_type_timer() -> void:
	if not _working or _pose_active or _hands_layer == null:
		return
	var alt_base := _variant_for("typing_b")
	var alt_hands := _variant_for("hands_b")
	if alt_base == null or alt_hands == null:
		return  # no second typing frame; hands simply stay still
	_type_frame_b = not _type_frame_b
	# Base and hands overlay swap TOGETHER. The overlay alone over an unchanged
	# base showed both finger positions at once — that was the "glitchy" look.
	if _type_frame_b:
		_typing_base_backup = _portrait.texture
		_portrait.texture = alt_base
		_hands_layer.texture = alt_hands
	else:
		if _typing_base_backup != null:
			_portrait.texture = _typing_base_backup
		_hands_layer.texture = _variant_for("hands")
	# Typing rhythm: a few alternations in a burst, then a pause to read.
	var burst := _rng.randf() < 0.72
	_type_timer.start(_rng.randf_range(0.16, 0.26) if burst else _rng.randf_range(1.0, 2.4))

# Settings "试一下" button: show any frame by name for a few seconds so the
# owner can flip through the set without triggering it in play.
func preview(frame_name: String, secs: float = 5.0) -> void:
	match frame_name:
		"blink":
			blink_now()
		"typing":
			set_working(true)
			var tw := create_tween()
			tw.tween_interval(secs)
			tw.tween_callback(func(): set_working(false))
		"drink", "chin":
			show_pose(frame_name, secs)
		_:
			show_expression(frame_name, secs)

func show_pose(pose_name: String, hold_seconds: float = 4.0) -> void:
	var tex := _variant_for(pose_name)
	if tex == null or _pose_active:
		return
	_pose_active = true
	var base_tex := _portrait.texture
	var base_hands: Texture2D = _hands_layer.texture if _hands_layer != null else null
	_portrait.texture = tex
	if _hands_layer != null:
		_hands_layer.texture = _variant_for(pose_name + "_hands")
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = create_tween()
	_pose_tween.tween_interval(hold_seconds)
	_pose_tween.tween_callback(func():
		_portrait.texture = base_tex
		if _hands_layer != null:
			_hands_layer.texture = base_hands
		_pose_active = false)

func _schedule_idle() -> void:
	_idle_timer.start(_rng.randf_range(20.0, 45.0))

func _on_idle_timer() -> void:
	_schedule_idle()
	if _pose_active:
		return
	# Small idle actions. Each is skipped harmlessly if its art is missing.
	var r := _rng.randf()
	if _working:
		# At work she mostly just glances up at the window now and then.
		if r < 0.6:
			show_expression("window", 3.0)
		return
	if r < 0.35:
		show_expression("at_work", 4.0)   # eyes drop to the screen for a moment
	elif r < 0.65:
		show_expression("window", 3.5)
	elif r < 0.85:
		show_pose("drink", 4.5)
	else:
		show_pose("chin", 6.0)

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
