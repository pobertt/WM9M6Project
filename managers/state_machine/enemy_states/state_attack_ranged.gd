extends State

@export var fire_rate: float = 0.5 # Shoots once per second
@export var lose_interest_range: float = 17.0 # Slightly larger than attack_range to prevent jitter
@export var attack_damage: int = 10
@export var weapon_spread: float = 1.0 # 1.0 meters of random inaccuracy

@export var strafe_speed: float = 5
var strafe_direction: int = 1
var next_strafe_time: int = 0
	
var player: Node3D
var last_shot_time: int = 0

func enter() -> void:
	print("Entering Ranged Attack State!")
	player = actor.target_player

func physics_update(_delta: float) -> void:
	if player == null:
		return

	# 1. THE MOVEMENT UPGRADE: Strafing with NavAgent & Gravity!
	var current_time = Time.get_ticks_msec()
	var nav = actor.nav_agent
	
	# Randomly change direction every 1.5 to 3 seconds
	if current_time > next_strafe_time:
		strafe_direction = [-1, 1].pick_random() 
		next_strafe_time = current_time + randi_range(1500, 3000)
		
		# Calculate a target coordinate 3 meters to the left/right
		var to_player = actor.global_position.direction_to(player.global_position)
		to_player.y = 0 
		var right_vector = to_player.cross(Vector3.UP).normalized()
		
		# Hand the new safe coordinate to the GPS!
		var strafe_target = actor.global_position + (right_vector * strafe_direction * 3.0)
		nav.target_position = strafe_target

	# APPLY GRAVITY so they don't float!
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * _delta
		
	# Move towards the strafe target if we aren't there yet
	if not nav.is_navigation_finished():
		var current_pos = actor.global_position
		var next_pos = nav.get_next_path_position()
		var direction = current_pos.direction_to(next_pos)
		
		direction.y = 0 
		direction = direction.normalized()
		
		# ONLY overwrite X and Z so we don't kill the gravity!
		var horizontal_vel = direction * strafe_speed
		actor.velocity.x = horizontal_vel.x
		actor.velocity.z = horizontal_vel.z
	else:
		# Stop horizontally if they reached the end of their strafe path
		actor.velocity.x = 0
		actor.velocity.z = 0

	actor.move_and_slide()
	
	# Look at the player while moving
	var aim_target = player.global_position
	aim_target.y = actor.global_position.y
	actor.look_at(aim_target, Vector3.UP)

	# 2. Check Line of Sight and Distance (Keep your existing code here!)
	var distance = actor.global_position.distance_to(player.global_position)
	
	# Cast a quick math-laser to check Line of Sight (LoS)
	var has_line_of_sight = false
	var space_state = actor.get_world_3d().direct_space_state
	
	# Raise the laser up to chest height so it doesn't clip the floor
	var start_pos = actor.muzzle.global_position
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	# Create and fire the mathematical raycast
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	var result = space_state.intersect_ray(query)
	
	# DIAGNOSTICS: Let's see exactly what the laser is hitting!
	if result:
		if result.collider == player:
			has_line_of_sight = true
		else:
			print("ATTACK ABORTED: Laser was blocked by -> ", result.collider.name)
	else:
		print("ATTACK ABORTED: Laser hit nothing (shot into the sky)")
		
	# If they are too far OR we can't see them, stop shooting and start pathfinding!
	if distance > lose_interest_range or not has_line_of_sight:
		actor.get_node("StateMachine").on_child_transition(self, "state_chase")
		return

	# 3. Pull the trigger if the gun is ready (using absolute time!)
	var gun_time = Time.get_ticks_msec()
	
	# Convert your fire_rate (seconds) to milliseconds for the clock
	if gun_time - last_shot_time >= (fire_rate * 1000.0):
		shoot()

func shoot() -> void:
	last_shot_time = Time.get_ticks_msec()
	
	var space_state = actor.get_world_3d().direct_space_state
	var start_pos = actor.muzzle.global_position 
	var target_pos = player.global_position + Vector3(0, 1.0, 0)
	
	# 1. CALCULATE DISTANCE: How far away is the player?
	var distance = start_pos.distance_to(target_pos)
	
	# Divide distance by 10.0 to create a multiplier. 
	# At 10 meters, spread is 100%. At 1 meter, spread is only 10%!
	# clamp() ensures the spread never goes above your maximum weapon_spread setting.
	var spread_multiplier = clamp(distance / 10.0, 0.0, 1.0)
	var active_spread = weapon_spread * spread_multiplier
	
	# 2. ADD SPREAD: Use the scaled active_spread instead of the flat rate
	var random_offset = Vector3(
		randf_range(-active_spread, active_spread),
		randf_range(-active_spread, active_spread),
		randf_range(-active_spread, active_spread)
	)
	
	var end_pos = target_pos + random_offset
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	var result = space_state.intersect_ray(query)
	
	# 2. DETERMINE ACTUAL HIT POSITION
	var hit_pos = end_pos # Default to the end of the line if the bullet hits the sky
	
	if result:
		hit_pos = result.position # Where did the bullet physically stop?
		
		# Did it actually hit the player?
		if result.collider == player:
			if player.has_method("take_damage"):
				player.take_damage(attack_damage)
		else:
			print("Enemy missed and hit a wall!")
			
	# 3. DRAW THE VISUAL BULLET TRAIL
	spawn_tracer(start_pos, hit_pos)


# Paste this brand new function at the bottom of your script!
func spawn_tracer(start: Vector3, end: Vector3) -> void:
	# SAFETY CHECK: If the player died and the level is restarting,
	# this enemy is no longer in the active world. Abort the visual effects!
	if not is_inside_tree():
		return
		
	# Create a 3D box mesh purely in code
	var tracer = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	# Make it a thin, long rectangle (Width, Height, Length)
	box.size = Vector3(0.05, 0.05, start.distance_to(end))
	tracer.mesh = box
	
	# Give it a glowing yellow material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.YELLOW
	mat.emission_enabled = true
	mat.emission = Color.YELLOW
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.surface_set_material(0, mat)
	
	# Add it to the main game world
	get_tree().root.add_child(tracer)
	
	# Position it halfway between the gun and the hit location
	tracer.global_position = start.lerp(end, 0.5)
	# Point the front of the trail toward the hit location
	tracer.look_at(end, Vector3.UP)
	
	# Let it flash on screen for exactly 0.05 seconds, then delete it
	await get_tree().create_timer(0.05).timeout
	tracer.queue_free()
