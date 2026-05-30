extends Node

func play_sound_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null: return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05) 
	
	# Add it to the tree so it exists
	add_child(player)
	
	# Standard audio players don't use 3D space, so we completely removed the position logic!
	player.play()
	
	player.finished.connect(player.queue_free)
