shader_type canvas_item;

uniform vec2 player_screen_pos = vec2(0.5, 0.5);
uniform float vision_radius : hint_range(0.0, 1.0) = 0.3;
uniform float edge_softness : hint_range(0.0, 0.3) = 0.08;
uniform float darkness : hint_range(0.0, 1.0) = 0.85;
uniform vec2 screen_size = vec2(1920.0, 1080.0);

void fragment() {
    float aspect = screen_size.x / screen_size.y;
    vec2 diff = UV - player_screen_pos;
    diff.x *= aspect;
    float dist = length(diff);
    float mask = smoothstep(vision_radius - edge_softness, vision_radius, dist);
    COLOR = vec4(0.0, 0.0, 0.0, mask * darkness);
}