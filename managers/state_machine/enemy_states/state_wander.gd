extends State

@export var move_speed: float = 3.0
@export var wander_radius: float = 8.0

var start_position: Vector3
var is_waiting: bool = false

func enter() -> void:
	start_position = actor.global_position
	pick_new_target()

func physics_update(_delta: float) -> void:
	if is_waiting:
		return
		
	var nav = actor.nav_agent
	
	if nav.is_navigation_finished():
		is_waiting = true
		await get_tree().create_timer(2.0).timeout
		pick_new_target()
		return
		
	var current_pos = actor.global_position
	var next_pos = nav.get_next_path_position()
	var direction = current_pos.direction_to(next_pos)
	
	direction.y = 0 
	direction = direction.normalized()
	
	actor.velocity = direction * move_speed
	actor.move_and_slide()
	
	if direction != Vector3.ZERO:
		actor.look_at(current_pos + direction, Vector3.UP)

func pick_new_target() -> void:
	is_waiting = false
	actor.nav_agent.target_position = start_position + Vector3(
		randf_range(-wander_radius, wander_radius), 
		0, 
		randf_range(-wander_radius, wander_radius)
	)
