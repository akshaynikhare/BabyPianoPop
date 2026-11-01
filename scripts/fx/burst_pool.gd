class_name BurstPool
extends Node2D
## Pre-instanced CPUParticles2D bursts. Each burst kind owns a few emitters used round-robin,
## so overlapping taps never cut each other off and nothing is allocated while playing.

const TEX_SIZE := 32
const COPIES := 4

var _groups := {}
var _next := {}
var _gradients := {}
var _circle: ImageTexture
var _star: ImageTexture


func _init() -> void:
	_circle = _make_texture(false)
	_star = _make_texture(true)


## shapes: "circle", "star" or both; `count` is split across the shapes.
func register(kind: StringName, count: int, spread_deg: float, gravity: float, scalar: float, colors: Array, shapes: Array) -> void:
	var gradient := Gradient.new()
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var pal := PackedColorArray()
	for c in colors:
		pal.append(Color(c))
	gradient.colors = pal
	var offsets := PackedFloat32Array()
	for i in pal.size():
		offsets.append(float(i) / pal.size())
	gradient.offsets = offsets
	_gradients[kind] = gradient

	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])

	var copies: Array = []
	for _c in COPIES:
		var emitters: Array[CPUParticles2D] = []
		for shape in shapes:
			var p := CPUParticles2D.new()
			p.amount = maxi(1, count / shapes.size())
			p.texture = _star if shape == "star" else _circle
			p.one_shot = true
			p.emitting = false
			p.explosiveness = 1.0
			p.local_coords = false
			p.lifetime = 1.7
			p.lifetime_randomness = 0.35
			p.direction = Vector2(0, -1)
			p.spread = spread_deg * 0.5
			p.initial_velocity_min = 600.0
			p.initial_velocity_max = 1350.0
			p.damping_min = 220.0
			p.damping_max = 420.0
			p.gravity = Vector2(0, 1500.0 * gravity)
			p.angle_min = 0.0
			p.angle_max = 360.0
			p.angular_velocity_min = -280.0
			p.angular_velocity_max = 280.0
			p.scale_amount_min = 0.7 * scalar
			p.scale_amount_max = 1.3 * scalar
			p.color_initial_ramp = gradient
			p.color_ramp = fade
			add_child(p)
			emitters.append(p)
		copies.append(emitters)
	_groups[kind] = copies
	_next[kind] = 0


## Fires a burst; `lead_color` (if given) replaces the first palette colour.
func burst(kind: StringName, pos: Vector2, lead_color := Color(0, 0, 0, 0)) -> void:
	if not _groups.has(kind):
		return
	if lead_color.a > 0.0:
		(_gradients[kind] as Gradient).set_color(0, lead_color)
	var copies: Array = _groups[kind]
	var index: int = _next[kind]
	_next[kind] = (index + 1) % copies.size()
	for p in copies[index]:
		var emitter := p as CPUParticles2D
		emitter.position = pos
		emitter.restart()
		emitter.emitting = true


func _make_texture(star: bool) -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(TEX_SIZE, TEX_SIZE) * 0.5
	var poly := PackedVector2Array()
	if star:
		for p in ShapeDraw.star_points(5, TEX_SIZE * 0.5 - 1.0, TEX_SIZE * 0.23):
			poly.append(p + c)
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var hits := 0
			for sy in 3:
				for sx in 3:
					var pt := Vector2(x + (sx + 0.5) / 3.0, y + (sy + 0.5) / 3.0)
					if star:
						if Geometry2D.is_point_in_polygon(pt, poly):
							hits += 1
					elif pt.distance_to(c) <= TEX_SIZE * 0.5 - 1.0:
						hits += 1
			img.set_pixel(x, y, Color(1, 1, 1, hits / 9.0))
	return ImageTexture.create_from_image(img)
