shader_type canvas_item;

uniform vec4 color_a = vec4(0.533333, 0.482353, 0.690196, 1.0);
uniform vec4 color_b = vec4(0.521569, 0.823529, 0.815686, 1.0);


vec4 blended_color(float val)
{
	vec4 delta = color_b - color_a;
	return color_a + delta * clamp(val, 0.0, 1.0);
}


float fmod(float a, float b)
{
	return (a - b * floor(a / b));
}


vec2 texture_size(sampler2D tex)
{
	ivec2 size = textureSize(tex, 0);
	return vec2(
		float(size.x),
		float(size.y)
	);
}


float wave(vec2 position, vec2 direction, float speed, float frequency)
{
	vec2 offset_position = position + direction * TIME * speed;
	return offset_position.y / frequency + sin(offset_position.x / frequency);
}


vec4 color(vec2 position)
{
	float val = 0.0;

	val += wave(position, vec2(-1.0, 1.0), 50.0, 100.0);
	val += wave(position, vec2(-1.0, 0.0), 25.0, 50.0);
	val += wave(position, vec2(0.5, -1.0), 10.0, 250.0);
	val += wave(position, vec2(1.0, 0.0), 50.0, 150.0);
	val += wave(position, vec2(1.0, 0.0), 50.0, 150.0);
	val += wave(position, vec2(1.0, 0.0), 50.0, 150.0);

	float m = 10.0;
	val = fmod(val, m) / m;

	return blended_color(val);
}


void fragment()
{
	vec2 p = FRAGCOORD.xy;
	COLOR = color(p);
}