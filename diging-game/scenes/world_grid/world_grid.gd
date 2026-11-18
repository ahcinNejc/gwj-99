extends Node2D
class_name WorldGrid

@onready var data_layer: TileMapLayer = $DataLayer

# Index = tier, lowest first
@onready var display_layers: Array[TileMapLayer] = [
	$DirtLayer,
	$StoneLayer,
	$StoneHardLayer,
	$StoneVeryHardLayer,
]

const DATA_SOURCE_ID := 0

const MATERIALS := {
	"Dirt":            {"atlas": Vector2i(0, 0), "tier": 0, "source": 0},
	"Stone":           {"atlas": Vector2i(1, 0), "tier": 1, "source": 0},
	"Copper":          {"atlas": Vector2i(2, 0), "tier": 1, "source": 1},
	"Iron":            {"atlas": Vector2i(3, 0), "tier": 1, "source": 2},
	"StoneHard":       {"atlas": Vector2i(4, 0), "tier": 2, "source": 0},
	"Gold":            {"atlas": Vector2i(5, 0), "tier": 2, "source": 1},
	"Ruby":            {"atlas": Vector2i(6, 0), "tier": 2, "source": 2},
	"StoneVeryHard":   {"atlas": Vector2i(7, 0), "tier": 3, "source": 0},
	"Emerald":         {"atlas": Vector2i(8, 0), "tier": 3, "source": 1},
	"Diamond":         {"atlas": Vector2i(9, 0), "tier": 3, "source": 2},
}

# bit 0 = TL, bit 1 = TR, bit 2 = BL, bit 3 = BR
const CORNERS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]

# corners and stuff?!
const AFFECTED := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

var _info_by_atlas := {}


func _ready() -> void:
	for mat_name in MATERIALS:
		var m: Dictionary = MATERIALS[mat_name]
		_info_by_atlas[m["atlas"]] = m
	
	# Offset every display layer by half a tile
	var half := Vector2(data_layer.tile_set.tile_size) / 2.0
	for layer in display_layers:
		layer.position = data_layer.position - half
	
	# Collect every touched display cell, refresh each only once
	var dirty := {}
	for cell in data_layer.get_used_cells():
		for offset in AFFECTED:
			dirty[cell + offset] = true
	for d in dirty:
		_refresh_display_cell(d)


# Public usable API 

# Place a block
func place_material(cell: Vector2i, mat_name: String) -> void:
	data_layer.set_cell(cell, DATA_SOURCE_ID, MATERIALS[mat_name]["atlas"])
	_update_around(cell)

# Delete a block
func clear_cell(cell: Vector2i) -> void:
	data_layer.erase_cell(cell)
	_update_around(cell)


# Internals methods

# update block state (rendering the block)
func _update_around(data_cell: Vector2i) -> void:
	for offset in AFFECTED:
		_refresh_display_cell(data_cell + offset)

# Returns the material info at a data cell, or null if empty
func _info_at(cell: Vector2i) -> Variant:
	if data_layer.get_cell_source_id(cell) == -1:
		return null
	# Unknown tiles fall back to Dirt
	return _info_by_atlas.get(data_layer.get_cell_atlas_coords(cell), MATERIALS["Dirt"])

# render block
func _refresh_display_cell(d: Vector2i) -> void:
	# Read the four corners once, reuse for every layer
	var infos: Array = []
	for c in CORNERS:
		infos.append(_info_at(d + c))
	
	for tier in display_layers.size():
		var index := 0
		var source := 0
		
		for i in 4:
			var info = infos[i]
			if info == null or info["tier"] < tier:
				continue
			index |= 1 << i
			if info["tier"] == tier:
				source = maxi(source, info["source"])
		
		var layer := display_layers[tier]
		if index == 0:
			layer.erase_cell(d)
		else:
			layer.set_cell(d, source, Vector2i(index, 0))
