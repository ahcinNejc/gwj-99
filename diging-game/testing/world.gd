class_name World
extends Node2D


@onready var player: Player = %Player
@onready var drill: Drill = player.drill
@onready var world_grid: WorldGrid = %WorldGrid
@onready var UI_layer: UserInterfaceLayer = %UI

func _ready() -> void:
	# Assign player too progress bar
	UI_layer.energy_bar.set_up_bar(player)
	
	drill.world_grid = world_grid
	
	# generate world
	world_grid.data_layer.generate()
	world_grid.refresh_display()
	AudioManager.play_music("silly")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
