class_name ToggleRow
extends CozyButton
## Full-width setting row: round badge, label, and an ON / OFF pill.

enum Kind { MUSIC, CHEERS }

var kind := Kind.MUSIC
var on := true:
	set(v):
		on = v
		fill = UIStyle.CREAM if on else UIStyle.CREAM_SHADE
		queue_redraw()
var label := ""
var note := ""


func _draw_content(body: Rect2) -> void:
	var cy := body.get_center().y
	var badge_c := Vector2(body.position.x + 56.0, cy)
	var badge_fill := Color("ff9ec1") if kind == Kind.CHEERS else Color("b7a1ff")
	draw_circle(badge_c, 33.0, UIStyle.BROWN)
	draw_circle(badge_c, 28.0, badge_fill if on else Color("d8cbb5"))
	if kind == Kind.MUSIC:
		_draw_note(badge_c)
	else:
		UIStyle.draw_sparkle(self, badge_c + Vector2(-5, 4), 17.0, Color("fef08a"), 2.6)
		UIStyle.draw_sparkle(self, badge_c + Vector2(11, -12), 8.0, Color.WHITE, 2.2)

	var f := UIStyle.font(700)
	var text_x := body.position.x + 112.0
	if note.is_empty():
		draw_string(f, Vector2(text_x, cy + (f.get_ascent(38) - f.get_descent(38)) * 0.5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, UIStyle.TEXT)
	else:
		draw_string(f, Vector2(text_x, cy - 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, UIStyle.TEXT)
		draw_string(UIStyle.font(500), Vector2(text_x, cy + 30.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, UIStyle.TEXT_SOFT)

	var pill := Rect2(body.end.x - 128.0, cy - 29.0, 108.0, 58.0)
	draw_style_box(UIStyle.box(Color("86e3b5") if on else Color("e6d5b8"), 29.0, 4.0), pill)
	UIStyle.draw_centered(self, "ON" if on else "OFF", pill.get_center(), 30, UIStyle.TEXT, 700)


func _draw_note(c: Vector2) -> void:
	draw_circle(c + Vector2(-7, 11), 8.0, Color.WHITE)
	draw_line(c + Vector2(0, 11), c + Vector2(0, -15), Color.WHITE, 5.0, true)
	draw_line(c + Vector2(0, -15), c + Vector2(13, -9), Color.WHITE, 5.0, true)
	if not on:
		draw_line(c + Vector2(-19, -19), c + Vector2(19, 19), UIStyle.BROWN, 5.0, true)
