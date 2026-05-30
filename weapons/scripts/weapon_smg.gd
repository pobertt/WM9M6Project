extends Weapon

@onready var raycast: RayCast3D = $RayCast3D
@onready var mesh: Node3D = $SMG
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle_light: SpotLight3D = $MuzzleLight

var flash_tween: Tween
var last_spread_time: int = 0 

@export var spread_recovery_time: float = 0.35 
@export var base_spread: float = 2.0           
@export var movement_penalty: float = 3.0      

func _weapon_behavior() -> void:
	if anim_player.is_playing(): anim_player.stop()
	anim_player.play("fire")
	
	if flash_tween and flash_tween.is_valid(): flash_tween.kill()
		
	muzzle_light.light_energy = 3.0
	flash_tween = create_tween()
	flash_tween.tween_property(muzzle_light, "light_energy", 0.0, 0.1)
	
	var random_fire_sound = fire_sound.pick_random()
	
	if fire_sound != null:
		AudioManager.play_sound_2d(random_fire_sound, -10.0)
	
	var final_spread: float = 0.0 
	
	if (Time.get_ticks_msec() - last_spread_time) / 1000.0 < spread_recovery_time:
		final_spread += base_spread
		
	var player: CharacterBody3D = get_tree().get_first_node_in_group("Player")
	if player and player.velocity.length() > 1.0:
		final_spread += movement_penalty
		
	raycast.rotation_degrees.x = randf_range(-final_spread, final_spread)
	raycast.rotation_degrees.y = randf_range(-final_spread, final_spread)
	raycast.force_raycast_update() 
	
	# 3. COLLISION
	if raycast.is_colliding():
		var target = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		
		if target.has_method("take_damage"):
			target.take_damage(damage)
			# FIX: We now pass the 'target' so the blood sticks to them!
			ObjectPoolManager.spawn_blood(hit_point, hit_normal, target)
		else:
			ObjectPoolManager.spawn_impact(hit_point, hit_normal)
			
	raycast.rotation_degrees = Vector3.ZERO
	last_spread_time = Time.get_ticks_msec()

func _weapon_reload_behavior() -> void:
	if anim_player.is_playing(): anim_player.stop()
	
	if reload_sound != null:
		AudioManager.play_sound_2d(reload_sound, 2.0)
		
	anim_player.play("reload")
