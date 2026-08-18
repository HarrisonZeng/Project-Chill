extends SceneTree
# Night version of the room master, made by relighting the DAY master pixel by
# pixel — so it stays exactly aligned with it and the day glass/desk masks
# apply unchanged. (A generated night picture would shift things slightly and
# the day/night swap would visibly jump.)
#
# Model: dim, slightly desaturated cool ambient, plus two lights —
#   * the table lamp: a warm pool on the right (side table, wall, prints, floor)
#   * the monitor: a soft cool glow on the desk at the left
# Each light is a smooth radial falloff added on top of the ambient, scaled by
# the day brightness at that pixel so it reads as the painted surfaces catching
# light, not as a flat overlay.
#
#   godot --headless --path . --script res://tools/art/relight.gd
#   godot --headless --path . --script res://tools/art/relight.gd -- --lamp=1250,330 --monitor=150,400
#
# Writes assets/art/backgrounds/room_master_night.png. Then key with the day
# masks (compose_layers.gd --mode=applymask) rather than re-cutting.

const SRC := "res://assets/art/backgrounds/room_master.png"
const OUT := "res://assets/art/backgrounds/room_master_night.png"

# Ambient: what an unlit surface becomes. Cool, dim, still readable.
var AMBIENT := Vector3(0.36, 0.40, 0.55)
var DESAT := 0.28

var lamp_pos := Vector2(1250, 330)
var lamp_radius := 620.0
var LAMP_COL := Vector3(1.0, 0.82, 0.55)
var LAMP_GAIN := 0.95

var mon_pos := Vector2(160, 420)
var mon_radius := 420.0
var MON_COL := Vector3(0.70, 0.82, 1.0)
var MON_GAIN := 0.55

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lamp="):
			var v := a.substr(7).split(",")
			lamp_pos = Vector2(float(v[0]), float(v[1]))
		elif a.begins_with("--monitor="):
			var v2 := a.substr(10).split(",")
			mon_pos = Vector2(float(v2[0]), float(v2[1]))
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if img == null:
		push_error("cannot load " + SRC)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			var day := Vector3(c.r, c.g, c.b)
			var lum := day.dot(Vector3(0.299, 0.587, 0.114))
			var desat := day.lerp(Vector3(lum, lum, lum), DESAT)
			# ambient
			var out := desat * AMBIENT
			# lamp pool
			var dl := Vector2(x, y).distance_to(lamp_pos) / lamp_radius
			var wl := 1.0 - smoothstep(0.0, 1.0, dl)
			wl = wl * wl
			out += day * LAMP_COL * (wl * LAMP_GAIN)
			# monitor glow
			var dm := Vector2(x, y).distance_to(mon_pos) / mon_radius
			var wm := 1.0 - smoothstep(0.0, 1.0, dm)
			wm = wm * wm
			out += day * MON_COL * (wm * MON_GAIN)
			img.set_pixel(x, y, Color(
				clampf(out.x, 0.0, 1.0), clampf(out.y, 0.0, 1.0), clampf(out.z, 0.0, 1.0), c.a))
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("wrote ", OUT)
	quit(0)
