extends TestCase

const NOW := 100000.0


func _rules(tier := "1-2y") -> TileRules:
	var r := TileRules.new(tier, 12345)
	r.set_viewport(TileRules.REF_WIDTH, TileRules.REF_HEIGHT)
	r.view_h = 800.0
	return r


func _add(r: TileRules, lane: int, y: float, content := "A") -> TileRules.Tile:
	var t := TileRules.Tile.new()
	t.id = r.next_id
	r.next_id += 1
	t.lane = lane
	t.content = content
	t.is_shape = GameContent.is_shape(content)
	t.w = r.board_w * (0.24 if t.is_shape else 0.23)
	t.h = t.w if t.is_shape else t.w * 4.0 / 3.0
	t.x = r.board_x + r.board_w * (lane * 0.25 + 0.01)
	t.y = y
	r.tiles.append(t)
	return t


func test_tier_content_pools() -> void:
	check_eq(GameContent.pool("6-12m").size(), 5 + 3 + 3, "infant pool")
	check_eq(GameContent.pool("1-2y").size(), 5 + 10 + 10, "young toddler pool")
	check_eq(GameContent.pool("2-3y").size(), 5 + 10 + 26, "toddler pool")
	check(GameContent.pool("6-12m").has("C") and not GameContent.pool("6-12m").has("D"), "infant letters")
	check(GameContent.pool("1-2y").has("J") and not GameContent.pool("1-2y").has("K"), "young toddler letters")


func test_base_speeds_and_palette_offset() -> void:
	check_near(GameContent.base_speed("6-12m"), 0.62)
	check_near(GameContent.base_speed("1-2y"), 0.85)
	check_near(GameContent.base_speed("2-3y"), 1.05)
	check_eq(GameContent.palette_index("6-12m", 0), 0)
	check_eq(GameContent.palette_index("1-2y", 0), 1)
	check_eq(GameContent.palette_index("2-3y", 5), 1, "wraps after six palettes")


func test_voice_ids() -> void:
	check_eq(GameContent.voice_id("A"), &"letter_a")
	check_eq(GameContent.voice_id("7"), &"number_7")
	check_eq(GameContent.voice_id("★"), &"shape_star")
	check_eq(GameContent.voice_id("■"), &"shape_square")


func test_first_frame_spawns_at_start_y() -> void:
	var r := _rules()
	var flags := r.step(NOW, 16.67)
	check(flags & TileRules.STEP_SPAWNED != 0, "spawn flag")
	check_eq(r.tiles.size(), 1)
	check_near(r.tiles[0].y, 95.0, 0.001, "start y")
	check(r.tiles[0].lane >= 0 and r.tiles[0].lane < 4, "lane in range")
	check(r.gap >= 220.0 and r.gap <= 300.0, "gap re-rolled after spawn")


func test_gap_after_spawn_in_range() -> void:
	var r := _rules()
	for i in 20:
		r.gap = 0.0
		r.tiles.clear()
		r.step(NOW, 16.67)
		check(r.gap >= 220.0 and r.gap <= 300.0, "gap %s" % r.gap)


func test_no_spawn_until_gap_cleared() -> void:
	var r := _rules()
	var t := _add(r, 0, 100.0)
	r.gap = 240.0
	check_eq(r.step(NOW, 16.67) & TileRules.STEP_SPAWNED, 0, "highest tile still above the gap")
	check_eq(r.tiles.size(), 1)
	t.y = 240.0
	check_eq(r.step(NOW, 16.67) & TileRules.STEP_SPAWNED, TileRules.STEP_SPAWNED, "moved past the gap")


func test_spawn_when_highest_below_gap() -> void:
	var r := _rules()
	_add(r, 0, 300.0)
	r.gap = 240.0
	var flags := r.step(NOW, 16.67)
	check(flags & TileRules.STEP_SPAWNED != 0, "spawns")
	check_eq(r.tiles.size(), 2)


func test_candy_index_cycles_through_six_themes() -> void:
	var r := _rules()
	for i in 8:
		r.tiles.clear()
		r.gap = 0.0
		r.step(NOW, 16.67)
		check_eq(r.last_spawned.candy_index, i % 6, "candy %d" % i)


