class_name Weapon
extends Node3D

@export var damage: int = 10
@export var fire_rate: float = 0.25
var can_shoot: bool = true

# The manager will call this, but the specific gun decides what actually happens
func fire() -> void:
	if not can_shoot:
		return
		
	can_shoot = false
	_weapon_behavior() # Run the specific gun's logic
	
	# Cooldown handling
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

# This is a placeholder that specific weapons will overwrite
func _weapon_behavior() -> void:
	pass
