class_name RotatingDoor
extends Interactable

@export_group("Door Settings")
@export var requires_button: bool = false 
@export var button_to_listen_to: InteractableButton
@export var open_angle: float = 90.0
@export var animation_duration: float = 1.2
@export var is_toggleable: bool = true

var is_open: bool = false
var is_moving: bool = false

# NEW: Variables to store our mathematically perfect rotations
var closed_quat: Quaternion
var open_quat: Quaternion

func _ready() -> void:
	# 1. Save the exact rotation the door was placed at in the level
	closed_quat = quaternion
	
	# 2. Calculate the open rotation precisely 'open_angle' degrees from its starting point
	open_quat = closed_quat * Quaternion(Vector3.UP, deg_to_rad(open_angle))

	if requires_button and button_to_listen_to != null:
		button_to_listen_to.button_pressed.connect(toggle_door)
	elif requires_button and button_to_listen_to == null:
		print("WARNING: Door '", name, "' requires a button but none is assigned!")

func interact(interactor: Node3D) -> void:
	if not requires_button:
		toggle_door()
	else:
		print("The door is locked. Find a button!")

func toggle_door() -> void:
	if is_moving:
		return
		
	if is_open and not is_toggleable:
		return

	is_moving = true
	is_open = not is_open
	
	# Pick the correct 3D rotation state
	var target_quat = open_quat if is_open else closed_quat
	
	var tween = create_tween()
	
	# 3. Tween the quaternion! This guarantees the shortest route and never spins wildly.
	tween.tween_property(self, "quaternion", target_quat, animation_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.finished.connect(func(): is_moving = false)
