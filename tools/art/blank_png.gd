extends SceneTree
# Write a fully transparent PNG of a given size.
#
# Used to disable an overlay for a screenshot. Moving the .png aside does NOT
# work: the .png.import stays, ResourceLoader.exists() still returns true, and
# Godot serves the cached texture from .godot/imported — which is how the
# original cream-knit hands ended up painted over three rounds of redesigns.
# Overwriting the file with transparent pixels is unambiguous.
#
#   godot --headless --path . --script res://tools/art/blank_png.gd -- --out=<png> [--size=1536x1024]

func _init() -> void:
	var out_p := ""
	var w := 1536
	var h := 1024
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_p = a.substr(6)
		elif a.begins_with("--size="):
			var parts := a.substr(7).split("x")
			if parts.size() == 2:
				w = int(parts[0])
				h = int(parts[1])
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.save_png(out_p)
	print("blank %dx%d -> %s" % [w, h, out_p])
	quit(0)
