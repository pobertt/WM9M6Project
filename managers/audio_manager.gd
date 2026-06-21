extends Node

func play_sound_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, max_dist: float = 100.0) -> void:
	if stream == null: return
	
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05) 
	
	var target_player = get_tree().get_first_node_in_group("Player")
	if target_player:
		var camera = target_player.get_node_or_null("Head/Camera3D")
		if camera:
			# Calculate distance
			var distance = position.distance_to(camera.global_position)
			
			# Fade the volume out dynamically 
			var distance_fade = clamp(distance / max_dist, 0.0, 1.0) * 40.0 
			audio_player.volume_db = volume_db - distance_fade
			
			if distance > max_dist:
				audio_player.queue_free()
				return
		else:
			audio_player.volume_db = volume_db
	else:
		audio_player.volume_db = volume_db
		
	add_child(audio_player)
	audio_player.play()
	
	audio_player.finished.connect(audio_player.queue_free)

func play_sound_2d(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null: return
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05) 
	
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
