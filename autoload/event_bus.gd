extends Node
## Global signal hub. Systems talk through these signals instead of node paths.

signal app_paused
signal app_resumed
signal settings_changed(key: StringName, value: Variant)

signal game_started
signal tile_popped(content: String, was_stuck: bool)
signal tile_stuck
signal stars_changed(count: int)
signal round_completed(completed_rounds: int)
signal mascot_mood_changed(mood: StringName)
signal settings_opened
signal settings_closed
signal palette_changed(index: int)
