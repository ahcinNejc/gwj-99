extends Node2D
class_name Drill



func _process(delta: float) -> void:
	var direction = (get_global_mouse_position() - global_position).normalized()
	if direction.y < -0.75:
		rotation_degrees = -90
	elif direction.y > 0.75:
		rotation_degrees = 90
	elif direction.x < -0.75:
		rotation_degrees = 180
	else:
		rotation_degrees = 0
		
