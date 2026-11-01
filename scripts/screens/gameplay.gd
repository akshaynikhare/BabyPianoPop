class_name Gameplay
extends Node2D
## The play field: falling candy tiles, header, touch handling and the parent gate.

signal settings_requested

const POOL_SIZE := 14
const GATE_MS := 3000.0
const GATE_TAP_MIN_MS := 40.0
const GATE_TAP_MAX_MS := 1200.0
const GATE_RING_AFTER_MS := 150.0

var fx: BurstPool
var rules: TileRules
var header := GameHeader.new()

var _board := BakedArt.new()
var _board_art := _Board.new()
var _tiles_root := Node2D.new()
var _free: Array[CandyTile] = []
var _view := Vector2(720, 1600)
var _halted := false
var _mascot_taps := 0
var _gear_taps := 0
var _praise_index := 0
var _reset_token := 0
var _gate_touch := -1
var _gate_start := 0.0


class _Board extends Node2D:
	var view := Vector2(720, 1600)
	var board_x := 0.0
	var board_w := 720.0

	func _draw() -> void:
		draw_rect(Rect2(board_x, 0, board_w, view.y), Color(1, 1, 1, 0.26))
		for i in range(1, 4):
			var x := board_x + board_w * 0.25 * i
			draw_dashed_line(Vector2(x, 0), Vector2(x, view.y), Color(1, 1, 1, 0.7), 3.0, 14.0, true, true)
		for i in 4:
			var cx := board_x + board_w * (0.25 * i + 0.125)
			for f in [0.25, 0.5, 0.75]:
				draw_circle(Vector2(cx, view.y * f), 5.0, Color(1, 1, 1, 0.55))


func _ready() -> void:
	_view = get_viewport_rect().size
	var saved: Variant = Settings.get_value(&"age_tier")
	rules = TileRules.new(saved if GameContent.is_valid_tier(saved) else GameContent.DEFAULT_TIER)
	add_child(_board)
	_apply_view()
	add_child(_tiles_root)
	add_child(header)
	for i in POOL_SIZE:
		_add_to_pool()
	header.layout(_view.x, rules.unit)
	header.pill.color = GameContent.PALETTES[rules.palette_index()]["pill"]

	EventBus.settings_opened.connect(_set_halted.bind(true))
	EventBus.settings_closed.connect(_set_halted.bind(false))
	EventBus.settings_changed.connect(_on_setting_changed)
	EventBus.palette_changed.connect(_on_palette_changed)
	EventBus.app_paused.connect(_cancel_gate)
	get_viewport().size_changed.connect(_on_resized)


func _apply_view() -> void:
	rules.set_viewport(_view.x, _view.y)
	_board_art.view = _view
	_board_art.board_x = rules.board_x
	_board_art.board_w = rules.board_w
	_board.bake(_board_art, Rect2(Vector2.ZERO, _view), 1.0)


func _on_resized() -> void:
	_view = get_viewport_rect().size
	_apply_view()
	header.layout(_view.x, rules.unit)
	for t in rules.tiles:
		(t.view as CandyTile).configure(t, false)


func _add_to_pool() -> CandyTile:
	var tile := CandyTile.new()
	tile.released.connect(_on_tile_released)
	_tiles_root.add_child(tile)
	_free.append(tile)
	return tile


func _on_tile_released(tile: CandyTile) -> void:
	_free.append(tile)


func _set_halted(on: bool) -> void:
	_halted = on
	if on:
		_cancel_gate()


func _on_setting_changed(key: StringName, value: Variant) -> void:
	if key == &"age_tier" and GameContent.is_valid_tier(value):
		rules.set_tier(value)
		header.mascot.set_mood(&"happy", 1400)


func _on_palette_changed(index: int) -> void:
	var tween := create_tween()
	tween.tween_property(header.pill, "color", GameContent.PALETTES[index]["pill"], 1.0)


func _process(delta: float) -> void:
	if _halted:
		return
	var flags := rules.step(float(Time.get_ticks_msec()), delta * 1000.0)
	if flags & TileRules.STEP_SPAWNED:
		_show_tile(rules.last_spawned)
	if flags & TileRules.STEP_STUCK:
		_on_stuck()
	for t in rules.tiles:
		(t.view as CandyTile).position = Vector2(t.x + t.w * 0.5, t.y + t.h * 0.5)
	if _gate_touch >= 0:
		_update_gate()


func _show_tile(tile: TileRules.Tile) -> void:
	var node: CandyTile = _free.pop_back() if not _free.is_empty() else _add_to_pool_and_take()
	node.configure(tile)


func _add_to_pool_and_take() -> CandyTile:
	var tile := _add_to_pool()
	_free.erase(tile)
	return tile


func _on_stuck() -> void:
	var stuck := rules.stuck_tile()
	if stuck != null and stuck.view != null:
		(stuck.view as CandyTile).set_stuck(true)
	header.mascot.set_mood(&"encourage", 2000)
	Haptics.play(&"stuck")
	EventBus.tile_stuck.emit()


