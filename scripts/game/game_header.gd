class_name GameHeader
extends Node2D
## Fixed header: Jelly Bear, three-star pill and the parent-gate gear. Drawn in a 100-unit-tall
## design space and scaled by `unit`; the static art is baked into a few sprites.
## Input is handled by the gameplay scene; this node only draws and animates.

const HEIGHT := 100.0
const PILL_SIZE := Vector2(172, 56)
const GEAR_RING := 40.0
const GEAR_SCALE := 0.8

var mascot := JellyBear.new(88.0)
var pill := _Pill.new()
var gear := _Gear.new()
var unit := 1.0
var view_w := 720.0

var _band := BakedArt.new()
var _band_art := _BandArt.new()


class _BandArt extends Node2D:
	var width := 720.0
	var pill_center := Vector2.ZERO
	var gear_center := Vector2.ZERO

	func _draw() -> void:
		draw_style_box(UIStyle.box(UIStyle.BROWN_SOFT, 32.0, 0.0), Rect2(-12, -50, width + 24, GameHeader.HEIGHT + 50 + 9))
		draw_style_box(UIStyle.box(UIStyle.CREAM, 32.0, 5.0), Rect2(-12, -50, width + 24, GameHeader.HEIGHT + 50))
		var r := Rect2(pill_center - GameHeader.PILL_SIZE * 0.5, GameHeader.PILL_SIZE)
		draw_style_box(UIStyle.box(UIStyle.BROWN_SOFT, 28.0, 0.0), Rect2(r.position + Vector2(0, 6), r.size))
		draw_set_transform(gear_center + Vector2(0, 4), 0.0, Vector2.ONE * GameHeader.GEAR_SCALE)
		draw_colored_polygon(ShapeDraw.gear(), UIStyle.BROWN_SOFT)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _StarArt extends Node2D:
	var filled := false

	func _draw() -> void:
		var pts := ShapeDraw.star_points(5, 18.0, 8.5)
		if filled:
			draw_colored_polygon(pts, Color("fde047"))
			draw_polyline(ShapeDraw.closed(pts), UIStyle.BROWN, 3.6, true)
			draw_colored_polygon(ShapeDraw.ellipse(Vector2(-4.5, -6), Vector2(4, 2.4), -0.6, 8), Color(1, 1, 1, 0.7))
		else:
			draw_colored_polygon(pts, Color(1, 1, 1, 0.5))
			draw_polyline(ShapeDraw.closed(pts), Color(0.478, 0.322, 0.2, 0.55), 3.2, true)


class _StarIcon extends Node2D:
	var baked := BakedArt.new()
	var art := _StarArt.new()
	var filled := false:
		set(v):
			filled = v
			art.filled = v
			baked.rebake()

	func _init() -> void:
		add_child(baked)

	func bake(pixel_scale: float) -> void:
		baked.bake(art, Rect2(-26, -26, 52, 52), pixel_scale)


class _PillArt extends Node2D:
	var color := Color("a855f7")

	func _draw() -> void:
		var r := Rect2(-GameHeader.PILL_SIZE * 0.5, GameHeader.PILL_SIZE)
		draw_style_box(UIStyle.box(color, 28.0, 5.0), r)
		draw_style_box(UIStyle.box(Color(1, 1, 1, 0.3), 5.0, 0.0), Rect2(r.position.x + 28, r.position.y + 8, r.size.x - 56, 9))


