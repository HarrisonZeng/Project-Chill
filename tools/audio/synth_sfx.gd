extends SceneTree
# Renders the game's two sound effects as WAV files, from scratch, in Godot.
#
#   godot --headless --path . --script res://tools/audio/synth_sfx.gd
#
# Why synthesize rather than download: no licence to track, no account needed,
# files are a few hundred KB, and every parameter is here to tune. The rain is
# band-limited noise with random drop transients and a slow gust swell — the
# same recipe most white-noise apps use. A real field recording would sound
# richer; if one is ever wanted, drop a CC0 loop at the same path and nothing
# else changes.
#
# Outputs (44.1 kHz, 16-bit, mono):
#   assets/audio/rain_loop.wav    8 s, seamless loop, played while the rainy
#                                 view is up
#   assets/audio/focus_chime.wav  ~2.2 s, soft three-note chime when a focus
#                                 session completes

const RATE := 44100
const OUT_DIR := "res://assets/audio/"

var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_rng.seed = 20260817
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_write(_rain(8.0), "rain_loop.wav", true)
	_write(_chime(), "focus_chime.wav", false)
	quit(0)

# ── rain ─────────────────────────────────────────────────────────────────────
func _rain(seconds: float) -> PackedFloat32Array:
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	# Two one-pole filters: low-pass to take the harsh top off white noise,
	# high-pass to remove rumble. Together they leave the "hiss" band of rain.
	var lp := 0.0
	var hp_prev_in := 0.0
	var hp_prev_out := 0.0
	var lp_a := 1.0 - exp(-2.0 * PI * 3400.0 / RATE)
	var hp_a := exp(-2.0 * PI * 350.0 / RATE)
	# Drop transients: short bursts of brighter noise at random moments.
	var drop_env := 0.0
	var next_drop := 0
	# Slow swell so it does not sound like a flat hiss.
	for i in range(n):
		var t := float(i) / RATE
		var white := _rng.randf_range(-1.0, 1.0)
		lp += lp_a * (white - lp)
		var hp := hp_a * (hp_prev_out + lp - hp_prev_in)
		hp_prev_in = lp
		hp_prev_out = hp
		var bed := hp * 0.9
		if i >= next_drop:
			drop_env = _rng.randf_range(0.25, 0.7)
			next_drop = i + int(_rng.randf_range(0.02, 0.14) * RATE)
		drop_env *= 0.9985
		var drop := white * drop_env * 0.35
		var swell := 0.82 + 0.18 * sin(t * 0.55) * sin(t * 0.23 + 1.0)
		out[i] = (bed + drop) * swell * 0.55
	# Seamless loop: crossfade the last half-second into the first.
	var fade := int(0.5 * RATE)
	for i in range(fade):
		var k := float(i) / fade
		var a := out[n - fade + i]
		var b := out[i]
		out[n - fade + i] = a * (1.0 - k) + b * k
	return out

# ── chime ────────────────────────────────────────────────────────────────────
func _chime() -> PackedFloat32Array:
	var seconds := 2.2
	var n := int(seconds * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	# E5, B5, E6 — an open, unhurried arpeggio. Each note: sine plus a quiet
	# second harmonic, exponential decay, staggered onsets.
	var notes := [
		[659.25, 0.00, 0.75, 0.42],
		[987.77, 0.13, 0.65, 0.34],
		[1318.5, 0.26, 0.55, 0.26],
	]
	for i in range(n):
		var t := float(i) / RATE
		var s := 0.0
		for nt in notes:
			var f: float = nt[0]
			var on: float = nt[1]
			var tau: float = nt[2]
			var amp: float = nt[3]
			if t < on:
				continue
			var lt := t - on
			var env := exp(-lt / tau) * minf(1.0, lt / 0.008)  # 8 ms attack
			s += amp * env * (sin(TAU * f * lt) + 0.18 * sin(TAU * f * 2.0 * lt))
		out[i] = s * 0.5
	# Tail fade so it never clicks off.
	var fade := int(0.15 * RATE)
	for i in range(fade):
		out[n - fade + i] *= 1.0 - float(i) / fade
	return out

# ── write ────────────────────────────────────────────────────────────────────
func _write(samples: PackedFloat32Array, name: String, loop: bool) -> void:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	var norm := 0.9 / peak if peak > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v := int(clampf(samples[i] * norm, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	var path := ProjectSettings.globalize_path(OUT_DIR + name)
	var err := wav.save_to_wav(path)
	print("%s -> %s (%.1f s, peak %.2f)" % [name, "ok" if err == OK else "ERROR %d" % err, float(samples.size()) / RATE, peak])
