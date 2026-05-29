extends State

var player: Node3D
var is_swinging: bool = false

func enter() -> void:
	player = actor.target_player
	is_swinging = true
	
	# Stop their momentum instantly so they don't slide while swinging
	actor.velocity = Vector3.ZERO 
	
	var attack_animations = [
		"standing_melee_attack_horizontal_anim",
		"standing_melee_attack_downward_anim",
		"standing_melee_punching_anim"
	]
	
	var chosen_attack = attack_animations.pick_random()
	
	if actor.anim_state_machine:
		actor.anim_state_machine.travel(chosen_attack)

func physics_update(_delta: float) -> void:
	# Keep gravity active so they don't float
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * _delta
		actor.move_and_slide()
		
	# LOCK: Do not allow any transitions while the animation is still playing!
	if is_swinging:
		return
		
	# UNLOCKED: The animation finished. Decide what to do next.
	var distance = actor.global_position.distance_to(player.global_position)
	if distance > actor.get("melee_attack_range"):
		actor.get_node("StateMachine").on_child_transition(self, "state_chase")
