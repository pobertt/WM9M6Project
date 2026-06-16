class_name AimbotPickup
extends Pickup

@export var duration: float = 10.0 # How many seconds the hack lasts

func _apply_effect(player: Node3D) -> bool:
	if player.has_method("activate_aimbot"):
		player.activate_aimbot(duration)
		return true
	return false
