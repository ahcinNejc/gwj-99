extends CanvasLayer
class_name PauseMenu


func _ready() -> void:
	hide()


func _unhandled_key_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if visible:
			get_tree().paused = false
			hide()
		else:
			get_tree().paused = true
			show()
	


func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()
	AudioManager.play_sfx("ui_click")


func _on_restart_pressed() -> void:
	get_tree().paused = false
	AudioManager.play_sfx("ui_click")
	GameState.money = 20
	get_tree().reload_current_scene()
