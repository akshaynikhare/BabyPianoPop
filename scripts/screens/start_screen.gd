class_name StartScreen
extends Control
## Mascot, age picker and the pulsing PLAY button.

signal play_pressed

var fx: BurstPool

var _mascot := JellyBear.new(250.0)
var _age := AgeSelector.new()
var _panel := _Panel.new()
var _play := CozyButton.new()
var _title := _Title.new()
var _mascot_taps := 0
var _started := false
var _pulse: Tween


class _Panel extends Control:
	func _draw() -> void:
		draw_style_box(UIStyle.box(UIStyle.BROWN_SOFT, 36.0, 0.0), Rect2(0, 12, size.x, size.y - 12))
		draw_style_box(UIStyle.box(UIStyle.CREAM, 36.0, 6.0), Rect2(0, 0, size.x, size.y - 12))


## Renders every tile glyph once, off screen and through the same bake path as the tiles, so the
## font cache is warm before the first tile falls.
class _GlyphSheet extends Node2D:
	var cell := Vector2(160, 160)
	var size := 100

	func _draw() -> void:
		var f := UIStyle.font(700)
		var chars := GameContent.ALPHABET + GameContent.NUMBERS
		for i in chars.size():
			var c := Vector2(i % 6, i / 6) * cell + cell * 0.5
			UIStyle.draw_centered(self, chars[i], c, size, Color.WHITE, 700, 9)


class _Title extends Control:
	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 0)
		UIStyle.draw_centered(self, "Baby Piano Pop", c + Vector2(0, 8), 84, Color.WHITE, 700, 16)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)

	_prewarm_glyphs()

	_mascot.rest_mood = &"happy"
	add_child(_mascot)

	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	_panel.add_child(_age)
	_age.tier_chosen.connect(_on_tier_chosen)

	_play.text = "PLAY"
	_play.font_size = 78
	_play.fill = Color("ff8fb1")
	_play.text_color = Color.WHITE
	_play.text_outline = 8
	_play.radius = 56.0
	_play.depth = 14.0
	_play.on_press = true
	_play.icon = CozyButton.Icon.PLAY_DECOR
	_play.activated.connect(_on_play)
	add_child(_play)

	get_viewport().size_changed.connect(_layout)
	_layout()

	_pulse = create_tween().set_loops()
	_pulse.tween_property(_play, "scale", Vector2.ONE * 1.04, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse.tween_property(_play, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_mascot.modulate.a = 0.0
	_mascot.scale = Vector2.ONE * 0.8
	var intro := create_tween().set_parallel(true)
	intro.tween_property(_mascot, "modulate:a", 1.0, 0.4)
	intro.tween_property(_mascot, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _prewarm_glyphs() -> void:
	var view := get_viewport_rect().size
	var probe := TileRules.new()
	probe.set_viewport(view.x, view.y)
	var sheet := _GlyphSheet.new()
	sheet.size = CandyTileArt.glyph_size(probe.board_w * 0.23 * 4.0 / 3.0)
	var baked := BakedArt.new()
	baked.visible = false
	add_child(baked)
	baked.bake(sheet, Rect2(0, 0, 960, 960), BakedArt.window_scale(get_viewport()))
	get_tree().create_timer(0.5, false).timeout.connect(baked.queue_free)


func _layout() -> void:
	var vw := get_viewport_rect().size.x
	var vh := get_viewport_rect().size.y
	var pw := minf(660.0, vw - 40.0)
	var ph := AgeSelector.TOTAL_H + 56.0
	var unit := vh / 1600.0

	_title.size = Vector2(vw, 0)
	_title.position = Vector2(0, vh * 0.1)
	_mascot.position = Vector2(vw * 0.5, vh * 0.1 + 250.0 * unit)
	_panel.size = Vector2(pw, ph)
	_panel.position = Vector2((vw - pw) * 0.5, vh * 0.1 + 400.0 * unit)
	_age.position = Vector2(28, 28)
	_age.size = Vector2(pw - 56.0, AgeSelector.TOTAL_H)
	_panel.queue_redraw()
	_play.size = Vector2(500, 164)
	_play.position = Vector2((vw - 500.0) * 0.5, _panel.position.y + ph + 70.0 * unit)
	_play.pivot_offset = _play.size * 0.5


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.distance_to(_mascot.position) < 125.0:
			_mascot_tap()


func _on_tier_chosen(_tier: String) -> void:
	_mascot.set_mood(&"happy", 1400)


func _mascot_tap() -> void:
	AudioDirector.play_sfx(&"giggle")
	_mascot.set_mood(&"celebrate", 1200)
	AudioDirector.play_voice(StringName("mascot_%d" % (_mascot_taps % GameContent.MASCOT_PHRASE_COUNT)))
	_mascot_taps += 1
	if fx:
		fx.burst(&"mascot", _mascot.position + Vector2(0, -60))


func _on_play() -> void:
	if _started:
		return
	_started = true
	_mascot.set_mood(&"happy", 1500)
	play_pressed.emit()
