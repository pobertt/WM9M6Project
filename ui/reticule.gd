extends Control

@export var dot_radius: float = 1.0
@export var dot_color: Color = Color.WHITE

@export var line_length: float = 5.0
@export var line_width: float = 2.0
@export var base_spread: float = 8.0     
@export var movement_spread: float = 25.0 
@export var shoot_spread: float = 20.0   

var current_spread: float = base_spread
var target_spread: float = base_spread

# We remove @onready so it doesn't crash on boot
var player: CharacterBody3D
var weapon_manager: Node3D 

func _process(delta: float) -> void:
	# THE GUARD: Safely hunt for the player if we don't have them yet
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player != null:
			# Once the player is finally found, grab the weapon manager!
			# (Adjust "Head/Camera3D/WeaponManager" if your node names are different)
			weapon_manager = player.get_node("Head/Camera3D/WeaponManager")
		return # Skip drawing the crosshair until everything is loaded
		
	# Double check we actually found the weapon manager before doing math
	if weapon_manager == null:
		return

	# 1. Figure out what the target spread should be
	target_spread = base_spread
	
	# If the player is moving, increase the spread
	if player.velocity.length() > 1.0:
		target_spread = movement_spread
		
	# If the weapon is firing, override with maximum spread
	if weapon_manager.current_weapon and weapon_manager.current_weapon.anim_player.is_playing() and weapon_manager.current_weapon.anim_player.current_animation == "fire":
		target_spread = shoot_spread

	# 2. Smoothly animate the current spread toward the target spread
	current_spread = lerp(current_spread, target_spread, delta * 15.0)
	
	# 3. Tell Godot to redraw the lines this frame
	queue_redraw()

# ... (Keep your _draw() function exactly the same!) ...

func _draw() -> void:
	# Draw the center dot
	draw_circle(Vector2.ZERO, dot_radius, dot_color)
	
	# Draw the 4 lines (Right, Left, Bottom, Top)
	draw_line(Vector2(current_spread, 0), Vector2(current_spread + line_length, 0), dot_color, line_width)
	draw_line(Vector2(-current_spread, 0), Vector2(-(current_spread + line_length), 0), dot_color, line_width)
	draw_line(Vector2(0, current_spread), Vector2(0, current_spread + line_length), dot_color, line_width)
	draw_line(Vector2(0, -current_spread), Vector2(0, -(current_spread + line_length)), dot_color, line_width)
