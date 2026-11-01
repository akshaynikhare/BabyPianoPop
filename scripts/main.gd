extends Node
## Owns the shared backdrop, effects pool and settings sheet; swaps start screen and gameplay.

const START_SCENE := preload("res://scenes/start_screen.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")

@onready var background: Background = $BackgroundLayer/Background
@onready var screens: Node = $Screens
@onready var fx: BurstPool = $FxLayer/BurstPool
@onready var sheet: SettingsSheet = $SettingsLayer/SettingsSheet

var _rounds := 0
var _start: StartScreen
var _gameplay: Gameplay


func _ready() -> void:
	_register_bursts()
	AudioPrefs.apply(false)
	EventBus.settings_changed.connect(_on_setting_changed)
	EventBus.round_completed.connect(_on_round_completed)
	EventBus.app_resumed.connect(_on_app_resumed)
	background.set_palette(_palette_index(), true)

	_start = START_SCENE.instantiate()
	_start.fx = fx
	_start.play_pressed.connect(_on_play)
	screens.add_child(_start)


func _tier() -> String:
	var saved: Variant = Settings.get_value(&"age_tier")
	return saved if GameContent.is_valid_tier(saved) else GameContent.DEFAULT_TIER


func _palette_index() -> int:
	return GameContent.palette_index(_tier(), _rounds)


func _apply_palette() -> void:
	var index := _palette_index()
	background.set_palette(index)
	EventBus.palette_changed.emit(index)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	if key == &"age_tier":
		_apply_palette()


func _on_round_completed(rounds: int) -> void:
	_rounds = rounds
	_apply_palette()


func _on_app_resumed() -> void:
	if bool(Settings.get_value(&"music_on")) and _gameplay != null:
		AudioDirector.play_music(&"music_box")


func _on_play() -> void:
	if _gameplay != null:
		return
	AudioPrefs.apply(true)
	EventBus.game_started.emit()
	var old := _start
	_gameplay = GAMEPLAY_SCENE.instantiate()
	_gameplay.fx = fx
	_gameplay.settings_requested.connect(sheet.open)
	_gameplay.modulate.a = 0.0
	screens.add_child(_gameplay)
	_gameplay.header.mascot.set_mood(&"happy", 1500)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_gameplay, "modulate:a", 1.0, 0.35)
	tween.tween_property(old, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(old.queue_free)


func _register_bursts() -> void:
	var tiers: Array = [
		["6-12m", 20, 55.0, 0.65, 1.15, ["circle"]],
		["1-2y", 32, 72.0, 0.88, 1.05, ["circle", "star"]],
		["2-3y", 44, 85.0, 1.05, 1.0, ["star", "circle"]],
	]
	for t in tiers:
		var colors: Array = ["000000"] + GameContent.BURST_COLORS[t[0]]
		fx.register(StringName("pop_" + t[0]), t[1], t[2], t[3], t[4], colors, t[5])
	fx.register(&"stars", 28, 70.0, 1.0, 1.0, ["ff70a6", "ffd166", "06d6a0", "a855f7"], ["star", "circle"])
	fx.register(&"mascot", 22, 70.0, 1.0, 1.0, ["ff70a6", "ffd166", "06d6a0", "a855f7"], ["star", "circle"])
	fx.register(&"pill", 16, 70.0, 1.0, 0.9, ["fbbf24", "f59e0b", "fef08a", "ffffff"], ["star"])
	fx.register(&"unlock", 22, 60.0, 1.0, 1.0, ["a855f7", "ec4899", "3b82f6"], ["circle", "star"])
	fx.register(&"tick", 12, 45.0, 1.0, 0.9, ["c084fc", "e879f9", "a855f7", "38bdf8"], ["circle"])
