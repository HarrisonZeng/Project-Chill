extends SceneTree
# Chroma-key the magenta-backed layers Codex produced and stack them, so the
# result can be checked before anything is wired into the game.
#
# Image models cannot output an alpha channel, so transparency was delivered as
# flat magenta. This keys it out and removes the magenta spill that anti-aliased
# edges pick up, which is what would otherwise leave a pink halo around every
# object.
#
#   godot --headless --path . --script res://tools/art/compose_layers.gd -- --dir=<abs dir> --out=<abs png>

# Back to front.
const STACK := [
	"exec-20d055e0-6971-473b-b7a1-049293bc0ee6.png",  # outside view (day)
	"exec-d0d66516-72a3-41b1-93c8-12e243b3bb76.png",  # room shell, glass keyed
	"exec-5f661009-0d25-48e7-a449-5b2ec5137f03.png",  # desk + items behind her
	"exec-27f556a1-77a6-4839-acbd-d8b6ebb89c56.png",  # Yua
	"exec-65af2a91-891c-4aca-a31d-a983755a4cd1.png",  # desk items in front
	"exec-6e5fa3eb-3221-43ff-9999-d300802b32c3.png",  # chair
]

# Bring the usable Codex output into the project.
#
# Only layers that are true EDITS of the original painting can be used for the
# room, because they must line up with it pixel for pixel. The outside views are
# different: they are free-standing backdrops seen through the window, so they
# need no alignment and any good picture works.
const INGEST := [
	# source file, destination, needs magenta keying
	["exec-20d055e0-6971-473b-b7a1-049293bc0ee6.png", "outside_day.png", false],
	["exec-305168ec-828d-4c07-adc9-814f3a8523c3.png", "outside_rain.png", false],
	["exec-ece537bb-8f71-42cd-8f97-e46a6a7cb134.png", "outside_night.png", false],
	# the one room layer that is a genuine carve of the original (diff 0.017)
	["exec-5e112835-5927-45fe-8038-f4987e41fde8.png", "room_layer.png", true],
]

func _ingest(dir_path: String) -> void:
	var out_dir := ProjectSettings.globalize_path("res://assets/art/backgrounds/")
	for row in INGEST:
		var img := Image.load_from_file(dir_path.path_join(row[0]))
		if img == null:
			push_error("missing " + row[0])
			continue
		img.convert(Image.FORMAT_RGBA8)
		if img.get_size() != Vector2i(1536, 1024):
			print("  resizing %s from %s to 1536x1024" % [row[1], img.get_size()])
			img.resize(1536, 1024, Image.INTERPOLATE_LANCZOS)
		if row[2]:
			key_magenta(img)
		img.save_png(out_dir.path_join(row[1]))
		print("wrote %s" % row[1])

