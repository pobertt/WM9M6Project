extends State

@export var chase_speed: float = 5.0
var player: Node3D

func enter() -> void:
	player = actor.target_player
	actor.anim_state_machine.travel("Movement")

func physics_update(_delta: float) -> void:
	if player == null:
		return
		
	var distance = actor.global_position.distance_to(player.global_position)
	
	# Fetch actor properties dynamically
	var check_melee = actor.get("is_melee_enemy") if "is_melee_enemy" in actor else false
	var melee_range = actor.get("melee_attack_range") if "melee_attack_range" in actor else 2.0
	var check_ranged = actor.get("is_ranged_enemy") if "is_ranged_enemy" in actor else false
	var ranged_range = actor.get("ranged_attack_range") if "ranged_attack_range" in actor else 10.0
	
	# Line of sight check
	var space_state = actor.get_world_3d().direct_space_state
	var start_pos = actor.muzzle.global_position
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	var result = space_state.intersect_ray(query)
	var has_los = result and result.collider == player

	# Attack transitions
	if check_melee and distance <= melee_range and has_los:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_melee")
		return
		
	if check_ranged and distance <= ranged_range and has_los:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
		return 
		
	# Pathfinding logic
	var nav = actor.nav_agent
	nav.target_position = player.global_position
	
	var direction = actor.global_position.direction_to(nav.get_next_path_position())
	direction.y = 0 
	
	actor.velocity = direction.normalized() * chase_speed
	actor.move_and_slide()
	
	if direction != Vector3.ZERO:
		actor.look_at(actor.global_position + direction, Vector3.UP)
