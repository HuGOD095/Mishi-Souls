shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float color_depth : hint_range(8.0, 64.0) = 32.0; // 32 = 15-bit PS1 real
uniform float dither_strength : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec3 col = texture(screen_texture, SCREEN_UV).rgb;
	
	// Matriz Bayer 4x4 clásica de PS1
	ivec2 pos = ivec2(FRAGCOORD.xy) % 4;
	float bayer[16] = float[16](
		0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
		12.0/16.0, 4.0/16.0, 14.0/16.0,  6.0/16.0,
		3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
		15.0/16.0, 7.0/16.0, 13.0/16.0,  5.0/16.0
	);
	float dither = (bayer[pos.y * 4 + pos.x] - 0.5) * (dither_strength / color_depth);
	
	// Reducción de paleta de colores estilo PS1
	col = floor((col + dither) * color_depth + 0.5) / color_depth;
	COLOR = vec4(col, 1.0);
}