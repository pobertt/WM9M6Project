class_name Pickup
extends Area3D

@export var amount: int = 25
@export var rotation_speed: float = 1.5

func _ready() -> void:
	# Automatically connect the signal so we don't have to do it in the editor
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Give it that classic floating/spinning video game feel
	var visuals = get_node_or_null("Visuals")
	if visuals:
		visuals.rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		# Try to apply the effect. If successful, destroy the pickup!
		if _apply_effect(body):
			queue_free()

# This is a "Virtual Function". The base class does nothing, 
# but child scripts will overwrite this with their own logic.
func _apply_effect(_player: Node3D) -> bool:
	return false
