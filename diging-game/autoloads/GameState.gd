extends Node



var ORES = {
	"Iron": preload("uid://ddrw7hwqyj64u"),
	"Copper":  preload("uid://bu8jpodl1e8a6"),
	"Ruby": preload("uid://c463kg04w8tt8"),
	"Gold":   preload("uid://csuvmflgwwqic"),
	"Diamond":  preload("uid://tardxy3pqgs2"),
	"Emerald": preload("uid://tardxy3pqgs2"),
}

# The players money highest point
var peak_money: int = roundi(money)

var money: float = 0:
	set(value):
		if value > peak_money:
			peak_money = roundi(money)
		money = value
		EventBus.money_changed.emit(money)


var ore_inventory: Dictionary[String, OreData] = {}

func ore_mined(ore_name: String) -> void:
	if ore_name in ORES.keys():
		add_ore_to_inventory(ORES[ore_name])

func add_ore_to_inventory(ore_to_add: OreData) -> void:
	print("Adding ore to inventory: ", ore_to_add.display_name)
	## duplicate is neede for reasources, otherwisi the amount breaks
	var ore_duplicate = ore_to_add.duplicate()
	if ore_duplicate.display_name in ore_inventory.keys():
		ore_inventory[ore_duplicate.display_name].amount_in_stack += ore_duplicate.amount_in_stack
	else:
		ore_inventory[ore_duplicate.display_name] = ore_duplicate
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
	EventBus.ore_inventory_changed.emit(ore_inventory)
	print("Gained: ", gained)
	print("Current money: ", money)
	return gained
