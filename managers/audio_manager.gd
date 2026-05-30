extends Node

# --- ADDED max_dist (default 100.0 for gunshots) to the end! ---
func play_sound_3d(stream: AudioStream, position: Vector3, volume_db: float = 0.0, pitch_scale: float = 1.0, max_dist: float = 100.0) -> void:
	if stream == null: return
	
	# We use a 2D player so Godot can't accidentally mute it!
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05) 
	
	var target_player = get_tree().get_first_node_in_group("Player")
	if target_player:
		var camera = target_player.get_node_or_null("Head/Camera3D")
		if camera:
			# 1. Calculate our own exact distance
			var distance = position.distance_to(camera.global_position)
			
			# 2. Fade the volume out dynamically based on the max_dist! 
			# At 0m it plays at normal volume. At max_dist, it drops by 40 decibels (silent).
			var distance_fade = clamp(distance / max_dist, 0.0, 1.0) * 40.0 
			audio_player.volume_db = volume_db - distance_fade
			
			# If the sound is further than max_dist, don't even bother playing it
			if distance > max_dist:
				audio_player.queue_free()
				return
		else:
			audio_player.volume_db = volume_db
	else:
		audio_player.volume_db = volume_db
		
	# Add it anywhere, it doesn't matter because it's 2D!
	add_child(audio_player)
	audio_player.play()
	
	audio_player.finished.connect(audio_player.queue_free)

func play_sound_2d(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null: return
	
	var player = AudioStreamPlayer.new() # 2D, plays straight to the headphones
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale + randf_range(-0.05, 0.05) 
	
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)
