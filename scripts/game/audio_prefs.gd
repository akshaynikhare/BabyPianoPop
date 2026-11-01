class_name AudioPrefs
extends RefCounted
## Applies the saved audio preferences. Speech stays audible; music and sound effects follow the
## music switch, quiet mode lowers everything, and the music track follows the age tier.


static func apply(play_music := true) -> void:
	var on := bool(Settings.get_value(&"music_on"))
	AudioDirector.set_bus_muted(&"Music", not on)
	AudioDirector.set_bus_muted(&"SFX", not on)
	AudioDirector.set_quiet(bool(Settings.get_value(&"quiet_mode")))
	if not on:
		AudioDirector.stop_music()
	elif play_music:
		AudioDirector.play_music(GameContent.music_id(Settings.get_value(&"age_tier")))
