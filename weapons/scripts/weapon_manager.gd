class_name WeaponManager
extends Node3D

var current_weapon: Weapon
var weapon_index: int = 0

func _ready() -> void:
	for child in get_children():
		child.hide()
	equip_weapon(weapon_index)

func _process(_delta: float) -> void:
	if current_weapon and current_weapon.is_full_auto and Input.is_action_pressed("shoot"):
		current_weapon.fire()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and current_weapon and not current_weapon.is_full_auto:
		current_weapon.fire()
			
	if Input.is_action_just_pressed("reload") and current_weapon:
		current_weapon.reload()
		
	if event.is_action_pressed("weapon_next"): equip_weapon(weapon_index + 1)
	elif event.is_action_pressed("weapon_prev"): equip_weapon(weapon_index - 1)
	elif event.is_action_pressed("weapon_1"): equip_weapon(0)
	elif event.is_action_pressed("weapon_2"): equip_weapon(1)

func equip_weapon(index: int) -> void:
	if get_child_count() == 0: return
	
	weapon_index = wrapi(index, 0, get_child_count())
	
	if current_weapon:
		current_weapon.is_reloading = false
		current_weapon.hide()
		
	current_weapon = get_child(weapon_index) as Weapon
	current_weapon.show()
	current_weapon.update_ammo_ui()
