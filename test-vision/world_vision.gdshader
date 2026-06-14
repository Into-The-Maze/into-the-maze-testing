// Full-screen post-process. Reads the rendered frame and the vision mask, then
// shows the world in full colour INSIDE the mask and greyscaled / dimmed /
// tinted OUTSIDE it. Every part of the "outside" look is tunable.
//
// Apply this to a full-rect ColorRect on a CanvasLayer that sits on top of the
// 3D scene. vision_mask is fed the SubViewport mask texture by vision_manager.gd.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D vision_mask : filter_linear;

// How the world looks OUTSIDE the vision polygon.
uniform float outside_saturation : hint_range(0.0, 1.0) = 0.0; // 0 = full grey
uniform float outside_brightness : hint_range(0.0, 2.0) = 0.55;
uniform vec3  outside_tint : source_color = vec3(0.7, 0.75, 0.85);

// Soft edge of the mask. mask < edge0 -> fully outside, > edge1 -> fully inside.
uniform float edge0 : hint_range(0.0, 1.0) = 0.30;
uniform float edge1 : hint_range(0.0, 1.0) = 0.70;
// Blur applied to the mask sample, in UV units, to feather the boundary.
uniform float mask_softness : hint_range(0.0, 0.02) = 0.004;

float sample_mask(vec2 uv) {
	// Cheap 5-tap blur so the hard polygon edge reads as a soft falloff.
	float m = texture(vision_mask, uv).r;
	m += texture(vision_mask, uv + vec2( mask_softness, 0.0)).r;
	m += texture(vision_mask, uv + vec2(-mask_softness, 0.0)).r;
	m += texture(vision_mask, uv + vec2(0.0,  mask_softness)).r;
	m += texture(vision_mask, uv + vec2(0.0, -mask_softness)).r;
	return m / 5.0;
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	float m = smoothstep(edge0, edge1, sample_mask(SCREEN_UV));

	// Build the "outside" appearance: desaturate, dim, tint.
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 grey = mix(vec3(luma), col, outside_saturation);
	vec3 outside = grey * outside_brightness * outside_tint;

	COLOR = vec4(mix(outside, col, m), 1.0);
}
