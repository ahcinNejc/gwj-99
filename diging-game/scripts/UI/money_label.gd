extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.money_changed.connect(update_money_label)
	text = "Money: " + str(roundi(GameState.money))


func update_money_label(current_money) -> void:
	text = "Money: " + str(roundi(current_money))