func test_content_comes_from_tier_pool() -> void:
	var r := _rules("6-12m")
	var pool := GameContent.pool("6-12m")
	for i in 40:
		r.tiles.clear()
		r.gap = 0.0
		r.step(NOW, 16.67)
		check(pool.has(r.last_spawned.content), "content %s in pool" % r.last_spawned.content)


func test_tile_layout_sizes() -> void:
	var r := _rules()
	var board := r.board_w
	r.gap = 0.0
	for i in 30:
		r.tiles.clear()
		r.gap = 0.0
		r.step(NOW, 16.67)
		var t := r.last_spawned
		if t.is_shape:
			check_near(t.w, board * 0.24, 0.001, "shape width")
			check_near(t.h, t.w, 0.001, "shape square")
		else:
			check_near(t.w, board * 0.23, 0.001, "glyph width")
			check_near(t.h, t.w * 4.0 / 3.0, 0.001, "glyph 3:4")
		check_near(t.x, r.board_x + board * (t.lane * 0.25 + 0.01), 0.001, "left")


func test_movement_uses_speed_tempo_and_time_scale() -> void:
	var r := _rules()
	var t := _add(r, 0, 200.0)
	r.gap = 9999.0
	r.tempo = 1.5
	r.last_pop_ms = NOW
	r.step(NOW, 16.67)
	check_near(t.y, 200.0 + 0.85 * 1.5 * 1.0, 0.001, "one 60fps frame")


func test_dt_is_clamped_to_35ms() -> void:
	var r := _rules()
	var t := _add(r, 0, 200.0)
	r.gap = 9999.0
	r.step(NOW, 500.0)
	check_near(t.y, 200.0 + 0.85 * (35.0 / 16.67), 0.001, "clamped step")


func test_unit_scales_distances() -> void:
	var r := TileRules.new("1-2y", 7)
	r.set_viewport(824.0, 1830.0)
	check_near(r.unit, 2.0, 0.0001)
	var t := _add(r, 0, 300.0)
	r.gap = 99999.0
	r.step(NOW, 16.67)
	check_near(t.y, 300.0 + 0.85 * 2.0, 0.001, "speed scales with unit")
	check_near(r.bottom_y(), 1830.0 - 220.0, 0.001, "bottom margin scales")


func test_tempo_decays_after_idle() -> void:
	var r := _rules()
	r.gap = 9999.0
	r.tempo = 2.0
	r.last_pop_ms = NOW - 1000.0
	r.step(NOW, 16.67)
	check_near(r.tempo, 2.0 - 0.015, 0.0001, "decays after 950 ms")
	r.tempo = 2.0
	r.last_pop_ms = NOW - 900.0
	r.step(NOW, 16.67)
	check_near(r.tempo, 2.0, 0.0001, "no decay inside 950 ms")


func test_tempo_never_below_one() -> void:
	var r := _rules()
	r.gap = 9999.0
	r.tempo = 1.005
	r.last_pop_ms = 0.0
	r.step(NOW, 16.67)
	check_near(r.tempo, 1.0, 0.0001)


func test_tile_sticks_at_bottom_threshold() -> void:
	var r := _rules()
	var t := _add(r, 1, r.bottom_y() - 0.2)
	r.gap = 9999.0
	r.step(NOW, 16.67)
	check(not t.stuck, "still moving just above")
	check(t.y > r.bottom_y() - 0.2, "moved down")
	t.y = r.bottom_y() + 3.0
	var flags := r.step(NOW, 16.67)
	check(t.stuck, "stuck")
	check_near(t.y, 800.0 - 110.0, 0.0001, "clamped to height - 110")
	check(flags & TileRules.STEP_STUCK != 0, "stuck flag")


func test_rewind_to_center_with_easing() -> void:
	var r := _rules()
	var t := _add(r, 0, r.bottom_y())
	t.stuck = true
	var other := _add(r, 2, 400.0)
	r.gap = 9999.0
	var center := maxf(160.0, 800.0 * 0.44)
	var diff := t.y - center
	var expected := maxf(0.65, diff * 0.08)
	var before_other := other.y
	r.step(NOW, 16.67)
	check_near(t.y, r.bottom_y() - expected, 0.001, "eased rewind step")
	check_near(other.y, before_other - expected, 0.001, "all tiles rewind together")


