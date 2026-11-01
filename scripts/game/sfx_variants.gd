class_name SfxVariants
extends RefCounted
## Variant groups of sound effects. Files named <group>_1 ... <group>_N play as <group>: each pick
## is random but never the one before. Also says which sounds must stay unvaried.

## Sounds that always play unvaried: the UI, the star chime and the celebration jingle.
const FIXED_PREFIXES: Array[String] = ["ui_", "star", "celebrate"]

var _groups := {}
var _last := {}


## Files that aren't named <group>_<number> are not part of any group.
func add(clip: StringName) -> void:
	var name := String(clip)
	var cut := name.rfind("_")
	if cut > 0 and name.substr(cut + 1).is_valid_int():
		var group: Array = _groups.get_or_add(StringName(name.left(cut)), [])
		group.append(clip)


## A random member of `clip`'s group that differs from the last pick, or `clip` when it has none.
func pick(clip: StringName) -> StringName:
	var group: Array = _groups.get(clip, [])
	if group.is_empty():
		return clip
	var index := randi() % group.size()
	if index == _last.get(clip, -1) and group.size() > 1:
		index = (index + 1 + randi() % (group.size() - 1)) % group.size()
	_last[clip] = index
	return group[index]


static func varies(clip: StringName) -> bool:
	for prefix in FIXED_PREFIXES:
		if String(clip).begins_with(prefix):
			return false
	return true
