extends Node3D

@export_group("Audio")
@export var enemy_footsteps: Array[AudioStream]

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

func play_footstep() -> void:
	if "enemy_footsteps" in self and not enemy_footsteps.is_empty():
		# Parameters are now: (Stream, Position, Volume, Pitch, Max_Distance)
		# We set Max_Distance to 15.0 meters so it fades out very quickly!
		AudioManager.play_sound_3d(enemy_footsteps.pick_random(), global_position, -30.0, 1.0, 15.0)
