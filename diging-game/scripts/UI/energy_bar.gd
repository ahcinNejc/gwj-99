class_name EnergyBar
extends ProgressBar

@export var player: Player

# Pass in player and set up the bar
func set_up_bar(p: Player) -> void:
	player = p
	max_value = player.max_energy
	value = player.energy
	EventBus.player_energy_changed.connect(update_bar)


func update_bar(current_energy: float) -> void:
	value = player.energy
	max_value = player.max_energy
