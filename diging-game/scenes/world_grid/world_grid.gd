class_name WorldGrid
extends Node2D

# connect drill to this
signal block_broken(cell: Vector2i, material_name: String)

@export_group("World")
@export var world_seed := 0
@export var width := 64
@export var depth := 250

@export_group("Surface")
@export var surface_amplitude := 4.0
@export var surface_frequency := 0.02

@export_group("Tier depths")
@export var stone_start := 5
@export var hard_start := 75
@export var very_hard_start := 150
@export var boundary_jitter := 2.0

@export_group("Caves")
@export var caves_enabled := true
@export var cave_min_depth := 12
@export var cave_frequency := 0.10
@export var cave_threshold := 0.15 ## higher = fewer caves

@export_group("VFX")
@export var vfx_enabled := true
@export var hit_particle_amount := 4
@export var break_particle_amount := 14
@export var particle_size := 2.0 ## Pixels, before the random size variation

@onready var data_layer: TileMapLayer = $DataLayer

const DATA_SOURCE_ID := 0
const DISPLAY_SOURCE_ID := 0 # every display layer uses source 0

# One entry per material. Each needs a display layer node named "<Material>Layer".
# atlas = tile coords on the DATA layer
# tier = 0 Dirt, 1 Stone, 2 StoneHard, 3 StoneVeryHard
# hp = damage needed to break it
# ore = true -> only drawn where a corner is exactly this ore, on top of its tier's base layer
# frequency/threshold = ore vein size and rarity (higher threshold = rarer)
#
# make sure to order tgingszzz:
#  - draw order of the layers (later = on top)
#  - ore generation priority within a tier (first hit wins, so list the rarest first)
const MATERIALS := {
	"Dirt":          {"atlas": Vector2i(0, 0), "tier": 0, "hp": 1.0},
	"Stone":         {"atlas": Vector2i(1, 0), "tier": 1, "hp": 2.0},
	"Iron":        {"atlas": Vector2i(3, 0), "tier": 1, "hp": 4.0, "ore": true, "frequency": 0.10, "threshold": 0.50},
	"Copper":        {"atlas": Vector2i(2, 0), "tier": 1, "hp": 3.0, "ore": true, "frequency": 0.10, "threshold": 0.45},
	"StoneHard":     {"atlas": Vector2i(4, 0), "tier": 2, "hp": 5.0},
	"Ruby":          {"atlas": Vector2i(6, 0), "tier": 2, "hp": 6.0, "ore": true, "frequency": 0.10, "threshold": 0.55},
	"Gold":          {"atlas": Vector2i(5, 0), "tier": 2, "hp": 6.0, "ore": true, "frequency": 0.10, "threshold": 0.50},
	"StoneVeryHard": {"atlas": Vector2i(7, 0), "tier": 3, "hp": 8.0},
	"Diamond":       {"atlas": Vector2i(9, 0), "tier": 3, "hp": 10.0, "ore": true, "frequency": 0.10, "threshold": 0.60},
	"Emerald":       {"atlas": Vector2i(8, 0), "tier": 3, "hp": 9.0, "ore": true, "frequency": 0.10, "threshold": 0.55},
}

# Debris colour per material. Tweak these to match your art.
const DEFAULT_PARTICLE_COLOR := Color("7a5230")
const PARTICLE_COLORS := {
	"Dirt":          Color("ae794dff"),
	"Stone":         Color("a1a1aaff"),
	"Iron":          Color("deb76eff"),
	"Copper":        Color("b26429ff"),
	"StoneHard":     Color("6a6a78"),
	"Ruby":          Color("e0245e"),
	"Gold":          Color("f2c230"),
	"StoneVeryHard": Color("4a4a58"),
	"Diamond":       Color("7fe8ff"),
	"Emerald":       Color("2ecc71"),
}

# bit 0 = TL, bit 1 = TR, bit 2 = BL, bit 3 = BR
const CORNERS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]

# A data cell touches these four display cells
const AFFECTED := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

const NO_CELL := Vector2i(2147483647, 2147483647)

var _probe := RectangleShape2D.new()
var _fade_ramp: Gradient # particle colour fades to transparent
var _infos: Array[Dictionary] = [] # in draw order
var _info_by_name := {}
var _info_by_atlas := {}
var _base_by_tier: Array[String] = [] # tier -> base material name
var _ores: Array[Dictionary] = [] # in generation priority order
var _damage := {} # Vector2i -> accumulated damage


