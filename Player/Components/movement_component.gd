class_name MovementComponent
extends Node

@export var max_speed: float = 8.0
@export var ground_acceleration: float = 10.0
@export var ground_friction: float = 7.0
@export var air_acceleration: float = 3.0
@export var jump_force: float = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func calculate_velocity(current_velocity: Vector3, direction: Vector3, is_on_floor: bool, delta: float) -> Vector3:
	var new_velocity = current_velocity
	
	if is_on_floor:
		# Apply friction when no keys are pressed
		if direction == Vector3.ZERO:
			new_velocity.x = move_toward(new_velocity.x, 0, ground_friction * delta * max_speed)
			new_velocity.z = move_toward(new_velocity.z, 0, ground_friction * delta * max_speed)
		# Apply rapid ground acceleration
		else:
			new_velocity.x = lerp(new_velocity.x, direction.x * max_speed, ground_acceleration * delta)
			new_velocity.z = lerp(new_velocity.z, direction.z * max_speed, ground_acceleration * delta)
	else:
		# Apply gravity and floaty air acceleration
		new_velocity.y -= gravity * delta
		new_velocity.x = lerp(new_velocity.x, direction.x * max_speed, air_acceleration * delta)
		new_velocity.z = lerp(new_velocity.z, direction.z * max_speed, air_acceleration * delta)
		
	return new_velocity

func calculate_jump(current_velocity: Vector3) -> Vector3:
	current_velocity.y = jump_force
	return current_velocity
