extends MarginContainer
class_name ShopUI

@export var sell_all_button: Button
@export var refill_energy_button: Button


func _ready() -> void:
	EventBus.shop_opened.connect(show)
	EventBus.shop_closed.connect(hide)
	EventBus.ore_inventory_changed.connect(_on_inventory_changed)
	if sell_all_button:
		if GameState.ore_inventory.size() <= 0:
			sell_all_button.disabled = true
	EventBus.money_changed.connect(_on_money_changed)


func _on_inventory_changed(current_inventory) -> void:
	if sell_all_button:
		if current_inventory.size() <= 0:
			sell_all_button.disabled = true
		else:
			sell_all_button.disabled = false
			


func _on_money_changed(money) -> void:
	## Energy button
	if money < 10:
		refill_energy_button.disabled = true
	else:
		refill_energy_button.disabled = false
		


func _on_sell_all_button_pressed() -> void:
	print("Pressed sell all")
	GameState.sell_all_ores()


func _on_refill_energy_button_pressed() -> void:
	print("Refill energy")
	GameState.money -= 10
	EventBus.refill_energy.emit()
