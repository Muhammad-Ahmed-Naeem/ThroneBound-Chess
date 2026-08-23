shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.16, 0.14, 0.22, 0.7); // Dusk violet tint

void fragment() {
	vec4 blurred_screen = textureLod(screen_texture, SCREEN_UV, blur_amount);
	// Mix the blurred background with our tint color
	COLOR = mix(blurred_screen, tint_color, tint_color.a);
}
