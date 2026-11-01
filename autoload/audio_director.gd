extends Node
## Owns the Music / SFX / Voice buses and plays pre-rendered OGG clips by name.
## Clips live in res://assets/audio/{sfx,voice,music}/<name>.ogg. An SFX id that only exists as
## numbered files (pop_1.ogg, pop_2.ogg, ...) is a variant group: each play picks one of them.

const SFX_DIR := "res://assets/audio/sfx/"
const VOICE_DIR := "res://assets/audio/voice/"
const MUSIC_DIR := "res://assets/audio/music/"
const SFX_POOL_SIZE := 12

## The voice is the anchor. Files are about -16 LUFS for the voice, -22 for SFX (-25 for UI) and
## -20 for music, so these buses leave SFX roughly 9 dB and music 10 dB under the voice.
const VOICE_BUS_DB := 0.0
const SFX_BUS_DB := -3.0
const MUSIC_BUS_DB := -6.0
## Quiet mode lowers the whole mix on Master, ahead of the limiter's ceiling.
const QUIET_MASTER_DB := -8.0
const LIMITER_CEILING_DB := -1.0

const SFX_PITCH_JITTER := 0.03
const SFX_VOLUME_JITTER_DB := 1.5
## A sound asked for again this soon is dropped, so mashing can't stack copies into distortion.
const SFX_RETRIGGER_MSEC := 40

const MUSIC_FADE_SECS := 1.2
const MUSIC_SILENT_DB := -40.0

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_clips: Array[StringName] = []
var _sfx_next := 0
var _sfx_last_msec := {}
var _variants := SfxVariants.new()
var _voice_player: AudioStreamPlayer
var _music_players: Array[AudioStreamPlayer] = []
var _music_active := 0
var _music_fade: Tween
var _cache := {}
## Ticks (msec) until which the app's own sound may still be audible to the mic.
## Talk-back ignores the mic before this time so the pet never repeats its own sounds.
var busy_until_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(&"Music", MUSIC_BUS_DB)
	_ensure_bus(&"SFX", SFX_BUS_DB)
	_ensure_bus(&"Voice", VOICE_BUS_DB)
	_add_limiter()
	for i in SFX_POOL_SIZE:
		_sfx_players.append(_make_player(&"SFX"))
	_sfx_clips.resize(SFX_POOL_SIZE)
	_voice_player = _make_player(&"Voice")
	for i in 2:
		_music_players.append(_make_player(&"Music"))
	_preload_all()


## Plays `clip`, or one of its variants. Everything but the fixed sounds gets a small random
## pitch and volume change on top of `volume_db` and `pitch`.
func play_sfx(clip: StringName, volume_db := 0.0, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_sfx_last_msec.get(clip, -SFX_RETRIGGER_MSEC)) < SFX_RETRIGGER_MSEC:
		return
	var stream := _load(SFX_DIR, _variants.pick(clip))
	if stream == null:
		return
	_sfx_last_msec[clip] = now
	if SfxVariants.varies(clip):
		volume_db += randf_range(-SFX_VOLUME_JITTER_DB, SFX_VOLUME_JITTER_DB)
		pitch *= randf_range(1.0 - SFX_PITCH_JITTER, 1.0 + SFX_PITCH_JITTER)
	var slot := _free_sfx_slot()
	var player := _sfx_players[slot]
	_sfx_clips[slot] = clip
	_sfx_next = (slot + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
	mark_busy(stream.get_length() / maxf(pitch, 0.01))


## Cuts every playing copy of `clip`, e.g. the gear hold tone when the finger lifts early.
func stop_sfx(clip: StringName) -> void:
	for slot in SFX_POOL_SIZE:
		if _sfx_clips[slot] == clip and _sfx_players[slot].playing:
			_sfx_players[slot].stop()


## Plays a spoken line, cutting off any line already playing. Sound effects have their own
## players, so they can never cut it.
func play_voice(clip: StringName) -> void:
	var stream := _load(VOICE_DIR, clip)
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()
	mark_busy(stream.get_length())


## Length of a spoken line in seconds, 0 when the clip is missing.
func voice_length(clip: StringName) -> float:
	var stream := _load(VOICE_DIR, clip)
	return stream.get_length() if stream != null else 0.0


## Extends the "own sound playing" window by `seconds` plus a short room-decay tail.
func mark_busy(seconds: float, tail_msec := 400) -> void:
	busy_until_msec = maxi(busy_until_msec, Time.get_ticks_msec() + int(seconds * 1000.0) + tail_msec)


func is_busy() -> bool:
	return Time.get_ticks_msec() < busy_until_msec


func stop_voice() -> void:
	_voice_player.stop()


## Loops `clip`, crossfading from the track already playing.
func play_music(clip: StringName) -> void:
	var stream := _load(MUSIC_DIR, clip)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var current := _music_players[_music_active]
	if current.stream == stream and current.playing:
		return
	_music_active = 1 - _music_active
	var next := _music_players[_music_active]
	if _music_fade:
		_music_fade.kill()
	next.stream = stream
	next.volume_db = MUSIC_SILENT_DB
	next.play()
	_music_fade = create_tween().set_parallel(true)
	_music_fade.tween_property(next, "volume_db", 0.0, MUSIC_FADE_SECS)
	if current.playing:
		_music_fade.tween_property(current, "volume_db", MUSIC_SILENT_DB, MUSIC_FADE_SECS)
		_music_fade.chain().tween_callback(current.stop)


func stop_music() -> void:
	if _music_fade:
		_music_fade.kill()
	for player in _music_players:
		player.stop()


func set_bus_muted(bus: StringName, muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), muted)


## Quiet mode: the whole mix sits `QUIET_MASTER_DB` lower.
func set_quiet(on: bool) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), QUIET_MASTER_DB if on else 0.0)


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
				var clip := StringName(file.get_basename())
				_load(dir, clip)
				if dir == SFX_DIR:
					_variants.add(clip)


## The next pool slot that isn't playing, so long sounds are only cut when all slots are busy.
func _free_sfx_slot() -> int:
	for step in SFX_POOL_SIZE:
		var slot := (_sfx_next + step) % SFX_POOL_SIZE
		if not _sfx_players[slot].playing:
			return slot
	return _sfx_next


func _all_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = _sfx_players.duplicate()
	players.append(_voice_player)
	players.append_array(_music_players)
	return players


func _make_player(bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _ensure_bus(bus: StringName, volume_db: float) -> void:
	if AudioServer.get_bus_index(bus) == -1:
		AudioServer.add_bus()
		var created := AudioServer.bus_count - 1
		AudioServer.set_bus_name(created, bus)
		AudioServer.set_bus_send(created, &"Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), volume_db)


## Last in the chain on Master, so no mix of overlapping sounds can clip.
func _add_limiter() -> void:
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = LIMITER_CEILING_DB
	AudioServer.add_bus_effect(AudioServer.get_bus_index(&"Master"), limiter)


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
