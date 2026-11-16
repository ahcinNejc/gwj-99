extends Node




var money: float = 0:
	set(value):
		money = value
		EventBus.money_changed.emit(money)


var ore_inventory: Dictionary[String, OreData] = {}

func add_ore_to_inventory(ore_to_add: OreData) -> void:
	print("Adding ore to inventory: ", ore_to_add.display_name)
	if ore_to_add.display_name in ore_inventory.keys():
		ore_inventory[ore_to_add.display_name].amount_in_stack += ore_to_add.amount_in_stack
	else:
		ore_inventory[ore_to_add.display_name] = ore_to_add
	print("Current Ore Inventory:")
	for ore in ore_inventory.keys():
		print("    " ,ore," ", ore_inventory[ore].amount_in_stack)
	EventBus.ore_inventory_changed.emit(ore_inventory)

## Sell all ores based on the stack and value, return how much money player gained
func sell_all_ores() -> float:
	print("Selling all ores")
	# gained could also be used for UI to show how much we gained
	var gained: float = 0
	for ore in ore_inventory.keys():
		gained += ore_inventory[ore].amount_in_stack * ore_inventory[ore].value
		money += gained
	# clear inventory
	ore_inventory = {}
	print("Gained: ", gained)
	print("Current money: ", money)
	return gained
