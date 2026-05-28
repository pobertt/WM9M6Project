class_name WeaponManager
extends Node3D

var current_weapon: Weapon
var weapon_index: int = 0

func _ready() -> void:
	# Hide all weapons at start, then equip the first one
	for child in get_children():
		child.hide()
	equip_weapon(weapon_index)

func _unhandled_input(event: InputEvent) -> void:
	# Tell the current weapon to fire
	if event.is_action_pressed("shoot") and current_weapon:
		current_weapon.fire()
	# Check for manual reload
	if Input.is_action_just_pressed("reload"):
		# Call reload on whichever weapon script is currently active
		current_weapon.reload()
		
	# Swap weapons with mouse wheel
	if event.is_action_pressed("weapon_next"):
		equip_weapon(weapon_index + 1)
	elif event.is_action_pressed("weapon_prev"):
		equip_weapon(weapon_index - 1)

func equip_weapon(index: int) -> void:
	if get_child_count() == 0: return
	
	# Wrap the index so scrolling loops through inventory
	weapon_index = wrapi(index, 0, get_child_count())
	
	if current_weapon:
		current_weapon.hide()
		
	current_weapon = get_child(weapon_index) as Weapon
	current_weapon.show()
