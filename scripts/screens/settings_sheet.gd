class_name SettingsSheet
extends Control
## Parent settings: age, music, praise mode and quiet mode. The game halts while this is open.

const PANEL_W := 640.0
const PAD := 32.0

var _dim := ColorRect.new()
var _panel := _Panel.new()
var _title := _Title.new()
var _age := AgeSelector.new()
var _music := ToggleRow.new()
var _cheers := ToggleRow.new()
var _quiet := ToggleRow.new()
var _done := CozyButton.new()
var _close := CozyButton.new()
var _tween: Tween


class _Panel extends Control:
	func _draw() -> void:
		draw_style_box(UIStyle.box(UIStyle.BROWN_SOFT, 36.0, 0.0), Rect2(0, 12, size.x, size.y - 12))
		draw_style_box(UIStyle.box(UIStyle.CREAM, 36.0, 6.0), Rect2(0, 0, size.x, size.y - 12))


class _Title extends Control:
	var items: Array[Array] = []

	func _draw() -> void:
		for it in items:
			var f := UIStyle.font(700)
			draw_string(f, it[1], it[0], HORIZONTAL_ALIGNMENT_LEFT, -1, it[2], it[3])


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_dim.color = Color(0.42, 0.28, 0.16, 0.45)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_title)

	_panel.add_child(_age)

	_music.kind = ToggleRow.Kind.MUSIC
	_music.label = "Music"
	_panel.add_child(_music)
	_music.activated.connect(_toggle_music)

	_cheers.kind = ToggleRow.Kind.CHEERS
	_cheers.label = "Jelly Bear Cheers"
	_cheers.note = "Praise every 3 stars"
	_panel.add_child(_cheers)
	_cheers.activated.connect(_toggle_cheers)

	_quiet.kind = ToggleRow.Kind.QUIET
	_quiet.label = "Quiet Mode"
	_quiet.note = "Softer for sleepy time"
	_panel.add_child(_quiet)
	_quiet.activated.connect(_toggle_quiet)

	_done.text = "Done"
	_done.font_size = 52
	_done.fill = Color("ff9ec1")
	_done.text_color = Color.WHITE
	_done.text_outline = 6
	_done.activated.connect(close)
	_panel.add_child(_done)

	_close.icon = CozyButton.Icon.CLOSE
	_close.radius = 36.0
	_close.activated.connect(close)
	_panel.add_child(_close)

	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var vw := get_viewport_rect().size.x
	var vh := get_viewport_rect().size.y
	var w := minf(PANEL_W, vw - 48.0)
	var y := PAD + 6.0
	var inner := w - PAD * 2.0

	_title.position = Vector2.ZERO
	_title.items = [
		["Settings", Vector2(PAD, y + 62.0), 58, UIStyle.TEXT],
		["AGE", Vector2(PAD, y + 150.0), 28, UIStyle.TEXT_SOFT],
	]
	_title.queue_redraw()
	_close.position = Vector2(w - PAD - 84.0, y - 4.0)
	_close.size = Vector2(84, 92)
	y += 168.0
	_age.position = Vector2(PAD, y)
	_age.size = Vector2(inner, AgeSelector.TOTAL_H)
	y += AgeSelector.TOTAL_H + 22.0
	_music.position = Vector2(PAD, y)
	_music.size = Vector2(inner, 112)
	y += 112.0 + 20.0
	_cheers.position = Vector2(PAD, y)
	_cheers.size = Vector2(inner, 124)
	y += 124.0 + 20.0
	_quiet.position = Vector2(PAD, y)
	_quiet.size = Vector2(inner, 124)
	y += 124.0 + 30.0
	_done.position = Vector2(PAD, y)
	_done.size = Vector2(inner, 116)
	y += 116.0 + PAD + 12.0

	_panel.size = Vector2(w, y)
	_panel.position = Vector2((vw - w) * 0.5, maxf(24.0, (vh - y) * 0.5))
	_panel.pivot_offset = _panel.size * 0.5
	_panel.queue_redraw()


func open() -> void:
	_music.on = bool(Settings.get_value(&"music_on"))
	_cheers.on = bool(Settings.get_value(&"praise_mode"))
	_quiet.on = bool(Settings.get_value(&"quiet_mode"))
	var saved: Variant = Settings.get_value(&"age_tier")
	_age.set_tier(saved if GameContent.is_valid_tier(saved) else GameContent.DEFAULT_TIER, true)
	_layout()
	visible = true
	AudioDirector.play_sfx(&"ui_open")
	_animate(true)
	EventBus.settings_opened.emit()


func close() -> void:
	if not visible:
		return
	AudioDirector.play_sfx(&"ui_close")
	_animate(false)
	EventBus.settings_closed.emit()


func _animate(opening: bool) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	if opening:
		modulate.a = 0.0
		_panel.scale = Vector2.ONE * 0.92
		_tween.tween_property(self, "modulate:a", 1.0, 0.16)
		_tween.tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_property(self, "modulate:a", 0.0, 0.12)
		_tween.tween_property(_panel, "scale", Vector2.ONE * 0.95, 0.12)
		_tween.chain().tween_callback(hide)


func _toggle_music() -> void:
	var on := not bool(Settings.get_value(&"music_on"))
	Settings.set_value(&"music_on", on)
	_music.on = on
	AudioPrefs.apply()
	AudioDirector.play_sfx(&"ui_toggle")


func _toggle_cheers() -> void:
	var on := not bool(Settings.get_value(&"praise_mode"))
	Settings.set_value(&"praise_mode", on)
	_cheers.on = on
	AudioDirector.play_sfx(&"ui_toggle")


func _toggle_quiet() -> void:
	var on := not bool(Settings.get_value(&"quiet_mode"))
	Settings.set_value(&"quiet_mode", on)
	_quiet.on = on
	AudioPrefs.apply()
	AudioDirector.play_sfx(&"ui_toggle")
