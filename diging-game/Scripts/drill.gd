extends Node2D
class_name Drill

@export var hitbox: Area2D
@export var drill_locator: Marker2D


func _process(delta: float) -> void:
	var direction = (get_global_mouse_position() - global_position).normalized()
	if direction.y < -0.75:
		rotation = lerp_angle(rotation, deg_to_rad(-90), 10 * delta)
	elif direction.y > 0.75:
		rotation = lerp_angle(rotation, deg_to_rad(90), 10 * delta)
	elif direction.x < -0.75:
		rotation = lerp_angle(rotation, deg_to_rad(180), 10 * delta)
	else:
		rotation = lerp_angle(rotation, deg_to_rad(0), 10 * delta)



func deal_damage(amount: float) -> void:
	var world_grid: WorldGrid = get_tree().get_first_node_in_group("Blocks")
	var location: Vector2i = world_grid.data_layer.local_to_map(drill_locator.global_position)
	world_grid.clear_cell(location)
