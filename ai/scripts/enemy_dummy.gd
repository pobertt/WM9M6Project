class_name enemy_dummy
extends CharacterBody3D

@export var max_health: int = 30
var current_health: int

func _ready() -> void:
	current_health = max_health
	
func _on_hurt_box_took_damage(amount: int) -> void:
	current_health -= amount
	print("Dummy hit! Remaining HP: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Dummy destroyed!")
	# This instantly deletes the node from the game
	queue_free()
