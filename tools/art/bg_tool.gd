extends SceneTree
# Background layer slicer. Cuts the single painted background into the layers
# the scene needs so weather can live *behind* the room instead of on top of it:
#
#   outside layer  the view through the glass (rain/weather applies here only)
#   room layer     everything else, glass area transparent, drawn over the top
#
# Nothing here runs in the game; it is an offline asset step. Re-run it after
# replacing Background_temp.png.
#
#   godot --headless --path . --script res://tools/art/bg_tool.gd -- --mode=grid
#   godot --headless --path . --script res://tools/art/bg_tool.gd -- --mode=slice
#
# "grid" writes a coordinate-gridded copy so the glass polygon below can be
# read off by eye. "slice" writes the actual layers.

const SRC := "res://assets/art/backgrounds/Background_temp.png"
const OUT_DIR := "res://assets/art/backgrounds/"

# Glass panes in SOURCE IMAGE pixels, as polygons. The window is a bay: a wide
# left run of three panes and a short return on the right, so it is not one
# rectangle. Curtains and the white frame are deliberately NOT included — they
# belong to the room layer, in front of the weather.
static func _panes() -> Array:
	return [
		# NOTE: the strip left of x=300 is glass too, but the sheer curtain hangs
		# in front of it. The curtain belongs to the room layer, so that strip is
		# deliberately not cut out — otherwise the curtain disappears there.
		# centre-left pane
		PackedVector2Array([Vector2(318, 0), Vector2(455, 0), Vector2(455, 487), Vector2(318, 473)]),
		# centre pane
		PackedVector2Array([Vector2(474, 0), Vector2(736, 0), Vector2(736, 505), Vector2(474, 490)]),
		# right pane of the main run
		PackedVector2Array([Vector2(755, 0), Vector2(944, 0), Vector2(944, 495), Vector2(755, 505)]),
		# last sliver before the sheer curtain takes over on the right
		PackedVector2Array([Vector2(962, 0), Vector2(1002, 0), Vector2(1002, 462), Vector2(962, 470)]),
	]

func _init() -> void:
	var mode := "grid"
	var src := SRC
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--src="):
			src = a.substr(6)
	var img := _load_src(src)
	if img == null:
		quit(1)
		return
	match mode:
		"grid": _write_grid(img)
		"alpha": _write_alpha(img)
		"crop": _write_crop(img)
		"slice": _write_layers(img)
		"outside": _write_outside(img)
		"charfix": _write_charfix(img)
		_:
			push_error("unknown --mode")
			quit(1)
			return
	quit(0)

func _load_src(path: String = SRC) -> Image:
	var tex: Texture2D = load(path)
	if tex == null:
		push_error("cannot load " + path)
		return null
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	print("source size: ", img.get_size())
	return img

