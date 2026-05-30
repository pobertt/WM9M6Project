extends State

func enter() -> void:
	if "death_sounds" in actor and not actor.death_sounds.is_empty():
		AudioManager.play_sound_3d(actor.death_sounds.pick_random(), actor.global_position, 0.0)
		
	# 1. Stop all movement
	actor.velocity = Vector3.ZERO
	
	# 2. Disable collisions
	actor.get_node("CollisionShape3D").set_deferred("disabled", true)
	
	var hurtbox = actor.get_node_or_null("HurtBox/CollisionShape3D")
	if hurtbox != null:
		hurtbox.set_deferred("disabled", true)
	
	# 3. Randomly pick a death animation
	if actor.anim_state_machine:
		var death_animations = [
			"melee_death_right_anim", # Replace with your exact node name
			"melee_headshot_death_anim"  # Replace with your exact node name
		]
		var chosen_death = death_animations.pick_random()
		actor.anim_state_machine.travel(chosen_death)
		
	# 4. Clean up
	await get_tree().create_timer(10.0).timeout
	if is_inside_tree():
		actor.queue_free()

func physics_update(_delta: float) -> void:
	# Keep applying gravity so they don't float mid-air if killed on stairs
	if not actor.is_on_floor():
		actor.velocity += actor.get_gravity() * _delta
		actor.move_and_slide()
