extends CanvasLayer
class_name PauseMenu


func _ready() -> void:
	hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = true
		show()
	


func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
