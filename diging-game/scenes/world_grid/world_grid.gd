extends Node2D

@onready var data_layer: TileMapLayer = $DataLayer
@onready var display_layer: TileMapLayer = $DisplayLayer

const SOURCE_ID := 0 # display_layer atlas ID

const FILLED_ATLAS := Vector2i(1, 0)

const MATERIAL_ATLAS := {
	"Dirt": Vector2i(0, 0),
	"Stone": Vector2i(1, 0),
	"Copper": Vector2i(2, 0),
	"Iron": Vector2i(3, 0),
	"Gold": Vector2i(4, 0),
	"Emerald": Vector2i(5, 0),
	"Diamond": Vector2i(6, 0),
}


# bit 0 = TL, bit 1 = TR, bit 2 = BL, bit 3 = BR (This is for settign the display layerr)
const CORNERS := [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]

# A data cell (x,y) touches these four display cells (This is for the data layer)
const AFFECTED := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

func _ready() -> void:
	# Create offset
	var half := Vector2(data_layer.tile_set.tile_size) / 2.0
	display_layer.position = data_layer.position - half
	
	# Build visuals for anything painted in the editor
	for cell in data_layer.get_used_cells():
		_update_around(cell)

func set_filled(cell: Vector2i, filled: bool) -> void:
	if filled:
		data_layer.set_cell(cell, SOURCE_ID, FILLED_ATLAS)
	else:
		data_layer.erase_cell(cell)
	_update_around(cell)

func _update_around(data_cell: Vector2i) -> void:
	for offset in AFFECTED:
		_refresh_display_cell(data_cell + offset)

func _refresh_display_cell(d: Vector2i) -> void:
	var index := 0
	
	# Check all four corners
	for i in 4:
		if data_layer.get_cell_source_id(d + CORNERS[i]) != -1: # checks if cell is not empty
			index |= 1 << i # OR assignment with bit-shift for selectin the atlas later, ask kyle if confusing (I'll try my best to explain)
	if index == 0:
		display_layer.erase_cell(d)
	else:
		# 4x4 atlas, laid out by bitmask index
		print(Vector2i(index, 0))
		display_layer.set_cell(d, SOURCE_ID, Vector2i(index, 0))
