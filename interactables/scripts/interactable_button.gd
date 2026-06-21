class_name InteractableButton
extends Interactable

signal button_pressed 

@export var is_one_shot: bool = false
var is_on: bool = false 

@onready var button_off: MeshInstance3D = $ButtonOff
@onready var button_on: MeshInstance3D = $ButtonOn

func _ready() -> void:
	button_on.hide()
	button_off.show()

func interact(interactor: Node3D) -> void:
	if is_one_shot and is_on:
		return 
		
	is_on = not is_on
	
	if is_on:
		button_off.hide()
		button_on.show()
	else:
		button_off.show()
		button_on.hide()
	
	button_pressed.emit()
	print("Button toggled to ", is_on, " by: ", interactor.name)
	
	# AudioManager.play_sound_3d(click_sound, global_position)
