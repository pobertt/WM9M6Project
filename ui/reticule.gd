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

var player: CharacterBody3D
var weapon_manager: Node3D 

func _process(delta: float) -> void:
	# Fallback to safely fetch player on load
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		if player != null:
			weapon_manager = player.get_node("Head/Camera3D/WeaponManager")
		return 
		
	if weapon_manager == null:
		return

	target_spread = base_spread
	
	if player.velocity.length() > 1.0:
		target_spread = movement_spread
		
	if weapon_manager.current_weapon and weapon_manager.current_weapon.anim_player.is_playing() and weapon_manager.current_weapon.anim_player.current_animation == "fire":
		target_spread = shoot_spread

	current_spread = lerp(current_spread, target_spread, delta * 15.0)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, dot_radius, dot_color)
	draw_line(Vector2(current_spread, 0), Vector2(current_spread + line_length, 0), dot_color, line_width)
	draw_line(Vector2(-current_spread, 0), Vector2(-(current_spread + line_length), 0), dot_color, line_width)
	draw_line(Vector2(0, current_spread), Vector2(0, current_spread + line_length), dot_color, line_width)
	draw_line(Vector2(0, -current_spread), Vector2(0, -(current_spread + line_length)), dot_color, line_width)
