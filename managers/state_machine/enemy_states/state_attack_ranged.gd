extends State

@export var fire_rate: float = 1.0 # Shoots once per second
@export var lose_interest_range: float = 12.0 # Slightly larger than attack_range to prevent jitter
@export var attack_damage: int = 10
	
var player: Node3D
var last_shot_time: int = 0

func enter() -> void:
	print("Entering Ranged Attack State!")
	player = actor.target_player

func physics_update(_delta: float) -> void:
	if player == null:
		return

	# 1. Stop walking, but keep tracking the player with our eyes
	actor.velocity = Vector3.ZERO
	
	var aim_target = player.global_position
	aim_target.y = actor.global_position.y # Keep the dummy standing up straight
	actor.look_at(aim_target, Vector3.UP)

	# 2. Did the player run away OR hide behind a wall? Go back to chasing!
	var distance = actor.global_position.distance_to(player.global_position)
	
	# Cast a quick math-laser to check Line of Sight (LoS)
	var has_line_of_sight = false
	var space_state = actor.get_world_3d().direct_space_state
	
	# Raise the laser up to chest height so it doesn't clip the floor
	var start_pos = actor.global_position + Vector3(0, 1.0, 0)
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
	var current_time = Time.get_ticks_msec()
	
	# Convert your fire_rate (seconds) to milliseconds for the clock
	if current_time - last_shot_time >= (fire_rate * 1000.0):
		shoot()

func shoot() -> void:
	# 1. Instantly lock the gun with the current system clock time
	last_shot_time = Time.get_ticks_msec()
	print("BANG! Enemy fired at player!")
	
	# 2. Set up the mathematical raycast
	var space_state = actor.get_world_3d().direct_space_state
	var start_pos = actor.global_position + Vector3(0, 1.0, 0) 
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	var result = space_state.intersect_ray(query)
	
	# 3. Check if the bullet hit the player or got blocked by the world
	if result and result.collider == player:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	else:
		print("Enemy bullet hit a wall!")
		
	# Notice there is no "await timer" or "can_shoot = true" down here anymore!
