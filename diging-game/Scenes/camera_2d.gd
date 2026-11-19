class_name PlayerCamera
extends Camera2D

@export_group("Follow")
@export var follow_speed = 6.0
@export var camera_offset = Vector2(0, 0)
@export var look_ahead_amount = Vector2(16.0, 16.0)
@export var look_ahead_speed = 3.0

@export_group("Mouse Offset")
@export var max_offset := 80.0
@export var offset_strength := 0.25
@export var smooth_speed := 8.0

var player: Player
var look_ahead_offset = Vector2.ZERO
var mouse_offset = Vector2.ZERO


func _ready():
	player = get_parent()

func _process(delta):
	if not player:
		return

	var mouse_from_center = (get_viewport().get_mouse_position() - get_viewport_rect().size * 0.5) / zoom
	var desired_mouse_offset = (mouse_from_center * offset_strength).limit_length(max_offset)
	mouse_offset = mouse_offset.lerp(desired_mouse_offset, 1.0 - exp(-smooth_speed * delta))

	var target_pos = player.global_position + camera_offset + mouse_offset
	global_position = global_position.lerp(target_pos, 1.0 - exp(-follow_speed * delta))

	var target_look_ahead = Vector2.ZERO
	if player.velocity.x != 0:
		target_look_ahead.x = sign(player.velocity.x) * look_ahead_amount.x
	if player.velocity.y != 0:
		target_look_ahead.y = sign(player.velocity.y) * look_ahead_amount.y

	look_ahead_offset = look_ahead_offset.lerp(target_look_ahead, 1.0 - exp(-look_ahead_speed * delta))

	global_position += (look_ahead_offset * delta * 10)