func _ready() -> void:
	_build_lookups()
	
	# Offset every display layer by half a tile
	var half := Vector2(data_layer.tile_set.tile_size) / 2.0
	for info in _infos:
		info["layer"].position = data_layer.position - half
	
	# Particles fade out over their lifetime
	_fade_ramp = Gradient.new()
	_fade_ramp.set_color(0, Color.WHITE)
	_fade_ramp.set_color(1, Color(1, 1, 1, 0))
	
	# render world
	refresh_display()


func _build_lookups() -> void:
	for mat_name in MATERIALS:
		var info: Dictionary = MATERIALS[mat_name].duplicate()
		info["name"] = mat_name
		
		var layer := get_node_or_null(mat_name + "Layer") as TileMapLayer ## Making new Ore/Mat name + "Layer"
		if layer == null:
			push_error("WorldGrid: missing display layer node '%sLayer'" % mat_name)
			continue
		info["layer"] = layer
		move_child(layer, get_child_count() - 1) # scene order now matches the draw order above
		
		_infos.append(info)
		_info_by_name[mat_name] = info
		_info_by_atlas[info["atlas"]] = info
		
		if info.get("ore", false):
			_ores.append(info)
		else:
			_base_by_tier.append(mat_name) # relies on bases being listed in tier order


# Public API

# All non-empty cells overlapped by the Area2D's collision shapes
func get_cells_in_area(area: Area2D) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	_probe.size = Vector2(data_layer.tile_set.tile_size)

	for child in area.get_children():
		var cs := child as CollisionShape2D
		if cs == null or cs.disabled or cs.shape == null:
			continue
		
		var xform := cs.global_transform
		var bounds: Rect2 = xform * cs.shape.get_rect() # world-space bounding box
		var min_cell := world_to_cell(bounds.position)
		var max_cell := world_to_cell(bounds.end)
		
		for x in range(min_cell.x, max_cell.x + 1):
			for y in range(min_cell.y, max_cell.y + 1):
				var cell := Vector2i(x, y)
				if cell in result or material_at(cell) == "":
					continue
				var tile_xform := Transform2D(0.0, cell_to_world(cell))
				if cs.shape.collide(xform, _probe, tile_xform):
					result.append(cell)
	return result

# Closest solid cell inside the area to the origin, or NO_CELL
func closest_cell_in_area(area: Area2D, origin: Vector2) -> Vector2i:
	var best := NO_CELL
	var best_dist := INF
	for cell in get_cells_in_area(area):
		var d := origin.distance_squared_to(cell_to_world(cell))
		if d < best_dist:
			best_dist = d
			best = cell
	return best

func cell_to_world(cell: Vector2i) -> Vector2:
	return data_layer.to_global(data_layer.map_to_local(cell))

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return data_layer.local_to_map(data_layer.to_local(world_pos))

# Material name at a cell, or "" if empty
func material_at(cell: Vector2i) -> String:
	var info = _info_at(cell)
	return "" if info == null else info["name"]

func place_material(cell: Vector2i, mat_name: String) -> void:
	data_layer.set_cell(cell, DATA_SOURCE_ID, MATERIALS[mat_name]["atlas"])
	_update_around(cell)

func clear_cell(cell: Vector2i) -> void:
	data_layer.erase_cell(cell)
	_damage.erase(cell)
	_update_around(cell)

# Returns true if this hit broke the block.
# source_pos (optional, world position of the drill tip) makes hit sparks fly back toward it.
func damage_block(cell: Vector2i, amount: float, source_pos := Vector2.INF) -> bool:
	var mat := material_at(cell)
	if mat == "":
		return false
	
	_damage[cell] = _damage.get(cell, 0.0) + amount
	if _damage[cell] < MATERIALS[mat]["hp"]:
		_spawn_hit_particles(cell, mat, source_pos)
		return false
	
	_spawn_break_particles(cell, mat)
	clear_cell(cell)
	AudioManager.play_sfx("block_break", false, 10.0)
	block_broken.emit(cell, mat)
	GameState.ore_mined(mat)
	return true

# Rebuild every display layer from the data layer
func refresh_display() -> void:
	for info in _infos:
		info["layer"].clear()
	
	var dirty := {}
	for cell in data_layer.get_used_cells():
		for offset in AFFECTED:
			dirty[cell + offset] = true
	for d in dirty:
		_refresh_display_cell(d)

