shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	vec3 world = texture(screen_texture, SCREEN_UV).rgb;
	float grey = dot(world, vec3(0.299, 0.587, 0.114));
	vec3 muted = mix(world, vec3(grey), 0.78);
	COLOR = vec4(muted * vec3(0.64, 0.68, 0.70), 1.0);
}
