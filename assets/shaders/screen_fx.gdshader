shader_type canvas_item;
// Full-screen overlay: soft vignette, a warm flash, and a radial iris fade for scene transitions.

uniform float vignette : hint_range(0.0, 1.0) = 0.3;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.25, 0.2, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fade_color : source_color = vec4(0.12, 0.06, 0.05, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.15, 1.0));
	float vig = smoothstep(0.35, 0.95, d) * vignette;
	vec3 col = mix(vec3(0.0), flash_color.rgb, flash);
	float a = vig * (1.0 - flash) + flash * 0.5;
	float iris = smoothstep(fade * 1.35 - 0.35, fade * 1.35, d + 0.0001);
	iris = fade <= 0.0 ? 0.0 : (fade >= 1.0 ? 1.0 : 1.0 - iris);
	col = mix(col, fade_color.rgb, iris);
	a = max(a, iris);
	COLOR = vec4(col, a);
}
