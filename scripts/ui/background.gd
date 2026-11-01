class_name Background
extends ColorRect
## Palette gradient + polka dots drawn by one shader; palette changes ease over a second.

const SHADER := preload("res://shaders/pastel_dots.gdshader")
const FADE_SECONDS := 1.0

var _mat := ShaderMaterial.new()
var _current: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var _from: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var _to: Array[Color] = [Color.WHITE, Color.WHITE, Color.WHITE]
var _tween: Tween
var _index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat.shader = SHADER
	material = _mat
	resized.connect(_update_size)
	_update_size()


func _update_size() -> void:
	_mat.set_shader_parameter("rect_size", size)


func set_palette(index: int, instant := false) -> void:
	if index == _index:
		return
	_index = index
	var p: Dictionary = GameContent.PALETTES[index]
	_from = _current.duplicate()
	_to = [p["top"], p["mid"], p["bottom"]]
	if _tween:
		_tween.kill()
	if instant:
		_apply(1.0)
		return
	_tween = create_tween()
	_tween.tween_method(_apply, 0.0, 1.0, FADE_SECONDS)


func _apply(t: float) -> void:
	for i in 3:
		_current[i] = _from[i].lerp(_to[i], t)
	_mat.set_shader_parameter("top_color", _current[0])
	_mat.set_shader_parameter("mid_color", _current[1])
	_mat.set_shader_parameter("bottom_color", _current[2])
