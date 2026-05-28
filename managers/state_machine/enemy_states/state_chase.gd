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
	
	# 2. MELEE CHECK
	if check_melee and distance <= melee_range:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_melee")
		return
		
	# 3. RANGED CHECK
	if check_ranged and distance <= ranged_range:
		actor.get_node("StateMachine").on_child_transition(self, "state_attack_ranged")
		return 
		
	# 4. If we aren't close enough to attack, keep running!
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
