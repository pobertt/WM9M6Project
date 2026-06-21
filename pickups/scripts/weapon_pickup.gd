class_name WeaponPickup
extends Pickup

@export_group("Weapon Pickup Settings")
@export var weapon_to_give: String = "SMG"
@export var ammo_in_pickup: int = 30

func _apply_effect(player: Node3D) -> bool:
	var weapon_manager = player.get_node_or_null("Head/Camera3D/WeaponManager")
	
	if weapon_manager == null:
		print("ERROR: Could not find the WeaponManager")
		return false
		
	if weapon_manager.has_method("receive_weapon_pickup"):
		print("SUCCESS: Asking for weapon: ", weapon_to_give)
		return weapon_manager.receive_weapon_pickup(weapon_to_give, ammo_in_pickup)
	else:
		print("ERROR: doesn't have the receive_weapon_pickup function")
		return false
