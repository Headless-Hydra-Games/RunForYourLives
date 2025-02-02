shader_type spatial;

uniform sampler2D displacement;
uniform int mesh_size;
uniform float height_scale = 1;

uniform vec3 color;
uniform float specular = 0.0;
uniform sampler2D normal_map;

varying vec2 texture_pos;

void vertex() {
	texture_pos = VERTEX.xz / float(mesh_size) + 0.5;
	float height = texture(displacement, texture_pos).x;
	VERTEX.y += height * height_scale;
}

void fragment() {
	NORMAL_MAP = texture(normal_map, texture_pos).xyz;
	ALBEDO = color;
	SPECULAR = specular;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
