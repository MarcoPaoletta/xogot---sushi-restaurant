shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// Patience ring for the order bubble: an arc from 12 o'clock, green > 0.6, yellow > 0.3, red below.

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float thickness : hint_range(0.02, 0.4) = 0.16;
uniform float pulse = 0.0;

void vertex() {
	// Billboard toward the camera.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv) * 2.0;
	float outer = 1.0 - pulse * 0.06;
	float inner = outer - thickness;
	float ring = smoothstep(inner - 0.02, inner + 0.02, d) * (1.0 - smoothstep(outer - 0.02, outer + 0.02, d));
	float ang = atan(uv.x, uv.y);          // 0 at top, clockwise
	float t = (ang / 6.2831853) + 0.5;     // 0..1
	t = fract(1.0 - t);
	float filled = step(t, progress);
	vec3 col = progress > 0.6 ? vec3(0.35, 0.85, 0.45) : (progress > 0.3 ? vec3(1.0, 0.78, 0.2) : vec3(1.0, 0.3, 0.25));
	vec3 back = vec3(0.12, 0.08, 0.08);
	ALBEDO = mix(back, col, filled);
	ALPHA = ring * mix(0.55, 1.0, filled);
	EMISSION = col * filled * (0.6 + 0.4 * pulse);
}