func test_rewind_min_step_near_target() -> void:
	var r := _rules()
	var center := r.center_y()
	var t := _add(r, 0, center + 2.0)
	t.stuck = true
	r.gap = 9999.0
	r.step(NOW, 16.67)
	check_near(t.y, center + 2.0 - 0.65, 0.001, "min rewind step")


func test_rewind_scales_with_dt() -> void:
	var r := _rules()
	var t := _add(r, 0, r.center_y() + 2.0)
	t.stuck = true
	r.step(NOW, 33.34)
	check_near(t.y, r.center_y() + 2.0 - 1.3, 0.01, "double dt double step")


func test_hold_at_center_and_no_spawn() -> void:
	var r := _rules()
	var t := _add(r, 0, r.center_y() - 1.0)
	t.stuck = true
	r.gap = 0.0
	var y := t.y
	var flags := r.step(NOW, 16.67)
	check_near(t.y, y, 0.0001, "holds still")
	check_eq(flags, 0, "nothing happens")
	check_eq(r.tiles.size(), 1, "no spawn while stuck")


func test_center_y_floor() -> void:
	var r := TileRules.new("1-2y", 1)
	r.set_viewport(412.0, 915.0)
	r.view_h = 300.0
	check_near(r.center_y(), 160.0, 0.001, "floor 160")
	r.view_h = 1000.0
	check_near(r.center_y(), 440.0, 0.001, "44% of height")


func test_no_spawn_on_the_frame_a_tile_sticks() -> void:
	var r := _rules()
	_add(r, 0, r.bottom_y() + 1.0)
	r.gap = 0.0
	var flags := r.step(NOW, 16.67)
	check_eq(flags & TileRules.STEP_SPAWNED, 0, "no spawn")
	check(flags & TileRules.STEP_STUCK != 0, "stuck")


func test_pop_removes_tile_and_ignores_repeat() -> void:
	var r := _rules()
	var t := _add(r, 0, 300.0)
	check(r.pop(t, NOW), "first pop")
	check(not r.pop(t, NOW + 10.0), "second pop ignored")
	check_eq(r.tiles.size(), 0)
	check_eq(r.star_count, 1, "only one star")


func test_pop_tempo_boost_inside_window() -> void:
	var r := _rules()
	var a := _add(r, 0, 300.0)
	var b := _add(r, 1, 300.0)
	r.pop(a, NOW)
	check_near(r.tempo, 1.0, 0.0001, "first pop has no boost")
	r.pop(b, NOW + 1000.0)
	check_near(r.tempo, 1.35, 0.0001, "boost within 1500 ms")


func test_pop_tempo_boost_capped() -> void:
	var r := _rules()
	var now := NOW
	for i in 10:
		r.pop(_add(r, 0, 300.0), now)
		now += 100.0
	check_near(r.tempo, 2.4, 0.0001, "tempo cap")


func test_pop_no_boost_when_slow() -> void:
	var r := _rules()
	r.pop(_add(r, 0, 300.0), NOW)
	r.pop(_add(r, 0, 300.0), NOW + 1500.0)
	check_near(r.tempo, 1.0, 0.0001, "1500 ms is outside the window")


func test_star_cycle() -> void:
	var r := _rules()
	var seen: Array[int] = []
	var now := NOW
	for i in 7:
		r.pop(_add(r, 0, 300.0), now)
		seen.append(r.star_count)
		now += 5000.0
	check_eq(seen, [1, 2, 3, 1, 2, 3, 1] as Array[int], "star sequence 1,2,3,1,2,3,1")


func test_three_stars_completes_a_round() -> void:
	var r := _rules()
	r.pop(_add(r, 0, 300.0), NOW)
	check(not r.pop_three_stars)
	r.pop(_add(r, 0, 300.0), NOW)
	check(not r.pop_three_stars)
	r.pop(_add(r, 0, 300.0), NOW)
	check(r.pop_three_stars, "third pop flagged")
	check_eq(r.completed_rounds, 1)
	check_eq(r.palette_index(), 2, "1-2y offset 1 plus one round")


