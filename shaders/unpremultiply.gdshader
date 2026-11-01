shader_type canvas_item;
// Baked viewport textures hold premultiplied colour; this restores straight alpha so
// translucent pixels (glosses, shadows) and modulate fades look right.

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR.rgb /= max(a, 0.0001);
}
