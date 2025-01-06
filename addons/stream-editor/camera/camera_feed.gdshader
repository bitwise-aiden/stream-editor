shader_type canvas_item;

uniform vec2 viewport_size;
uniform sampler2D camera_y;
uniform sampler2D camera_CbCr;

uniform bool flip_horz = false;
uniform bool flip_vert = false;

const mat3 transform = mat3(
	vec3(1.00000, 1.00000, 1.00000),
	vec3(0.00000, -0.18732, 1.85560),
	vec3(1.57481, -0.46813, 0.00000)
);

void vertex() {
	if (flip_horz) {
		UV.x = 1.0 - UV.x;
	}
	if (flip_vert) {
		UV.y = 1.0 - UV.y;
	}
}


void fragment() {
	vec2 texture_size = vec2(textureSize(camera_y, 0));
	vec2 scale = viewport_size / texture_size;

	vec2 uv = UV * scale + vec2(0.32, 0.3);

	vec4 color;
	color.r = texture(camera_y, uv).r;
	color.gb = texture(camera_CbCr, uv).rg - vec2(0.5, 0.5);
	color.rgb = transform * color.rgb;

	COLOR = color;
}