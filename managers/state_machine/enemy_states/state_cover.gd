extends State

@export var movement_speed: float = 5.5
@export var max_search_radius: float = 15.0
@export var wait_in_cover_time: float = 2.0

var player: Node3D
var target_cover_position: Vector3 = Vector3.ZERO
var reached_cover: bool = false
var is_peeking: bool = false

func enter() -> void:
	player = actor.target_player
	
	# Fallback if damaged outside detection zone
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		actor.target_player = player
		
	reached_cover = false
	is_peeking = false
	
	# FIX 1: Tell the tree to use the Movement BlendSpace. 
	# They will automatically run while moving, and automatically idle when they reach the wall!
	if actor.anim_state_machine:
		actor.anim_state_machine.travel("Movement")
	
	if player != null:
		find_best_cover()
	else:
		actor.get_node("StateMachine").on_child_transition(self, "state_wander")

func physics_update(_delta: float) -> void:
	if player == null:
		return
		
	# Keep gravity active
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * _delta
		
	var nav = actor.nav_agent
	
	if not reached_cover:
		if target_cover_position == Vector3.ZERO:
			actor.get_node("StateMachine").on_child_transition(self, "state_chase")
			return
			
		nav.target_position = target_cover_position
		
		# FIX 2: The Bulletproof Distance Check (Bypasses the 1-frame nav bug)
		var current_pos = actor.global_position
		var target_pos = nav.target_position
		var horizontal_dist = Vector2(current_pos.x, current_pos.z).distance_to(Vector2(target_pos.x, target_pos.z))
		
		if horizontal_dist < 1.0:
			reached_cover = true
			execute_cover_loop()
			return
			
		var direction = actor.global_position.direction_to(nav.get_next_path_position())
		direction.y = 0
		direction = direction.normalized()
		
		actor.velocity.x = direction.x * movement_speed
		actor.velocity.z = direction.z * movement_speed
		actor.move_and_slide()
		
		if direction != Vector3.ZERO:
			actor.look_at(actor.global_position + direction, Vector3.UP)

func find_best_cover() -> void:
	var best_point: Vector3 = Vector3.ZERO
	var closest_distance: float = max_search_radius
	var space_state = actor.get_world_3d().direct_space_state
	
	for node in get_tree().get_nodes_in_group("CoverPoints"):
		if not node is Marker3D: continue
		
		var dist_to_enemy = actor.global_position.distance_to(node.global_position)
		
		if dist_to_enemy < closest_distance:
			var query = PhysicsRayQueryParameters3D.create(node.global_position + Vector3(0, 1.0, 0), player.global_position + Vector3(0, 1.0, 0))
			query.exclude = [actor.get_rid()]
			var result = space_state.intersect_ray(query)
			
			if result and result.collider != player:
				closest_distance = dist_to_enemy
				best_point = node.global_position
				
	target_cover_position = best_point

func execute_cover_loop() -> void:
	# 1. Stop and hide (Velocity hits 0, so the BlendSpace drops them into rifle_idle)
	actor.velocity = Vector3.ZERO
	await get_tree().create_timer(wait_in_cover_time).timeout
	
	# Safety check in case they died while hiding
	if not is_inside_tree() or actor.current_health <= 0: return
	
	is_peeking = true
	
	# 2. CALCULATE THE PEEK
	var to_player = actor.global_position.direction_to(player.global_position)
	to_player.y = 0
	var right_vector = to_player.cross(Vector3.UP).normalized()
	
	var peek_dir = right_vector * [-1, 1].pick_random()
	var peek_target = actor.global_position + (peek_dir * 1.5)
	
	# 3. STEP OUT (Replaced nav_agent with a clean distance check to prevent infinite loops)
	while is_inside_tree() and actor.current_health > 0:
		var current_pos = actor.global_position
		var dist_to_peek = Vector2(current_pos.x, current_pos.z).distance_to(Vector2(peek_target.x, peek_target.z))
		
		if dist_to_peek < 0.5:
			break # We arrived at the peek spot!
			
		var dir = current_pos.direction_to(peek_target)
		dir.y = 0
		
		actor.velocity.x = dir.normalized().x * movement_speed
		actor.velocity.z = dir.normalized().z * movement_speed
		actor.move_and_slide()
		
		var look_target = player.global_position
		look_target.y = actor.global_position.y
		actor.look_at(look_target, Vector3.UP)
		
		await get_tree().physics_frame 
		
	# 4. OPEN FIRE
	if is_inside_tree() and actor.current_health > 0:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
