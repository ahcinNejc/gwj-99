class_name TeleportLabel
extends Label

var player: Player

func _process(delta: float) -> void:
	if player:
		if player.can_teleport and player.energy <= (player.max_energy * player.teleport_energy_threshold):
			visible = true
			text = "\"R\" to return to surface\ncost: $" + str(round(GameState.peak_money * player.debt_scale))
		else:
			visible = false
