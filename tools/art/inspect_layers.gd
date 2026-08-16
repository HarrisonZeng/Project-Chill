extends SceneTree
# Triage for candidate layer PNGs produced outside the project. Reports size and
# how much of each image is transparent — a usable layer must have real alpha,
# and an image that is 100% opaque is a flat picture, not a layer.
#
#   godot --headless --path . --script res://tools/art/inspect_layers.gd -- --dir=<abs dir>

# Grid of thumbnails so a whole batch can be reviewed in one look. Cells are
# numbered left-to-right, top-to-bottom, matching the printed order.
func _contact_sheet(dir_path: String, names: Array, out_path: String) -> void:
	var cols := 4
	var cw := 380
	var ch := 254
	var pad := 6
	var rows: int = int(ceil(float(names.size()) / float(cols)))
	var sheet := Image.create(cols * (cw + pad) + pad, rows * (ch + pad) + pad, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.1, 0.1, 0.12))
	for i in range(names.size()):
		var img := Image.load_from_file(dir_path.path_join(names[i]))
		if img == null:
			continue
		img.convert(Image.FORMAT_RGBA8)
		img.resize(cw, ch, Image.INTERPOLATE_BILINEAR)
		var cx := pad + (i % cols) * (cw + pad)
		var cy := pad + (i / cols) * (ch + pad)
		sheet.blit_rect(img, Rect2i(0, 0, cw, ch), Vector2i(cx, cy))
		# Index bar: i+1 white pixels along the top edge of the cell, readable
		# as a short tally without needing font rendering.
		for t in range(i + 1):
			for yy in range(6):
				for xx in range(4):
					sheet.set_pixel(cx + 4 + t * 7 + xx, cy + 3 + yy, Color(1, 1, 0))
		print("cell %d = %s" % [i + 1, names[i]])
	sheet.save_png(out_path)
	print("wrote ", out_path)

# Is a candidate layer a true edit of the original (pixel-aligned) or a fresh
# generation that merely looks similar? Compares only where the candidate is not
# keyed magenta. A true edit scores near zero; a regeneration scores high.
func _compare(a_path: String, b_path: String) -> void:
	var a := Image.load_from_file(a_path)
	var b := Image.load_from_file(b_path)
	if a == null or b == null:
		push_error("load failed")
		return
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	if a.get_size() != b.get_size():
		print("SIZE MISMATCH %s vs %s" % [a.get_size(), b.get_size()])
		b.resize(a.get_width(), a.get_height(), Image.INTERPOLATE_BILINEAR)
	var diff := 0.0
	var n := 0
	var y := 0
	while y < a.get_height():
		var x := 0
		while x < a.get_width():
			var cb := b.get_pixel(x, y)
			# Compare only where the candidate actually carries content: skip
			# magenta-keyed areas AND genuinely transparent ones. Transparent
			# pixels keep arbitrary RGB (usually black), which would otherwise
			# swamp the score and make every alpha layer look "regenerated".
			if cb.a >= 0.5 and (cb.r + cb.b) * 0.5 - cb.g < 0.30:
				var ca := a.get_pixel(x, y)
				diff += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
				n += 1
			x += 3
		y += 3
	if n == 0:
		print("no comparable pixels")
		return
	var mean := diff / float(n) / 3.0
	print("mean per-channel difference: %.4f over %d px  ->  %s" % [
		mean, n,
		"ALIGNED EDIT" if mean < 0.04 else ("close" if mean < 0.10 else "REGENERATED, not aligned")
	])

# Crop a region and scale it up, to inspect an edge or artifact closely.
#   --crop=<src>|<out>|x,y,w,h
func _crop(spec: String) -> void:
	var parts := spec.split("|")
	var img := Image.load_from_file(parts[0])
	if img == null:
		push_error("cannot load " + parts[0])
		return
	img.convert(Image.FORMAT_RGBA8)
	var r := parts[2].split(",")
	var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
	var out := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, rect, Vector2i.ZERO)
	# "rgb" forces alpha opaque, revealing any colour still stored underneath a
	# transparent area. If the pixels survived, a broken cutout is repairable by
	# restoring alpha rather than repainting the art.
	if parts.size() > 3 and parts[3] == "rgb":
		for y in range(rect.size.y):
			for x in range(rect.size.x):
				var c0 := out.get_pixel(x, y)
				out.set_pixel(x, y, Color(c0.r, c0.g, c0.b, 1.0))
	# Checkerboard behind, so transparent areas are obvious rather than black.
	var vis := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var chk := 0.25 if ((x / 16) + (y / 16)) % 2 == 0 else 0.6
			var c := out.get_pixel(x, y)
			vis.set_pixel(x, y, Color(
				c.r * c.a + chk * (1.0 - c.a),
				c.g * c.a + chk * (1.0 - c.a),
				c.b * c.a + chk * (1.0 - c.a), 1.0))
	if rect.size.x < 700:
		vis.resize(rect.size.x * 2, rect.size.y * 2, Image.INTERPOLATE_NEAREST)
	vis.save_png(parts[1])
	print("cropped -> ", parts[1])

# Bounding box of the actual subject, treating either transparency or magenta
# as "not the subject". Comparing boxes says whether a replacement character
# drops into the same place or has to be rescaled and repositioned.
func _bbox(path: String) -> void:
	var img := Image.load_from_file(path)
	if img == null:
		push_error("cannot load " + path)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var is_subject := c.a > 0.5 and ((c.r + c.b) * 0.5 - c.g) < 0.30
			if is_subject:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		print("%s: no subject found" % path.get_file())
		return
	print("%s  canvas %dx%d  subject x:%d..%d y:%d..%d  (w=%d h=%d)" % [
		path.get_file().substr(0, 22), w, h, x0, x1, y0, y1, x1 - x0 + 1, y1 - y0 + 1])

func _init() -> void:
	var dir_path := ""
	var cmp := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--crop="):
			_crop(a.substr(7))
			quit(0)
			return
		elif a.begins_with("--bbox="):
			_bbox(a.substr(7))
			quit(0)
			return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--compare="):
			cmp = a.substr(10)
	if not cmp.is_empty():
		var parts := cmp.split("|")
		_compare(parts[0], parts[1])
		quit(0)
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="):
			dir_path = a.substr(6)
	if dir_path.is_empty():
		push_error("need --dir=")
		quit(1)
		return
	var d := DirAccess.open(dir_path)
	if d == null:
		push_error("cannot open " + dir_path)
		quit(1)
		return
	var names := []
	for f in d.get_files():
		if f.to_lower().ends_with(".png"):
			names.append(f)
	names.sort()

	var sheet := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--sheet="):
			sheet = a.substr(8)
	if not sheet.is_empty():
		_contact_sheet(dir_path, names, sheet)
		quit(0)
		return
	print("file,width,height,clear%,partial%,opaque%")
	for n in names:
		var img := Image.load_from_file(dir_path.path_join(n))
		if img == null:
			print("%s,LOAD_FAILED" % n)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var clear := 0
		var partial := 0
		var opaque := 0
		var step := 4
		var y := 0
		while y < h:
			var x := 0
			while x < w:
				var a := img.get_pixel(x, y).a
				if a <= 0.02:
					clear += 1
				elif a >= 0.98:
					opaque += 1
				else:
					partial += 1
				x += step
			y += step
		var total: float = float(clear + partial + opaque)
		print("%s,%d,%d,%.1f,%.1f,%.1f" % [
			n.substr(0, 18), w, h,
			100.0 * float(clear) / total,
			100.0 * float(partial) / total,
			100.0 * float(opaque) / total,
		])
	quit(0)