func test_reset_stars_restarts_cycle() -> void:
	var r := _rules()
	for i in 3:
		r.pop(_add(r, 0, 300.0), NOW)
	r.reset_stars()
	check_eq(r.star_count, 0)
	r.pop(_add(r, 0, 300.0), NOW + 9000.0)
	check_eq(r.star_count, 1)


func test_speed_adapts_up_and_caps() -> void:
	var r := _rules()
	r.pop(_add(r, 0, 300.0), NOW)
	check_near(r.speed, 0.90, 0.0001, "plus 0.05")
	for i in 100:
		r.pop(_add(r, 0, 300.0), NOW)
	check_near(r.speed, 0.85 * 2.2, 0.0001, "capped at base x 2.2")


func test_speed_drops_after_popping_stuck_tile() -> void:
	var r := _rules()
	r.speed = 1.5
	var t := _add(r, 0, 500.0)
	t.stuck = true
	r.pop(t, NOW)
	check(r.pop_was_stuck, "flag")
	check_near(r.speed, 1.25, 0.0001, "minus 0.25")
	var s := _add(r, 0, 500.0)
	s.stuck = true
	r.speed = 0.7
	r.pop(s, NOW + 5000.0)
	check_near(r.speed, 0.85 * 0.7, 0.0001, "floored at base x 0.7")


func test_set_tier_resets_speed() -> void:
	var r := _rules()
	r.speed = 1.7
	r.set_tier("2-3y")
	check_near(r.speed, 1.05, 0.0001)
	check(not r.allows_glide())
	r.set_tier("6-12m")
	check(r.allows_glide())


func test_hit_rejects_header_guard() -> void:
	var r := _rules()
	var t := _add(r, 0, 90.0)
	check(r.find_hit(t.x + 10.0, 99.0, false) == null, "inside guard")
	check(r.find_hit(t.x + 10.0, 100.0, false) == t, "just below guard")


func test_hit_move_only_for_infants() -> void:
	var t: TileRules.Tile
	var r := _rules("1-2y")
	t = _add(r, 1, 300.0)
	check(r.find_hit(t.center().x, t.center().y, true) == null, "toddler ignores glide")
	check(r.find_hit(t.center().x, t.center().y, false) == t, "toddler taps")
	var infant := _rules("6-12m")
	t = _add(infant, 1, 300.0)
	check(infant.find_hit(t.center().x, t.center().y, true) == t, "infant glides")


func test_hit_direct_beats_sticky() -> void:
	var r := _rules()
	var a := _add(r, 0, 300.0)
	var b := _add(r, 1, 300.0)
	var inside_a := Vector2(a.x + a.w - 1.0, a.center().y)
	check(r.find_hit(inside_a.x, inside_a.y, false) == a, "direct on a")
	check(r.find_hit(b.center().x, b.center().y, false) == b, "direct on b")


func test_hit_margin_around_tile() -> void:
	var r := _rules()
	var t := _add(r, 1, 300.0)
	var c := t.center()
	var edge := t.w * 0.5 + 20.0
	check(r.find_hit(c.x + edge - 0.5, c.y, false) == t, "inside the 20 px margin")
	check(r.find_hit(c.x + edge + 0.5, c.y, false) == null, "outside the margin")
	var far_y := t.h * 0.5 + 20.0
	check(r.find_hit(c.x, c.y + far_y + 0.5, false) == null, "outside vertical margin")


func test_hit_motion_grows_box_by_15_percent() -> void:
	var r := _rules("6-12m")
	var t := _add(r, 1, 300.0)
	var c := t.center()
	var edge := (t.w * 0.5 + 16.0) * 1.15
	check(r.find_hit(c.x + edge - 0.5, c.y, true) == t, "moving grown box")
	check(r.find_hit(c.x + edge + 0.5, c.y, true) == null, "beyond grown box")
	check(r.find_hit(c.x + t.w * 0.5 + 20.0 + 1.0, c.y, false) == null, "still tight when tapping")


