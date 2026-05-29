class_name GameManager
extends Node

# This allows any script to talk to the GameManager instantly!
static var instance: GameManager

var total_enemies: int = 0
var enemies_killed: int = 0

func _enter_tree() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()

func register_enemy() -> void:
	total_enemies += 1
	update_objective_ui()

func on_enemy_killed() -> void:
	enemies_killed += 1
	update_objective_ui()
	
	if enemies_killed >= total_enemies:
		trigger_victory()

func update_objective_ui() -> void:
	# For now, we will just print to the console. 
	# Later, we can hook this up to a slick text prompt on the player's HUD!
	print("OBJECTIVE: Eliminate all targets (", enemies_killed, " / ", total_enemies, ")")

func trigger_victory() -> void:
	print("ROOM CLEARED!")
	
	# THE FIX: Give the final enemy 2 seconds to fall over before deleting the world!
	await get_tree().create_timer(2.0).timeout
	
	get_tree().reload_current_scene()
