extends Node2D
class_name Drill

@export var hitbox: Area2D


func _process(delta: float) -> void:
	var direction = (get_global_mouse_position() - global_position).normalized()
	if direction.y < -0.75:
		rotation = lerp_angle(rotation, deg_to_rad(-90), 10 * delta)
		#rotation_degrees = -90
	elif direction.y > 0.75:
		rotation = lerp_angle(rotation, deg_to_rad(90), 10 * delta)
		#rotation_degrees = 90
	elif direction.x < -0.75:
		rotation = lerp_angle(rotation, deg_to_rad(180), 10 * delta)
		#rotation_degrees = 180
	else:
		rotation = lerp_angle(rotation, deg_to_rad(0), 10 * delta)
		#rotation_degrees = 0


func deal_damage(amount: float) -> void:
	if hitbox.get_overlapping_bodies().size() > 0:
		print("Deal damage")
