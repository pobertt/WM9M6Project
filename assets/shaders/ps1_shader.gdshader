shader_type spatial;
render_mode skip_vertex_transform, diffuse_lambert_wrap, depth_draw_always;

uniform sampler2D albedo: source_color, filter_nearest;
uniform vec3 albedo_colour: source_color = vec3(1.0);
uniform float specular: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D emission: source_color, filter_nearest;
uniform vec3 emission_colour: source_color = vec3(0.0);

uniform float jitter: hint_range(0.0, 1.0) = 0.5;
uniform bool jitter_z_coordinate = true;
uniform bool jitter_depth_independent = true;
uniform bool affine_texture_mapping = true;
uniform vec3 uv_scale = vec3(1.0, 1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0,0.0);
uniform bool triplanar = false;
uniform float uv_blend_sharpness : hint_range(0.0, 150.0, 0.001);
uniform float alpha_scissor: hint_range(0.0, 1.0) = 1.0;

varying vec3 uv_power_normal;
varying vec3 uv_triplanar_pos;

void vertex() {
	if (triplanar) {
		// UV1 Triplanar: Enabled
		uv_power_normal = pow(abs(NORMAL), vec3(uv_blend_sharpness));
		uv_triplanar_pos = VERTEX * uv_scale;
		uv_power_normal /= dot(uv_power_normal, vec3(1.0));
		uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);
	}

	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	float z_orig = VERTEX.z;
	float i = (1.0 - jitter) * min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y) / 2.0;

	if (jitter_depth_independent) {
		float w = (PROJECTION_MATRIX * vec4(VERTEX, 1.0)).w;
		VERTEX = round(VERTEX / w * i) / i * w;
	} else {
		VERTEX = round(VERTEX * i) / i;
	}

	if (!jitter_z_coordinate) {
		VERTEX.z = z_orig;
	}

	if (affine_texture_mapping) {
		UV *= VERTEX.z;
	}

}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec2 uv = UV * uv_scale.xy + uv_offset;

	if (affine_texture_mapping) {
		uv /= VERTEX.z;
	}

	if (triplanar) {
		vec4 albedo_tex = triplanar_texture(albedo, uv_power_normal, uv_triplanar_pos);
		ALBEDO = albedo_tex.rgb * COLOR.rgb * albedo_colour;

		ALPHA = albedo_tex.a;
		vec4 emission_tex = triplanar_texture(emission, uv_power_normal, uv_triplanar_pos);
		EMISSION = emission_tex.rgb * emission_colour;
	} else {
		ALBEDO = texture(albedo, uv).rgb * COLOR.rgb * albedo_colour;
		ALPHA = texture(albedo, uv).a;
		EMISSION = texture(emission, uv).rgb * emission_colour * COLOR.rgb;
	}

	SPECULAR = specular;
}