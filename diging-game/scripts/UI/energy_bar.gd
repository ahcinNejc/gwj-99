extends ProgressBar

@export var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_value = player.max_energy
	value = player.energy
	EventBus.player_energy_changed.connect(update_bar)
	


func update_bar(current_energy: float) -> void:
	value = player.energy
	max_value = player.max_energy