# ── grid ──────────────────────────────────────────────────────────────────────
# Every 50 px faint, every 100 px stronger, every 500 px red. Counting cells on
# the output gives the coordinates used in PANES above.
func _write_grid(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for x in range(0, w, 50):
		var col := Color(1, 0, 0) if x % 500 == 0 else (Color(0, 0, 0) if x % 100 == 0 else Color(1, 1, 1))
		for y in range(h):
			img.set_pixel(x, y, col)
	for y in range(0, h, 50):
		var col2 := Color(1, 0, 0) if y % 500 == 0 else (Color(0, 0, 0) if y % 100 == 0 else Color(1, 1, 1))
		for x in range(w):
			img.set_pixel(x, y, col2)
	var p := OUT_DIR + "_grid_preview.png"
	img.save_png(ProjectSettings.globalize_path(p))
	print("wrote ", p)

# ── alpha ─────────────────────────────────────────────────────────────────────
# Opaque pixels in magenta over a grid, so cutout artifacts in a character PNG
# are obvious and their bounds can be read off.
func _write_alpha(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var a := img.get_pixel(x, y).a
			out.set_pixel(x, y, Color(1, 0, 1).lerp(Color(0, 0, 0), 1.0 - a))
	for x in range(0, w, 100):
		var c := Color(1, 1, 0) if x % 500 == 0 else Color(0, 1, 1)
		for y in range(h):
			out.set_pixel(x, y, c)
	for y in range(0, h, 100):
		var c2 := Color(1, 1, 0) if y % 500 == 0 else Color(0, 1, 1)
		for x in range(w):
			out.set_pixel(x, y, c2)
	var p := OUT_DIR + "_alpha_preview.png"
	out.save_png(ProjectSettings.globalize_path(p))
	print("wrote ", p)

# ── crop ──────────────────────────────────────────────────────────────────────
# Zoomed crop on a checkerboard, so transparent and near-white read differently.
func _write_crop(img: Image) -> void:
	var r := Rect2i(880, 500, 340, 460)
	var zoom := 3
	var sub := Image.create(r.size.x * zoom, r.size.y * zoom, false, Image.FORMAT_RGBA8)
	for y in range(r.size.y * zoom):
		for x in range(r.size.x * zoom):
			var sx: int = r.position.x + x / zoom
			var sy: int = r.position.y + y / zoom
			var c := img.get_pixel(clampi(sx, 0, img.get_width() - 1), clampi(sy, 0, img.get_height() - 1))
			var checker := 0.25 if ((x / 24) + (y / 24)) % 2 == 0 else 0.55
			var bg := Color(checker, checker * 0.4, checker * 0.5)
			sub.set_pixel(x, y, bg.lerp(Color(c.r, c.g, c.b), c.a))
	# Grid every 20 source px.
	for gx in range(0, r.size.x, 20):
		for y in range(sub.get_height()):
			sub.set_pixel(gx * zoom, y, Color(0, 1, 0) if (r.position.x + gx) % 100 == 0 else Color(0, 0.4, 0))
	for gy in range(0, r.size.y, 20):
		for x in range(sub.get_width()):
			sub.set_pixel(x, gy * zoom, Color(0, 1, 0) if (r.position.y + gy) % 100 == 0 else Color(0, 0.4, 0))
	var p := OUT_DIR + "_crop_preview.png"
	sub.save_png(ProjectSettings.globalize_path(p))
	print("wrote ", p, " region ", r)

# ── charfix ───────────────────────────────────────────────────────────────────
# Erase the rectangular background-removal artifact beside her shoulder and
# feather what remains, then write the cleaned character next to the original.
func _write_charfix(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# The stray pale fragment floating off her shoulder — nothing of her in it.
	var kill := PackedVector2Array([
		Vector2(1000, 548), Vector2(1145, 590), Vector2(1145, 616), Vector2(1000, 616),
	])
	for y in range(h):
		for x in range(w):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), kill):
				var c := img.get_pixel(x, y)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
	_despeckle_alpha(img)
	# The cutout left dead-straight vertical/horizontal cuts through her
	# cardigan. They cannot be repainted here, but feathering them stops the
	# eye reading a rectangle. A regenerated character PNG is the real fix.
	_feather_cuts(img)
	var p := "res://assets/art/character/Character_clean.png"
	img.save_png(ProjectSettings.globalize_path(p))
	print("wrote ", p)

# Pull in near-transparent fringe pixels left by the original cutout so edges
# don't show a pale halo against the room.
func _despeckle_alpha(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	for y in range(h):
		for x in range(w):
			var c := im.get_pixel(x, y)
			if c.a > 0.0 and c.a < 0.35:
				im.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))

