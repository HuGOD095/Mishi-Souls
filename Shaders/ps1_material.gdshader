shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_tex : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float jitter_resolution : hint_range(60.0, 640.0) = 240.0;

varying vec2 affine_uv;
varying float clip_w;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip_pos = PROJECTION_MATRIX * view_pos;

	// Efecto de parpadeo / temblor de vértices PS1
	vec2 snapped = floor(clip_pos.xy / clip_pos.w * jitter_resolution + 0.5) / jitter_resolution;
	clip_pos.xy = snapped * clip_pos.w;

	// Regresar a espacio local para conservar la iluminación y animaciones de huesos
	vec4 snapped_view = inverse(PROJECTION_MATRIX) * clip_pos;
	VERTEX = (inverse(MODELVIEW_MATRIX) * snapped_view).xyz;

	// Coordenadas afines PS1
	clip_w = clip_pos.w;
	affine_uv = UV * clip_w;
}

void fragment() {
	vec2 uv_ps1 = affine_uv / clip_w;
	vec4 tex = texture(albedo_tex, uv_ps1) * albedo_color;
	ALBEDO = tex.rgb;
}