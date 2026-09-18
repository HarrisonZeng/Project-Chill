extends SceneTree
# Catch the recurring "new outfit, old sleeves" bug in generated character art.
#
# Three rounds of redesigns came back with the reference's cream cable-knit
# forearms attached to entirely different outfits. Wording the brief harder did
# not fix it, and spotting it by eye is unreliable across six images. So measure
# it: the forearm region of a candidate is compared pixel-for-pixel against the
# ORIGINAL character's forearm region. Copied sleeves score near zero.
#
#   godot --headless --path . --script res://tools/art/armcheck.gd -- \
#       --orig=<original character png> --mask=<hands png> --files=<png>[,<png>...]
#
# Also reports how close the forearm is to the candidate's OWN torso colour,
# which separates "copied the old sleeve" from "drew a sleeve that happens to
# be a similar colour".

const COPIED := 0.05   # below this, the forearm is the original's, verbatim

func _init() -> void:
	var orig_p := ""
	var mask_p := ""
	var files: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--orig="):
			orig_p = a.substr(7)
		elif a.begins_with("--mask="):
			mask_p = a.substr(7)
		elif a.begins_with("--files="):
			files = a.substr(8).split(",")
	var orig := Image.load_from_file(orig_p)
	var mask := Image.load_from_file(mask_p)
	if orig == null or mask == null:
		push_error("armcheck: cannot load --orig or --mask")
		quit(1)
		return
	orig.convert(Image.FORMAT_RGBA8)
	mask.convert(Image.FORMAT_RGBA8)
	print("file,vs_original,vs_own_torso,verdict")
	var bad := 0
	for f in files:
		if f.strip_edges().is_empty():
			continue
		var img := Image.load_from_file(f)
		if img == null:
			print("%s,LOAD_FAILED,," % f.get_file())
			bad += 1
			continue
		img.convert(Image.FORMAT_RGBA8)
		if img.get_size() != orig.get_size():
			print("%s,SIZE_MISMATCH,," % f.get_file())
			bad += 1
			continue
		# 1. forearm vs the original's forearm, over the mask
		var diff := 0.0
		var n := 0
		var arm := Color(0, 0, 0, 0)
		var y := 0
		while y < img.get_height():
			var x := 0
			while x < img.get_width():
				if mask.get_pixel(x, y).a > 0.6:
					var c := img.get_pixel(x, y)
					if c.a > 0.5:
						var o := orig.get_pixel(x, y)
						diff += absf(c.r - o.r) + absf(c.g - o.g) + absf(c.b - o.b)
						arm += c
						n += 1
				x += 2
			y += 2
		if n == 0:
			print("%s,NO_ARM_PIXELS,," % f.get_file())
			bad += 1
			continue
		var vs_orig := diff / float(n) / 3.0
		arm = arm / float(n)
		# 2. forearm colour vs this image's own torso colour
		var torso := Color(0, 0, 0, 0)
		var tn := 0
		var ty := 340
		while ty < 640:
			var tx := 430
			while tx < 900:
				var tc := img.get_pixel(tx, ty)
				if tc.a > 0.9:
					torso += tc
					tn += 1
				tx += 2
			ty += 2
		var vs_torso := 1.0
		if tn > 0:
			torso = torso / float(tn)
			vs_torso = (absf(arm.r - torso.r) + absf(arm.g - torso.g) + absf(arm.b - torso.b)) / 3.0
		var verdict := "OK"
		if vs_orig < COPIED:
			verdict = "SLEEVES COPIED FROM ORIGINAL"
			bad += 1
		print("%s,%.4f,%.4f,%s" % [f.get_file(), vs_orig, vs_torso, verdict])
	if bad > 0:
		print("FAILED %d file(s)" % bad)
		quit(1)
		return
	print("all clear")
	quit(0)
