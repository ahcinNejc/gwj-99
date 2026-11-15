extends CharacterBody2D
class_name Player


@export var max_health: float = 100
@export var current_health: float = 100:
	set(value):
		current_health = value
		EventBus.player_health_changed.emit(current_health)
		if current_health <= 0:
			EventBus.player_died.emit()


# Drill and Jetpack both use energy 
@export var max_energy: float = 500
@export var energy: float = 500:
	set(value):
		energy = value
		EventBus.player_energy_changed.emit(energy)
		if energy <= 0:
			EventBus.player_out_of_stamina.emit()

@export var drill_energy_drain_rate: float = 20 # drill drains 20 energy per second
@export var jetpack_energy_drain_rate: float = 10 # jetpack drains 10 energy per second
@export var jetpack_velocity: float = -300.0


const SPEED = 300.0
const JUMP_VELOCITY = -400.0


func _process(delta: float) -> void:
	if Input.is_action_pressed("Dig"):
		try_drilling(delta)



func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	handle_jump(delta)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func take_damage(amount: float) -> void:
	current_health -= amount

func handle_jump(delta: float) -> void:
	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handle jetpack
	if Input.is_action_pressed("jump") and  not is_on_floor():
		if energy >= 0:
			velocity.y = jetpack_velocity
			energy -= jetpack_energy_drain_rate * delta

func try_drilling(delta: float) -> void:
	if energy >= 0:
		energy -= drill_energy_drain_rate * delta
	else:
		print("Not enough energy")
