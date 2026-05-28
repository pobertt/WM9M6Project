class_name enemy_dummy
extends CharacterBody3D

# Grab references to the AI tools
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var line_of_sight: RayCast3D = $LineOfSight

# We need a reference to the player once they are spotted
var target_player: Node3D = null

@export var max_health: int = 30
var current_health: int

func _ready() -> void:
	current_health = max_health
	# Tell the raycast to ignore the dummy's own physical body!
	line_of_sight.add_exception(self)

func _physics_process(_delta: float) -> void:
	# Only do vision math if someone tripped the wire!
	if target_player != null:
		# 1. Point the invisible laser exactly at the player
		# (We add Vector3(0, 1, 0) to look at their chest, not their feet)
		var aim_target = target_player.global_position + Vector3(0, 1.0, 0)
		line_of_sight.look_at(aim_target, Vector3.UP)
		
		# 2. THE MISSING CODE: Stretch the laser so it actually reaches the player!
		var distance = global_position.distance_to(aim_target)
		line_of_sight.target_position = Vector3(0, 0, -distance)
		
		line_of_sight.force_raycast_update()
		
		# 3. Check what the laser is hitting
		if line_of_sight.is_colliding():
			var hit = line_of_sight.get_collider()
			
			if hit.is_in_group("Player"):
				print("I SEE YOU! Switching to Chase State!")
				target_player = null

func _on_hurt_box_took_damage(amount: int) -> void:
	current_health -= amount
	print("Dummy hit! Remaining HP: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Dummy destroyed!")
	# This instantly deletes the node from the game
	queue_free()

func _on_detection_zone_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		target_player = body
		print("player entered")
