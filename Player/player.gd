class_name Player
extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var movement_component = $MovementComponent
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var damage_overlay: ColorRect = $HUD/DamageOverlay
@onready var collision_shape = $CollisionShape3D
@onready var ceiling_check = $CeilingCheck
@onready var interaction_ray: RayCast3D = $Head/Camera3D/InteractionRay
@onready var default_head_y = head.position.y

# Placeholder path for your weapon animator
@onready var weapon_manager = $Head/Camera3D/WeaponManager


@export_group("Crouch Settings")
@export var crouch_camera_drop: float = 0.2 

@export var max_health: int = 100
var current_health: int

const CROUCH_HEIGHT: float = 1.0
const NORMAL_HEIGHT: float = 2.0
const BOB_FREQ : float = 2.0
const BOB_AMP : float = 0.08
const BASE_FOV : float = 75.0
const FOV_CHANGE : float = 1.5
const SENSITIVITY : float = 0.007

var input_dir: Vector2 = Vector2.ZERO
var t_bob : float = 0.0
var last_step_cycle: int = 0

@export_group("Audio")
@export var footstep_sounds: Array[AudioStream]
@export var footstep_rate: float = 6.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_health = max_health
	add_to_group("Player")
	
	health_bar.max_value = max_health
	health_bar.value = current_health
	
	# Force master camera and audio listener active
	camera.make_current()
	var ears = camera.get_node_or_null("AudioListener3D")
	if ears:
		ears.make_current()

func _input(event: InputEvent) -> void:
	# Interact with world objects
	if event.is_action_pressed("interact"):
		if interaction_ray.is_colliding():
			var hit_object = interaction_ray.get_collider()
			if hit_object is Interactable:
				hit_object.interact(self)

func _unhandled_input(event: InputEvent) -> void:
	# Rotate head and camera based on mouse movement
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	# Check jump input and prevent jumping into low ceilings
	if event.is_action_pressed("Jump") and is_on_floor():
		if movement_component.is_crouching and ceiling_check.is_colliding():
			return 
		velocity = movement_component.calculate_jump(velocity)
		
		# Force floor magnet to release for the jump
		floor_snap_length = 0.0

func _physics_process(delta: float) -> void:
	# Turn floor magnet back on when falling or grounded
	if velocity.y <= 0.0:
		floor_snap_length = 0.5
		
	# Gather current inputs
	var direction = get_input_direction()
	var is_sprinting = Input.is_action_pressed("sprint") and direction != Vector3.ZERO
	var wants_to_crouch = Input.is_action_pressed("crouch")
	var ceiling_clear = not ceiling_check.is_colliding() if ceiling_check else true
	
	var look_direction = -head.global_transform.basis.z
	look_direction.y = 0
	look_direction = look_direction.normalized()
	
	# Delegate movement states and physics math to the component
	velocity = movement_component.update_state(wants_to_crouch, ceiling_clear, is_on_floor(), direction, -head.transform.basis.z, velocity)
	velocity = movement_component.process_velocity(velocity, direction, look_direction, is_sprinting, is_on_floor(), get_floor_normal(), delta)
	
	# Apply visually and move
	adjust_posture_smoothly(delta)
	move_and_slide()
	update_visuals(delta)
	
	# Animation triggers
	handle_animation_states()

func get_input_direction() -> Vector3:
	# Convert raw input vector into 3D direction
	input_dir = Input.get_vector("Left", "Right", "Forward", "Backwards")
	return (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func handle_animation_states() -> void:
	# Trigger slide start animation
	if movement_component.is_sliding and not movement_component.is_crouching: 
		#weapon_manager.play_animation("slide_start")
		pass
		
	# Trigger slide end animation
	elif not movement_component.is_sliding:
		#weapon_manager.play_animation("slide_end")
		pass

func adjust_posture_smoothly(delta: float) -> void:
	# Smooth hitbox and camera height transitions
	var target_height = CROUCH_HEIGHT if movement_component.is_crouching else NORMAL_HEIGHT
	var target_head_y = (default_head_y - crouch_camera_drop) if movement_component.is_crouching else default_head_y
	
	if collision_shape:
		collision_shape.shape.height = lerp(collision_shape.shape.height, target_height, delta * 10.0)
		
	head.position.y = lerp(head.position.y, target_head_y, delta * 10.0)

func update_visuals(delta: float) -> void:
	# Handle headbobbing and FOV changes
	if velocity.length() > 0.1 and is_on_floor() and not movement_component.is_sliding:
		headbobbing(delta)
	else:
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 8.0)

func headbobbing(delta: float) -> void:
	# Calculate camera bobbing motion
	t_bob += delta * velocity.length()
	var pos = Vector3.ZERO
	pos.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	pos.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP
	camera.transform.origin = pos
	
	var velocity_clamped = clamp(velocity.length(), 0.5, movement_component.walk_speed * 2)
	camera.fov = lerp(camera.fov, BASE_FOV + FOV_CHANGE * velocity_clamped, delta * 8.0)
	
	var current_step_cycle = int((t_bob * BOB_FREQ) / footstep_rate)
	if current_step_cycle != last_step_cycle:
		last_step_cycle = current_step_cycle
		play_footstep_sound()

func play_footstep_sound() -> void:
	# Play random footstep sound
	if footstep_sounds.is_empty():
		return
		
	var random_step = footstep_sounds.pick_random()
	AudioManager.play_sound_2d(random_step, -30.0)

func take_damage(amount: int) -> void:
	# Subtract health and trigger damage overlay
	current_health -= amount
	health_bar.value = current_health
	
	var tween = create_tween()
	damage_overlay.color.a = 0.4 
	tween.tween_property(damage_overlay, "color:a", 0.0, 0.3)
	
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	# Add health and update interface
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	health_bar.value = current_health

func die() -> void:
	# Reload scene on death
	get_tree().reload_current_scene()
