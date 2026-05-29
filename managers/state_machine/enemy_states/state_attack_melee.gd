extends State

@export var attack_damage: int = 20
@export var attack_range: float = 2.5
@export var attack_windup: float = 0.3  # Time before the hit actually lands
@export var attack_cooldown: float = 1.5

var player: Node3D
var last_attack_time: int = 0
var is_swinging: bool = false

func enter() -> void:
	player = actor.target_player
	is_swinging = false

func physics_update(delta: float) -> void:
	if player == null:
		return
		
	# 1. ALWAYS APPLY GRAVITY
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * delta
		actor.move_and_slide()

	# 2. THE ANIMATION LOCK
	# If we are currently locked in an attack swing, stop processing movement
	if is_swinging:
		return
		
	var distance = actor.global_position.distance_to(player.global_position)
	
	# 3. DISTANCE CHECK
	# If the player ran away, go back to chasing!
	if distance > attack_range:
		actor.get_node("StateMachine").on_child_transition(self, "state_chase")
		return
		
	# 4. POSITIONING
	# Keep facing the player while close, but stop walking directly into them
	var aim_target = player.global_position
	aim_target.y = actor.global_position.y
	actor.look_at(aim_target, Vector3.UP)
	
	actor.velocity.x = 0
	actor.velocity.z = 0
	actor.move_and_slide()

	# 5. THE ATTACK TRIGGER
	var current_time = Time.get_ticks_msec()
	if current_time - last_attack_time >= (attack_cooldown * 1000.0):
		execute_melee_strike()

func execute_melee_strike() -> void:
	print("SWINGING!")
	is_swinging = true
	last_attack_time = Time.get_ticks_msec()
	
	# 1. Put the exact names of your AnimationTree nodes into an Array
	var attack_animations = [
		"standing_melee_attack_horizontal_anim",
		"standing_melee_attack_downward_anim",
		"standing_melee_punching_anim"
	]
	
	# 2. Pick one at random
	var chosen_attack = attack_animations.pick_random()
	
	# 3. Tell the tree to play the randomly chosen attack
	if actor.anim_state_machine:
		actor.anim_state_machine.travel(chosen_attack)
		
	# Wait for the "windup" (e.g., the arm swinging forward) before dealing damage
	await get_tree().create_timer(attack_windup).timeout
	
	# Ensure the enemy hasn't died or been deleted during the windup
	if not is_inside_tree() or actor.current_health <= 0:
		return
		
	# Double check the player didn't dodge out of the way during the windup!
	var distance = actor.global_position.distance_to(player.global_position)
	
	# We give a slight 0.5m leniency so it doesn't feel like the hit unfairly missed
	if distance <= attack_range + 0.5: 
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	
	# Unlock the movement so they can chase again
	is_swinging = false
