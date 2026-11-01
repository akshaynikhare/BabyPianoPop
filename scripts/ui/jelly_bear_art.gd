class_name JellyBearArt
extends Node2D
## Static art for Jelly Bear in a 100 x 100 design box. Redraws only when the face changes.

const STROKE := 3.2
const EYE := Color("3a0ca3")
const NOSE := Color("5c0029")
const CHEEK := Color("ff758f")
const SOFT_TOP := Color("ffd6e0")
const SOFT_BOTTOM := Color("ffb3c1")
const JELLY := [Color("ff70a6"), Color("ff477e"), Color("e5234f")]

var size := 100.0:
	set(v):
		size = v
		queue_redraw()
var happy_eyes := false:
	set(v):
		if v != happy_eyes:
			happy_eyes = v
			queue_redraw()

var _ears: Array[PackedVector2Array] = []
var _body: PackedVector2Array
var _head: PackedVector2Array
var _arms: Array[PackedVector2Array] = []
var _muzzle: PackedVector2Array
var _gloss: PackedVector2Array
var _star: PackedVector2Array
var _inner_ears: Array[PackedVector2Array] = []


func _init() -> void:
	_ears = [ShapeDraw.ellipse(Vector2(28, 28), Vector2(14, 14)), ShapeDraw.ellipse(Vector2(72, 28), Vector2(14, 14))]
	_inner_ears = [ShapeDraw.ellipse(Vector2(28, 28), Vector2(8, 8), 0.0, 16), ShapeDraw.ellipse(Vector2(72, 28), Vector2(8, 8), 0.0, 16)]
	_body = ShapeDraw.ellipse(Vector2(50, 62), Vector2(34, 30), 0.0, 36)
	_head = ShapeDraw.ellipse(Vector2(50, 46), Vector2(33, 28), 0.0, 36)
	_arms = [ShapeDraw.ellipse(Vector2(22, 68), Vector2(8, 8), 0.0, 16), ShapeDraw.ellipse(Vector2(78, 68), Vector2(8, 8), 0.0, 16)]
	_muzzle = ShapeDraw.ellipse(Vector2(50, 64), Vector2(20, 16), 0.0, 24)
	var g := PackedVector2Array()
	for s in 11:
		g.append(Vector2(28, 36).bezier_interpolate(Vector2(36, 26), Vector2(64, 26), Vector2(72, 36), s / 10.0))
	for s in 11:
		g.append(Vector2(72, 36).bezier_interpolate(Vector2(62, 31), Vector2(38, 31), Vector2(28, 36), s / 10.0))
	_gloss = g
	var raw := PackedVector2Array([
		Vector2(10, 0), Vector2(13, 7), Vector2(20, 8), Vector2(15, 13), Vector2(16, 20),
		Vector2(10, 16), Vector2(4, 20), Vector2(5, 13), Vector2(0, 8), Vector2(7, 7),
	])
	_star = PackedVector2Array()
	for p in raw:
		_star.append((p - Vector2(10, 10)) * 0.95 + Vector2(70, 15))


func _draw() -> void:
	var k := size / 100.0
	draw_set_transform(Vector2(-50, -52) * k, 0.0, Vector2(k, k))

	# Fat brown copies first so the union of all parts gets one clean outline.
	for poly in _ears + [_body, _head] + _arms:
		_outline_pass(poly)
	for poly in _ears:
		_fill_gradient(poly)
	for poly in _inner_ears:
		_fill_soft(poly)
	for poly in _arms:
		_fill_gradient(poly)
	_fill_gradient(_body)
	_fill_gradient(_head)

	draw_colored_polygon(_gloss, Color(1, 1, 1, 0.55))
	draw_colored_polygon(_muzzle, Color(1, 0.84, 0.88, 0.8))
	draw_circle(Vector2(27, 52), 6.0, CHEEK)
	draw_circle(Vector2(73, 52), 6.0, CHEEK)

	if happy_eyes:
		draw_arc(Vector2(38, 46), 6.0, PI * 1.12, PI * 1.88, 10, EYE, 3.6, true)
		draw_arc(Vector2(62, 46), 6.0, PI * 1.12, PI * 1.88, 10, EYE, 3.6, true)
	else:
		for cx in [37.0, 63.0]:
			draw_circle(Vector2(cx, 43), 6.0, EYE)
			draw_circle(Vector2(cx - 2, 41), 2.2, Color.WHITE)
			draw_circle(Vector2(cx + 2, 45), 1.1, Color.WHITE)

	draw_colored_polygon(ShapeDraw.ellipse(Vector2(50, 48), Vector2(4, 3), 0.0, 12), NOSE)
	draw_arc(Vector2(50, 50), 6.0, PI * 0.2, PI * 0.8, 8, NOSE, 2.4, true)

	draw_colored_polygon(_star, Color("fef08a"))
	draw_polyline(ShapeDraw.closed(_star), Color("eab308"), 1.6, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _outline_pass(poly: PackedVector2Array) -> void:
	draw_colored_polygon(poly, UIStyle.BROWN)
	draw_polyline(ShapeDraw.closed(poly), UIStyle.BROWN, STROKE * 2.0, true)


func _fill_gradient(poly: PackedVector2Array) -> void:
	var colors := PackedColorArray()
	for p in poly:
		colors.append(_jelly_at(p.y))
	draw_polygon(poly, colors)


func _fill_soft(poly: PackedVector2Array) -> void:
	var colors := PackedColorArray()
	for p in poly:
		colors.append(SOFT_TOP.lerp(SOFT_BOTTOM, clampf((p.y - 20.0) / 16.0, 0.0, 1.0)))
	draw_polygon(poly, colors)


func _jelly_at(y: float) -> Color:
	var t := clampf((y - 14.0) / 78.0, 0.0, 1.0)
	if t < 0.5:
		return JELLY[0].lerp(JELLY[1], t * 2.0)
	return JELLY[1].lerp(JELLY[2], (t - 0.5) * 2.0)
