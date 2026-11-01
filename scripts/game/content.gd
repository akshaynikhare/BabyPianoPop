class_name GameContent
extends RefCounted
## Static game content: tiers, palettes, candy themes and voice-clip ids.

const TIERS: Array[String] = ["6-12m", "1-2y", "2-3y"]
const DEFAULT_TIER := "1-2y"
const SHAPES: Array[String] = ["★", "♥", "●", "▲", "■"]
const ALPHABET: Array[String] = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
]
const NUMBERS: Array[String] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
const PRAISE_COUNT := 6
const MASCOT_PHRASE_COUNT := 6
const GEAR_PHRASE_COUNT := 4

const TIER_CONFIG := {
	"6-12m": {
		"stage": "Infant",
		"title": "6 – 12 Months",
		"subtitle": "Touch-Enter Glide",
		"badge": "Shapes + A,B,C + 1,2,3",
		"base_speed": 0.62,
		"glide": true,
		"palette_offset": 0,
		"accent": Color("f9a8d4"),
		"voice": &"tier_6_12m",
	},
	"1-2y": {
		"stage": "Young Toddler",
		"title": "1 – 2 Years",
		"subtitle": "Targeted Tap Only",
		"badge": "Shapes + 0–9 + A–J",
		"base_speed": 0.85,
		"glide": false,
		"palette_offset": 1,
		"accent": Color("fcd34d"),
		"voice": &"tier_1_2y",
	},
	"2-3y": {
		"stage": "Toddler",
		"title": "2 – 3+ Years",
		"subtitle": "Precision Tap Only",
		"badge": "Full A–Z, 0–9 & Shapes",
		"base_speed": 1.05,
		"glide": false,
		"palette_offset": 2,
		"accent": Color("c4b5fd"),
		"voice": &"tier_2_3y",
	},
}

## top / mid / bottom gradient stops and the star-pill colour.
const PALETTES: Array[Dictionary] = [
	{"id": "lavender", "top": Color("fce7f3"), "mid": Color("f3e8ff"), "bottom": Color("e0e7ff"), "pill": Color("a855f7")},
	{"id": "peach", "top": Color("fef3c7"), "mid": Color("ffe4e6"), "bottom": Color("ffedd5"), "pill": Color("fb923c")},
	{"id": "mint", "top": Color("d1fae5"), "mid": Color("ccfbf1"), "bottom": Color("e0f2fe"), "pill": Color("14b8a6")},
	{"id": "rose", "top": Color("ffe4e6"), "mid": Color("fce7f3"), "bottom": Color("fae8ff"), "pill": Color("f43f5e")},
	{"id": "sky", "top": Color("e0f2fe"), "mid": Color("dbeafe"), "bottom": Color("e0e7ff"), "pill": Color("3b82f6")},
	{"id": "lemon", "top": Color("fef9c3"), "mid": Color("fef3c7"), "bottom": Color("d1fae5"), "pill": Color("f59e0b")},
]

const THEMES: Array[Dictionary] = [
	{"name": "strawberry", "top": Color("f43f5e"), "mid": Color("ec4899"), "bottom": Color("e11d48"), "shadow": Color("9f1239"), "glow": Color(0.957, 0.247, 0.369, 0.6)},
	{"name": "tangerine", "top": Color("fbbf24"), "mid": Color("fb923c"), "bottom": Color("f97316"), "shadow": Color("c2410c"), "glow": Color(0.984, 0.573, 0.235, 0.6)},
	{"name": "lemon", "top": Color("fcd34d"), "mid": Color("facc15"), "bottom": Color("f59e0b"), "shadow": Color("b45309"), "glow": Color(0.98, 0.8, 0.082, 0.6)},
	{"name": "apple-mint", "top": Color("34d399"), "mid": Color("2dd4bf"), "bottom": Color("059669"), "shadow": Color("047857"), "glow": Color(0.204, 0.827, 0.6, 0.6)},
	{"name": "blue-raspberry", "top": Color("38bdf8"), "mid": Color("3b82f6"), "bottom": Color("4f46e5"), "shadow": Color("1d4ed8"), "glow": Color(0.376, 0.647, 0.98, 0.6)},
	{"name": "grape-jelly", "top": Color("a855f7"), "mid": Color("d946ef"), "bottom": Color("7e22ce"), "shadow": Color("6b21a8"), "glow": Color(0.753, 0.518, 0.988, 0.6)},
]

const SHAPE_VOICE := {
	"★": &"shape_star",
	"♥": &"shape_heart",
	"●": &"shape_circle",
	"▲": &"shape_triangle",
	"■": &"shape_square",
}

const BURST_COLORS := {
	"6-12m": ["f472b6", "38bdf8", "fbbf24", "a78bfa", "ffffff"],
	"1-2y": ["ec4899", "06d6a0", "f59e0b", "8b5cf6", "ffffff"],
	"2-3y": ["d946ef", "10b981", "0ea5e9", "f43f5e", "eab308", "ffffff"],
}


static func is_valid_tier(tier: Variant) -> bool:
	return tier is String and TIERS.has(tier)


static func palette_offset(tier: String) -> int:
	return TIER_CONFIG[tier]["palette_offset"]


static func palette_index(tier: String, completed_rounds: int) -> int:
	return (completed_rounds + palette_offset(tier)) % PALETTES.size()


static func base_speed(tier: String) -> float:
	return TIER_CONFIG[tier]["base_speed"]


static func is_shape(content: String) -> bool:
	return SHAPES.has(content)


static func pool(tier: String) -> Array[String]:
	var out: Array[String] = []
	out.append_array(SHAPES)
	match tier:
		"6-12m":
			out.append_array(["A", "B", "C", "1", "2", "3"])
		"1-2y":
			out.append_array(NUMBERS)
			out.append_array(ALPHABET.slice(0, 10))
		_:
			out.append_array(NUMBERS)
			out.append_array(ALPHABET)
	return out


static func voice_id(content: String) -> StringName:
	if SHAPE_VOICE.has(content):
		return SHAPE_VOICE[content]
	if content.is_valid_int():
		return StringName("number_" + content)
	return StringName("letter_" + content.to_lower())
