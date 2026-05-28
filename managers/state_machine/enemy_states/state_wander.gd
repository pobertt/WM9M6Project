extends State

@export var move_speed: float = 3.0
@export var wander_radius: float = 8.0

var start_position: Vector3
var is_waiting: bool = false

func enter() -> void:
	print("Entering Wander State!")
	# Save where the actor spawned so they don't wander off the edge of the map
	start_position = actor.global_position
	pick_new_target()

func physics_update(_delta: float) -> void:
	# If we are taking a break, don't move
	if is_waiting:
		return
		
	var nav = actor.nav_agent
	
	# 1. Did we reach our random destination?
	if nav.is_navigation_finished():
		is_waiting = true
		# Wait for 2 seconds using Godot's built-in timer
		await get_tree().create_timer(2.0).timeout
		pick_new_target()
		return
		
	# 2. If not, calculate the path to the destination
	var current_pos = actor.global_position
	var next_pos = nav.get_next_path_position()
	var direction = current_pos.direction_to(next_pos)
	
	# Keep them flat on the floor so they don't tilt upward on ramps
	direction.y = 0 
	direction = direction.normalized()
	
	# 3. Move the physical body
	actor.velocity = direction * move_speed
	actor.move_and_slide()
	
	# 4. Make the 3D model turn to face where it is walking
	if direction != Vector3.ZERO:
		actor.look_at(current_pos + direction, Vector3.UP)

func pick_new_target() -> void:
	is_waiting = false
	
	# Pick a random 3D coordinate around the starting position
	var random_x = randf_range(-wander_radius, wander_radius)
	var random_z = randf_range(-wander_radius, wander_radius)
	var target = start_position + Vector3(random_x, 0, random_z)
	
	# Hand the new coordinate to the GPS
	actor.nav_agent.target_position = target
