extends Control
class_name Credits

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_sfx("china", false, 10)
	AudioManager.play_music("china")
