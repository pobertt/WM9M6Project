extends Weapon

@onready var raycast: RayCast3D = $RayCast3D
@onready var mesh: Node3D = $SMG
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle_light: OmniLight3D = $MuzzleLight # Grab the light

func _weapon_behavior() -> void:
	# 1. VISUALS
	if anim_player.is_playing():
		anim_player.stop()
	anim_player.play("fire")
	
	# Flash the environment light!
	muzzle_light.light_energy = 3.0
	var tween = create_tween()
	tween.tween_property(muzzle_light, "light_energy", 0.0, 0.1) # Fade out in 0.1 seconds
	
	raycast.force_raycast_update() 
	
	if raycast.is_colliding():
		var target = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		
		# Did we hit an enemy?
		if target.has_method("take_damage"):
			target.take_damage(damage)
			ObjectPoolManager.spawn_blood(hit_point, hit_normal)
			
		# Or did we hit a wall?
		else:
			ObjectPoolManager.spawn_impact(hit_point, hit_normal)

func _weapon_reload_behavior() -> void:
	# Stop the fire animation if it's currently playing
	if anim_player.is_playing():
		anim_player.stop()
		
	# Play the new reload animation!
	anim_player.play("reload")
