shader_type canvas_item;
// Vertical three-stop gradient with a soft staggered polka-dot pattern, in base units.

uniform vec4 top_color : source_color = vec4(0.99, 0.91, 0.95, 1.0);
uniform vec4 mid_color : source_color = vec4(0.95, 0.91, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.88, 0.91, 1.0, 1.0);
uniform vec2 rect_size = vec2(720.0, 1600.0);
uniform float cell = 84.0;
uniform float dot_radius = 13.0;
uniform float dot_strength = 0.5;
uniform vec2 drift = vec2(5.0, 3.0);

void fragment() {
	float y = UV.y;
	vec3 col = y < 0.5 ? mix(top_color.rgb, mid_color.rgb, y * 2.0) : mix(mid_color.rgb, bottom_color.rgb, (y - 0.5) * 2.0);

	vec2 p = UV * rect_size + drift * TIME;
	vec2 g = p / cell;
	g.x += mod(floor(g.y), 2.0) * 0.5;
	vec2 f = (fract(g) - 0.5) * cell;
	float d = length(f);
	float aa = 1.2;
	float dot = 1.0 - smoothstep(dot_radius - aa, dot_radius + aa, d);
	col = mix(col, vec3(1.0), dot * dot_strength);
	COLOR = vec4(col, 1.0);
}
