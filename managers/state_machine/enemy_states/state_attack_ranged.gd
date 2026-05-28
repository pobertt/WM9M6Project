extends State

@export var fire_rate: float = 1.0 # Shoots once per second
@export var lose_interest_range: float = 12.0 # Slightly larger than attack_range to prevent jitter
@export var attack_damage: int = 10
	
var player: Node3D
var can_shoot: bool = true

func enter() -> void:
	print("Entering Ranged Attack State!")
	player = actor.target_player
	can_shoot = true

func physics_update(_delta: float) -> void:
	if player == null:
		return

	# 1. Stop walking, but keep tracking the player with our eyes
	actor.velocity = Vector3.ZERO
	
	var aim_target = player.global_position
	aim_target.y = actor.global_position.y # Keep the dummy standing up straight
	actor.look_at(aim_target, Vector3.UP)

	# 2. Did the player run away? Go back to chasing them!
	var distance = actor.global_position.distance_to(player.global_position)
	if distance > lose_interest_range:
		actor.get_node("StateMachine").on_child_transition(self, "state_chase")
		return

	# 3. Pull the trigger if the gun is ready
	if can_shoot:
		shoot()

func shoot() -> void:
	can_shoot = false
	print("BANG! Enemy fired at player!")
	
	# Safely ask the player to take damage
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	# SAFETY CHECK: If the shot killed the player and the level is restarting, 
	# this enemy is being deleted. Abort the rest of the function!
	if not is_inside_tree():
		return
		
	# Wait for the gun cooldown
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
