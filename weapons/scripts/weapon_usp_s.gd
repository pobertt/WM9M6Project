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
	
	# 2. HIT DETECTION
	raycast.force_raycast_update() 
	
	if raycast.is_colliding():
		var target = raycast.get_collider()
		print("I hit: ", target.name)
		if target.has_method("take_damage"):
			target.take_damage(damage)
