class_name enemy_dummy
extends CharacterBody3D

@export_group("Attack Settings")
@export var is_ranged_enemy: bool = true
@export var ranged_attack_range: float = 10.0
@export var is_melee_enemy: bool = false
@export var melee_attack_range: float = 2.0
@export var max_health: int = 30

var current_health: int
var is_in_combat: bool = false
var target_player: Node3D = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var line_of_sight: RayCast3D = $LineOfSight
@onready var muzzle: Marker3D = find_child("Muzzle", true, false)
@onready var anim_state_machine = find_child("AnimationTree", true, false).get("parameters/playback")


func _ready() -> void:
	current_health = max_health
	line_of_sight.add_exception(self)
	
	if GameManager.instance:
		GameManager.instance.register_enemy()

func _physics_process(_delta: float) -> void:
	if target_player != null and not is_in_combat:
		var aim_target = target_player.global_position + Vector3(0, 1.0, 0)
		line_of_sight.look_at(aim_target, Vector3.UP)
		line_of_sight.target_position = Vector3(0, 0, -global_position.distance_to(aim_target))
		line_of_sight.force_raycast_update()
		
		if line_of_sight.is_colliding() and line_of_sight.get_collider().is_in_group("Player"):
			is_in_combat = true 
			$StateMachine.on_child_transition($StateMachine.current_state, "state_chase")
	
	# NEW: Calculate the horizontal speed (ignore jumping/falling)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	# Normalize the speed to a 0.0 - 1.0 range (Assuming your max run speed is around 5.0)
	var blend_value = clamp(horizontal_speed / 5.0, 0.0, 1.0)
	
	# Send that value to BOTH BlendSpaces
	if anim_state_machine:
		var anim_tree = find_child("AnimationTree", true, false)
		anim_tree.set("parameters/Movement/blend_position", blend_value)
		anim_tree.set("parameters/Shooting/blend_position", blend_value)

func _on_hurt_box_took_damage(amount: int) -> void:
	current_health -= amount
	
	if target_player == null:
		target_player = get_tree().get_first_node_in_group("Player")
	
	is_in_combat = true 
	
	if current_health <= 0:
		die()
	else:
		if randf() < 0.30 and $StateMachine.current_state.name.to_lower() != "state_cover":
			$StateMachine.on_child_transition($StateMachine.current_state, "state_cover")
		elif $StateMachine.current_state.name.to_lower() == "state_wander":
			$StateMachine.on_child_transition($StateMachine.current_state, "state_chase")

func die() -> void:
	$DetectionZone/CollisionShape3D.set_deferred("disabled", true)
	$CollisionShape3D.set_deferred("disabled", true)
	
	if GameManager.instance:
		GameManager.instance.on_enemy_killed()
		
	$StateMachine.on_child_transition($StateMachine.current_state, "state_death")

func _on_detection_zone_body_entered(body: Node3D) -> void:
	if current_health > 0 and body.name == "Player":
		target_player = body
