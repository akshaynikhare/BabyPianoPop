class_name AudioPrefs
extends RefCounted
## Applies the saved music preference. Speech stays audible; music and sound effects follow the switch.


static func apply(play_music := true) -> void:
	var on := bool(Settings.get_value(&"music_on"))
	AudioDirector.set_bus_muted(&"Music", not on)
	AudioDirector.set_bus_muted(&"SFX", not on)
	if not on:
		AudioDirector.stop_music()
	elif play_music:
		AudioDirector.play_music(&"music_box")
