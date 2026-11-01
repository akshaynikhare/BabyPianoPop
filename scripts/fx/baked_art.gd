class_name BakedArt
extends Node2D
## Draws a node once into a SubViewport and shows the result as a single sprite, so a busy
## drawing costs one draw call per frame. Call rebake() whenever the drawing changes.

const UNPREMULTIPLY := preload("res://shaders/unpremultiply.gdshader")

static var _material: ShaderMaterial

var art: Node2D

var _vp := SubViewport.new()
var _sprite := Sprite2D.new()


func _init() -> void:
	_vp.transparent_bg = true
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_sprite.centered = false
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = UNPREMULTIPLY
	_sprite.material = _material
	add_child(_vp)
	add_child(_sprite)


## Real screen pixels per base unit, so baked art stays sharp on dense phone screens.
static func window_scale(viewport: Viewport) -> float:
	var base := viewport.get_visible_rect().size.x
	if base <= 0.0:
		return 1.0
	return clampf(float(viewport.get_window().size.x) / base, 1.0, 3.0)


## `rect` is the area of `drawing` (in its own coordinates) to capture; `pixel_scale` is texture pixels per unit.
func bake(drawing: Node2D, rect: Rect2, pixel_scale: float) -> void:
	if art != drawing:
		if art != null:
			art.queue_free()
		art = drawing
		_vp.add_child(art)
	var px := Vector2i(maxi(1, ceili(rect.size.x * pixel_scale)), maxi(1, ceili(rect.size.y * pixel_scale)))
	if _vp.size != px:
		_vp.size = px
	_vp.canvas_transform = Transform2D(0.0, Vector2(pixel_scale, pixel_scale), 0.0, -rect.position * pixel_scale)
	_sprite.texture = _vp.get_texture()
	_sprite.position = rect.position
	_sprite.scale = Vector2.ONE / pixel_scale
	rebake()


func rebake() -> void:
	if art != null:
		art.queue_redraw()
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
