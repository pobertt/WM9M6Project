class_name Hurtbox
extends Area3D

signal took_damage(amount: int)

# Your USP-S RayCast looks specifically for this function
func take_damage(amount: int) -> void:
	took_damage.emit(amount)
