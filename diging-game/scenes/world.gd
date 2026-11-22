class_name World
extends Node2D

signal in_china

@onready var player: Player = %Player
@onready var drill: Drill = player.drill
@onready var world_grid: WorldGrid = %WorldGrid
@onready var UI_layer: UserInterfaceLayer = %UI
@onready var shop: Shop = %Shop

var china_location: float
var reached_china: bool = false

func _ready() -> void:
	# set up for upgrades
	china_location = world_grid.cell_to_world(Vector2i(0, world_grid.depth - 1)).y
	shop.shop_ui.player = player
	
	# Assign player
	UI_layer.energy_bar.set_up_bar(player)
	player.teleport_position = %Shop.global_position
	drill.world_grid = world_grid
	
	# generate world
	world_grid.generate()
	
	AudioManager.play_music("silly")

func _process(delta: float) -> void:
	if player.global_position.y > china_location:
		get_tree().change_scene_to_file("uid://dtw5rt2xeyrno")
