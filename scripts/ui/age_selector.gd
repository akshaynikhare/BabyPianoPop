class_name AgeSelector
extends Control
## Three stage cards plus a 0-2 slider. Choosing a tier saves it and gives audible feedback.

signal tier_chosen(tier: String)

const CARD_H := 188.0
const GAP := 14.0
const SLIDER_TOP := CARD_H + 40.0
const SLIDER_H := 64.0
const INFO_TOP := SLIDER_TOP + SLIDER_H + 22.0
const TOTAL_H := INFO_TOP + 78.0

var tier: String = GameContent.DEFAULT_TIER
var knob := 1.0:
	set(v):
		knob = v
		queue_redraw()

var _cards: Array[CozyButton] = []
var _dragging := false
var _knob_tween: Tween


func _init() -> void:
	custom_minimum_size = Vector2(0, TOTAL_H)
	for i in 3:
		var tier_id: String = GameContent.TIERS[i]
		var cfg: Dictionary = GameContent.TIER_CONFIG[tier_id]
		var card := CozyButton.new()
		card.text = cfg["title"]
		card.subtext = cfg["stage"]
		card.font_size = 31
		card.sub_size = 23
		card.radius = 26.0
		card.depth = 9.0
		card.activated.connect(_choose.bind(i))
		add_child(card)
		_cards.append(card)
	resized.connect(_layout)


func _ready() -> void:
	var saved: Variant = Settings.get_value(&"age_tier")
	set_tier(saved if GameContent.is_valid_tier(saved) else GameContent.DEFAULT_TIER, true)
	_layout()


func set_tier(new_tier: String, instant := false) -> void:
	tier = new_tier
	var index := GameContent.TIERS.find(tier)
	for i in 3:
		var accent: Color = GameContent.TIER_CONFIG[GameContent.TIERS[i]]["accent"]
		_cards[i].selected = i == index
		_cards[i].fill = accent if i == index else UIStyle.CREAM
	if _knob_tween:
		_knob_tween.kill()
	if instant:
		knob = float(index)
	else:
		_knob_tween = create_tween()
		_knob_tween.tween_property(self, "knob", float(index), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _layout() -> void:
	var w := (size.x - GAP * 2.0) / 3.0
	for i in 3:
		_cards[i].position = Vector2(i * (w + GAP), 0)
		_cards[i].size = Vector2(w, CARD_H)
	queue_redraw()


func _stop_x(i: float) -> float:
	var w := (size.x - GAP * 2.0) / 3.0
	return w * 0.5 + i * (w + GAP)


func _choose(index: int) -> void:
	var new_tier: String = GameContent.TIERS[index]
	var changed := new_tier != tier
	set_tier(new_tier)
	if not changed and _dragging:
		return
	Settings.set_value(&"age_tier", new_tier)
	AudioDirector.play_sfx(&"pop")
	AudioDirector.play_voice(GameContent.TIER_CONFIG[new_tier]["voice"])
	Haptics.play(&"tick")
	tier_chosen.emit(new_tier)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y >= SLIDER_TOP - 16.0 and event.position.y <= SLIDER_TOP + SLIDER_H + 16.0:
			_dragging = true
			_slide_to(event.position.x)
		elif not event.pressed:
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_slide_to(event.position.x)
		accept_event()


func _slide_to(x: float) -> void:
	var best := 0
	var best_d := INF
	for i in 3:
		var d := absf(x - _stop_x(i))
		if d < best_d:
			best_d = d
			best = i
	if GameContent.TIERS[best] != tier:
		_choose(best)


func _draw() -> void:
	var cy := SLIDER_TOP + SLIDER_H * 0.5
	var x0 := _stop_x(0.0)
	var x1 := _stop_x(2.0)
	draw_style_box(UIStyle.box(UIStyle.CREAM_SHADE, 15.0, 5.0), Rect2(x0 - 34, cy - 15, x1 - x0 + 68, 30))
	var kx := lerpf(x0, x1, knob / 2.0)
	var fill_to := Rect2(x0 - 34 + 5, cy - 15 + 5, kx - x0 + 34 - 5, 20)
	var accent: Color = GameContent.TIER_CONFIG[GameContent.TIERS[clampi(roundi(knob), 0, 2)]]["accent"]
	draw_style_box(UIStyle.box(accent, 10.0, 0.0), fill_to)
	for i in 3:
		draw_circle(Vector2(_stop_x(i), cy), 7.0, UIStyle.BROWN)
	draw_circle(Vector2(kx, cy + 5.0), 31.0, UIStyle.BROWN_SOFT)
	draw_circle(Vector2(kx, cy), 31.0, UIStyle.BROWN)
	draw_circle(Vector2(kx, cy), 25.5, UIStyle.CREAM)
	draw_circle(Vector2(kx, cy), 14.0, accent)

	var cfg: Dictionary = GameContent.TIER_CONFIG[tier]
	UIStyle.draw_centered(self, cfg["subtitle"], Vector2(size.x * 0.5, INFO_TOP + 14.0), 34, UIStyle.TEXT, 700)
	UIStyle.draw_centered(self, cfg["badge"], Vector2(size.x * 0.5, INFO_TOP + 56.0), 28, UIStyle.TEXT_SOFT, 600)
