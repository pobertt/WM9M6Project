class_name MovementComponent
extends Node

@export var walk_speed: float = 8.0
@export var sprint_speed: float = 12.0
@export var crouch_speed: float = 3.5
@export var slide_boost: float = 14.0
@export var slope_slide_boost: float = 12.0
@export var ground_acceleration: float = 10.0
@export var ground_friction: float = 7.0
@export var slide_friction: float = 1.5
@export var air_acceleration: float = 3.0
@export var jump_force: float = 4.5
@export var slide_steer_speed: float = 30.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Active States
var is_crouching: bool = false
var is_sliding: bool = false
var slide_direction: Vector3 = Vector3.ZERO

func update_state(wants_to_crouch: bool, ceiling_clear: bool, is_on_floor: bool, direction: Vector3, head_forward: Vector3, current_velocity: Vector3) -> Vector3:
	# Handle state transitions and apply initial burst or brakes
	var new_velocity = current_velocity
	
	if wants_to_crouch:
		if not is_crouching:
			is_crouching = true
			
			# Trigger slide burst if sprint threshold is met
			if is_on_floor and current_velocity.length() > walk_speed:
				is_sliding = true
				slide_direction = direction if direction != Vector3.ZERO else head_forward
				new_velocity.x = slide_direction.x * slide_boost
				new_velocity.z = slide_direction.z * slide_boost
	else:
		# Cancel slide and apply hard brakes when releasing crouch
		if is_sliding:
			is_sliding = false
			new_velocity = apply_hard_brakes(current_velocity, direction)

		# Stand up if space above is clear
		if ceiling_clear:
			is_crouching = false
			
	return new_velocity

func process_velocity(current_velocity: Vector3, direction: Vector3, look_direction: Vector3, is_sprinting: bool, is_on_floor: bool, floor_normal: Vector3, delta: float) -> Vector3:
	# Calculate final velocity based on the active state
	var new_velocity = current_velocity
	
	if is_sliding:
		slide_direction = slide_direction.lerp(look_direction, delta * slide_steer_speed).normalized()
		new_velocity = calculate_slide_velocity(current_velocity, slide_direction, is_on_floor, floor_normal, delta)
		
		# Cancel slide once friction stops movement completely
		if Vector2(new_velocity.x, new_velocity.z).length() < (crouch_speed + 0.5):
			is_sliding = false
	else:
		new_velocity = calculate_velocity(current_velocity, direction, is_on_floor, is_crouching, is_sprinting, delta)
		
	return new_velocity

func calculate_velocity(current_velocity: Vector3, direction: Vector3, is_on_floor: bool, crouching: bool, sprinting: bool, delta: float) -> Vector3:
	var target_speed = walk_speed
	if crouching:
		target_speed = crouch_speed
	elif sprinting:
		target_speed = sprint_speed
		
	var new_velocity = current_velocity
	
	if is_on_floor:
		if direction == Vector3.ZERO:
			new_velocity.x = move_toward(new_velocity.x, 0, ground_friction * delta * target_speed)
			new_velocity.z = move_toward(new_velocity.z, 0, ground_friction * delta * target_speed)
		else:
			new_velocity.x = lerp(new_velocity.x, direction.x * target_speed, ground_acceleration * delta)
			new_velocity.z = lerp(new_velocity.z, direction.z * target_speed, ground_acceleration * delta)
	else:
		new_velocity.y -= gravity * delta
		new_velocity.x = lerp(new_velocity.x, direction.x * target_speed, air_acceleration * delta)
		new_velocity.z = lerp(new_velocity.z, direction.z * target_speed, air_acceleration * delta)
		
	return new_velocity

func calculate_slide_velocity(current_velocity: Vector3, current_slide_dir: Vector3, is_on_floor: bool, floor_normal: Vector3, delta: float) -> Vector3:
	var new_velocity = current_velocity
	
	if is_on_floor:
		if floor_normal.y < 0.99:
			var downhill_dir = Vector3.DOWN.slide(floor_normal).normalized()
			
			# Check downhill trajectory
			if current_slide_dir.dot(downhill_dir) > 0.0:
				# Drop friction to allow gravity acceleration
				new_velocity.x = lerp(new_velocity.x, current_slide_dir.x * crouch_speed, (slide_friction * 0.1) * delta)
				new_velocity.z = lerp(new_velocity.z, current_slide_dir.z * crouch_speed, (slide_friction * 0.1) * delta)
				
				# Add slope gravity boost
				new_velocity += downhill_dir * slope_slide_boost * delta
				
				# Cap maximum terminal velocity
				var current_speed = Vector2(new_velocity.x, new_velocity.z).length()
				if current_speed > 25.0:
					var clamped = Vector3(new_velocity.x, 0, new_velocity.z).normalized() * 25.0
					new_velocity.x = clamped.x
					new_velocity.z = clamped.z
			else:
				# Heavy friction for sliding uphill
				new_velocity.x = lerp(new_velocity.x, current_slide_dir.x * crouch_speed, (slide_friction * 3.0) * delta)
				new_velocity.z = lerp(new_velocity.z, current_slide_dir.z * crouch_speed, (slide_friction * 3.0) * delta)
		else:
			# Normal friction on flat ground
			new_velocity.x = lerp(new_velocity.x, current_slide_dir.x * crouch_speed, slide_friction * delta)
			new_velocity.z = lerp(new_velocity.z, current_slide_dir.z * crouch_speed, slide_friction * delta)
	else:
		# Mid-air gravity
		new_velocity.y -= gravity * delta
		
	return new_velocity

func calculate_jump(current_velocity: Vector3) -> Vector3:
	# Apply upward jump force
	current_velocity.y = jump_force
	return current_velocity

func apply_hard_brakes(current_velocity: Vector3, direction: Vector3) -> Vector3:
	# Instantly drop momentum to walking speed
	var new_velocity = current_velocity
	if direction == Vector3.ZERO:
		new_velocity.x = 0
		new_velocity.z = 0
	else:
		var current_speed = Vector2(new_velocity.x, new_velocity.z).length()
		if current_speed > walk_speed:
			var clamped_dir = Vector3(new_velocity.x, 0, new_velocity.z).normalized()
			new_velocity.x = clamped_dir.x * walk_speed
			new_velocity.z = clamped_dir.z * walk_speed
	return new_velocity
