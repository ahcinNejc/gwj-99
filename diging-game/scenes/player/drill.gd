class_name Drill
extends Node2D

# Drill STATS
@export_group("Drill")
@export var drill_timer: Timer
@export var drill_energy_drain_rate: float = 20.0
@export var drill_interval: float = 0.3
@export var drill_damage: float = 1.0

# assigned externally by world.tscn
var world_grid: WorldGrid

@onready var player: Player = get_parent()
@onready var hitbox: Area2D = $Area2D
@onready var drill_locator: Marker2D = $DrillLocator

func _process(delta: float) -> void:
	#var direction = (get_global_mouse_position() - global_position).normalized()
	#if direction.y < -0.75:
		#rotation = lerp_angle(rotation, deg_to_rad(-90), 10 * delta)
	#elif direction.y > 0.75:
		#rotation = lerp_angle(rotation, deg_to_rad(90), 10 * delta)
	#elif direction.x < -0.75:
		#rotation = lerp_angle(rotation, deg_to_rad(180), 10 * delta)
	#else:
		#rotation = lerp_angle(rotation, deg_to_rad(0), 10 * delta)
	look_at(get_global_mouse_position())

func try_drilling(delta: float) -> void:
	if player.energy <= 0.0:
		stop_drilling()
		return
	player.energy -= drill_energy_drain_rate * delta
	if drill_timer and drill_timer.is_stopped():
		drill_timer.start()

func stop_drilling() -> void:
	if drill_timer and not drill_timer.is_stopped():
		drill_timer.stop()

	if drill_timer:
		drill_timer.wait_time = drill_interval
		# Safe to leave the editor connection in place; this only connects if missing
		if not drill_timer.timeout.is_connected(_on_drill_timer_timeout):
			drill_timer.timeout.connect(_on_drill_timer_timeout)

func deal_damage() -> void:
	var location: Vector2i = world_grid.data_layer.local_to_map(drill_locator.global_position)
	world_grid.damage_block(location, drill_damage)


func _on_drill_timer_timeout() -> void:
	if player.can_act():
		deal_damage()
