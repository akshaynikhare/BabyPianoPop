class_name UIStyle
extends RefCounted
## Cozy-pastel look: warm-brown outlines, cream surfaces, one rounded font.

const BROWN := Color("7A5233")
const BROWN_SOFT := Color(0.478, 0.322, 0.2, 0.35)
const TEXT := Color("5A3A22")
const TEXT_SOFT := Color("9A7552")
const CREAM := Color("FFF6E3")
const CREAM_SHADE := Color("F3DDB8")
const WHITE := Color.WHITE
const PLAY_TOP := Color("ff8fb1")
const MINT := Color("86e3b5")

## OpenType tag "wght" as an integer.
const WGHT_TAG := 2003265652

static var _fonts := {}
static var _boxes := {}


static func font(weight := 600) -> Font:
	if not _fonts.has(weight):
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/Fredoka.ttf")
		fv.variation_opentype = {WGHT_TAG: weight}
		_fonts[weight] = fv
	return _fonts[weight]


## Cached anti-aliased rounded box with a brown border.
static func box(fill: Color, radius: float, border := 5.0, border_color := BROWN) -> StyleBoxFlat:
	var key := "%s|%s|%s|%s" % [fill.to_html(true), radius, border, border_color.to_html(true)]
	if not _boxes.has(key):
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.set_corner_radius_all(int(radius))
		sb.set_border_width_all(int(border))
		sb.border_color = border_color
		sb.anti_aliasing = true
		sb.corner_detail = 10
		_boxes[key] = sb
	return _boxes[key]


## Draws text centered on `center` (vertically by cap height) with an optional outline.
static func draw_centered(ci: CanvasItem, text: String, center: Vector2, size: int, color: Color, weight := 700, outline := 0, outline_color := BROWN) -> void:
	var f := font(weight)
	var width := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(center.x - width * 0.5, center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5)
	if outline > 0:
		ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, outline_color)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_heart(ci: CanvasItem, center: Vector2, size: float, fill: Color, line := 3.0) -> void:
	ci.draw_set_transform(center - Vector2(size, size) * 0.5, 0.0, Vector2(size, size) / 100.0)
	ci.draw_colored_polygon(ShapeDraw.heart(), fill)
	ci.draw_polyline(ShapeDraw.closed(ShapeDraw.heart()), BROWN, line * 100.0 / size, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_sparkle(ci: CanvasItem, center: Vector2, radius: float, fill: Color, line := 3.0) -> void:
	var pts := ShapeDraw.star_points(4, radius, radius * 0.38)
	for i in pts.size():
		pts[i] += center
	ci.draw_colored_polygon(pts, fill)
	ci.draw_polyline(ShapeDraw.closed(pts), BROWN, line, true)
