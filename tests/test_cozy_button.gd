extends TestCase


func _click(button: CozyButton, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = Vector2(10, 10)
	button._gui_input(e)


func test_on_press_button_fires_once_per_tap() -> void:
	var b := CozyButton.new()
	b.size = Vector2(100, 100)
	b.on_press = true
	var fired := [0]
	b.activated.connect(func() -> void: fired[0] += 1)
	_click(b, true)
	_click(b, false)
	check_eq(fired[0], 1, "press and release fire once")
	b.free()


func test_flipping_mode_inside_handler_does_not_refire_on_release() -> void:
	var b := CozyButton.new()
	b.size = Vector2(100, 100)
	b.on_press = true
	var fired := [0]
	b.activated.connect(func() -> void:
		fired[0] += 1
		b.on_press = false)
	_click(b, true)
	_click(b, false)
	check_eq(fired[0], 1, "release after an on-press fire is ignored")
	b.free()


func test_release_button_fires_on_release_inside_only() -> void:
	var b := CozyButton.new()
	b.size = Vector2(100, 100)
	var fired := [0]
	b.activated.connect(func() -> void: fired[0] += 1)
	_click(b, true)
	check_eq(fired[0], 0, "press alone does nothing")
	_click(b, false)
	check_eq(fired[0], 1)
	b.free()