func test_hit_padding_scales_with_unit() -> void:
	var r := TileRules.new("6-12m", 3)
	r.set_viewport(824.0, 1830.0)
	var t := _add(r, 1, 600.0)
	var c := t.center()
	var direct := t.w * 0.5 + 20.0 * 2.0
	check(r.find_hit(c.x + direct - 0.5, c.y, false) == t, "margin is 40 px at unit 2")
	check(r.find_hit(c.x + direct + 0.5, c.y, false) == null, "and no more")
	var moving := (t.w * 0.5 + 16.0 * 2.0) * 1.15
	check(r.find_hit(c.x + moving - 0.5, c.y, true) == t, "sticky pad is 32 px at unit 2")
	check(r.find_hit(c.x + moving + 0.5, c.y, true) == null, "grown box ends there")


func test_hit_sticky_picks_nearest() -> void:
	var r := _rules()
	var a := _add(r, 0, 300.0)
	var b := _add(r, 1, 300.0)
	var mid_x := (a.x + a.w + b.x) * 0.5
	var nearer_a := mid_x - 1.0
	check(r.find_hit(nearer_a, a.center().y, false) == a, "nearer to a")
	check(r.find_hit(mid_x + 1.0, a.center().y, false) == b, "nearer to b")


func test_hit_misses_empty_space() -> void:
	var r := _rules()
	_add(r, 0, 300.0)
	check(r.find_hit(r.board_x + r.board_w - 5.0, 700.0, false) == null)


func test_board_fills_the_width_and_caps_on_wide_screens() -> void:
	var r := TileRules.new("1-2y", 1)
	r.set_viewport(720.0, 1600.0)
	check_near(r.unit, 720.0 / 412.0, 0.001, "unit follows width on a tall phone")
	check_near(r.board_w, 720.0, 0.001, "fills")
	r.set_viewport(1000.0, 1600.0)
	check_near(r.unit, 1600.0 / TileRules.REF_HEIGHT, 0.0001, "height limits unit on wide screens")
	check_near(r.board_w, 448.0 * r.unit, 0.001, "capped at 448 reference px")
	check_near(r.board_x, (1000.0 - r.board_w) * 0.5, 0.001, "centered")


func test_header_guard_and_start_follow_unit() -> void:
	var r := TileRules.new("1-2y", 1)
	r.set_viewport(824.0, 1830.0)
	check_near(r.guard_y, 200.0, 0.001, "guard 100 x unit")
	check_near(r.start_y, 190.0, 0.001, "start 95 x unit")
	r.step(NOW, 16.67)
	check_near(r.tiles[0].y, 190.0, 0.001, "tiles start under the scaled header")
	check(r.find_hit(r.tiles[0].center().x, 199.0, false) == null, "guard rejects")


func test_spawn_cadence_matches_legacy_at_any_unit() -> void:
	var counts: Array[int] = []
	for size in [Vector2(412, 915), Vector2(720, 1600), Vector2(824, 1830)]:
		var r := TileRules.new("1-2y", 99)
		r.set_viewport(size.x, size.y)
		var spawned := 0
		var now := NOW
		for i in 600:
			now += 16.67
			if r.step(now, 16.67) & TileRules.STEP_SPAWNED:
				spawned += 1
		counts.append(spawned)
	check(counts[0] >= 3 and counts[0] <= 5, "about 4 spawns in 10 s, got %d" % counts[0])
	check_eq(counts[1], counts[0], "unit 1.75 keeps the legacy cadence")
	check_eq(counts[2], counts[0], "unit 2 keeps the legacy cadence")


func test_resize_relays_out_existing_tiles() -> void:
	var r := TileRules.new("1-2y", 1)
	r.set_viewport(412.0, 915.0)
	var t := _add(r, 2, 300.0)
	var old_w := t.w
	r.set_viewport(824.0, 1830.0)
	check_near(t.w, old_w * 2.0, 0.001, "width follows the board")
	check_near(t.x, r.board_x + r.board_w * (2 * 0.25 + 0.01), 0.001, "lane x follows the board")
	check_near(t.y, 600.0, 0.001, "y scales with unit")
