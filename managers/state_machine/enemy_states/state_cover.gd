extends State

@export var movement_speed: float = 5.5
@export var max_search_radius: float = 15.0
@export var wait_in_cover_time: float = 2.0

var player: Node3D
var target_cover_position: Vector3 = Vector3.ZERO
var reached_cover: bool = false
var is_peeking: bool = false

func enter() -> void:
	print("Entering Cover State!")
	
	# Try to grab the player from the actor's memory first
	player = actor.target_player
	
	# THE FIX: If we were shot from outside our detection zone, find the player manually!
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		# Update the enemy's brain so they remember the player for the other states
		actor.target_player = player
		
	reached_cover = false
	is_peeking = false
	
	# Final safety lock: Only run the cover math if the player actually exists
	if player != null:
		find_best_cover()
	else:
		# If the player was deleted or doesn't exist, just go back to wandering
		actor.get_node("StateMachine").on_child_transition(self, "state_wander")

func physics_update(_delta: float) -> void:
	if player == null:
		return
		
	var nav = actor.nav_agent
	
	# 1. Navigating to the chosen safe wall
	if not reached_cover:
		if target_cover_position == Vector3.ZERO:
			print("COVER FAILED: No safe walls nearby! Charging instead!")
			actor.get_node("StateMachine").on_child_transition(self, "state_chase")
			return
			
		nav.target_position = target_cover_position
		
		var current_pos = actor.global_position
		var next_pos = nav.get_next_path_position()
		var direction = current_pos.direction_to(next_pos)
		
		direction.y = 0
		direction = direction.normalized()
		
		actor.velocity = direction * movement_speed
		actor.move_and_slide()
		
		if direction != Vector3.ZERO:
			actor.look_at(current_pos + direction, Vector3.UP)
			
		if nav.is_navigation_finished():
			reached_cover = true
			execute_cover_loop()

func find_best_cover() -> void:
	var cover_nodes = get_tree().get_nodes_in_group("CoverPoints")
	var best_point: Vector3 = Vector3.ZERO
	var closest_distance: float = max_search_radius
	
	var space_state = actor.get_world_3d().direct_space_state
	
	for node in cover_nodes:
		if not node is Marker3D: continue
		
		var point_pos = node.global_position
		var dist_to_enemy = actor.global_position.distance_to(point_pos)
		
		# Only evaluate nodes within a reasonable sprinting distance
		if dist_to_enemy < closest_distance:
			# Verify if this position actually blocks the player's vision
			var start_pos = point_pos + Vector3(0, 1.0, 0) # Chest height
			var end_pos = player.global_position + Vector3(0, 1.0, 0)
			
			var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
			query.exclude = [actor.get_rid()]
			var result = space_state.intersect_ray(query)
			
			# If the raycast hits something BEFORE reaching the player, it's a solid wall!
			if result and result.collider != player:
				closest_distance = dist_to_enemy
				best_point = point_pos
				
	target_cover_position = best_point

func execute_cover_loop() -> void:
	# Stop moving once nested safely behind the geometry
	actor.velocity = Vector3.ZERO
	
	# Wait behind cover out of sight
	await get_tree().create_timer(wait_in_cover_time).timeout
	
	if not is_inside_tree() or actor.current_health <= 0: return
	
	# Step 3: The Peek and Shoot routine
	is_peeking = true
	print("Peeking out from cover!")
	
	# Turn to face the player before stepping out
	var look_target = player.global_position
	look_target.y = actor.global_position.y
	actor.look_at(look_target, Vector3.UP)
	
	# Transition back to attack state to fire from this new position
	actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
