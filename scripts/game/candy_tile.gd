class_name CandyTile
extends Node2D
## One pooled candy tile. The art is baked once per configure(); moving, pulsing and the
## stuck badge only change transforms. Origin is the tile centre.

signal released(tile: CandyTile)

const PULSE_SECONDS := 1.2

var data: TileRules.Tile

var _w := 100.0
var _h := 100.0
var _baked := BakedArt.new()
var _art := CandyTileArt.new()
var _glow := _Glow.new()
var _badge := _Badge.new()
var _t := 0.0
var _tween: Tween


class _Glow extends Node2D:
	var half := Vector2(50, 50)
	var radius := 30.0
	var color := Color(0.992, 0.878, 0.278, 0.2)

	func _init() -> void:
		show_behind_parent = true

	func _draw() -> void:
		for i in 5:
			var grow := 5.0 + i * 7.0
			var r := Rect2(-half - Vector2(grow, grow), (half + Vector2(grow, grow)) * 2.0)
			draw_style_box(UIStyle.box(color, radius + grow, 0.0), r)


class _Badge extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2(0, 3), 30.0, UIStyle.BROWN_SOFT)
		draw_circle(Vector2.ZERO, 30.0, UIStyle.BROWN)
		draw_circle(Vector2.ZERO, 24.5, Color("fcd34d"))
		draw_circle(Vector2(-5, -6), 11.0, Color(1, 1, 1, 0.35))
		var pts := ShapeDraw.star_points(5, 15.0, 7.0)
		draw_colored_polygon(pts, Color("fffbeb"))
		draw_polyline(ShapeDraw.closed(pts), UIStyle.BROWN, 2.6, true)


func _init() -> void:
	add_child(_glow)
	add_child(_baked)
	add_child(_badge)
	_glow.visible = false
	_badge.visible = false
	set_process(false)
	visible = false


## Shows `tile` here. With `animate` the tile fades and pops in; otherwise it only re-bakes (after a resize).
func configure(tile: TileRules.Tile, animate := true) -> void:
	data = tile
	tile.view = self
	_w = tile.w
	_h = tile.h
	var theme: Dictionary = GameContent.THEMES[tile.candy_index]
	_art.setup(tile.content, _w, _h, theme)
	_baked.bake(_art, _art.bounds(), BakedArt.window_scale(get_viewport()))

	var round_glow := tile.is_shape and tile.content != "■"
	_glow.half = Vector2(_w, _h) * 0.5
	_glow.radius = _w * 0.5 if round_glow else _w * 0.2
	_glow.queue_redraw()
	_badge.position = Vector2(_w * 0.5 - 8.0, -_h * 0.5 + 8.0)
	position = Vector2(tile.x + _w * 0.5, tile.y + _h * 0.5)
	if not animate:
		return

	_t = 0.0
	scale = Vector2.ONE
	rotation = 0.0
	set_process(false)
	_glow.visible = false
	_badge.visible = false
	modulate.a = 0.0
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.2).from(Vector2.ONE * 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_stuck(on: bool) -> void:
	_glow.visible = on
	_badge.visible = on
	_t = 0.0
	set_process(on)
	if not on:
		scale = Vector2.ONE


func play_pop() -> void:
	set_process(false)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", scale * 1.3, 0.16).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, 0.16)
	_tween.chain().tween_callback(_release)


func _release() -> void:
	visible = false
	_glow.visible = false
	_badge.visible = false
	data = null
	released.emit(self)


func recycle_now() -> void:
	if _tween:
		_tween.kill()
	set_process(false)
	_release()


func _process(delta: float) -> void:
	_t += delta
	var phase := TAU * _t / PULSE_SECONDS
	var s := 1.05 - 0.03 * cos(phase)
	scale = Vector2(s, s)
	_glow.modulate.a = 0.55 - 0.45 * cos(phase)
	_badge.rotation += TAU * 0.25 * delta
	_badge.scale = Vector2.ONE * (1.07 - 0.07 * cos(phase))
