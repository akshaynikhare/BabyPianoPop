class_name TileRules
extends RefCounted
## Pure falling-tile rules: spawning, per-frame motion, stuck/rewind, popping and hit tests.
## All distances are tuned in reference pixels (a 412 px wide phone) and multiplied by `unit`.

const REF_WIDTH := 412.0
const REF_HEIGHT := 915.0
const MAX_BOARD_REF := 448.0
const MAX_DT_MS := 35.0
const FRAME_MS := 16.67
const TEMPO_IDLE_MS := 950.0
const TEMPO_BOOST_WINDOW_MS := 1500.0
const TEMPO_BOOST := 0.35
const TEMPO_MAX := 2.4
const TEMPO_DECAY := 0.015
const LANES := 4
const FIRST_GAP := 240.0
const BOTTOM_MARGIN := 110.0
const CENTER_MIN := 160.0
const CENTER_FRACTION := 0.44
const REWIND_MIN := 0.65
const REWIND_EASE := 0.08
const TOUCH_PAD := 16.0
## The old app's tiles had an invisible 20 px margin that counted as a direct hit.
const DIRECT_MARGIN := 20.0
const HEADER_REF := 100.0
const START_REF := 95.0
const MOTION_GROW := 1.15

## Bit flags returned by step().
const STEP_SPAWNED := 1
const STEP_STUCK := 2


class Tile extends RefCounted:
	var id := 0
	var lane := 0
	var candy_index := 0
	var content := ""
	var is_shape := false
	var x := 0.0
	var y := 0.0
	var w := 0.0
	var h := 0.0
	var stuck := false
	## Whatever draws this tile; the rules never touch it.
	var view: Object = null

	func center() -> Vector2:
		return Vector2(x + w * 0.5, y + h * 0.5)


var tier := GameContent.DEFAULT_TIER
var unit := 1.0
var view_w := REF_WIDTH
var view_h := 915.0
var board_x := 0.0
var board_w := REF_WIDTH
var guard_y := HEADER_REF
var start_y := START_REF

var speed := 0.85
var tempo := 1.0
var last_pop_ms := -1.0e9
var gap := FIRST_GAP
var candy_index := 0
var next_id := 0
var star_count := 0
var completed_rounds := 0

var tiles: Array[Tile] = []
var last_spawned: Tile = null
var pop_was_stuck := false
var pop_three_stars := false

var rng := RandomNumberGenerator.new()
var _pool: Array[String] = []


func _init(start_tier := GameContent.DEFAULT_TIER, seed_value := 0) -> void:
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	set_tier(start_tier)


func set_tier(new_tier: String) -> void:
	tier = new_tier
	speed = GameContent.base_speed(tier)
	_pool = GameContent.pool(tier)


## Fits the rules to the screen. `unit` is the scale against a 412 x 915 reference phone; the header
## guard, tile start and every distance follow it. Tiles already on screen are re-laid out.
func set_viewport(width: float, height: float) -> void:
	var old_unit := unit
	view_w = width
	view_h = height
	unit = minf(width / REF_WIDTH, height / REF_HEIGHT)
	board_w = minf(width, MAX_BOARD_REF * unit)
	board_x = (width - board_w) * 0.5
	guard_y = HEADER_REF * unit
	start_y = START_REF * unit
	for t in tiles:
		_layout_tile(t)
		t.y *= unit / old_unit


func _layout_tile(t: Tile) -> void:
	t.w = board_w * (0.24 if t.is_shape else 0.23)
	t.h = t.w if t.is_shape else t.w * 4.0 / 3.0
	t.x = board_x + board_w * (t.lane * 0.25 + 0.01)


func allows_glide() -> bool:
	return GameContent.TIER_CONFIG[tier]["glide"]


func center_y() -> float:
	return maxf(CENTER_MIN * unit, view_h * CENTER_FRACTION)


func bottom_y() -> float:
	return view_h - BOTTOM_MARGIN * unit


