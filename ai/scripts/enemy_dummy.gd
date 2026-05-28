class_name enemy_dummy
extends CharacterBody3D

# --- LIFTED ATTACK CONFIGURATION ---
@export_group("Attack Settings")
@export var is_ranged_enemy: bool = true
@export var ranged_attack_range: float = 10.0

@export var is_melee_enemy: bool = false
@export var melee_attack_range: float = 2.0

var is_in_combat: bool = false
# -----------------------------------

# Grab references to the AI tools
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var line_of_sight: RayCast3D = $LineOfSight

@onready var muzzle: Marker3D = $Muzzle

# We need a reference to the player once they are spotted
var target_player: Node3D = null

@export var max_health: int = 30
var current_health: int

func _ready() -> void:
	current_health = max_health
	# Tell the raycast to ignore the dummy's own physical body!
	line_of_sight.add_exception(self)

func _physics_process(_delta: float) -> void:
	# Only do vision math if someone tripped the wire AND we aren't already fighting!
	if target_player != null and not is_in_combat:
		var aim_target = target_player.global_position + Vector3(0, 1.0, 0)
		line_of_sight.look_at(aim_target, Vector3.UP)
		
		var distance = global_position.distance_to(aim_target)
		line_of_sight.target_position = Vector3(0, 0, -distance)
		
		line_of_sight.force_raycast_update()
		
		if line_of_sight.is_colliding():
			var hit = line_of_sight.get_collider()
			
			if hit.is_in_group("Player"):
				print("I SEE YOU! Switching to Chase State!")
				
				# THE LOCK: Stop running this vision math forever!
				is_in_combat = true 
				
				$StateMachine.on_child_transition($StateMachine.current_state, "state_chase")

func _on_hurt_box_took_damage(amount: int) -> void:
	current_health -= amount
	print("Dummy hit! Remaining HP: ", current_health)
	
	# THE OMNISCIENCE FIX: Instantly realize who shot us, no matter what!
	if target_player == null:
		target_player = get_tree().get_first_node_in_group("Player")
	
	# Tell the root brain we are fighting so it stops hijacking the states
	is_in_combat = true 
	
	if current_health <= 0:
		die()
	else:
		# 30% chance to break combat and sprint to cover when hit
		if randf() < 0.30 and $StateMachine.current_state.name.to_lower() != "state_cover":
			$StateMachine.on_child_transition($StateMachine.current_state, "state_cover")
			
		# The other 70% of the time, charge the player!
		elif $StateMachine.current_state.name.to_lower() == "state_wander":
			$StateMachine.on_child_transition($StateMachine.current_state, "state_chase")

func die() -> void:
	# 1. Turn off the detection box so it physically cannot see you anymore
	# We use set_deferred because Godot gets mad if you disable physics shapes in the middle of a frame
	$DetectionZone/CollisionShape3D.set_deferred("disabled", true)
	
	# 2. (Optional) Turn off the main hit box so you can't shoot the corpse
	$CollisionShape3D.set_deferred("disabled", true)
	
	# 3. Hand the steering wheel to the Death State so it can die gracefully
	$StateMachine.on_child_transition($StateMachine.current_state, "state_death")

func _on_detection_zone_body_entered(body: Node3D) -> void:
	if current_health <= 0:
		return
		
	if body.name == "Player":
		target_player = body
		print("player entered")
