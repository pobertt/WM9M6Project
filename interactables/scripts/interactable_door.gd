class_name RotatingDoor
extends Interactable

@export_group("Door Settings")
@export var requires_button: bool = false 
@export var button_to_listen_to: InteractableButton
@export var open_angle: float = 90.0
@export var animation_duration: float = 1.2
@export var is_toggleable: bool = true

@export_group("Level Transition")
@export var is_level_transition: bool = false
@export_file("*.tscn") var next_level_path: String = ""
@export var is_level_exit: bool = false

var is_open: bool = false
var is_moving: bool = false

var closed_quat: Quaternion
var open_quat: Quaternion

func _ready() -> void:
	closed_quat = quaternion
	
	open_quat = closed_quat * Quaternion(Vector3.UP, deg_to_rad(open_angle))

	if requires_button and button_to_listen_to != null:
		button_to_listen_to.button_pressed.connect(toggle_door)
	elif requires_button and button_to_listen_to == null:
		print("Door ", name, "none assigned!")

func interact(interactor: Node3D) -> void:
	if is_level_exit:
		get_tree().change_scene_to_file("res://ui/win_screen.tscn")
		return 
		
	if requires_button and not is_open:
		print("The door is locked. Find a button!")
		return
		
	if is_level_transition:
		if next_level_path != "":
			get_tree().change_scene_to_file(next_level_path)
		else:
			print("No next level path assigned to this door")
		return
		
	toggle_door()

func toggle_door() -> void:
	if is_moving:
		return
		
	if is_open and not is_toggleable:
		return

	is_moving = true
	is_open = not is_open
	
	var target_quat = open_quat if is_open else closed_quat
	
	var tween = create_tween()
	
	tween.tween_property(self, "quaternion", target_quat, animation_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	tween.finished.connect(func(): is_moving = false)
