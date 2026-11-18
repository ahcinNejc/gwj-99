extends MarginContainer
class_name ShopUI

@export var sell_all_button: Button


func _ready() -> void:
	EventBus.shop_opened.connect(show)
	EventBus.shop_closed.connect(hide)
	EventBus.ore_inventory_changed.connect(_on_inventory_changed)
	if sell_all_button:
		if GameState.ore_inventory.size() <= 0:
			sell_all_button.disabled = true

func _on_inventory_changed(current_inventory) -> void:
	if sell_all_button:
		if current_inventory.size() <= 0:
			sell_all_button.disabled = true
		else:
			sell_all_button.disabled = false
			


func _on_sell_all_button_pressed() -> void:
	print("Pressed sell all")
	GameState.sell_all_ores()
