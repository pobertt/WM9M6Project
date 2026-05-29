extends Node3D

func trigger_hit() -> void:
	var node = self
	while node != null:
		if node.has_method("deal_melee_damage"):
			node.deal_melee_damage()
			break
		node = node.get_parent()

func trigger_end() -> void:
	var node = self
	while node != null:
		if node.has_method("end_melee_swing"):
			node.end_melee_swing()
			break
		node = node.get_parent()
