extends Pickup

# Overwrite the virtual function!
func _apply_effect(player: Node3D) -> bool:
	if player.has_method("heal") and player.current_health < player.max_health:
		player.heal(amount)
		return true # Returning true tells the base class to delete the item
		
	return false # Player is at full health, don't pick it up!
