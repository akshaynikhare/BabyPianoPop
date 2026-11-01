extends Node
## Owns the Music / SFX / Voice buses and plays pre-rendered OGG clips by name.
## Clips live in res://assets/audio/{sfx,voice,music}/<name>.ogg.

const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_POOL_SIZE := 8

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _voice_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _cache := {}
## Ticks (msec) until which the app's own sound may still be audible to the mic.
## Talk-back ignores the mic before this time so the pet never repeats its own sounds.
var busy_until_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [&"Music", &"SFX", &"Voice"]:
		_ensure_bus(bus)
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player(&"SFX"))
	_voice_player = _make_player(&"Voice")
	_music_player = _make_player(&"Music")
	_preload_all()


func play_sfx(clip: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var stream := _load(SFX_DIR, clip)
	if stream == null:
		return
	var player := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	mark_busy(stream.get_length() / maxf(pitch, 0.01))


## Plays a spoken line, cutting off any line already playing.
func play_voice(clip: StringName) -> void:
	var stream := _load(VOICE_DIR, clip)
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()
	mark_busy(stream.get_length())


## Extends the "own sound playing" window by `seconds` plus a short room-decay tail.
func mark_busy(seconds: float, tail_msec := 400) -> void:
	busy_until_msec = maxi(busy_until_msec, Time.get_ticks_msec() + int(seconds * 1000.0) + tail_msec)


func is_busy() -> bool:
	return Time.get_ticks_msec() < busy_until_msec


func stop_voice() -> void:
	_voice_player.stop()


func play_music(clip: StringName) -> void:
	var stream := _load(MUSIC_DIR, clip)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func set_bus_muted(bus: StringName, muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), muted)


func pause_all() -> void:
	for player in _all_players():
		player.stream_paused = true


func resume_all() -> void:
	for player in _all_players():
		player.stream_paused = false


## Loads every clip up front so the first use of a sound never stalls a frame.
func _preload_all() -> void:
	for dir in [SFX_DIR, VOICE_DIR, MUSIC_DIR]:
		for file in ResourceLoader.list_directory(dir):
			if file.ends_with(".ogg"):
				_load(dir, StringName(file.get_basename()))


func _all_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = _sfx_players.duplicate()
	players.append(_voice_player)
	players.append(_music_player)
	return players


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _ensure_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")


func _load(dir: String, clip: StringName) -> AudioStream:
	var path := dir + String(clip) + ".ogg"
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("AudioDirector: missing clip " + path)
		_cache[path] = null
		return null
	var stream: AudioStream = load(path)
	_cache[path] = stream
	return stream
