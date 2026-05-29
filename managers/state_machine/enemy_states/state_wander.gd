extends State

@export var move_speed: float = 3.0
@export var wander_radius: float = 8.0

var start_position: Vector3
var wait_timer: float = 0.0
var is_waiting: bool = false

func enter() -> void:
	start_position = actor.global_position
	
	# NEW: Just tell the tree to use the Movement BlendSpace once when we enter the state.
	# The speed calculation in enemy_dummy.gd will handle the rest!
	if actor.anim_state_machine:
		actor.anim_state_machine.travel("Movement")
		
	pick_new_target()

func physics_update(delta: float) -> void:
	# 1. Apply gravity
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * delta
		
	# 2. Handle the safe waiting timer
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0.0:
			pick_new_target()
			
		# Keep moving gravity but stop forward momentum
		# Because velocity becomes 0, the BlendSpace will automatically play the Idle animation!
		actor.velocity.x = 0
		actor.velocity.z = 0
		actor.move_and_slide()
		return
		
	var nav = actor.nav_agent
	
	# 3. Check if we arrived
	if nav.is_navigation_finished():
		start_waiting()
		return
		
	# 4. Normal Movement
	var current_pos = actor.global_position
	var next_pos = nav.get_next_path_position()
	var direction = current_pos.direction_to(next_pos)
	
	direction.y = 0 
	direction = direction.normalized()
	
	actor.velocity.x = direction.x * move_speed
	actor.velocity.z = direction.z * move_speed
	actor.move_and_slide()
	
	if direction != Vector3.ZERO:
		actor.look_at(current_pos + direction, Vector3.UP)

func start_waiting() -> void:
	is_waiting = true
	wait_timer = 2.0 
	
	# REMOVED: No need to travel to idle manually anymore.
	# The velocity change in physics_update handles it.

func pick_new_target() -> void:
	is_waiting = false
	
	actor.nav_agent.target_position = start_position + Vector3(
		randf_range(-wander_radius, wander_radius), 
		0, 
		randf_range(-wander_radius, wander_radius)
	)
	
