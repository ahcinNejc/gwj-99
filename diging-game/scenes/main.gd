extends Node2D


func _ready() -> void:
	SceneManager.change_scene("res://scenes/world.tscn")
	await SceneManager.level_loaded
