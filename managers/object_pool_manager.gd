extends Node

var pool_size: int = 50 
var decal_scene: PackedScene = preload("res://assets/vfx/bullet_decal.tscn")
var bullet_hole_pool: Array = []
var current_index: int = 0

var blood_pool_size: int = 30 
var blood_scene: PackedScene = preload("res://assets/vfx/blood_decal.tscn")
var blood_pool: Array[Node3D] = []
var blood_index: int = 0

func _ready() -> void:
	for i in range(pool_size):
		var decal = decal_scene.instantiate()
		add_child(decal)
		decal.hide()
		bullet_hole_pool.append(decal)
		
	for i in range(blood_pool_size):
		var blood = blood_scene.instantiate()
		add_child(blood)
		blood.hide()
		blood_pool.append(blood)

func spawn_impact(pos: Vector3, normal: Vector3) -> void:
	var decal = bullet_hole_pool[current_index] 
	decal.global_position = pos 
	
	# Align to surfaces
	if normal != Vector3.UP and normal != Vector3.DOWN:
		decal.look_at(pos + normal, Vector3.UP)
	elif normal == Vector3.UP:
		decal.rotation_degrees.x = -90
	elif normal == Vector3.DOWN:
		decal.rotation_degrees.x = 90
		
	current_index = (current_index + 1) % bullet_hole_pool.size()
	decal.show()

func spawn_blood(pos: Vector3, normal: Vector3, target: Node3D = null) -> void:
	var blood = blood_pool[blood_index]
	
	# FIX: If the blood was destroyed (because the scene reloaded or the enemy was deleted),
	# we just instantiate a fresh replacement to heal the pool!
	if not is_instance_valid(blood):
		blood = blood_scene.instantiate()
		add_child(blood) # Add it to the tree first so reparenting works
		blood_pool[blood_index] = blood
	
	# Pin the blood to the target so it moves with them
	if target != null:
		blood.reparent(target)
	else:
		blood.reparent(self) # Pin it back to the manager if we hit a wall
		
	# The clean alignment math
	blood.global_position = pos + (normal * 0.01)
	
	if normal != Vector3.UP and normal != Vector3.DOWN:
		blood.look_at(pos - normal, Vector3.UP)
	elif normal == Vector3.UP:
		blood.rotation_degrees.x = -90
	elif normal == Vector3.DOWN:
		blood.rotation_degrees.x = 90
		
	blood.show()
	blood.get_node("GPUParticles3D").restart() 
	
	blood_index = (blood_index + 1) % blood_pool_size
