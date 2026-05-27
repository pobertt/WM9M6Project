extends Weapon

@onready var raycast: RayCast3D = $RayCast3D
@onready var mesh: Node3D = $"USP-S"
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _weapon_behavior() -> void:
	# 1. VISUALS
	# Stop the animation if it's already playing so rapid clicks don't break it
	if anim_player.is_playing():
		anim_player.stop()
	anim_player.play("fire")
	
	# ... inside your _weapon_behavior() function ...
	
	raycast.force_raycast_update() 
	
	if raycast.is_colliding():
		var target = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		
		# 1. Did we hit an enemy?
		if target.has_method("take_damage"):
			target.take_damage(damage)
			# Spawn the blood exactly where the ray hit the enemy!
			ObjectPoolManager.spawn_blood(hit_point, hit_normal)
			
		# 2. Or did we hit a wall?
		else:
			ObjectPoolManager.spawn_impact(hit_point, hit_normal)
