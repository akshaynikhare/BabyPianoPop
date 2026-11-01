class_name ShapeDraw
extends RefCounted
## Cached polygon builders for the candy shapes. Shapes live in a 100 x 100 design box.

static var _cache := {}


static func rounded_rect(rect: Rect2, radius: float, seg := 6) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centers := [
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.position.y + r),
	]
	var pts := PackedVector2Array()
	for c in 4:
		var start := -PI * 0.5 + c * PI * 0.5
		for s in seg + 1:
			var a := start + PI * 0.5 * float(s) / seg
			pts.append(centers[c] + Vector2(cos(a), sin(a)) * r)
	return pts


static func rounded_poly(verts: PackedVector2Array, radius: float, seg := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := verts.size()
	for i in n:
		var v := verts[i]
		var to_prev := verts[(i + n - 1) % n] - v
		var to_next := verts[(i + 1) % n] - v
		var la := to_prev.length()
		var lb := to_next.length()
		var a := to_prev / la
		var b := to_next / lb
		var half := absf(a.angle_to(b)) * 0.5
		var t := minf(radius / tan(half), minf(la, lb) * 0.5)
		var r := t * tan(half)
		var p1 := v + a * t
		var p2 := v + b * t
		var center := v + (a + b).normalized() * (r / sin(half))
		var a1 := (p1 - center).angle()
		var d := wrapf((p2 - center).angle() - a1, -PI, PI)
		for s in seg + 1:
			var an := a1 + d * float(s) / seg
			out.append(center + Vector2(cos(an), sin(an)) * r)
	return out


static func closed(pts: PackedVector2Array) -> PackedVector2Array:
	var out := pts.duplicate()
	out.append(pts[0])
	return out


static func ellipse(center: Vector2, radii: Vector2, rotation := 0.0, seg := 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in seg:
		var a := TAU * float(i) / seg
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y).rotated(rotation))
	return pts


## Pointy sparkle / star with n points around the origin.
static func star_points(points: int, outer: float, inner: float, rotation := -PI * 0.5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var r := outer if i % 2 == 0 else inner
		var a := rotation + PI * float(i) / points
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts


static func star() -> PackedVector2Array:
	if not _cache.has("star"):
		var v := PackedVector2Array([
			Vector2(50, 10), Vector2(61, 36), Vector2(89, 38), Vector2(67, 56), Vector2(75, 84),
			Vector2(50, 69), Vector2(25, 84), Vector2(33, 56), Vector2(11, 38), Vector2(39, 36),
		])
		_cache["star"] = rounded_poly(v, 6.0, 5)
	return _cache["star"]


static func heart() -> PackedVector2Array:
	if not _cache.has("heart"):
		var curves := [
			[Vector2(50, 86), Vector2(18, 64), Vector2(8, 46), Vector2(8, 30)],
			[Vector2(8, 30), Vector2(8, 16), Vector2(18, 8), Vector2(33, 8)],
			[Vector2(33, 8), Vector2(41, 8), Vector2(47, 12), Vector2(50, 17)],
			[Vector2(50, 17), Vector2(53, 12), Vector2(59, 8), Vector2(67, 8)],
			[Vector2(67, 8), Vector2(82, 8), Vector2(92, 16), Vector2(92, 30)],
			[Vector2(92, 30), Vector2(92, 46), Vector2(82, 64), Vector2(50, 86)],
		]
		var pts := PackedVector2Array()
		for c in curves:
			for s in 10:
				pts.append(_bezier(c, float(s) / 10.0))
		_cache["heart"] = pts
	return _cache["heart"]


static func triangle() -> PackedVector2Array:
	if not _cache.has("triangle"):
		var v := PackedVector2Array([Vector2(50, 12), Vector2(88, 80), Vector2(12, 80)])
		_cache["triangle"] = rounded_poly(v, 12.0, 7)
	return _cache["triangle"]


static func gear(teeth := 8, outer := 40.0, inner := 31.0) -> PackedVector2Array:
	var key := "gear%d" % teeth
	if not _cache.has(key):
		var v := PackedVector2Array()
		for i in teeth:
			var a := TAU * float(i) / teeth
			var step := TAU / teeth
			for pair in [[-0.34, inner], [-0.2, outer], [0.2, outer], [0.34, inner]]:
				var an: float = a + step * pair[0]
				v.append(Vector2(cos(an), sin(an)) * float(pair[1]))
		_cache[key] = rounded_poly(v, 3.5, 3)
	return _cache[key]


static func _bezier(c: Array, t: float) -> Vector2:
	var p0: Vector2 = c[0]
	return p0.bezier_interpolate(c[1], c[2], c[3], t)
