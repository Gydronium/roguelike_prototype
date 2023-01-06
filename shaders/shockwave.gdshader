shader_type canvas_item;

uniform vec2 center;
uniform float force;
uniform float size;
uniform float thickness;

void fragment() {
	float ratio = 1955.0 / 3270.0;
	vec2 scaledUV = (UV - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);
	float mask = (1.0 - smoothstep(size - 0.1, size, length(scaledUV - center))) *
			smoothstep(size - thickness - 0.1, size - thickness, length(scaledUV - center));
	vec2 disp = normalize(scaledUV - center) * force * mask;
	COLOR = texture(TEXTURE, UV - disp);
	//COLOR.rgb = vec3(mask);
}