# --- Input -----------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if _halted:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_down(event.index, event.position)
		else:
			_touch_up(event.index, event.canceled)
	elif event is InputEventScreenDrag:
		if event.index == _gate_touch and not header.gear_rect().grow(20.0 * rules.unit).has_point(event.position):
			_cancel_gate()
		if rules.allows_glide():
			_check_point(event.position, true)


func _touch_down(index: int, pos: Vector2) -> void:
	if pos.y >= rules.guard_y:
		_check_point(pos, false)
		return
	if header.gear_rect().has_point(pos):
		if _gate_touch < 0:
			_gate_touch = index
			_gate_start = Time.get_ticks_msec()
	elif header.pill_rect().has_point(pos):
		_pill_tap()
	elif header.mascot_rect().has_point(pos):
		_mascot_tap()


func _touch_up(index: int, canceled := false) -> void:
	if index != _gate_touch:
		return
	var held := Time.get_ticks_msec() - _gate_start
	_cancel_gate()
	if canceled:
		return
	if held >= GATE_TAP_MIN_MS and held <= GATE_TAP_MAX_MS:
		header.gear.wobble()
		AudioDirector.play_sfx(&"tick")
		AudioDirector.play_voice(StringName("gear_%d" % (_gear_taps % GameContent.GEAR_PHRASE_COUNT)))
		_gear_taps += 1
		fx.burst(&"tick", _frac(0.88, 0.12))


func _update_gate() -> void:
	var held := Time.get_ticks_msec() - _gate_start
	header.gear.progress = 0.0 if held < GATE_RING_AFTER_MS else minf(held / GATE_MS, 1.0)
	if held >= GATE_MS:
		_cancel_gate()
		Haptics.play(&"unlock")
		fx.burst(&"unlock", _frac(0.8, 0.12))
		settings_requested.emit()


func _cancel_gate() -> void:
	_gate_touch = -1
	header.gear.progress = 0.0


func _check_point(pos: Vector2, moving: bool) -> void:
	var tile := rules.find_hit(pos.x, pos.y, moving)
	if tile != null:
		_pop(tile)


# --- Reactions -------------------------------------------------------------

func _frac(x: float, y: float) -> Vector2:
	return Vector2(_view.x * x, _view.y * y)


func _pop(tile: TileRules.Tile) -> void:
	var content := tile.content
	var theme: Dictionary = GameContent.THEMES[tile.candy_index]
	var node := tile.view as CandyTile
	if not rules.pop(tile, float(Time.get_ticks_msec())):
		return
	_reset_token += 1

	AudioDirector.play_sfx(&"pop")
	AudioDirector.play_voice(GameContent.voice_id(content))
	Haptics.play(&"pop")
	if node != null:
		node.play_pop()
	fx.burst(StringName("pop_" + rules.tier), _frac(0.5, 0.72), theme["shadow"])

	header.pill.set_stars(rules.star_count)
	if rules.pop_three_stars:
		_celebrate_three_stars()
	else:
		header.mascot.set_mood(&"happy", 900)
	EventBus.tile_popped.emit(content, rules.pop_was_stuck)
	EventBus.stars_changed.emit(rules.star_count)


func _celebrate_three_stars() -> void:
	EventBus.round_completed.emit(rules.completed_rounds)
	header.mascot.set_mood(&"celebrate", 2400)
	AudioDirector.play_sfx(&"star")
	Haptics.play(&"stars")
	fx.burst(&"stars", _frac(0.5, 0.12))

	var praise := bool(Settings.get_value(&"praise_mode"))
	var clip := &"three_stars_hooray"
	if praise:
		clip = StringName("three_stars_praise_%d" % (_praise_index % GameContent.PRAISE_COUNT))
		_praise_index += 1
	get_tree().create_timer(0.28, false).timeout.connect(AudioDirector.play_voice.bind(clip))

	var token := _reset_token
	get_tree().create_timer(1.8, false).timeout.connect(_reset_stars.bind(token))


func _reset_stars(token: int) -> void:
	if token != _reset_token:
		return
	rules.reset_stars()
	header.pill.set_stars(0)
	EventBus.stars_changed.emit(0)


func _mascot_tap() -> void:
	AudioDirector.play_sfx(&"giggle")
	header.mascot.set_mood(&"celebrate", 1200)
	AudioDirector.play_voice(StringName("mascot_%d" % (_mascot_taps % GameContent.MASCOT_PHRASE_COUNT)))
	_mascot_taps += 1
	fx.burst(&"mascot", _frac(0.18, 0.12))


func _pill_tap() -> void:
	AudioDirector.play_sfx(&"star")
	fx.burst(&"pill", _frac(0.5, 0.12))
	AudioDirector.play_voice(StringName("stars_%d" % rules.star_count))
