extends Node
## Plays vibration patterns as timed pulses: [on_ms, off_ms, on_ms, ...].
## Needs the VIBRATE permission in the Android export preset.

const PATTERNS := {
	&"pop": [12],
	&"stuck": [20, 40, 20],
	&"stars": [30, 50, 30, 50, 60],
	&"unlock": [60],
	&"tick": [8],
}

var enabled := true
var _sequence := 0


func play(pattern: StringName) -> void:
	if not enabled or not PATTERNS.has(pattern):
		return
	_sequence += 1
	var sequence := _sequence
	var steps: Array = PATTERNS[pattern]
	for i in steps.size():
		if sequence != _sequence:
			return
		if i % 2 == 0:
			Input.vibrate_handheld(int(steps[i]))
		await get_tree().create_timer(steps[i] / 1000.0, true, false, true).timeout
