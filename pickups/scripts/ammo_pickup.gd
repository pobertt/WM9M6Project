extends Pickup

func _apply_effect(player: Node3D) -> bool:
	# Find the weapon manager to get the currently equipped gun
	var weapon_manager = player.get_node_or_null("Head/Camera3D/WeaponManager")
	
	if weapon_manager and weapon_manager.current_weapon:
		var wep = weapon_manager.current_weapon
		
		if wep.has_method("add_ammo") and wep.current_reserve_ammo < wep.max_reserve_ammo:
			wep.add_ammo(amount)
			return true 
			
	return false # Reserve ammo is full, leave the crate on the ground
