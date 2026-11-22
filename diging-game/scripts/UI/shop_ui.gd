extends MarginContainer
class_name ShopUI

@export var sell_all_button: Button
@export var refill_energy_button: Button

@export var refill_percentage: float = 0.25 ## Take a fraction of the peak money
var refill_cost: int = 0

func _ready() -> void:
	EventBus.shop_opened.connect(show)
	EventBus.shop_closed.connect(hide)
	EventBus.ore_inventory_changed.connect(_on_inventory_changed)
	if sell_all_button:
		if GameState.ore_inventory.size() <= 0:
			sell_all_button.disabled = true
	EventBus.money_changed.connect(_on_money_changed)
	
	refill_cost = roundi(GameState.peak_money * refill_percentage)
	%RefillEnergyButton.text = "Refill Energy $" + str(refill_cost)


func _on_inventory_changed(current_inventory) -> void:
	if sell_all_button:
		if current_inventory.size() <= 0:
			sell_all_button.disabled = true
		else:
			sell_all_button.disabled = false
			


func _on_money_changed(money) -> void:
	## Energy button
	if money < refill_cost:
		refill_energy_button.disabled = true
	else:
		refill_energy_button.disabled = false


func _on_sell_all_button_pressed() -> void:
	print("Pressed sell all")
	GameState.sell_all_ores()
	refill_cost = roundi(GameState.peak_money * refill_percentage)
	%RefillEnergyButton.text = "Refill Energy $" + str(refill_cost)

	AudioManager.play_sfx("ui_click")
	AudioManager.play_sfx("money")


func _on_refill_energy_button_pressed() -> void:
	print("Refill energy")
	GameState.money -= refill_cost
	EventBus.refill_energy.emit()
	AudioManager.play_sfx("ui_click")
