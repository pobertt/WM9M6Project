extends Node

# --- BULLET POOL ---
var pool_size: int = 50 
var decal_scene: PackedScene = preload("res://assets/vfx/bullet_decal.tscn")
var bullet_hole_pool: Array = []
var current_index: int = 0

# --- BLOOD POOL ---
var blood_pool_size: int = 30 # Blood usually needs fewer decals than bullets
var blood_scene: PackedScene = preload("res://assets/vfx/blood_decal.tscn")
var blood_pool: Array[Node3D] = []
var blood_index: int = 0

func _ready() -> void:
	# Build the bullet pool
	for i in range(pool_size):
		var decal = decal_scene.instantiate()
		add_child(decal)
		decal.hide()
		bullet_hole_pool.append(decal)
		
	# Build the blood pool
	for i in range(blood_pool_size):
		var blood = blood_scene.instantiate()
		add_child(blood)
		blood.hide()
		blood_pool.append(blood)

func spawn_impact(pos: Vector3, normal: Vector3) -> void:
	# 1. Grab a bullet hole from your pool array
	var decal = bullet_hole_pool[current_index] 
	
	
	# 2. Move it to the exact coordinate the raycast hit
	decal.global_position = pos 
	
	# 3. Rotate it so it sits flat against the wall, floor, or ceiling
	if normal != Vector3.UP and normal != Vector3.DOWN:
		decal.look_at(pos + normal, Vector3.UP)
	elif normal == Vector3.UP:
		decal.rotation_degrees.x = -90
	elif normal == Vector3.DOWN:
		decal.rotation_degrees.x = 90
		
	# 4. Cycle to the next bullet hole in the pool
	current_index = (current_index + 1) % bullet_hole_pool.size()
	
	decal.show()

# Add this new function for the blood
func spawn_blood(pos: Vector3, normal: Vector3) -> void:
	var blood = blood_pool[blood_index]
	
	# Move it to the hit location (add the + normal * 0.01 nudge if using Sprite3D)
	blood.global_position = pos + (normal * 0.01)
	
	# Align it to the surface
	if normal != Vector3.UP and normal != Vector3.DOWN:
		blood.look_at(pos - normal, Vector3.UP)
	elif normal == Vector3.UP:
		blood.rotation_degrees.x = -90
	elif normal == Vector3.DOWN:
		blood.rotation_degrees.x = 90
		
	blood.show()
	
	# --- ADD THESE TWO LINES ---
	# Find the particle node inside the blood scene and force it to burst
	var particles = blood.get_node("GPUParticles3D")
	particles.restart() 
	
	blood_index = (blood_index + 1) % blood_pool_size
