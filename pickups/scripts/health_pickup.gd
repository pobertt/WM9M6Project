extends Pickup

func _apply_effect(player: Node3D) -> bool:
	if player.has_method("heal") and player.current_health < player.max_health:
		player.heal(amount)
		return true
		
	return false
