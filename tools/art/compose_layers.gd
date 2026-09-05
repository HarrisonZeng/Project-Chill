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

# Inside a protect rect, decide per pixel whether it belongs to the object in
# front of the glass (daisy petals / centres / stems / leaves) or to the view
# behind it. Only the object survives; sky and foliage between the petals are
# keyed like the rest of the pane, so the outside view shows through there.
static func is_protected_pixel(c: Color) -> bool:
	# Protected unless the pixel is clearly the blurred background foliage behind
	# the bouquet: light, yellowish green. Stems and leaves are darker and redder-
	# poor (r < 0.55); petals are near-white (b high); centres are orange (r high).
	var is_bg := c.g > 0.60 and c.g >= c.r and c.r > 0.55 and c.b < 0.62 and c.g < 0.93 and not (c.r > 0.85 and c.b < 0.42)
	# Teal-grey tree blur (bluer than the foliage, greyer than a leaf).
	var is_bg2 := c.b >= 0.50 and c.g > c.r + 0.05 and absf(c.g - c.b) < 0.22 and c.r < 0.80 and c.r > 0.30
	# Neutral grey-green shadow blur, well below petal brightness.
	var mn := minf(c.r, minf(c.g, c.b))
	var mx := maxf(c.r, maxf(c.g, c.b))
	var is_bg3 := mn > 0.42 and mx < 0.74 and c.g >= c.r - 0.03 and (mx - mn) < 0.16
	return not (is_bg or is_bg2 or is_bg3)

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
	if mode == "panes":
		# Glass cut from measured geometry: paint magenta inside the pane rects,
		# except inside protect rects (objects standing in front of the glass,
		# e.g. the daisy bouquet). Deterministic and re-runnable, unlike a
		# generated mask. --rects=x,y,w,h;... --protect=x,y,w,h;...
		var in_g := ""
		var out_g := ""
		var rects_g := ""
		var prot_g := ""
		var smart_g := false
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_g = a.substr(5)
			elif a.begins_with("--out="):
				out_g = a.substr(6)
			elif a.begins_with("--rects="):
				rects_g = a.substr(8)
			elif a.begins_with("--protect="):
				prot_g = a.substr(10)
			elif a == "--smart":
				smart_g = true
		var pane_list: Array[Rect2i] = []
		for part in rects_g.split(";"):
			var v := part.split(",")
			if v.size() == 4:
				pane_list.append(Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])))
		var prot_list: Array[Rect2i] = []
		for part in prot_g.split(";"):
			var v := part.split(",")
			if v.size() == 4:
				prot_list.append(Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])))
		var img_g := Image.load_from_file(in_g)
		img_g.convert(Image.FORMAT_RGBA8)
		var painted := 0
		for r in pane_list:
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var skip := false
					for pr in prot_list:
						if pr.has_point(Vector2i(x, y)):
							skip = true
							break
					if skip and smart_g and not is_protected_pixel(img_g.get_pixel(x, y)):
						skip = false
					if not skip:
						img_g.set_pixel(x, y, Color(1, 0, 1, 1))
						painted += 1
		img_g.save_png(out_g)
		print("panes: painted %d px magenta over %d rects (%d protected) -> %s" % [painted, pane_list.size(), prot_list.size(), out_g])
		quit(0)
		return
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
	if mode == "flatten":
		# Composite an alpha PNG over flat magenta so an image model can see the
		# subject (it cannot read alpha) and hand it back keyable.
		# --mode=flatten --in=<png> --out=<png>
		var in_f := ""
		var out_f := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_f = a.substr(5)
			elif a.begins_with("--out="):
				out_f = a.substr(6)
		var imf := Image.load_from_file(in_f)
		imf.convert(Image.FORMAT_RGBA8)
		for y in range(imf.get_height()):
			for x in range(imf.get_width()):
				var c := imf.get_pixel(x, y)
				imf.set_pixel(x, y, Color(
					c.r * c.a + (1.0 - c.a),
					c.g * c.a,
					c.b * c.a + (1.0 - c.a), 1.0))
		imf.save_png(out_f)
		print("flattened on magenta -> ", out_f)
		quit(0)
		return
	if mode == "patch":
		# Fill a region of BASE from DONOR with a feathered seam. Inside the rect,
		# where base is transparent the donor wins outright; where base is opaque
		# it blends toward the donor by closeness to the hole (a blurred copy of
		# the hole mask gives that distance cheaply). With --force the whole rect
		# is replaced, feathered at its border — for swapping a region such as
		# closed eyes.
		# --mode=patch --base=<png> --donor=<png> --out=<png> --rect=x,y,w,h [--feather=16] [--force]
		var base_p := ""
		var donor_p := ""
		var out_p2 := ""
		var rect_s := ""
		var feather := 16
		var force := false
		var donor_alpha := false
		var match_tone := false
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--base="):
				base_p = a.substr(7)
			elif a.begins_with("--donor="):
				donor_p = a.substr(8)
			elif a.begins_with("--out="):
				out_p2 = a.substr(6)
			elif a.begins_with("--rect="):
				rect_s = a.substr(7)
			elif a.begins_with("--feather="):
				feather = int(a.substr(10))
			elif a == "--force":
				force = true
			elif a == "--donoralpha":
				donor_alpha = true
			elif a == "--match":
				match_tone = true
		var base := Image.load_from_file(base_p)
		var donor := Image.load_from_file(donor_p)
		base.convert(Image.FORMAT_RGBA8)
		donor.convert(Image.FORMAT_RGBA8)
		var rv := rect_s.split(",")
		var rect := Rect2i(int(rv[0]), int(rv[1]), int(rv[2]), int(rv[3]))
		var w := base.get_width()
		var h := base.get_height()
		var wm := Image.create(w, h, false, Image.FORMAT_RF)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if force:
					var dxr: int = mini(x - rect.position.x, rect.end.x - 1 - x)
					var dyr: int = mini(y - rect.position.y, rect.end.y - 1 - y)
					var d: int = mini(dxr, dyr)
					wm.set_pixel(x, y, Color(clampf(float(d) / float(feather), 0.0, 1.0), 0, 0, 1))
				else:
					wm.set_pixel(x, y, Color(1.0 if base.get_pixel(x, y).a < 0.95 else 0.0, 0, 0, 1))
		if not force:
			var srcw := wm.duplicate() as Image
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					var acc := 0.0
					var n := 0.0
					for dy in range(-feather, feather + 1, 2):
						for dx in range(-feather, feather + 1, 2):
							var sx: int = clampi(x + dx, 0, w - 1)
							var sy: int = clampi(y + dy, 0, h - 1)
							acc += srcw.get_pixel(sx, sy).r
							n += 1.0
					wm.set_pixel(x, y, Color(minf(1.0, (acc / n) * 1.15), 0, 0, 1))
		# Tone match: shift the donor so its mean over the overlap (pixels opaque
		# in BOTH, i.e. the surviving sleeve inside the rect) equals the base mean.
		# Without this the patch reads as a lighter/darker rectangle.
		var shift := Color(0, 0, 0, 0)
		if match_tone:
			var sb := Color(0, 0, 0, 0)
			var sd := Color(0, 0, 0, 0)
			var cnt := 0.0
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					var pb := base.get_pixel(x, y)
					var pd := donor.get_pixel(x, y)
					if pb.a > 0.95 and pd.a > 0.95:
						sb += pb
						sd += pd
						cnt += 1.0
			if cnt > 0.0:
				shift = (sb / cnt) - (sd / cnt)
				print("tone shift r%.3f g%.3f b%.3f over %d px" % [shift.r, shift.g, shift.b, int(cnt)])
		var out := base.duplicate() as Image
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var t := wm.get_pixel(x, y).r
				var b := base.get_pixel(x, y)
				var d := donor.get_pixel(x, y)
				d = Color(clampf(d.r + shift.r, 0, 1), clampf(d.g + shift.g, 0, 1), clampf(d.b + shift.b, 0, 1), d.a)
				if t <= 0.0:
					if donor_alpha:
						out.set_pixel(x, y, Color(b.r, b.g, b.b, minf(b.a, d.a)))
					continue
				var oa := (b.a * (1.0 - t) + d.a * t)
				if donor_alpha:
					oa = d.a
				out.set_pixel(x, y, Color(
					b.r * (1.0 - t) + d.r * t,
					b.g * (1.0 - t) + d.g * t,
					b.b * (1.0 - t) + d.b * t, oa))
		out.save_png(out_p2)
		print("patched %s from donor -> %s" % [rect, out_p2])
		quit(0)
		return
	if mode == "maskfrom":
		# New overlay = SRC pixels where the REF alpha (dilated) says so. Re-cuts
		# the hands overlay from a different rendition of the same pose.
		# --mode=maskfrom --src=<png> --ref=<alpha png> --out=<png> [--dilate=4]
		var s_p := ""
		var r_p := ""
		var o_p := ""
		var dil := 4
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--src="):
				s_p = a.substr(6)
			elif a.begins_with("--ref="):
				r_p = a.substr(6)
			elif a.begins_with("--out="):
				o_p = a.substr(6)
			elif a.begins_with("--dilate="):
				dil = int(a.substr(9))
		var srcm := Image.load_from_file(s_p)
		var refm := Image.load_from_file(r_p)
		srcm.convert(Image.FORMAT_RGBA8)
		refm.convert(Image.FORMAT_RGBA8)
		var w2 := srcm.get_width()
		var h2 := srcm.get_height()
		var outm := Image.create(w2, h2, false, Image.FORMAT_RGBA8)
		for y in range(h2):
			for x in range(w2):
				var m := 0.0
				for dy in range(-dil, dil + 1):
					for dx in range(-dil, dil + 1):
						var sx: int = clampi(x + dx, 0, w2 - 1)
						var sy: int = clampi(y + dy, 0, h2 - 1)
						m = maxf(m, refm.get_pixel(sx, sy).a)
				var c := srcm.get_pixel(x, y)
				outm.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * m))
		outm.save_png(o_p)
		print("masked overlay -> ", o_p)
		quit(0)
		return
	if mode == "diffmerge":
		# Keep BASE everywhere except where DONOR genuinely differs — for a second
		# animation frame from an image model, where the intended change (a few
		# fingers) is buried in whole-image repaint noise. Pixels whose colour
		# differs by more than --thresh form the change mask; it is dilated by
		# --dilate and feathered, then donor is blended in only there. Alternating
		# the result with the base then moves only what should move.
		# --mode=diffmerge --base=<png> --donor=<png> --out=<png> [--rect=x,y,w,h] [--thresh=0.12] [--dilate=6]
		var bp := ""
		var dp := ""
		var op := ""
		var rs := ""
		var thresh := 0.12
		var dil := 6
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--base="):
				bp = a.substr(7)
			elif a.begins_with("--donor="):
				dp = a.substr(8)
			elif a.begins_with("--out="):
				op = a.substr(6)
			elif a.begins_with("--rect="):
				rs = a.substr(7)
			elif a.begins_with("--thresh="):
				thresh = float(a.substr(9))
			elif a.begins_with("--dilate="):
				dil = int(a.substr(9))
		var bi := Image.load_from_file(bp)
		var di := Image.load_from_file(dp)
		bi.convert(Image.FORMAT_RGBA8)
		di.convert(Image.FORMAT_RGBA8)
		var w := bi.get_width()
		var h := bi.get_height()
		var rect := Rect2i(0, 0, w, h)
		if not rs.is_empty():
			var rv := rs.split(",")
			rect = Rect2i(int(rv[0]), int(rv[1]), int(rv[2]), int(rv[3]))
		# 1. raw change mask
		var m := Image.create(w, h, false, Image.FORMAT_RF)
		var changed := 0
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var b := bi.get_pixel(x, y)
				var d := di.get_pixel(x, y)
				var dv := absf(b.r - d.r) + absf(b.g - d.g) + absf(b.b - d.b) + absf(b.a - d.a) * 2.0
				if dv > thresh * 3.0:
					m.set_pixel(x, y, Color(1, 0, 0, 1))
					changed += 1
		# 2. dilate + feather (box blur over the dilation radius)
		var out_m := Image.create(w, h, false, Image.FORMAT_RF)
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var acc := 0.0
				var n := 0.0
				for yy in range(-dil, dil + 1, 2):
					for xx in range(-dil, dil + 1, 2):
						var sx: int = clampi(x + xx, 0, w - 1)
						var sy: int = clampi(y + yy, 0, h - 1)
						acc += m.get_pixel(sx, sy).r
						n += 1.0
				out_m.set_pixel(x, y, Color(minf(1.0, (acc / n) * 3.0), 0, 0, 1))
		# 3. blend
		var out := bi.duplicate() as Image
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				var t := out_m.get_pixel(x, y).r
				if t <= 0.0:
					continue
				var b := bi.get_pixel(x, y)
				var d := di.get_pixel(x, y)
				out.set_pixel(x, y, Color(
					b.r * (1.0 - t) + d.r * t,
					b.g * (1.0 - t) + d.g * t,
					b.b * (1.0 - t) + d.b * t,
					b.a * (1.0 - t) + d.a * t))
		out.save_png(op)
		print("diffmerge: %d changed px in rect -> %s" % [changed, op])
		quit(0)
		return
	if mode == "demagenta":
		# Replace any pixel that still leans magenta (key spill that survived a
		# graft) with the same pixel from a clean reference image.
		# --mode=demagenta --in=<png> --ref=<png> --out=<png> [--amount=0.18]
		var in_dm := ""
		var ref_dm := ""
		var out_dm := ""
		var amt := 0.18
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_dm = a.substr(5)
			elif a.begins_with("--ref="):
				ref_dm = a.substr(6)
			elif a.begins_with("--out="):
				out_dm = a.substr(6)
			elif a.begins_with("--amount="):
				amt = float(a.substr(9))
		var im_dm := Image.load_from_file(in_dm)
		var rf_dm := Image.load_from_file(ref_dm)
		im_dm.convert(Image.FORMAT_RGBA8)
		rf_dm.convert(Image.FORMAT_RGBA8)
		var fixed := 0
		for y in range(im_dm.get_height()):
			for x in range(im_dm.get_width()):
				var c := im_dm.get_pixel(x, y)
				if c.a > 0.05 and magenta_amount(c) > amt:
					im_dm.set_pixel(x, y, rf_dm.get_pixel(x, y))
					fixed += 1
		im_dm.save_png(out_dm)
		print("demagenta: replaced %d px -> %s" % [fixed, out_dm])
		quit(0)
		return
	if mode == "sharpen":
		# Unsharp mask: out = src + k * (src - blur(src)). Recovers the apparent
		# detail that repeated image-model edits wash out. Alpha untouched; only
		# blends opaque neighbours so edges do not pick up transparent black.
		# --mode=sharpen --in=<png> --out=<png> [--k=0.7]
		var in_s := ""
		var out_s := ""
		var k := 0.7
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--in="):
				in_s = a.substr(5)
			elif a.begins_with("--out="):
				out_s = a.substr(6)
			elif a.begins_with("--k="):
				k = float(a.substr(4))
		var im := Image.load_from_file(in_s)
		im.convert(Image.FORMAT_RGBA8)
		var w := im.get_width()
		var h := im.get_height()
		var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in range(h):
			for x in range(w):
				var c := im.get_pixel(x, y)
				if c.a < 0.02:
					out.set_pixel(x, y, c)
					continue
				var acc := Color(0, 0, 0, 0)
				var wsum := 0.0
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var sx: int = clampi(x + dx, 0, w - 1)
						var sy: int = clampi(y + dy, 0, h - 1)
						var n := im.get_pixel(sx, sy)
						if n.a < 0.5:
							continue
						var wt := 1.0 / (1.0 + float(dx * dx + dy * dy))
						acc += n * wt
						wsum += wt
				var bl := acc / maxf(wsum, 0.0001)
				out.set_pixel(x, y, Color(
					clampf(c.r + k * (c.r - bl.r), 0.0, 1.0),
					clampf(c.g + k * (c.g - bl.g), 0.0, 1.0),
					clampf(c.b + k * (c.b - bl.b), 0.0, 1.0), c.a))
		out.save_png(out_s)
		print("sharpened k=%.2f -> %s" % [k, out_s])
		quit(0)
		return
	if mode == "alphacopy":
		# Night layer from a relit master + an ALPHA day layer (no magenta):
		# --mode=alphacopy --alpha=<day alpha png> --in=<night master> --out=<png>
		# RGB comes from the relit master, alpha from the day cut. Both are
		# pixel-aligned by construction, so the day cut is correct for night.
		var al_p := ""
		var in_a := ""
		var out_a := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--alpha="):
				al_p = a.substr(8)
			elif a.begins_with("--in="):
				in_a = a.substr(5)
			elif a.begins_with("--out="):
				out_a = a.substr(6)
		var al := Image.load_from_file(al_p)
		var srca := Image.load_from_file(in_a)
		if al == null or srca == null:
			push_error("alphacopy: cannot load inputs")
			quit(1)
			return
		al.convert(Image.FORMAT_RGBA8)
		srca.convert(Image.FORMAT_RGBA8)
		if al.get_size() != srca.get_size():
			push_error("alphacopy: size mismatch %s vs %s" % [al.get_size(), srca.get_size()])
			quit(1)
			return
		for y in range(srca.get_height()):
			for x in range(srca.get_width()):
				var s := srca.get_pixel(x, y)
				srca.set_pixel(x, y, Color(s.r, s.g, s.b, al.get_pixel(x, y).a))
		srca.save_png(out_a)
		print("alphacopy -> ", out_a)
		quit(0)
		return
	if mode == "applymask":
		# Reuse a magenta-keyed DAY layer as the alpha for a relit master:
		# --mode=applymask --mask=<day keyed png> --in=<night master> --out=<alpha png>
		# The relit master is pixel-aligned with the day one, so the day cut is
		# the correct cut for it too — no second cutting pass, no drift.
		var mask_p := ""
		var in_m := ""
		var out_m := ""
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--mask="):
				mask_p = a.substr(7)
			elif a.begins_with("--in="):
				in_m = a.substr(5)
			elif a.begins_with("--out="):
				out_m = a.substr(6)
		var mask := Image.load_from_file(mask_p)
		var src := Image.load_from_file(in_m)
		if mask == null or src == null:
			push_error("applymask: cannot load inputs")
			quit(1)
			return
		mask.convert(Image.FORMAT_RGBA8)
		src.convert(Image.FORMAT_RGBA8)
		if mask.get_size() != src.get_size():
			push_error("applymask: size mismatch %s vs %s" % [mask.get_size(), src.get_size()])
			quit(1)
			return
		key_magenta(mask)  # now mask.a is the alpha we want
		for y in range(src.get_height()):
			for x in range(src.get_width()):
				var s := src.get_pixel(x, y)
				var m := mask.get_pixel(x, y)
				src.set_pixel(x, y, Color(s.r, s.g, s.b, m.a))
		src.save_png(out_m)
		print("applied mask -> ", out_m)
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
