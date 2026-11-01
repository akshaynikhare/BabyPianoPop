extends Node
## Persists parent settings in user://settings.cfg.

const PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULTS := {
	&"age_tier": "1-2y",
	&"praise_mode": true,
	&"music_on": true,
}

var _config := ConfigFile.new()


func _ready() -> void:
	_config.load(PATH)


func get_value(key: StringName) -> Variant:
	return _config.get_value(SECTION, key, DEFAULTS.get(key))


func set_value(key: StringName, value: Variant) -> void:
	_config.set_value(SECTION, key, value)
	_config.save(PATH)
	EventBus.settings_changed.emit(key, value)
