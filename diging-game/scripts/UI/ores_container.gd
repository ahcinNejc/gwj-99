extends HBoxContainer
class_name OresContainer

const ORE_INVENTORY_ICON = preload("uid://bip5srg2q6vbp")


func _ready() -> void:
	EventBus.ore_inventory_changed.connect(update_ore_invetory)


func update_ore_invetory(current_inventory) -> void:
	for child in get_children():
		child.queue_free()
	for ore in current_inventory.keys():
		var data: OreData = current_inventory[ore]
		var icon: OreInventoryIcon = ORE_INVENTORY_ICON.instantiate()
		icon.amount_label.text = str(data.amount_in_stack)
		icon.texture_rect.texture = load(data.texture)
		icon.name_label.text = data.display_name
		add_child(icon)
	
