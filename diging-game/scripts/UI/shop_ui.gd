class_name ShopUI
extends MarginContainer

@export var sell_all_button: Button
@export var refill_energy_button: Button
@export var upgrade_damage_button: Button
@export var upgrade_speed_button: Button

@export_group("Upgrade Settings")
@export var base_upgrade_cost: int = 100
@export var cost_growth: float = 1.6
@export var max_level: int = 10
@export var damage_per_level: float = 0.5
@export var interval_multiplier: float = 0.9
@export var min_drill_interval: float = 0.08

@export var refill_percentage: float = 0.10 ## Take a fraction of the peak money
var refill_cost: int = 0

var damage_level: int = 0
var speed_level: int = 0

var player: Player

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
	
	# Deferred so the Player and its Drill have finished _ready() first
	_refresh_upgrades.call_deferred()


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
	_refresh_upgrades()


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


# Upgrades

func _on_upgrade_damage_button_pressed() -> void:
	var drill := _get_drill()
	var cost := _cost_for(damage_level)
	if drill == null or damage_level >= max_level or GameState.money < cost:
		return
	
	GameState.money -= cost
	damage_level += 1
	drill.drill_damage += damage_per_level
	
	AudioManager.play_sfx("ui_click")
	_refresh_upgrades()


func _on_upgrade_mining_speed_button_pressed() -> void:
	var drill := _get_drill()
	var cost := _cost_for(speed_level)
	if drill == null or speed_level >= max_level or GameState.money < cost:
		return
	
	GameState.money -= cost
	speed_level += 1
	drill.drill_interval = maxf(drill.drill_interval * interval_multiplier, min_drill_interval)
	if drill.drill_timer:
		drill.drill_timer.wait_time = drill.drill_interval
	
	AudioManager.play_sfx("ui_click")
	_refresh_upgrades()


func _cost_for(level: int) -> int:
	return roundi(base_upgrade_cost * pow(cost_growth, level))


# Finds the player lazily, so it doesn't matter which node becomes ready first
func _get_drill() -> Drill:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return null
	return player.drill


func _refresh_upgrades() -> void:
	_refresh_button(upgrade_damage_button, "Damage", damage_level)
	_refresh_button(upgrade_speed_button, "Mining Speed", speed_level)


func _refresh_button(button: Button, label: String, level: int) -> void:
	if button == null:
		return
	if level >= max_level:
		button.text = "%s (MAX)" % label
		button.disabled = true
	else:
		var cost := _cost_for(level)
		button.text = "%s Lv.%d  $%d" % [label, level, cost]
		button.disabled = GameState.money < cost
