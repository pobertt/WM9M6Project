class_name Player
extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var movement_component = $MovementComponent

@export var max_health: int = 100
var current_health: int
@onready var health_bar: ProgressBar = $HUD/HealthBar

# Bob vars.
const BOB_FREQ : float = 2.0
const BOB_AMP : float = 0.08
var t_bob : float = 0.0

# FOV vars.
const BASE_FOV : float = 75.0
const FOV_CHANGE : float = 1.5
const SENSITIVITY : float = 0.007

# Store input to avoid polling on the event tick
var input_dir: Vector2 = Vector2.ZERO



func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	current_health = max_health
	add_to_group("Player")
	
	# Set the UI bar to match our starting health
	health_bar.max_value = max_health
	health_bar.value = current_health

func _unhandled_input(event: InputEvent) -> void:
	# 1. Mouse Look
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	# 2. Movement Keys
	if event.is_action("Left") or event.is_action("Right") or event.is_action("Forward") or event.is_action("Backwards"):
		input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
		
	# 3. Jump
	if event.is_action_pressed("Jump") and is_on_floor():
		velocity = movement_component.calculate_jump(velocity)

func _physics_process(delta: float) -> void:
	# Calculate 3D direction relative to where the head is looking
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Pass data to the component to get the new velocity
	velocity = movement_component.calculate_velocity(velocity, direction, is_on_floor(), delta)
	
	move_and_slide()
	
	# Only calculate headbob math if the player is actually moving
	if velocity.length() > 0.1 and is_on_floor():
		headbobbing(delta)
	else:
		# Smoothly reset FOV when standing still
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)

func headbobbing(delta: float):
	t_bob += delta * velocity.length()
	camera.transform.origin = headbob_pos(t_bob)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, movement_component.max_speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func headbob_pos(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Player took ", amount, " damage! HP remaining: ", current_health)
	
	# Update the UI!
	health_bar.value = current_health
	
	if current_health <= 0:
		die()

func die() -> void:
	print("PLAYER DIED! Restarting level...")
	# Instantly reload the current test gym so you can try again
	get_tree().reload_current_scene()
