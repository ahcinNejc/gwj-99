class_name World
extends Node2D


@onready var player: Player = %Player
@onready var drill: Drill = player.drill
@onready var world_grid: WorldGrid = %WorldGrid
@onready var UI_layer: UserInterfaceLayer = %UI

func _ready() -> void:
	# Assign player
	UI_layer.energy_bar.set_up_bar(player)
	player.teleport_position = %Shop.global_position
	drill.world_grid = world_grid
	
	# generate world
	world_grid.generate()
	
	AudioManager.play_music("silly")
