class_name JellyBear
extends Node2D
## Jelly Bear mascot with idle / happy / encourage / celebrate moods driven by tweens.

var art := _Face.new()
var rest_mood := &"idle"
var mood := &"idle"

var _aura := _Aura.new()
var _idle_tween: Tween
var _mood_tween: Tween
var _aura_tween: Tween
var _token := 0
var _diameter := 100.0


## Holds the two baked faces and swaps between them when the eyes change.
class _Face extends Node2D:
	var open := BakedArt.new()
	var happy := BakedArt.new()
	var happy_eyes := false:
		set(v):
			happy_eyes = v
			open.visible = not v
			happy.visible = v

	func _init() -> void:
		add_child(open)
		add_child(happy)
		happy.visible = false


class _Aura extends Node2D:
	var radius := 60.0

	func _draw() -> void:
		for i in 6:
			draw_circle(Vector2.ZERO, radius * (1.0 - i * 0.14), Color(0.996, 0.94, 0.54, 0.14))


func _init(diameter := 100.0) -> void:
	_diameter = diameter
	_aura.radius = diameter * 0.62
	_aura.visible = false
	add_child(_aura)
	add_child(art)


func _ready() -> void:
	bake()
	_set_face(rest_mood)
	_start_idle()


## Renders both faces at the current on-screen size. Call again when the parent scale changes.
func bake() -> void:
	var k := BakedArt.window_scale(get_viewport()) * absf(get_global_transform().get_scale().x)
	var area := Rect2(-_diameter * 0.56, -_diameter * 0.56, _diameter * 1.12, _diameter * 1.12)
	for pair in [[art.open, false], [art.happy, true]]:
		var drawing := JellyBearArt.new()
		drawing.size = _diameter
		drawing.happy_eyes = pair[1]
		(pair[0] as BakedArt).bake(drawing, area, k)


func set_diameter(diameter: float) -> void:
	_diameter = diameter
	_aura.radius = diameter * 0.62
	_aura.queue_redraw()
	if is_inside_tree():
		bake()


func set_rest_mood(m: StringName) -> void:
	rest_mood = m
	if mood == &"idle":
		_set_face(m)


## Plays a one-shot mood animation, then settles back to the resting mood after hold_ms.
func set_mood(m: StringName, hold_ms := 0) -> void:
	_token += 1
	var token := _token
	mood = m
	_set_face(m)
	_stop_idle()
	if _mood_tween:
		_mood_tween.kill()
	art.position = Vector2.ZERO
	art.rotation = 0.0
	art.scale = Vector2.ONE
	var d := _diameter
	_mood_tween = create_tween()
	match m:
		&"happy":
			_mood_tween.set_parallel(true)
			_mood_tween.tween_property(art, "position:y", -d * 0.1, 0.18).set_ease(Tween.EASE_OUT)
			_mood_tween.tween_property(art, "scale", Vector2.ONE * 1.12, 0.18)
			_mood_tween.chain().tween_property(art, "position:y", d * 0.02, 0.2)
			_mood_tween.parallel().tween_property(art, "scale", Vector2.ONE * 0.97, 0.2)
			_mood_tween.chain().tween_property(art, "position:y", 0.0, 0.2)
			_mood_tween.parallel().tween_property(art, "scale", Vector2.ONE, 0.2)
		&"encourage":
			for deg in [-8.0, 8.0, -4.0, 0.0]:
				_mood_tween.tween_property(art, "rotation", deg_to_rad(deg), 0.15).set_trans(Tween.TRANS_SINE)
		&"celebrate":
			_mood_tween.set_parallel(true)
			_mood_tween.tween_property(art, "position:y", -d * 0.14, 0.15).set_ease(Tween.EASE_OUT)
			_mood_tween.tween_property(art, "rotation", deg_to_rad(-12.0), 0.15)
			_mood_tween.chain().tween_property(art, "position:y", 0.0, 0.15)
			_mood_tween.parallel().tween_property(art, "rotation", deg_to_rad(12.0), 0.15)
			_mood_tween.chain().tween_property(art, "position:y", -d * 0.1, 0.15)
			_mood_tween.parallel().tween_property(art, "rotation", deg_to_rad(-6.0), 0.15)
			_mood_tween.chain().tween_property(art, "position:y", 0.0, 0.15)
			_mood_tween.parallel().tween_property(art, "rotation", 0.0, 0.15)
		_:
			_mood_tween.kill()
			_start_idle()
			return
	var hold := maxf(hold_ms / 1000.0, 0.65)
	get_tree().create_timer(hold, false).timeout.connect(_settle.bind(token))


func _settle(token: int) -> void:
	if token != _token:
		return
	mood = &"idle"
	_set_face(rest_mood)
	_start_idle()


func _set_face(m: StringName) -> void:
	var f := m if m != &"idle" else rest_mood
	art.happy_eyes = f == &"happy" or f == &"celebrate"
	var celebrating := m == &"celebrate"
	if celebrating and not _aura.visible:
		if _aura_tween:
			_aura_tween.kill()
		_aura_tween = create_tween().set_loops()
		_aura_tween.tween_property(_aura, "scale", Vector2.ONE * 1.08, 0.35).from(Vector2.ONE * 0.92)
		_aura_tween.tween_property(_aura, "scale", Vector2.ONE * 0.92, 0.35)
	elif not celebrating and _aura_tween:
		_aura_tween.kill()
		_aura_tween = null
	_aura.visible = celebrating


func _start_idle() -> void:
	if not is_inside_tree():
		return
	_stop_idle()
	_idle_tween = create_tween().set_loops()
	var amp := _diameter * 0.03
	_idle_tween.tween_property(art, "position:y", -amp, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(art, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_idle() -> void:
	if _idle_tween:
		_idle_tween.kill()
		_idle_tween = null
