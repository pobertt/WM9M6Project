extends State

@export var chase_speed: float = 5.0

var player: Node3D

func enter() -> void:
	print("Entering Chase State!")
	player = actor.target_player

func physics_update(_delta: float) -> void:
	if player == null:
		return
		
	var distance = actor.global_position.distance_to(player.global_position)
	
	# 1. Safely grab the variables from the root actor
	var check_melee = actor.is_melee_enemy if "is_melee_enemy" in actor else false
	var melee_range = actor.melee_attack_range if "melee_attack_range" in actor else 2.0
	
	var check_ranged = actor.is_ranged_enemy if "is_ranged_enemy" in actor else false
	var ranged_range = actor.ranged_attack_range if "ranged_attack_range" in actor else 10.0
	
	# 2. Check Line of Sight (so we don't try to attack walls!)
	var has_line_of_sight = false
	var space_state = actor.get_world_3d().direct_space_state
	var start_pos = actor.muzzle.global_position
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()] # Ignore our own physics body
	var result = space_state.intersect_ray(query)
	
	if result and result.collider == player:
		has_line_of_sight = true
	
	# 3. MELEE CHECK (Must be in range AND see the player)
	if check_melee and distance <= melee_range and has_line_of_sight:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_melee")
		return
		
	# 4. RANGED CHECK (Must be in range AND see the player)
	if check_ranged and distance <= ranged_range and has_line_of_sight:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
		return 
		
	# 5. If we aren't close enough to attack (or a wall is blocking us), keep running!
	var nav = actor.nav_agent
	nav.target_position = player.global_position
	
	var current_pos = actor.global_position
	var next_pos = nav.get_next_path_position()
	var direction = current_pos.direction_to(next_pos)
	
	direction.y = 0 
	direction = direction.normalized()
	
	actor.velocity = direction * chase_speed
	actor.move_and_slide()
	
	if direction != Vector3.ZERO:
		actor.look_at(current_pos + direction, Vector3.UP)
