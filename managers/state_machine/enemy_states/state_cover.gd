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
	
	if player != null:
		find_best_cover()
	else:
		actor.get_node("StateMachine").on_child_transition(self, "state_wander")

func physics_update(_delta: float) -> void:
	if player == null:
		return
		
	var nav = actor.nav_agent
	
	if not reached_cover:
		if target_cover_position == Vector3.ZERO:
			actor.get_node("StateMachine").on_child_transition(self, "state_chase")
			return
			
		nav.target_position = target_cover_position
		
		var direction = actor.global_position.direction_to(nav.get_next_path_position())
		direction.y = 0
		direction = direction.normalized()
		
		actor.velocity = direction * movement_speed
		actor.move_and_slide()
		
		if direction != Vector3.ZERO:
			actor.look_at(actor.global_position + direction, Vector3.UP)
			
		if nav.is_navigation_finished():
			reached_cover = true
			execute_cover_loop()

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
	# 1. Stop and hide
	actor.velocity = Vector3.ZERO
	await get_tree().create_timer(wait_in_cover_time).timeout
	
	# Safety check in case they died while hiding
	if not is_inside_tree() or actor.current_health <= 0: return
	
	is_peeking = true
	
	# 2. CALCULATE THE PEEK
	# Find our left and right sides relative to the player
	var to_player = actor.global_position.direction_to(player.global_position)
	to_player.y = 0
	var right_vector = to_player.cross(Vector3.UP).normalized()
	
	# Randomly pick left or right, and set a target 1.5 meters out
	var peek_dir = right_vector * [-1, 1].pick_random()
	var peek_target = actor.global_position + (peek_dir * 1.5)
	actor.nav_agent.target_position = peek_target
	
	# 3. STEP OUT
	# A mini-loop to walk sideways until they reach the peek spot
	while not actor.nav_agent.is_navigation_finished() and is_inside_tree() and actor.current_health > 0:
		var current_pos = actor.global_position
		var next_pos = actor.nav_agent.get_next_path_position()
		var dir = current_pos.direction_to(next_pos)
		
		dir.y = 0
		actor.velocity = dir.normalized() * movement_speed
		actor.move_and_slide()
		
		# Keep eyes on the player while stepping out
		var look_target = player.global_position
		look_target.y = actor.global_position.y
		actor.look_at(look_target, Vector3.UP)
		
		await get_tree().physics_frame 
		
	# 4. OPEN FIRE
	if is_inside_tree() and actor.current_health > 0:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
