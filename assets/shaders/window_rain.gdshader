shader_type canvas_item;
// Rain on the window glass. Applied to a ColorRect stretched over the window
// region only, so UV (0,0)-(1,1) spans just the glass. Reads the screen behind
// it and re-renders it refracted through running drops, with an overcast grade
// so the sunny painting outside reads as a rainy day.
// Works in the compatibility renderer (web build): no derivatives, no arrays.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float intensity : hint_range(0.0, 1.0) = 0.7;   // 0 = dry glass
uniform float overcast : hint_range(0.0, 1.0) = 0.55;   // grey-out of the view
uniform float refraction_px = 7.0;                       // drop lens strength

float hash1(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

// One layer of drops running down the glass. Columns of the window each carry
// a falling drop head with a fading trail above it. Returns (offset.xy, mask).
vec3 run_layer(vec2 uv, float t, float cols, float seed) {
	float col = floor(uv.x * cols);
	float fx = fract(uv.x * cols);
	float rn = hash1(col * 7.31 + seed);
	float speed = 0.06 + 0.12 * rn;
	float head_y = fract(t * speed + rn * 7.0);
	// Drops wander sideways a little as they slide.
	float cx = 0.5 + 0.22 * sin(uv.y * 14.0 + rn * 40.0 + t * speed * 30.0);
	vec2 d = vec2((fx - cx) * 2.4, (uv.y - head_y) * cols * 0.8);
	float head = 1.0 - smoothstep(0.08, 0.2, length(d));
	// Trail: thin, only above the head, fading with distance behind it.
	float above = smoothstep(0.0, 0.02, head_y - uv.y);
	float behind = 1.0 - smoothstep(0.0, 0.35, head_y - uv.y);
	float trail = above * behind * (1.0 - smoothstep(0.015, 0.05, abs(fx - cx))) * 0.5;
	float m = max(head, trail);
	// Skip some columns entirely so the pattern doesn't read as a grid.
	m *= step(0.35, hash1(col * 3.7 + seed + 1.0));
	return vec3(d * head, m);
}

// Small static droplets that sit on the glass and slowly renew.
float static_drops(vec2 uv, float t) {
	vec2 g = uv * vec2(30.0, 20.0);
	vec2 id = floor(g);
	vec2 f = fract(g) - 0.5;
	float rn = hash1(id.x * 13.7 + id.y * 51.3);
	vec2 pos = vec2(hash1(rn * 97.0), hash1(rn * 41.0)) - 0.5;
	float life = fract(t * 0.05 + rn);            // fade in and out over time
	float fade = smoothstep(0.0, 0.15, life) * (1.0 - smoothstep(0.6, 1.0, life));
	float r = 0.03 + 0.05 * rn;
	return (1.0 - smoothstep(r * 0.6, r, length(f - pos * 0.6))) * fade;
}

void fragment() {
	float t = TIME;
	vec3 a = run_layer(UV, t, 14.0, 0.0);
	vec3 b = run_layer(UV, t * 1.35, 22.0, 5.0);
	float drops = max(max(a.z, b.z), static_drops(UV, t) * 0.8) * intensity;
	vec2 offs = (a.xy + b.xy) * intensity;

	vec2 px = SCREEN_PIXEL_SIZE * refraction_px;
	vec3 col = texture(screen_tex, SCREEN_UV + offs * px * 4.0 - vec2(0.0, px.y * drops * 6.0)).rgb;

	// Overcast grade: pull the outside view toward cool grey.
	float grey = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 rainy = mix(col, vec3(grey) * vec3(0.82, 0.88, 0.97), overcast);
	// Distant falling rain: faint fast streaks, slightly diagonal.
	float sn = hash1(floor(UV.x * 160.0 + UV.y * 12.0));
	float streak = step(0.92, fract(UV.y * 1.5 - t * (1.2 + sn) + sn * 9.0)) * 0.05 * intensity;
	rainy += streak;
	// Drops themselves catch a touch of light.
	rainy += drops * 0.035;

	COLOR = vec4(rainy, 1.0);
}
