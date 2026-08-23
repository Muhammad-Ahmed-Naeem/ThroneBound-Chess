shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	// Sample the screen texture and blur it using LOD
	vec4 blurred_screen = textureLod(screen_texture, SCREEN_UV, 3.0);
	
	// Specific dusk violet palette
	vec4 tint = vec4(0.16, 0.14, 0.22, 0.85);
	
	// Multiply the blurred output by the tint color
	COLOR = blurred_screen * tint;
}
