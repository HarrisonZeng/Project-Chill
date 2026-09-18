extends SceneTree
# Make a reference image with the forearms ERASED, for briefing an image model.
#
# Two rounds of redesigns came back with the original cream cable-knit sleeves
# attached to entirely new outfits, no matter how explicitly the brief said to
# redraw them. Wording was not the problem: the model sees sleeves in the
# reference and reproduces them. So remove them from the reference — there is
# then nothing to copy, and the arms must be drawn to match the new garment.
#
# The hands overlay (yua_hands.png) already marks exactly the arm region that
# sits above the desk; its alpha, dilated upward, is the erase mask.
#
#   godot --headless --path . --script res://tools/art/erase_arms.gd -- \
#       --src=<character png> --mask=<hands png> --out=<png> [--grow=26] [--magenta]

func _init() -> void:
	var src_p := ""
	var mask_p := ""
	var out_p := ""
	var grow := 26
	var on_magenta := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--src="):
			src_p = a.substr(6)
		elif a.begins_with("--mask="):
			mask_p = a.substr(7)
		elif a.begins_with("--out="):
			out_p = a.substr(6)
		elif a.begins_with("--grow="):
			grow = int(a.substr(7))
		elif a == "--magenta":
			on_magenta = true
	var src := Image.load_from_file(src_p)
	var mask := Image.load_from_file(mask_p)
	if src == null or mask == null:
		push_error("cannot load inputs")
		quit(1)
		return
	src.convert(Image.FORMAT_RGBA8)
	mask.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var erased := 0
	for y in range(h):
		for x in range(w):
			# Dilate the mask: erase if ANY mask pixel within `grow` is opaque.
			# Sampled on a coarse step — the mask is a solid blob, so this is
			# exact enough and far faster than a true distance transform.
			var hit := false
			var dy := -grow
			while dy <= grow and not hit:
				var dx := -grow
				while dx <= grow:
					var sx: int = clampi(x + dx, 0, w - 1)
					var sy: int = clampi(y + dy, 0, h - 1)
					if mask.get_pixel(sx, sy).a > 0.4:
						hit = true
						break
					dx += 4
				dy += 4
			if hit:
				src.set_pixel(x, y, Color(0, 0, 0, 0))
				erased += 1
	if on_magenta:
		for y in range(h):
			for x in range(w):
				var c := src.get_pixel(x, y)
				src.set_pixel(x, y, Color(
					c.r * c.a + (1.0 - c.a),
					c.g * c.a,
					c.b * c.a + (1.0 - c.a), 1.0))
	src.save_png(out_p)
	print("erased %d px of forearm -> %s" % [erased, out_p])
	quit(0)
