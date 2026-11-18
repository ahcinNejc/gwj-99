extends TileMapLayer

signal generated

@export_group("World")
@export var world_seed := 0 ## 0 = random every run
@export var width := 64
@export var depth := 500
@export var data_source_id := 0

@export_group("Surface")
@export var surface_amplitude := 4.0
@export var surface_frequency := 0.02

@export_group("Tier depths (cells below the surface)")
@export var stone_start := 5
@export var hard_start := 150
@export var very_hard_start := 300
@export var boundary_jitter := 2.0

@export_group("Caves")
@export var caves_enabled := true
@export var cave_min_depth := 12
@export var cave_frequency := 0.06
@export var cave_threshold := 0.30 ## higher = fewer caves

# atlas_cords for data_layer ?!?!??!?!
const ATLAS := {
	"Dirt": Vector2i(0, 0),
	"Stone": Vector2i(1, 0),
	"Copper": Vector2i(2, 0),
	"Iron": Vector2i(3, 0),
	"StoneHard": Vector2i(4, 0),
	"Gold": Vector2i(5, 0),
	"Ruby": Vector2i(6, 0),
	"StoneVeryHard": Vector2i(7, 0),
	"Emerald": Vector2i(8, 0),
	"Diamond": Vector2i(9, 0),
}

# tier = base material the ore can replace. Ores are checked top to bottom, first hit wins.
# Higher threshold = rarer. Order each tier's ores from rarest to most common
# if you want the rare one to take priority.
const ORES := [
	{"mat": "Iron",    "tier": "Stone",         "frequency": 0.10, "threshold": 0.50},
	{"mat": "Copper",  "tier": "Stone",         "frequency": 0.10, "threshold": 0.45},
	{"mat": "Ruby",    "tier": "StoneHard",     "frequency": 0.10, "threshold": 0.55},
	{"mat": "Gold",    "tier": "StoneHard",     "frequency": 0.10, "threshold": 0.50},
	{"mat": "Diamond", "tier": "StoneVeryHard", "frequency": 0.10, "threshold": 0.60},
	{"mat": "Emerald", "tier": "StoneVeryHard", "frequency": 0.10, "threshold": 0.55},
]


func _ready() -> void:
	generate()


func generate() -> void:
	clear() # wipes anything painted in the editor
	
	var s := world_seed if world_seed != 0 else randi()
	var surface_noise := _make_noise(s, surface_frequency)
	var boundary_noise := _make_noise(s + 1, 0.05)
	var cave_noise := _make_noise(s + 2, cave_frequency)
	
	# Each ore gets its own noise so veins don't line up with each other
	var ore_noises: Array[FastNoiseLite] = []
	for i in ORES.size():
		ore_noises.append(_make_noise(s + 100 + i, ORES[i]["frequency"]))
	
	for x in width:
		var surface_y := roundi(surface_noise.get_noise_1d(x) * surface_amplitude)
	
		for y in range(surface_y, depth):
			var below := y - surface_y
		
			# Caves
			if caves_enabled and below >= cave_min_depth \
					and cave_noise.get_noise_2d(x, y) > cave_threshold:
				continue
			
			# Base material by depth
			var wobble := boundary_noise.get_noise_2d(x, y) * boundary_jitter
			var mat: String = _tier_for(below + wobble)
			
			# Ore veins replace the base material of their own tier
			for i in ORES.size():
				var ore: Dictionary = ORES[i]
				if ore["tier"] == mat and ore_noises[i].get_noise_2d(x, y) > ore["threshold"]:
					mat = ore["mat"]
					break
			
			set_cell(Vector2i(x, y), data_source_id, ATLAS[mat])
	
	generated.emit()


func _tier_for(d: float) -> String:
	if d < stone_start:
		return "Dirt"
	if d < hard_start:
		return "Stone"
	if d < very_hard_start:
		return "StoneHard"
	return "StoneVeryHard"


func _make_noise(noise_seed: int, freq: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = noise_seed
	n.frequency = freq
	return n
