class_name Player
extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var movement_component = $MovementComponent
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var damage_overlay: ColorRect = $HUD/DamageOverlay

@export var max_health: int = 100
var current_health: int

const BOB_FREQ : float = 2.0
const BOB_AMP : float = 0.08
var t_bob : float = 0.0

const BASE_FOV : float = 75.0
const FOV_CHANGE : float = 1.5
const SENSITIVITY : float = 0.007

var input_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_health = max_health
	add_to_group("Player")
	
	health_bar.max_value = max_health
	health_bar.value = current_health

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if event.is_action("Left") or event.is_action("Right") or event.is_action("Forward") or event.is_action("Backwards"):
		input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
		
	if event.is_action_pressed("Jump") and is_on_floor():
		velocity = movement_component.calculate_jump(velocity)

func _physics_process(delta: float) -> void:
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity = movement_component.calculate_velocity(velocity, direction, is_on_floor(), delta)
	
	move_and_slide()
	
	if velocity.length() > 0.1 and is_on_floor():
		headbobbing(delta)
	else:
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)

func headbobbing(delta: float):
	t_bob += delta * velocity.length()
	
	var pos = Vector3.ZERO
	pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	pos.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP
	camera.transform.origin = pos
	
	var velocity_clamped = clamp(velocity.length(), 0.5, movement_component.max_speed * 2)
	camera.fov = lerp(camera.fov, BASE_FOV + FOV_CHANGE * velocity_clamped, delta * 8.0)

func take_damage(amount: int) -> void:
	current_health -= amount
	health_bar.value = current_health
	
	var tween = create_tween()
	damage_overlay.color.a = 0.4 
	tween.tween_property(damage_overlay, "color:a", 0.0, 0.3)
	
	if current_health <= 0:
		die()

func die() -> void:
	get_tree().reload_current_scene()

func heal(amount: int) -> void:
	current_health += amount
	if current_health > max_health:
		current_health = max_health
		
	health_bar.value = current_health
	
	# add green flash overlay here
