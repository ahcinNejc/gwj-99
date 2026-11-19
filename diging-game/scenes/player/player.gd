class_name Player
extends CharacterBody2D


@export var max_health: float = 100
@export var current_health: float = 100:
	set(value):
		current_health = clampf(value, 0.0, max_health)
		EventBus.player_health_changed.emit(current_health)
		if current_health <= 0.0 and not is_dead:
			is_dead = true
			EventBus.player_died.emit()

# Drill and Jetpack both use energy
@export var max_energy: float = 500
@export var energy: float = 500:
	set(value):
		energy = clampf(value, 0.0, max_energy)
		EventBus.player_energy_changed.emit(energy)
		if energy <= 0.0:
			EventBus.player_out_of_stamina.emit()

@export_group("Movement")
@export var move_speed: float = 125.0
@export var acceleration: float = 300.0
@export var friction: float = 250.0
@export_range(0.0, 1.0) var air_control: float = 0.6 ## 1.0 = same control as on the ground, lower = floatier in the air
@export var external_velocity_decay: float = 4.0 ## Exponential decay rate for knockback / explosion impulses (higher = fades faster)
@export var jump_velocity: float = -400.0
@export var max_fall_speed: float = 400.0 ## Terminal velocity: falling speed never exceeds this (px/s)

@export_group("Jetpack")
@export var jetpack_energy_drain_rate: float = 10 # jetpack drains 10 energy per second
@export var jetpack_velocity: float = -300.0 ## Max upward speed while the jetpack is firing
@export var jetpack_acceleration: float = 1500.0 ## How quickly the jetpack pushes you up to that speed
@export var jetpack_needs_repress: bool = true ## If true, you must press jump again in the air to fire the jetpack,

@export_group("Squash & Stretch")
@export var squash_stretch_enabled: bool = true
@export var stretch_amount: float = 0.2 ## How much the sprite stretches vertically at max speed (0.2 = 20% taller)
@export var landing_squash_amount: float = 0.3 ## How much the sprite squashes on the hardest landing (0.3 = 30% shorter)
@export var min_landing_speed: float = 120.0 ## Landings slower than this (px/s) don't squash
@export var squash_recovery_speed: float = 14.0 ## How fast the squash springs back to normal
@export var stretch_smooth_speed: float = 18.0 ## How fast the stretch eases in and out as your vertical speed changes
@export_range(0.0, 1.0) var width_compensation: float = 0.5 ## 0 = height changes only, 0.5 = roughly keeps the sprite's "volume" (wider when squashed)



## TODO: remove test stuff
const COPPER = preload("res://scripts/resources/copper.tres")
const IRON = preload("res://scripts/resources/iron.tres")
const GOLD = preload("res://scripts/resources/gold.tres")

var resources: Array = [COPPER, IRON, GOLD]

var in_shop: bool = false
var is_dead: bool = false
var jetpack_ready: bool = true

## Knockback / explosion velocity, kept separate so movement input doesn't overwrite it
var external_velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
var sprite_base_scale: Vector2 = Vector2.ONE
var sprite_base_position: Vector2 = Vector2.ZERO
var was_on_floor: bool = false
var stretch_current: float = 0.0 # smoothed stretch from vertical speed
var squash_current: float = 0.0  # landing squash, decays back to 0

@onready var drill: Drill = %Drill

func _ready() -> void:
	if sprite:
		sprite_base_scale = sprite.scale
		sprite_base_position = sprite.position
	EventBus.shop_opened.connect(on_shop_opened)
	EventBus.shop_closed.connect(on_shop_closed)



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_key"):
		GameState.add_ore_to_inventory(resources.pick_random().duplicate())
	elif event.is_action_pressed("Charge"):
		GameState.sell_all_ores()


