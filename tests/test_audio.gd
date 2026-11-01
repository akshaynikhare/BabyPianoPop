extends TestCase

const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"


func _variants_of(clips: Array) -> SfxVariants:
	var variants := SfxVariants.new()
	for clip in clips:
		variants.add(clip)
	return variants


func _distinct_picks(variants: SfxVariants, clip: StringName) -> Dictionary:
	var seen := {}
	for i in 200:
		seen[variants.pick(clip)] = true
	return seen


func test_numbered_files_form_a_group() -> void:
	var v := _variants_of([&"pop_1", &"pop_2", &"pop_3", &"ui_tap_1", &"ui_tap_2", &"celebrate"])
	check_eq(_distinct_picks(v, &"pop").keys().size(), 3, "all pop files get picked")
	check(not _distinct_picks(v, &"pop").has(&"ui_tap_1"), "groups stay apart")
	check_eq(v.pick(&"celebrate"), &"celebrate", "a single file plays as itself")
	check_eq(v.pick(&"missing"), &"missing", "an unknown id passes through")


func test_pick_never_repeats_back_to_back() -> void:
	var three := _variants_of([&"pop_1", &"pop_2", &"pop_3"])
	var two := _variants_of([&"tick_1", &"tick_2"])
	var last_three := &""
	var last_two := &""
	for i in 300:
		var a := three.pick(&"pop")
		var b := two.pick(&"tick")
		check(a != last_three, "pop repeated %s" % a)
		check(b != last_two, "tick repeated %s" % b)
		last_three = a
		last_two = b


func test_group_of_one_file_keeps_playing_it() -> void:
	var v := _variants_of([&"boing_1"])
	for i in 5:
		check_eq(v.pick(&"boing"), &"boing_1")


func test_files_on_disk_make_the_expected_groups() -> void:
	var v := SfxVariants.new()
	for file in ResourceLoader.list_directory(SFX_DIR):
		if file.ends_with(".ogg"):
			v.add(StringName(file.get_basename()))
	var expected := {&"pop": 4, &"star": 2, &"giggle": 2, &"boing": 2, &"tick": 2, &"ui_tap": 3, &"ui_toggle": 2}
	for group in expected:
		var seen := _distinct_picks(v, group)
		check_eq(seen.size(), expected[group], "%s variants" % group)
		for clip in seen:
			check(ResourceLoader.exists(SFX_DIR + String(clip) + ".ogg"), "%s exists" % clip)
	for clip in [&"celebrate", &"ui_open", &"ui_close", &"ui_hold", &"ui_unlock"]:
		check_eq(v.pick(clip), clip)


func test_ui_star_and_celebrate_are_never_varied() -> void:
	for clip in [&"pop", &"giggle", &"boing", &"tick"]:
		check(SfxVariants.varies(clip), "%s varies" % clip)
	for clip in [&"ui_tap", &"ui_toggle", &"ui_hold", &"ui_unlock", &"star", &"celebrate"]:
		check(not SfxVariants.varies(clip), "%s is fixed" % clip)


func test_each_age_tier_has_its_own_music() -> void:
	check_eq(GameContent.music_id("6-12m"), &"music_calm")
	check_eq(GameContent.music_id("1-2y"), &"music_box")
	check_eq(GameContent.music_id("2-3y"), &"music_play")
	check_eq(GameContent.music_id("nonsense"), &"music_box", "unknown tier falls back to the default")
	check_eq(GameContent.music_id(null), &"music_box", "missing setting falls back to the default")
	for tier in GameContent.TIERS:
		check(ResourceLoader.exists(MUSIC_DIR + String(GameContent.music_id(tier)) + ".ogg"), "%s music exists" % tier)


func test_praise_count_matches_the_voice_clips() -> void:
	check_eq(GameContent.PRAISE_COUNT, 12)
	for i in GameContent.PRAISE_COUNT:
		check(ResourceLoader.exists(VOICE_DIR + "praise_%d.ogg" % i), "praise_%d" % i)
		check(ResourceLoader.exists(VOICE_DIR + "three_stars_praise_%d.ogg" % i), "three_stars_praise_%d" % i)


func test_quiet_mode_is_off_by_default() -> void:
	check_eq(Settings.DEFAULTS[&"quiet_mode"], false)


## One director for the whole check: its limiter is added to Master every time it starts. The
## runner has no scene tree yet, so `_ready` is called by hand.
func test_mix_is_balanced_limited_and_quiet_mode_lowers_master() -> void:
	var director: Node = load("res://autoload/audio_director.gd").new()
	director._ready()
	var master := AudioServer.get_bus_index(&"Master")
	check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Voice")), 0.0, 0.0001, "voice")
	check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"SFX")), -3.0, 0.0001, "sfx")
	check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")), -6.0, 0.0001, "music")

	var limiters := 0
	for i in AudioServer.get_bus_effect_count(master):
		var effect := AudioServer.get_bus_effect(master, i)
		if effect is AudioEffectHardLimiter:
			limiters += 1
			check_near(effect.ceiling_db, -1.0, 0.0001, "limiter ceiling")
	check_eq(limiters, 1, "one limiter on Master")

	director.set_quiet(true)
	check_near(AudioServer.get_bus_volume_db(master), -8.0, 0.0001, "quiet master")
	director.set_quiet(false)
	check_near(AudioServer.get_bus_volume_db(master), 0.0, 0.0001, "normal master")
	director.free()