func stuck_tile() -> Tile:
	for t in tiles:
		if t.stuck:
			return t
	return null


## Advances one frame. Returns STEP_* flags; `last_spawned` holds the new tile when STEP_SPAWNED is set.
func step(now_ms: float, dt_ms: float) -> int:
	var dt := minf(MAX_DT_MS, dt_ms)
	var ts := dt / FRAME_MS

	if now_ms - last_pop_ms > TEMPO_IDLE_MS and tempo > 1.0:
		tempo = maxf(1.0, tempo - TEMPO_DECAY * ts)

	var flags := 0
	var stuck := stuck_tile()
	if stuck != null:
		var target := center_y()
		if stuck.y > target:
			var up := maxf(REWIND_MIN * unit, (stuck.y - target) * REWIND_EASE) * ts
			for t in tiles:
				t.y -= up
		return flags

	var bottom := bottom_y()
	var advance := speed * unit * tempo * ts
	var hit_bottom := false
	var highest := 1000.0 * unit
	for t in tiles:
		if t.y >= bottom:
			t.y = bottom
			t.stuck = true
			hit_bottom = true
			flags |= STEP_STUCK
		else:
			t.y += advance
		highest = minf(highest, t.y)

	if highest > gap * unit and not hit_bottom:
		_spawn()
		flags |= STEP_SPAWNED
	return flags


func _spawn() -> void:
	var t := Tile.new()
	t.id = next_id
	next_id += 1
	t.lane = rng.randi_range(0, LANES - 1)
	t.candy_index = candy_index % GameContent.THEMES.size()
	candy_index += 1
	t.content = _pool[rng.randi_range(0, _pool.size() - 1)]
	t.is_shape = GameContent.is_shape(t.content)
	_layout_tile(t)
	t.y = start_y
	tiles.append(t)
	last_spawned = t
	gap = (220.0 + rng.randf() * 80.0)


## Removes a tile and updates tempo, stars and speed. False when it was already popped.
func pop(tile: Tile, now_ms: float) -> bool:
	var i := tiles.find(tile)
	if i < 0:
		return false
	tiles.remove_at(i)
	pop_was_stuck = tile.stuck

	if now_ms - last_pop_ms < TEMPO_BOOST_WINDOW_MS:
		tempo = minf(TEMPO_MAX, tempo + TEMPO_BOOST)
	last_pop_ms = now_ms

	star_count = 1 if star_count >= 3 else star_count + 1
	pop_three_stars = star_count == 3
	if pop_three_stars:
		completed_rounds += 1

	var base := GameContent.base_speed(tier)
	if pop_was_stuck:
		speed = maxf(base * 0.7, speed - 0.25)
	else:
		speed = minf(base * 2.2, speed + 0.05)
	return true


func reset_stars() -> void:
	star_count = 0


func palette_index() -> int:
	return GameContent.palette_index(tier, completed_rounds)


## Finds the tile a touch should pop, or null. Applies the header guard and tier glide rule.
func find_hit(px: float, py: float, moving: bool) -> Tile:
	if py < guard_y:
		return null
	if moving and not allows_glide():
		return null

	var point := Vector2(px, py)
	var best: Tile = null
	var best_d := INF
	var margin := DIRECT_MARGIN * unit
	for t in tiles:
		if px >= t.x - margin and px <= t.x + t.w + margin and py >= t.y - margin and py <= t.y + t.h + margin:
			var d := point.distance_squared_to(t.center())
			if d < best_d:
				best_d = d
				best = t
	if best != null:
		return best

	var grow := MOTION_GROW if moving else 1.0
	var pad := TOUCH_PAD * unit
	for t in tiles:
		var c := t.center()
		var dx := absf(px - c.x)
		var dy := absf(py - c.y)
		if dx <= (t.w * 0.5 + pad) * grow and dy <= (t.h * 0.5 + pad) * grow:
			var d := point.distance_squared_to(c)
			if d < best_d:
				best_d = d
				best = t
	return best
