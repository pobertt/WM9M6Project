class_name InteractableButton
extends Interactable

# Anything else in the level can listen for this signal!
signal button_pressed 

@export var is_one_shot: bool = false
var is_on: bool = false # Renamed this to make the toggle logic easier to read!

@onready var button_off: MeshInstance3D = $ButtonOff
@onready var button_on: MeshInstance3D = $ButtonOn

func _ready() -> void:
	button_on.hide()
	button_off.show()

func interact(interactor: Node3D) -> void:
	# 1. If it's a one-time use button and it's already on, completely ignore the interaction
	if is_one_shot and is_on:
		return 
		
	# 2. Flip the state! (If it was false, it becomes true. If true, it becomes false)
	is_on = not is_on
	
	# 3. Swap the visual meshes based on the new state
	if is_on:
		button_off.hide()
		button_on.show()
	else:
		button_off.show()
		button_on.hide()
	
	# Emit the signal so doors or spawners know to activate
	button_pressed.emit()
	print("Button toggled to ", is_on, " by: ", interactor.name)
	
	# Optional: Play your button 'click' sound right here!
	# AudioManager.play_sound_3d(click_sound, global_position)
