class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Tell the brain to wait until the physical body is fully assembled!
	await owner.ready 
	
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_child_transition)
			child.actor = owner 
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state

# The State Machine is the ONLY thing allowed to run on the event tick!
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(state: State, new_state_name: String) -> void:
	# Security check: Make sure the state asking to change is the active one
	if state != current_state:
		return
		
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
		
	# Clean up the old state, boot up the new one
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state