func _process(delta: float) -> void:
	if can_act() and Input.is_action_pressed("Dig"):
		drill.try_drilling(delta)
	else:
		drill.stop_drilling()

	_update_squash_stretch(delta)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		velocity.y = minf(velocity.y, max_fall_speed)

	if can_act():
		handle_jump(delta)
		handle_horizontal_movement(delta)
	else:
		# Don't keep sliding forever when the shop opens or the player dies
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# External velocity is added for the move, then removed so it
	var impact_speed := velocity.y
	velocity += external_velocity
	move_and_slide()

	if is_on_floor() and not was_on_floor:
		on_landed(impact_speed)
	was_on_floor = is_on_floor()

	# Don't keep pushing into things we've hit
	if is_on_wall():
		external_velocity.x = 0.0
	if is_on_ceiling() and external_velocity.y < 0.0:
		external_velocity.y = 0.0
	if is_on_floor() and external_velocity.y > 0.0:
		external_velocity.y = 0.0

	velocity -= external_velocity
	external_velocity = external_velocity.lerp(Vector2.ZERO, 1.0 - exp(-external_velocity_decay * delta))

# always check for any action veing done
func can_act() -> bool:
	return not in_shop and not is_dead


func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var control := 1.0 if is_on_floor() else air_control

	if direction != 0.0:
		var accel := acceleration
		# Turning around: brake harder so reversing doesn't feel mushy
		if signf(velocity.x) == -signf(direction):
			accel += friction
		velocity.x = move_toward(velocity.x, direction * move_speed, accel * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * control * delta)


func handle_jump(delta: float) -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			jetpack_ready = not jetpack_needs_repress
		else:
			# Walking off a ledge, or just landed
			jetpack_ready = true
		return

	# In the air
	if Input.is_action_just_pressed("jump"):
		jetpack_ready = true

	if jetpack_ready and Input.is_action_pressed("jump") and energy > 0.0:
		# Only push up to the jetpack speed. This never slows a faster jump down.
		if velocity.y > jetpack_velocity:
			velocity.y = maxf(velocity.y - jetpack_acceleration * delta, jetpack_velocity)
		energy -= jetpack_energy_drain_rate * delta

func on_landed(impact_speed: float) -> void:
	if impact_speed < min_landing_speed:
		return
	var t := clampf(impact_speed / max_fall_speed, 0.0, 1.0)
	squash_current = t * landing_squash_amount
	stretch_current = 0.0 # drop the fall stretch so the squash reads immediately


# Public API

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount

## Call this for knockback, explosions, etc. e.g. apply_knockback(Vector2(200, -150))
func apply_knockback(impulse: Vector2) -> void:
	external_velocity += impulse

func on_shop_opened() -> void:
	in_shop = true

func on_shop_closed() -> void:
	in_shop = false


# Private Methods

# Squishy SQUASHY THINGY
func _update_squash_stretch(delta: float) -> void:
	if not sprite:
		return
	if not squash_stretch_enabled:
		sprite.scale = sprite_base_scale
		sprite.position = sprite_base_position
		return

	# Stretch taller the faster we move vertically (rising or falling), none on the ground
	var target_stretch := 0.0
	if not is_on_floor():
		target_stretch = clampf(absf(velocity.y) / max_fall_speed, 0.0, 1.0) * stretch_amount
	stretch_current = lerpf(stretch_current, target_stretch, 1.0 - exp(-stretch_smooth_speed * delta))
	squash_current = lerpf(squash_current, 0.0, 1.0 - exp(-squash_recovery_speed * delta))

	# Positive = taller and thinner, negative = shorter and wider
	var amount := stretch_current - squash_current
	var scale_y := 1.0 + amount
	var scale_x := 1.0 - amount * width_compensation
	sprite.scale = sprite_base_scale * Vector2(scale_x, scale_y)

	# Scale around the feet, not the sprite's center, so it doesn't float or sink into the ground
	var bottom := sprite.get_rect().end.y * sprite_base_scale.y
	sprite.position.y = sprite_base_position.y + bottom * (1.0 - scale_y)
