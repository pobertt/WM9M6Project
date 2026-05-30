class_name Pickup
extends Area3D

@export var amount: int = 25
@export var rotation_speed: float = 1.5
@export var pickup_sound: AudioStream

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	var visuals = get_node_or_null("Visuals")
	if visuals:
		visuals.rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if _apply_effect(body):
			if pickup_sound != null:
				print("pickup sound")
				AudioManager.play_sound_3d(pickup_sound, global_position)
				
			queue_free()

func _apply_effect(_player: Node3D) -> bool:
	return false
