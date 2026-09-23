extends SceneTree
# Lighten Yua's hair without regenerating the image.
#
# Every Codex pass costs real detail, and an unsharp mask cannot put detail
# back — it only amplifies the render's noise, which is what turned her skin
# blotchy on 2026-09-24. So colour tweaks are done here instead: a direct
# per-pixel adjustment keeps the artwork bit-identical everywhere it does not
# touch.
#
# Hair is isolated by hue. Her plum/rose sits around 300-355 degrees, while the
# things that must NOT move are far away on the wheel: skin ~25, the sapphire
# butterfly ~225, her eyes ~150, and the cream top is nearly unsaturated.
#
#   godot --headless --path . --script res://tools/art/recolour_hair.gd -- \
#       --in=<png> --out=<png> [--lift=0.10] [--desat=0.08]
#
# lift  : how much brightness to add to hair pixels (0-1)
# desat : how much saturation to remove, so it reads softer rather than neon

func _init() -> void:
	var in_p := ""
	var out_p := ""
	var lift := 0.10
	var desat := 0.08
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--in="):
			in_p = a.substr(5)
		elif a.begins_with("--out="):
			out_p = a.substr(6)
		elif a.begins_with("--lift="):
			lift = float(a.substr(7))
		elif a.begins_with("--desat="):
			desat = float(a.substr(8))
	var img := Image.load_from_file(in_p)
	if img == null:
		push_error("cannot load " + in_p)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var touched := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			var h := c.h * 360.0
			var s := c.s
			var v := c.v
			# Plum through rose. Skin, sky-blue and green are all outside this.
			var is_hair := (h >= 295.0 and h <= 360.0) and s > 0.12
			if not is_hair:
				continue
			# Lift the darkest strands most, so the shape opens up without the
			# highlights blowing out into flat pink.
			var weight: float = clampf(1.0 - v, 0.0, 1.0)
			var nv: float = clampf(v + lift * (0.45 + 0.55 * weight), 0.0, 1.0)
			var ns: float = clampf(s - desat * (0.45 + 0.55 * weight), 0.0, 1.0)
			var out := Color.from_hsv(c.h, ns, nv, c.a)
			img.set_pixel(x, y, out)
			touched += 1
	img.save_png(out_p)
	print("hair: lifted %d px (lift %.2f desat %.2f) -> %s" % [touched, lift, desat, out_p])
	quit(0)
