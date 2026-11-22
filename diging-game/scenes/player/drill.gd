class_name Drill
extends Node2D

# Drill STATS
@export_group("Drill")
@export var drill_timer: Timer
@export var drill_energy_drain_rate: float = 20.0
@export var drill_interval: float = 0.3
@export var drill_damage: float = 1.0
@export var drill_rotation_speed: float = 10.0

# assigned externally by world.tscn
var world_grid: WorldGrid

# for handling drilling sfx
var _drilling_sfx: AudioStreamPlayer
var _beepfs_sfx: AudioStreamPlayer

var _target_cell := WorldGrid.NO_CELL

@onready var player: Player = get_parent()
@onready var hitbox: Area2D = $Area2D
@onready var drill_locator: Marker2D = $DrillLocator
@onready var area: Area2D = $Area2D
@onready var locator: Node2D = $DrillLocator

func _process(_delta: float) -> void:
	# look_at(get_global_mouse_position())
	
	# Calculate the angle to the mouse instead of instantly looking at it
	var target_angle = (get_global_mouse_position() - global_position).angle()
	
	# Smoothly rotate toward that angle
	rotation = lerp_angle(rotation, target_angle, drill_rotation_speed * _delta)
	
	# Keep rotation in 0-360 range
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	
	# Flip sprite when facing left
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1

func try_drilling(delta: float) -> void:
	if player.energy <= (player.max_energy * player.energy_regenerated) * 3:
		stop_drilling()
		
		if not _beepfs_sfx:
			_beepfs_sfx = AudioManager.play_sfx("beeps")
		
		return
	
	if not _drilling_sfx:
		_drilling_sfx = AudioManager.play_sfx("drilling", true, -10)
	
	player.energy -= drill_energy_drain_rate * delta
	if drill_timer and drill_timer.is_stopped():
		drill_timer.start()

func stop_drilling() -> void:
	if drill_timer and not drill_timer.is_stopped():
		drill_timer.stop()
	
	if _drilling_sfx:
		AudioManager.stop_sfx(_drilling_sfx)
	
	if drill_timer:
		drill_timer.wait_time = drill_interval
		# Safe to leave the editor connection in place; this only connects if missing
		if not drill_timer.timeout.is_connected(_on_drill_timer_timeout):
			drill_timer.timeout.connect(_on_drill_timer_timeout)

func deal_damage() -> void:
	if _target_cell == WorldGrid.NO_CELL \
			or world_grid.material_at(_target_cell) == "" \
			or _target_cell not in world_grid.get_cells_in_area(area):
		_target_cell = world_grid.closest_cell_in_area(area, locator.global_position)

	if _target_cell == WorldGrid.NO_CELL:
		return

	world_grid.damage_block(_target_cell, drill_damage)


func _on_drill_timer_timeout() -> void:
	if player.can_act():
		deal_damage()
