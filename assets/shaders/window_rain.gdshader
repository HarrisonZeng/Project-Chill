shader_type canvas_item;
// Rain running down the window glass.
//
// This is applied to the OUTSIDE layer — the full background painting that sits
// behind the room. The room layer on top of it is transparent only where the
// glass is, so the weather is visible through exactly the window's real shape
// and nowhere else. That is why there is no mask here and no rectangle around
// the effect: the window frame itself does the masking.
//
// It samples its own TEXTURE rather than the screen. Reading the screen made it
// pick up whatever had already been drawn that frame (and smear during the
// breathing zoom), which is where the glitching came from.
// Compatibility-renderer safe: no derivatives, no dynamic loops, no arrays.

uniform float intensity : hint_range(0.0, 1.0) = 0.7;   // 0 = dry glass
uniform float overcast : hint_range(0.0, 1.0) = 0.5;    // grey-out of the view
uniform float refraction = 0.011;                        // drop lens strength

float hash1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// One layer of drops sliding down. Returns (offset.xy, mask).
vec3 run_layer(vec2 uv, float t, float cols, float seed) {
	float col = floor(uv.x * cols);
	float fx = fract(uv.x * cols);
	float rn = hash1(col * 7.31 + seed);
	float speed = 0.05 + 0.10 * rn;
	float head_y = fract(t * speed + rn * 7.0);
	float cx = 0.5 + 0.18 * sin(uv.y * 12.0 + rn * 40.0 + t * speed * 24.0);
	vec2 d = vec2((fx - cx) * 2.2, (uv.y - head_y) * cols * 0.7);
	float head = 1.0 - smoothstep(0.11, 0.26, length(d));
	float above = smoothstep(0.0, 0.02, head_y - uv.y);
	float behind = 1.0 - smoothstep(0.0, 0.28, head_y - uv.y);
	float trail = above * behind * (1.0 - smoothstep(0.012, 0.04, abs(fx - cx))) * 0.45;
	float m = max(head, trail);
	m *= step(0.4, hash1(col * 3.7 + seed + 1.0));
	return vec3(d * head, m);
}

// Small droplets clinging to the glass, slowly renewing.
float static_drops(vec2 uv, float t) {
	vec2 g = uv * vec2(46.0, 26.0);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float rn = hash1(id.x * 13.7 + id.y * 51.3);
	vec2 pos = vec2(hash1(rn * 97.0), hash1(rn * 41.0)) - 0.5;
	float life = fract(t * 0.05 + rn);
	float fade = smoothstep(0.0, 0.15, life) * (1.0 - smoothstep(0.6, 1.0, life));
	float r = 0.03 + 0.05 * rn;
	return (1.0 - smoothstep(r * 0.6, r, length(f - pos * 0.6))) * fade;
}

void fragment() {
	float t = TIME;
	// Column counts are across the WHOLE painting, of which the window is only
	// about a third — hence the high numbers for a normal-looking density.
	vec3 a = run_layer(UV, t, 32.0, 0.0);
	vec3 b = run_layer(UV, t * 1.3, 50.0, 5.0);
	float drops = max(max(a.z, b.z), static_drops(UV, t) * 0.8) * intensity;
	vec2 offs = (a.xy + b.xy) * intensity * refraction;

	// Refract the view through the drops, sampling our own texture.
	vec2 suv = clamp(UV + offs - vec2(0.0, drops * refraction * 0.9), vec2(0.001), vec2(0.999));
	vec4 src = texture(TEXTURE, suv);

	// Overcast grade: pull the sunny view toward cool grey.
	float grey = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 rainy = mix(src.rgb, vec3(grey) * vec3(0.82, 0.88, 0.97), overcast);
	// Faint falling rain in the distance.
	float sn = hash1(floor(UV.x * 190.0 + UV.y * 12.0));
	rainy += step(0.93, fract(UV.y * 1.4 - t * (1.1 + sn) + sn * 9.0)) * 0.045 * intensity;
	// Drops catch a little light.
	rainy += drops * 0.035;

	COLOR = vec4(rainy, src.a);
}
