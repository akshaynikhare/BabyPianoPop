class_name CandyTileArt
extends Node2D
## The candy tile drawing, centred on the origin. Rendered once per tile by BakedArt.

const SHAPE_COLORS := {"★": Color("fbbf24"), "♥": Color("f43f5e"), "▲": Color("10b981")}
const FACE := Color("4a2a14")
const BEVEL := 14.0

var _w := 100.0
var _h := 100.0
var _content := ""
var _theme: Dictionary


static func glyph_size(tile_h: float) -> int:
	return int(tile_h * 0.54)


func setup(content: String, w: float, h: float, theme: Dictionary) -> void:
	_content = content
	_w = w
	_h = h
	_theme = theme
	queue_redraw()


## Area to capture: the tile plus its outline and drop shadow.
func bounds() -> Rect2:
	return Rect2(-_w * 0.5 - 12.0, -_h * 0.5 - 12.0, _w + 24.0, _h + 36.0)


func _draw() -> void:
	if _content.is_empty():
		return
	if SHAPE_COLORS.has(_content):
		_draw_vector_shape()
	else:
		_draw_block()


func _draw_block() -> void:
	var is_circle := _content == "●"
	var r := _w * 0.5 if is_circle else _w * 0.2
	var rect := Rect2(-_w * 0.5, -_h * 0.5, _w, _h)
	var shadow: Color = _theme["shadow"]
	draw_style_box(UIStyle.box(Color(0.478, 0.322, 0.2, 0.3), r, 0.0), Rect2(rect.position + Vector2(0, 9), rect.size))
	draw_style_box(UIStyle.box(shadow, r, 6.0), rect)

	var body := Rect2(rect.position + Vector2(6, 6), Vector2(_w - 12.0, _h - 12.0 - BEVEL))
	var poly := ShapeDraw.rounded_rect(body, maxf(r - 6.0, 4.0), 8)
	var colors := PackedColorArray()
	for p in poly:
		colors.append(_candy_at((p.y - body.position.y) / body.size.y))
	draw_polygon(poly, colors)

	var gloss_x := 0.2 if is_circle else 0.12
	var gloss := Rect2(body.position.x + body.size.x * gloss_x, body.position.y + 9.0, body.size.x * (1.0 - gloss_x * 2.0), 20.0)
	draw_colored_polygon(ShapeDraw.rounded_rect(gloss, 10.0, 4), Color(1, 1, 1, 0.5))

	var c := body.get_center()
	if _content == "●" or _content == "■":
		_draw_face(c + Vector2(0, 4), _w / 100.0 * 1.15)
	else:
		var size := glyph_size(_h)
		UIStyle.draw_centered(self, _content, c + Vector2(0, 2), size, Color.WHITE, 700, 9)


func _candy_at(t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	if t < 0.5:
		return (_theme["top"] as Color).lerp(_theme["mid"], t * 2.0)
	return (_theme["mid"] as Color).lerp(_theme["bottom"], (t - 0.5) * 2.0)


func _draw_vector_shape() -> void:
	var k := _w / 100.0
	var pts: PackedVector2Array
	var face_y := 50.0
	match _content:
		"★":
			pts = ShapeDraw.star()
			face_y = 50.0
		"♥":
			pts = ShapeDraw.heart()
			face_y = 42.0
		_:
			pts = ShapeDraw.triangle()
			face_y = 58.0
	var base: Color = SHAPE_COLORS[_content]
	var shadow: Color = _theme["shadow"]
	# Offset copy first: the bevel under the body.
	draw_set_transform(Vector2(-_w * 0.5, -_w * 0.5 + 7.0 * k), 0.0, Vector2(k, k))
	draw_polyline(ShapeDraw.closed(pts), UIStyle.BROWN, 9.0, true)
	draw_colored_polygon(pts, shadow)

	draw_set_transform(Vector2(-_w, -_w) * 0.5, 0.0, Vector2(k, k))
	var colors := PackedColorArray()
	for p in pts:
		var t := clampf((p.y - 8.0) / 78.0, 0.0, 1.0)
		colors.append(base.lightened(0.28).lerp(base.darkened(0.12), t))
	draw_polygon(pts, colors)
	draw_polyline(ShapeDraw.closed(pts), UIStyle.BROWN, 4.6, true)

	var gloss_at := Vector2(36, 24)
	var gloss_r := Vector2(13, 6)
	var gloss_rot := -0.45
	if _content == "★":
		gloss_at = Vector2(45, 31)
		gloss_r = Vector2(8, 4)
		gloss_rot = -1.0
	elif _content == "▲":
		gloss_at = Vector2(46, 44)
		gloss_r = Vector2(9, 4.5)
		gloss_rot = -1.05
	draw_colored_polygon(ShapeDraw.ellipse(gloss_at, gloss_r, gloss_rot, 14), Color(1, 1, 1, 0.6))
	_draw_face_design(face_y)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Face for the shape tiles, in the 100-unit design box (transform already applied).
func _draw_face_design(y: float) -> void:
	for dx in [-8.0, 8.0]:
		draw_circle(Vector2(50 + dx, y), 3.8, FACE)
		draw_circle(Vector2(50 + dx - 1.1, y - 1.4), 1.3, Color.WHITE)
		draw_circle(Vector2(50 + dx * 2.1, y + 4.5), 3.2, Color(1, 0.45, 0.55, 0.45))
	draw_arc(Vector2(50, y + 3.0), 5.2, PI * 0.18, PI * 0.82, 8, FACE, 2.4, true)


## Face for round / square candies, drawn in tile pixels around `center`.
func _draw_face(center: Vector2, k: float) -> void:
	draw_set_transform(center, 0.0, Vector2(k, k))
	for dx in [-17.0, 17.0]:
		draw_circle(Vector2(dx, -6), 5.6, FACE)
		draw_circle(Vector2(dx - 1.6, -8), 1.9, Color.WHITE)
		draw_circle(Vector2(dx * 1.75, 8), 4.6, Color(1, 1, 1, 0.35))
	draw_arc(Vector2(0, 2), 9.0, PI * 0.15, PI * 0.85, 8, FACE, 3.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
