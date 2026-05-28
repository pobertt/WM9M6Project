extends State

# We will drag our new corpse scene into this box in the Inspector
@export var corpse_scene: PackedScene 

func enter() -> void:
	print("Entering Death State! Spawning Ragdoll...")
	
	# 1. Stop the brain and disable hitboxes
	actor.velocity = Vector3.ZERO
	actor.get_node("CollisionShape3D").set_deferred("disabled", true)
	actor.get_node("HurtBox/CollisionShape3D").set_deferred("disabled", true)
	
	# 2. Hide the living visual mesh! 
	# (Change "MeshInstance3D" to whatever your dummy's visual node is actually named)
	if actor.has_node("MeshInstance3D"):
		actor.get_node("MeshInstance3D").visible = false
	elif actor.has_node("CSGBox3D"):
		actor.get_node("CSGBox3D").visible = false
		
	# 3. Spawn the physics ragdoll
	if corpse_scene != null:
		var corpse = corpse_scene.instantiate()
		
		# Add it to the main game world, NOT as a child of the dying dummy
		get_tree().current_scene.add_child(corpse)
		
		# Teleport the corpse to the exact position and rotation of the dummy
		corpse.global_transform = actor.global_transform
		
		# Give it a dramatic shove backward and slightly up so it tips over
		var push_dir = -actor.global_transform.basis.z + (Vector3.UP * 0.5)
		corpse.apply_central_impulse(push_dir * 5.0)
	
	# 4. Wait 2 seconds while the ragdoll falls, then delete the invisible AI brain
	await get_tree().create_timer(2.0).timeout
	actor.queue_free()

func physics_update(_delta: float) -> void:
	pass
