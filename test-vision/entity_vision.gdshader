// Spatial shader for ENTITIES (enemies, items, props that should only exist when
// seen). Full colour and opaque INSIDE the vision polygon, completely invisible
// OUTSIDE it. Drive any entity's material with this and vision_manager.gd will
// feed it the shared mask texture.
shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, shadows_disabled;

uniform sampler2D vision_mask : filter_linear;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform bool use_texture = false;

// Same soft-edge controls as the world shader so boundaries match.
uniform float edge0 : hint_range(0.0, 1.0) = 0.30;
uniform float edge1 : hint_range(0.0, 1.0) = 0.70;
uniform float mask_softness : hint_range(0.0, 0.02) = 0.004;

float sample_mask(vec2 uv) {
	float m = texture(vision_mask, uv).r;
	m += texture(vision_mask, uv + vec2( mask_softness, 0.0)).r;
	m += texture(vision_mask, uv + vec2(-mask_softness, 0.0)).r;
	m += texture(vision_mask, uv + vec2(0.0,  mask_softness)).r;
	m += texture(vision_mask, uv + vec2(0.0, -mask_softness)).r;
	return m / 5.0;
}

void fragment() {
	vec4 base = albedo;
	if (use_texture) {
		base *= texture(albedo_texture, UV);
	}
	ALBEDO = base.rgb;

	// SCREEN_UV indexes the same screen-space mask the post-process uses.
	float m = smoothstep(edge0, edge1, sample_mask(SCREEN_UV));
	ALPHA = base.a * m; // outside the cone -> 0 -> not drawn at all
}
