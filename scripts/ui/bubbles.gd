class_name Bubbles
extends Node2D
## 16 translucent bubbles drifting up. Sprites share one texture, so only transforms change per frame.

const COUNT := 16
const TEX_SIZE := 64

var _sprites: Array[Sprite2D] = []
var _left := PackedFloat32Array()
var _duration := PackedFloat32Array()
var _offset := PackedFloat32Array()
var _sway := PackedFloat32Array()
var _time := 0.0
var _view := Vector2(720, 1600)


func _ready() -> void:
	var tex := _make_texture()
	for i in COUNT:
		var s := Sprite2D.new()
		s.texture = tex
		var size := 18 + (i * 17 + 7) % 36
		s.scale = Vector2.ONE * (size * 2.0 / TEX_SIZE)
		s.modulate = Color(1, 1, 1, 0.22 + float((i * 5) % 18) / 100.0)
		add_child(s)
		_sprites.append(s)
		_left.append(float((i * 23 + 11) % 94 + 3) / 100.0)
		_duration.append(float(14 + (i * 7) % 12))
		_offset.append(fmod(i * 3.5, 16.0))
		_sway.append(3.5 + fmod(i * 1.8, 4.0))
	get_viewport().size_changed.connect(_on_resized)
	_on_resized()
	_process(0.0)


func _on_resized() -> void:
	_view = get_viewport_rect().size


func _process(delta: float) -> void:
	_time += delta
	for i in COUNT:
		var progress := fposmod((_time + _offset[i]) / _duration[i], 1.0)
		var y := lerpf(1.05, -0.15, progress) * _view.y
		var x := _left[i] * _view.x + sin(TAU * _time / _sway[i]) * 18.0
		_sprites[i].position = Vector2(x, y)


func _make_texture() -> ImageTexture:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var c := (TEX_SIZE - 1) * 0.5
	for py in TEX_SIZE:
		for px in TEX_SIZE:
			var d := Vector2(px - c, py - c).length() / (TEX_SIZE * 0.5)
			var a := 0.0
			if d < 1.0:
				a = 0.4
				a += 0.9 * smoothstep(0.72, 0.9, d) * (1.0 - smoothstep(0.94, 1.0, d))
				var h := Vector2(px - c * 0.62, py - c * 0.55).length() / (TEX_SIZE * 0.5)
				a += 0.8 * (1.0 - smoothstep(0.08, 0.17, h))
			img.set_pixel(px, py, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