# World generation
func generate(seed: int = 0) -> void:
	data_layer.clear()
	_damage.clear()
	
	if seed != 0:
		world_seed = seed
	
	var s := world_seed if world_seed != 0 else randi()
	var surface_noise := _make_noise(s, surface_frequency)
	var boundary_noise := _make_noise(s + 1, 0.05)
	var cave_noise := _make_noise(s + 2, cave_frequency)
	
	# Each ore gets its own noise so veins don't line up
	var ore_noises: Array[FastNoiseLite] = []
	for i in _ores.size():
		ore_noises.append(_make_noise(s + 100 + i, _ores[i]["frequency"]))
	
	for x in width:
		var surface_y := roundi(surface_noise.get_noise_1d(x) * surface_amplitude)
		
		for y in range(surface_y, depth):
			var below := y - surface_y
			
			if caves_enabled and below >= cave_min_depth \
					and cave_noise.get_noise_2d(x, y) > cave_threshold:
				continue
			
			var wobble := boundary_noise.get_noise_2d(x, y) * boundary_jitter
			var tier := _tier_for(below + wobble)
			var mat: String = _base_by_tier[tier]
			
			# Ore veins replace the base material of their own tier
			for i in _ores.size():
				if _ores[i]["tier"] == tier and ore_noises[i].get_noise_2d(x, y) > _ores[i]["threshold"]:
					mat = _ores[i]["name"]
					break
			
			data_layer.set_cell(Vector2i(x, y), DATA_SOURCE_ID, MATERIALS[mat]["atlas"])
	
	refresh_display()

# Rebuild only a rectangle of data cells (Will mostly not be used, just incase for some weird edge cases :) )
func refresh_region(rect: Rect2i) -> void:
	for x in range(rect.position.x, rect.end.x + 2):
		for y in range(rect.position.y, rect.end.y + 2):
			_refresh_display_cell(Vector2i(x, y))


# Private methods

func _tier_for(d: float) -> int:
	if d < stone_start:
		return 0
	if d < hard_start:
		return 1
	if d < very_hard_start:
		return 2
	return 3

func _make_noise(noise_seed: int, freq: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = noise_seed
	n.frequency = freq
	return n

func _update_around(data_cell: Vector2i) -> void:
	for offset in AFFECTED:
		_refresh_display_cell(data_cell + offset)

# Material info at a data cell, or null if empty. Unknown tiles fall back to Dirt.
func _info_at(cell: Vector2i) -> Variant:
	if data_layer.get_cell_source_id(cell) == -1:
		return null
	return _info_by_atlas.get(data_layer.get_cell_atlas_coords(cell), _info_by_name["Dirt"])

func _refresh_display_cell(d: Vector2i) -> void:
	# Read the four corners once, reuse for every layer
	var corners: Array = []
	for c in CORNERS:
		corners.append(_info_at(d + c))
	
	for info in _infos:
		var is_ore: bool = info.get("ore", false)
		var index := 0
		
		for i in 4:
			var c = corners[i]
			if c == null:
				continue
			if is_ore:
				if c["name"] != info["name"]:
					continue # ore layers only mark their own ore
			elif c["tier"] < info["tier"]:
				continue # base layers mark their tier and everything above it
			index |= 1 << i
		
		var layer: TileMapLayer = info["layer"]
		if index == 0:
			layer.erase_cell(d)
		else:
			layer.set_cell(d, DISPLAY_SOURCE_ID, Vector2i(index, 0))


# VFX

func _spawn_hit_particles(cell: Vector2i, mat_name: String, source_pos: Vector2) -> void:
	var dir := Vector2.UP
	var spread := 180.0
	if source_pos != Vector2.INF:
		dir = (source_pos - cell_to_world(cell)).normalized()
		spread = 50.0
	_spawn_particles(cell, mat_name, hit_particle_amount, 40.0, 90.0, dir, spread, 0.25)

func _spawn_break_particles(cell: Vector2i, mat_name: String) -> void:
	_spawn_particles(cell, mat_name, break_particle_amount, 50.0, 140.0, Vector2.UP, 180.0, 0.5)

func _spawn_particles(cell: Vector2i, mat_name: String, amount: int,
		speed_min: float, speed_max: float, dir: Vector2, spread: float, life: float) -> void:
	if not vfx_enabled:
		return
	
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = life
	p.local_coords = false # particles stay in the world instead of following the node
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = particle_size
	p.scale_amount_max = particle_size * 1.6
	p.color = PARTICLE_COLORS.get(mat_name, DEFAULT_PARTICLE_COLOR)
	p.color_ramp = _fade_ramp
	p.z_index = 10
	p.finished.connect(p.queue_free)
	
	add_child(p)
	p.global_position = cell_to_world(cell)
	p.emitting = true