func _init() -> void:
	var dir_path := ""
	var out_path := ""
	var mode := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.substr(7)
	if mode == "key":
		# Convert one magenta-backed layer to a real alpha PNG in place.
		var in_p := ""
		var out_p := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_p = a.substr(5)
			elif a.begins_with("--out="):
				out_p = a.substr(6)
		var im := Image.load_from_file(in_p)
		if im == null:
			push_error("cannot load " + in_p)
			quit(1)
			return
		im.convert(Image.FORMAT_RGBA8)
		key_magenta(im)
		im.save_png(out_p)
		print("keyed -> ", out_p)
		quit(0)
		return
	if mode == "keep":
		# Keep only pixels inside any of the given rects (x,y,w,h;x,y,w,h;...),
		# clear everything else. For trimming a front layer down to just what is
		# nearer the camera than the character.
		var in_k := ""
		var out_k := ""
		var rects_s := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_k = a.substr(5)
			elif a.begins_with("--out="):
				out_k = a.substr(6)
			elif a.begins_with("--rects="):
				rects_s = a.substr(8)
		var rects: Array[Rect2i] = []
		for part in rects_s.split(";"):
			var v := part.split(",")
			if v.size() == 4:
				rects.append(Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])))
		var imk := Image.load_from_file(in_k)
		imk.convert(Image.FORMAT_RGBA8)
		for y in range(imk.get_height()):
			for x in range(imk.get_width()):
				var inside := false
				for r in rects:
					if r.has_point(Vector2i(x, y)):
						inside = true
						break
				if not inside:
					imk.set_pixel(x, y, Color(0, 0, 0, 0))
		imk.save_png(out_k)
		print("kept %d rects -> %s" % [rects.size(), out_k])
		quit(0)
		return
	if mode == "cutx":
		# Keep only content left of a column, clear the rest. Used to test which
		# desk objects need to occlude Yua: anything her hands rest ON must be
		# drawn behind her, and the room layer already contains it.
		var in_p2 := ""
		var out_p2 := ""
		var cx := 0
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_p2 = a.substr(5)
			elif a.begins_with("--out="):
				out_p2 = a.substr(6)
			elif a.begins_with("--x="):
				cx = int(a.substr(4))
		var im2 := Image.load_from_file(in_p2)
		im2.convert(Image.FORMAT_RGBA8)
		for y in range(im2.get_height()):
			for x in range(cx, im2.get_width()):
				im2.set_pixel(x, y, Color(0, 0, 0, 0))
		im2.save_png(out_p2)
		print("cut at x=%d -> %s" % [cx, out_p2])
		quit(0)
		return
	if mode == "ingest":
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--dir="):
				dir_path = a.substr(6)
		_ingest(dir_path)
		quit(0)
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir_path = a.substr(6)
		elif a.begins_with("--out="):
			out_path = a.substr(6)
	if dir_path.is_empty() or out_path.is_empty():
		push_error("need --dir= and --out=")
		quit(1)
		return

	var canvas: Image = null
	for i in range(STACK.size()):
		var img := Image.load_from_file(dir_path.path_join(STACK[i]))
		if img == null:
			push_error("missing " + STACK[i])
			continue
		img.convert(Image.FORMAT_RGBA8)
		if canvas == null:
			# First layer defines the canvas; it is the backdrop and opaque.
			canvas = Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
			canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
			print("base %s %s" % [STACK[i].substr(0, 18), img.get_size()])
			continue
		if img.get_size() != canvas.get_size():
			print("resizing %s from %s" % [STACK[i].substr(0, 18), img.get_size()])
			img.resize(canvas.get_width(), canvas.get_height(), Image.INTERPOLATE_BILINEAR)
		key_magenta(img)
		_over(canvas, img)
		print("stacked %s" % STACK[i].substr(0, 18))
	canvas.save_png(out_path)
	print("wrote ", out_path)
	quit(0)

# Magenta-ness: how far the pixel leans to red+blue against green. Pure magenta
# is 1.0, any neutral or warm colour is near 0. Keying on this rather than on
# an exact RGB match survives the compression noise in a generated PNG.
static func magenta_amount(c: Color) -> float:
	return (c.r + c.b) * 0.5 - c.g

func key_magenta(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var lo := 0.30   # below this: fully opaque
	var hi := 0.62   # above this: fully transparent
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var m := magenta_amount(c)
			var a := 1.0 - clampf((m - lo) / (hi - lo), 0.0, 1.0)
			if a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			if a < 1.0:
				# Edge pixel: strip the magenta it picked up from the backdrop,
				# otherwise every silhouette gets a pink rim.
				var excess: float = maxf(0.0, m)
				c = Color(
					clampf(c.r - excess * 0.75, 0.0, 1.0),
					c.g,
					clampf(c.b - excess * 0.75, 0.0, 1.0)
				)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, a))

func _over(dst: Image, src: Image) -> void:
	var w := dst.get_width()
	var h := dst.get_height()
	for y in range(h):
		for x in range(w):
			var s := src.get_pixel(x, y)
			if s.a <= 0.0:
				continue
			var d := dst.get_pixel(x, y)
			var a := s.a
			dst.set_pixel(x, y, Color(
				s.r * a + d.r * (1.0 - a),
				s.g * a + d.g * (1.0 - a),
				s.b * a + d.b * (1.0 - a),
				1.0
			))
