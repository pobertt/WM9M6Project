extends State

@export var corpse_scene: PackedScene 

func enter() -> void:
	actor.velocity = Vector3.ZERO
	actor.get_node("CollisionShape3D").set_deferred("disabled", true)
	actor.get_node("HurtBox/CollisionShape3D").set_deferred("disabled", true)
	
	var mesh = actor.get_node_or_null("BadGuy")
	if mesh != null:
		mesh.hide()
		
	if mesh != null:
		mesh.hide()
		
	if corpse_scene != null:
		var corpse = corpse_scene.instantiate()
		var active_scene = get_tree().current_scene
		
		# THE SAFETY NET: Only spawn the corpse if the level hasn't been deleted!
		if active_scene != null:
			active_scene.add_child(corpse)
			corpse.global_transform = actor.global_transform
			
			var push_dir = -actor.global_transform.basis.z + (Vector3.UP * 0.5)
			corpse.apply_central_impulse(push_dir * 5.0)
	
	await get_tree().create_timer(2.0).timeout
	actor.queue_free()

func physics_update(_delta: float) -> void:
	pass
