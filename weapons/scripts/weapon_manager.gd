class_name WeaponManager
extends Node3D

var current_weapon: Weapon
var weapon_index: int = 0

func _ready() -> void:
	for child in get_children():
		child.hide()
		
	# Find the first unlocked weapon on startup and equip it
	for i in range(get_child_count()):
		var w = get_child(i) as Weapon
		if w and w.is_unlocked:
			equip_weapon(i)
			break

func _process(_delta: float) -> void:
	if current_weapon and current_weapon.is_full_auto and Input.is_action_pressed("shoot"):
		current_weapon.fire()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and current_weapon and not current_weapon.is_full_auto:
		current_weapon.fire()
			
	if Input.is_action_just_pressed("reload") and current_weapon:
		current_weapon.reload()
		
	# Upgraded weapon swapping
	if event.is_action_pressed("weapon_next"): equip_next(1)
	elif event.is_action_pressed("weapon_prev"): equip_next(-1)
	elif event.is_action_pressed("weapon_1"): try_equip(0)
	elif event.is_action_pressed("weapon_2"): try_equip(1)

func equip_next(direction: int) -> void:
	var count = get_child_count()
	if count == 0: return

	for i in range(1, count + 1):
		var check_idx = wrapi(weapon_index + (direction * i), 0, count)
		var w = get_child(check_idx) as Weapon
		if w and w.is_unlocked:
			equip_weapon(check_idx)
			return

func try_equip(index: int) -> void:
	if index >= 0 and index < get_child_count():
		var w = get_child(index) as Weapon
		if w and w.is_unlocked:
			equip_weapon(index)

func equip_weapon(index: int) -> void:
	weapon_index = index
	
	if current_weapon:
		current_weapon.is_reloading = false
		current_weapon.hide()
		
	current_weapon = get_child(weapon_index) as Weapon
	current_weapon.show()
	current_weapon.update_ammo_ui()

func receive_weapon_pickup(target_weapon_name: String, ammo_amount: int) -> bool:
	print("--- PICKUP ATTEMPT ---")
	print("Looking for: '", target_weapon_name, "'")
	
	for i in range(get_child_count()):
		var w = get_child(i) as Weapon
		if w == null:
			continue
			
		print("Checking slot ", i, " - Found: '", w.weapon_name, "'")
		
		if w.weapon_name == target_weapon_name:
			print("MATCH FOUND!")
			if not w.is_unlocked:
				print("Weapon was locked. Unlocking now!")
				w.is_unlocked = true
				w.add_ammo(ammo_amount)
				equip_weapon(i) 
				return true
			else:
				print("Weapon already unlocked. Checking ammo...")
				if w.current_reserve_ammo < w.max_reserve_ammo:
					print("Player needs ammo. Giving ammo!")
					w.add_ammo(ammo_amount)
					if w == current_weapon:
						w.update_ammo_ui()
					return true
				else:
					print("Ammo is completely full. Rejecting pickup.")
					return false
					
	print("ERROR: Checked all guns, could not find one named: '", target_weapon_name, "'")
	return false

func play_animation(anim_name: String) -> void:
	if current_weapon and current_weapon.has_node("AnimationPlayer"):
		var anim_player = current_weapon.get_node("AnimationPlayer")
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