class _Pill extends Node2D:
	var color := Color("a855f7"):
		set(v):
			color = v
			art.color = v
			baked.rebake()
	var baked := BakedArt.new()
	var art := _PillArt.new()
	var icons: Array[_StarIcon] = []

	func _init() -> void:
		add_child(baked)
		for i in 3:
			var s := _StarIcon.new()
			s.position = Vector2((i - 1) * 50.0, 0)
			add_child(s)
			icons.append(s)

	func bake(pixel_scale: float) -> void:
		art.color = color
		var r := Rect2(-GameHeader.PILL_SIZE * 0.5 - Vector2(4, 4), GameHeader.PILL_SIZE + Vector2(8, 8))
		baked.bake(art, r, pixel_scale)
		for icon in icons:
			icon.bake(pixel_scale)

	func set_stars(count: int) -> void:
		for i in 3:
			var on := count > i
			var icon := icons[i]
			if on and not icon.filled:
				icon.filled = true
				var t := icon.create_tween().set_parallel(true)
				t.tween_property(icon, "scale", Vector2.ONE * 1.3, 0.12).set_ease(Tween.EASE_OUT)
				t.tween_property(icon, "rotation", deg_to_rad(14.0), 0.12)
				t.chain().tween_property(icon, "scale", Vector2.ONE, 0.18)
				t.parallel().tween_property(icon, "rotation", 0.0, 0.18)
			elif not on:
				icon.filled = false


class _GearArt extends Node2D:
	func _draw() -> void:
		var pts := ShapeDraw.gear()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * GameHeader.GEAR_SCALE)
		draw_colored_polygon(pts, UIStyle.CREAM)
		draw_polyline(ShapeDraw.closed(pts), UIStyle.BROWN, 5.0, true)
		draw_circle(Vector2.ZERO, 12.0, UIStyle.CREAM_SHADE)
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 20, UIStyle.BROWN, 4.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class _Gear extends Node2D:
	var body := Node2D.new()
	var baked := BakedArt.new()
	var art := _GearArt.new()
	var progress := 0.0:
		set(v):
			if v != progress:
				progress = v
				queue_redraw()

	func _init() -> void:
		body.add_child(baked)
		add_child(body)

	func bake(pixel_scale: float) -> void:
		baked.bake(art, Rect2(-40, -40, 80, 80), pixel_scale)

	func wobble() -> void:
		var t := body.create_tween()
		for deg in [90.0, -45.0, 30.0, 0.0]:
			t.tween_property(body, "rotation", deg_to_rad(deg), 0.11).set_trans(Tween.TRANS_SINE)

	func _draw() -> void:
		if progress <= 0.0:
			return
		draw_arc(Vector2.ZERO, GameHeader.GEAR_RING, 0.0, TAU, 40, Color(0.478, 0.322, 0.2, 0.18), 9.0, true)
		var segs := 48
		var n := ceili(progress * segs)
		var a0 := -PI * 0.5
		var pink := Color("ec4899")
		var purple := Color("8b5cf6")
		for i in n:
			var f0 := float(i) / segs
			var f1 := minf(float(i + 1) / segs, progress)
			draw_arc(Vector2.ZERO, GameHeader.GEAR_RING, a0 + TAU * f0, a0 + TAU * f1 + 0.02, 3, pink.lerp(purple, f0), 9.0, true)


func _init() -> void:
	add_child(_band)
	add_child(pill)
	add_child(gear)
	add_child(mascot)


## `width` is the screen width in base units; everything is drawn at `new_unit` times its design size.
func layout(width: float, new_unit := 1.0) -> void:
	unit = new_unit
	view_w = width
	scale = Vector2(unit, unit)
	var w := width / unit
	mascot.position = Vector2(72, 52)
	pill.position = Vector2(w * 0.5, 50)
	gear.position = Vector2(w - 64, 50)
	_band_art.width = w
	_band_art.pill_center = pill.position
	_band_art.gear_center = gear.position
	var k := BakedArt.window_scale(get_viewport()) * unit
	_band.bake(_band_art, Rect2(-12, -50, w + 24, HEIGHT + 50 + 16), k)
	pill.bake(k)
	gear.bake(k)
	mascot.bake()


func mascot_rect() -> Rect2:
	return _screen(Rect2(0, 0, 140, HEIGHT))


func pill_rect() -> Rect2:
	return _screen(Rect2(view_w / unit * 0.5 - 96, 6, 192, 88))


func gear_rect() -> Rect2:
	return _screen(Rect2(view_w / unit - 130, 0, 130, HEIGHT))


func _screen(r: Rect2) -> Rect2:
	return Rect2(r.position * unit, r.size * unit)
