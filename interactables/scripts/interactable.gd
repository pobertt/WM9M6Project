class_name Interactable
extends StaticBody3D

@export var prompt_message: String = "Interact"

# This is a "Virtual Function". The parent doesn't do anything,
# it just guarantees that all child scripts will have this exact method.
func interact(interactor: Node3D) -> void:
	pass