# Taper alpha over a few pixels inward from the artificial straight cuts, so the
# clipped cardigan fades out instead of ending on a ruler-straight line.
func _feather_cuts(im: Image) -> void:
	var h := im.get_height()
	var ramp := 14
	# vertical cut at x ~= 1000, running y 600..890
	for y in range(596, mini(896, h)):
		for i in range(ramp):
			var x := 1000 - 1 - i
			if x < 0:
				continue
			var c := im.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var t := float(i) / float(ramp - 1)   # 0 at the cut, 1 inward
			im.set_pixel(x, y, Color(c.r, c.g, c.b, minf(c.a, t)))
	# horizontal cut along the bottom bite, y ~= 888, x 930..1000
	for x in range(930, 1002):
		for i in range(ramp):
			var y2 := 888 - 1 - i
			if y2 < 0:
				continue
			var c2 := im.get_pixel(x, y2)
			if c2.a <= 0.0:
				continue
			var t2 := float(i) / float(ramp - 1)
			im.set_pixel(x, y2, Color(c2.r, c2.g, c2.b, minf(c2.a, t2)))

# ── outside ───────────────────────────────────────────────────────────────────
# Build a full-frame picture of the view through the window.
#
# The painting only contains "outside" inside the glass. To make the outside a
# real independent layer — one that can drift for parallax, or be swapped for a
# night or rainy version — it has to cover the whole frame. So the glass content
# is pushed outward to fill everything else. That invented area is never seen
# directly; it only has to exist so the glass never runs out of picture when the
# layer moves.
#
# This is a STAND-IN. Drop a properly generated view at the same path and it is
# used instead, no code change: assets/art/backgrounds/outside_layer.png
func _write_outside(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Work at quarter resolution: the filled area is blurred anyway, and
	# per-pixel GDScript over 1.5M pixels is far too slow.
	var sw := w / 4
	var sh := h / 4
	var small := img.duplicate() as Image
	small.resize(sw, sh, Image.INTERPOLATE_BILINEAR)

	var m := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	for y in range(sh):
		for x in range(sw):
			var inside := false
			var pt := Vector2(float(x * 4) + 2.0, float(y * 4) + 2.0)
			for poly in _panes():
				if Geometry2D.is_point_in_polygon(pt, poly):
					inside = true
					break
			m.set_pixel(x, y, Color(1, 1, 1, 1) if inside else Color(0, 0, 0, 1))

	var filled := PackedByteArray()
	filled.resize(sw * sh)
	for y in range(sh):
		for x in range(sw):
			filled[y * sw + x] = 1 if m.get_pixel(x, y).r > 0.5 else 0

	# Horizontal push, both directions.
	for y in range(sh):
		var last := -1
		for x in range(sw):
			if filled[y * sw + x] == 1:
				last = x
			elif last >= 0:
				small.set_pixel(x, y, small.get_pixel(last, y))
				filled[y * sw + x] = 2
		last = -1
		for x in range(sw - 1, -1, -1):
			if filled[y * sw + x] == 1:
				last = x
			elif last >= 0 and filled[y * sw + x] != 2:
				small.set_pixel(x, y, small.get_pixel(last, y))
				filled[y * sw + x] = 2
	# Vertical push, for rows with no glass at all (below the sill).
	var last_row := -1
	for y in range(sh):
		var any := false
		for x in range(sw):
			if filled[y * sw + x] != 0:
				any = true
				break
		if any:
			last_row = y
		elif last_row >= 0:
			for x in range(sw):
				small.set_pixel(x, y, small.get_pixel(x, last_row))
	for i in range(4):
		_blur_rgb(small)

	small.resize(w, h, Image.INTERPOLATE_BILINEAR)
	# Keep the real glass pixels sharp; only the invented surround is blurred.
	for y in range(h):
		for x in range(w):
			var pt2 := Vector2(float(x) + 0.5, float(y) + 0.5)
			for poly in _panes():
				if Geometry2D.is_point_in_polygon(pt2, poly):
					var c := img.get_pixel(x, y)
					small.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
					break
	small.save_png(ProjectSettings.globalize_path(OUT_DIR + "outside_layer.png"))
	print("wrote outside_layer.png (stand-in; replace with a generated view)")

func _blur_rgb(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var src := im.duplicate() as Image
	for y in range(h):
		for x in range(w):
			var acc := Color(0, 0, 0, 0)
			var n := 0.0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var sx: int = clampi(x + dx, 0, w - 1)
					var sy: int = clampi(y + dy, 0, h - 1)
					acc += src.get_pixel(sx, sy)
					n += 1.0
			im.set_pixel(x, y, Color(acc.r / n, acc.g / n, acc.b / n, 1.0))

# ── slice ─────────────────────────────────────────────────────────────────────

# Objects nearest the camera, in SOURCE IMAGE pixels. These get redrawn on top
# of Yua so she sits *behind* them — the difference between a character pasted
# onto a photo and one sitting in the room. Same pixels as the room layer, so
# the seam is invisible.
static func _foreground() -> Array:
	return [
		# monitor and its stand, far left
		PackedVector2Array([Vector2(0, 220), Vector2(315, 238), Vector2(338, 700), Vector2(0, 712)]),
		# dinosaur plush on its wooden coaster
		PackedVector2Array([Vector2(118, 636), Vector2(316, 648), Vector2(316, 918), Vector2(118, 908)]),
		# potted plant, bottom-left corner
		PackedVector2Array([Vector2(0, 742), Vector2(152, 758), Vector2(152, 1024), Vector2(0, 1024)]),
		# desk mat, keyboard and mouse — her forearms pass behind these
		PackedVector2Array([Vector2(292, 700), Vector2(918, 668), Vector2(946, 1024), Vector2(292, 1024)]),
		# chair cushion and the near arm of the L-shaped desk
		PackedVector2Array([Vector2(1030, 600), Vector2(1536, 620), Vector2(1536, 1024), Vector2(1030, 1024)]),
	]

func _write_layers(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# Coverage mask: 1 inside glass. Sampled 2x2 per pixel so pane edges come out
	# anti-aliased instead of stair-stepped.
	var mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var hits := 0.0
			for oy in [0.25, 0.75]:
				for ox in [0.25, 0.75]:
					var pt := Vector2(float(x) + ox, float(y) + oy)
					for poly in _panes():
						if Geometry2D.is_point_in_polygon(pt, poly):
							hits += 1.0
							break
			var a := hits / 4.0
			mask.set_pixel(x, y, Color(a, a, a, 1.0))
	# Soften by one pixel so the room layer's cut edge never reads as a hard
	# rectangle against the weather behind it.
	_blur1(mask)

	# Foreground coverage, same 2x2 sampling then softened.
	var fg_mask := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var hits := 0.0
			for oy in [0.25, 0.75]:
				for ox in [0.25, 0.75]:
					var pt := Vector2(float(x) + ox, float(y) + oy)
					for poly in _foreground():
						if Geometry2D.is_point_in_polygon(pt, poly):
							hits += 1.0
							break
			var a := hits / 4.0
			fg_mask.set_pixel(x, y, Color(a, a, a, 1.0))
	_blur1(fg_mask)

	var room := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var front := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var src := img.get_pixel(x, y)
			var g := mask.get_pixel(x, y).r
			# Room keeps everything, minus the glass.
			room.set_pixel(x, y, Color(src.r, src.g, src.b, 1.0 - g))
			# Front carries only the nearest objects.
			front.set_pixel(x, y, Color(src.r, src.g, src.b, fg_mask.get_pixel(x, y).r))

	room.save_png(ProjectSettings.globalize_path(OUT_DIR + "room_layer.png"))
	front.save_png(ProjectSettings.globalize_path(OUT_DIR + "desk_front.png"))
	print("wrote room_layer.png / desk_front.png")

func _blur1(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var src := im.duplicate() as Image
	for y in range(h):
		for x in range(w):
			var acc := 0.0
			var n := 0.0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var sx: int = clampi(x + dx, 0, w - 1)
					var sy: int = clampi(y + dy, 0, h - 1)
					acc += src.get_pixel(sx, sy).r
					n += 1.0
			var v := acc / n
			im.set_pixel(x, y, Color(v, v, v, 1.0))
