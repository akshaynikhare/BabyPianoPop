class_name CozyButton
extends Control
## Chunky cream button drawn in one pass: offset shadow, bordered body, gloss and a pressed dip.

signal activated

enum Icon { NONE, CLOSE, PLAY_DECOR }

var text := "":
	set(v):
		text = v
		queue_redraw()
var subtext := "":
	set(v):
		subtext = v
		queue_redraw()
var font_size := 44
var sub_size := 26
var fill := UIStyle.CREAM:
	set(v):
		fill = v
		queue_redraw()
var text_color := UIStyle.TEXT
var text_outline := 0
var radius := 30.0
var depth := 9.0
var on_press := false
var icon := Icon.NONE
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var press := 0.0:
	set(v):
		press = v
		queue_redraw()

var _down := false
var _fired := false
var _tween: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	resized.connect(_update_pivot)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if event.pressed:
		_down = true
		_fired = on_press
		_dip(1.0)
		if _fired:
			activated.emit()
	elif _down:
		_down = false
		_dip(0.0)
		if not _fired and Rect2(Vector2.ZERO, size).has_point(event.position):
			activated.emit()
		_fired = false
	accept_event()


func _dip(target: float) -> void:
	if _tween:
		_tween.kill()
	if not is_inside_tree():
		press = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "press", target, 0.07)


func _draw() -> void:
	var dip := press if not selected else maxf(press, 0.6)
	var face_h := size.y - depth
	draw_style_box(UIStyle.box(UIStyle.BROWN_SOFT, radius, 0.0), Rect2(0, depth, size.x, face_h))
	var body := Rect2(0, depth * dip, size.x, face_h)
	draw_style_box(UIStyle.box(fill, radius, 5.0), body)
	var gloss_h := minf(16.0, face_h * 0.2)
	draw_style_box(UIStyle.box(Color(1, 1, 1, 0.38), gloss_h * 0.5, 0.0), Rect2(body.position.x + radius, body.position.y + 9.0, size.x - radius * 2.0, gloss_h))
	_draw_content(body)


func _draw_content(body: Rect2) -> void:
	var c := body.get_center()
	match icon:
		Icon.CLOSE:
			var r := minf(body.size.x, body.size.y) * 0.2
			draw_line(c + Vector2(-r, -r), c + Vector2(r, r), UIStyle.BROWN, 9.0, true)
			draw_line(c + Vector2(-r, r), c + Vector2(r, -r), UIStyle.BROWN, 9.0, true)
			draw_circle(c + Vector2(-r, -r), 4.5, UIStyle.BROWN)
			draw_circle(c + Vector2(r, r), 4.5, UIStyle.BROWN)
			draw_circle(c + Vector2(-r, r), 4.5, UIStyle.BROWN)
			draw_circle(c + Vector2(r, -r), 4.5, UIStyle.BROWN)
			return
		Icon.PLAY_DECOR:
			var f := UIStyle.font(700)
			var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			UIStyle.draw_sparkle(self, c + Vector2(-w * 0.5 - 52, -6), 24.0, Color("fef08a"))
			UIStyle.draw_heart(self, c + Vector2(w * 0.5 + 50, -4), 46.0, Color("ffd1dc"))
	if subtext.is_empty():
		UIStyle.draw_centered(self, text, c, font_size, text_color, 700, text_outline)
		return
	var f2 := UIStyle.font(700)
	var box_w := body.size.x - 24.0
	var title_h := f2.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, box_w, font_size).y
	var total := sub_size + 8.0 + title_h
	var top := c.y - total * 0.5
	UIStyle.draw_centered(self, subtext, Vector2(c.x, top + sub_size * 0.5), sub_size, text_color.lerp(UIStyle.TEXT_SOFT, 0.4) if not selected else text_color, 600)
	var pos := Vector2(body.position.x + 12.0, top + sub_size + 8.0 + f2.get_ascent(font_size))
	draw_multiline_string(f2, pos, text, HORIZONTAL_ALIGNMENT_CENTER, box_w, font_size, -1, text_color)
