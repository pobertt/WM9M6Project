extends State

@export var fire_rate: float = 0.5 
@export var lose_interest_range: float = 17.0 
@export var attack_damage: int = 10
@export var weapon_spread: float = 1.0 
@export var strafe_speed: float = 5.0

var strafe_direction: int = 1
var next_strafe_time: int = 0
var player: Node3D
var last_shot_time: int = 0

func enter() -> void:
	player = actor.target_player
	actor.anim_state_machine.travel("Shooting")

func physics_update(_delta: float) -> void:
	if player == null:
		return

	# Strafing movement logic
	var current_time = Time.get_ticks_msec()
	var nav = actor.nav_agent
	
	if current_time > next_strafe_time:
		strafe_direction = [-1, 1].pick_random() 
		next_strafe_time = current_time + randi_range(1500, 3000)
		
		var to_player = actor.global_position.direction_to(player.global_position)
		to_player.y = 0 
		nav.target_position = actor.global_position + (to_player.cross(Vector3.UP).normalized() * strafe_direction * 3.0)

	# Apply gravity
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * _delta
		
	# Move towards strafe target
	if not nav.is_navigation_finished():
		var direction = actor.global_position.direction_to(nav.get_next_path_position())
		direction.y = 0 
		
		var horizontal_vel = direction.normalized() * strafe_speed
		actor.velocity.x = horizontal_vel.x
		actor.velocity.z = horizontal_vel.z
	else:
		actor.velocity.x = 0
		actor.velocity.z = 0

	actor.move_and_slide()
	
	var aim_target = player.global_position
	aim_target.y = actor.global_position.y
	actor.look_at(aim_target, Vector3.UP)

	# Line of sight check
	var space_state = actor.get_world_3d().direct_space_state
	var start_pos = actor.muzzle.global_position
	var end_pos = player.global_position + Vector3(0, 1.0, 0)
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	query.hit_back_faces = true
	
	var result = space_state.intersect_ray(query)

	# Lose interest if too far or line of sight is broken
	# NEW
	if actor.global_position.distance_to(player.global_position) > lose_interest_range:
		actor.get_node("StateMachine").on_child_transition(self, "state_chase")
		return

	# Fire weapon based on fire rate
	if current_time - last_shot_time >= (fire_rate * 1000.0):
		shoot(start_pos, end_pos, space_state)

func shoot(start_pos: Vector3, target_pos: Vector3, space_state: PhysicsDirectSpaceState3D) -> void:
	last_shot_time = Time.get_ticks_msec()
	
	if "shoot_sounds" in actor:
		if not actor.shoot_sounds.is_empty():
			AudioManager.play_sound_3d(actor.shoot_sounds.pick_random(), start_pos, -20.0)

	
	# Calculate spread based on distance
	var active_spread = weapon_spread * clamp(start_pos.distance_to(target_pos) / 10.0, 0.0, 1.0)
	
	var random_offset = Vector3(
		randf_range(-active_spread, active_spread),
		randf_range(-active_spread, active_spread),
		randf_range(-active_spread, active_spread)
	)
	
	var end_pos = target_pos + random_offset
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [actor.get_rid()]
	query.hit_back_faces = true
	
	var result = space_state.intersect_ray(query)
	
	var hit_pos = end_pos 
	
	if result:
		hit_pos = result.position
		if result.collider == player and player.has_method("take_damage"):
			player.take_damage(attack_damage)
			
	spawn_tracer(start_pos, hit_pos)

func spawn_tracer(start: Vector3, end: Vector3) -> void:
	if not is_inside_tree():
		return
		
	var tracer = MeshInstance3D.new()
	var box = BoxMesh.new()
	
	box.size = Vector3(0.01, 0.01, start.distance_to(end))
	tracer.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.YELLOW
	mat.emission_enabled = true
	mat.emission = Color.YELLOW
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.surface_set_material(0, mat)
	
	get_tree().root.add_child(tracer)
	tracer.global_position = start.lerp(end, 0.5)
	tracer.look_at(end, Vector3.UP)
	
	await get_tree().create_timer(0.05).timeout
	tracer.queue_free()
