class_name Weapon
extends Node3D

@export var damage: int = 10
@export var fire_rate: float = 0.25
@export var is_full_auto: bool = false
var last_shot_time: int = 0

@export_group("Ammo Settings")
@export var max_mag_ammo: int = 12       
@export var max_reserve_ammo: int = 36   
@export var reload_time: float = 1.8

var current_mag_ammo: int
var current_reserve_ammo: int
var is_reloading: bool = false

@export_group("Gun Juice")
@export var weapon_kickback: float = 0.1    
@export var weapon_pitch: float = 0.15      
@export var fov_punch: float = 2.0          
@export var recovery_speed: float = 15.0    
@export var fire_sound: Array[AudioStream] 
@export var reload_sound: AudioStream

@export_group("Weapon Sway")
@export var sway_amount: float = 0.002    
@export var sway_speed: float = 5.0       

var current_recoil_pos: Vector3 = Vector3.ZERO
var current_recoil_rot: Vector3 = Vector3.ZERO
var mouse_delta: Vector2 = Vector2.ZERO

var resting_position: Vector3
var resting_rotation: Vector3
var default_fov: float

@onready var cam: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	current_mag_ammo = max_mag_ammo
	current_reserve_ammo = max_reserve_ammo
	update_ammo_ui()
	
	resting_position = position
	resting_rotation = rotation
	if cam: default_fov = cam.fov

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative
		
func _physics_process(delta: float) -> void:
	current_recoil_pos = current_recoil_pos.lerp(Vector3.ZERO, recovery_speed * delta)
	current_recoil_rot = current_recoil_rot.lerp(Vector3.ZERO, recovery_speed * delta)
	
	var sway_offset = Vector3(
		clamp(mouse_delta.x * sway_amount, -0.1, 0.1), 
		clamp(-mouse_delta.y * sway_amount, -0.1, 0.1), 
		0
	)
	
	position = resting_position + sway_offset + current_recoil_pos
	rotation = resting_rotation + current_recoil_rot
	
	mouse_delta = mouse_delta.lerp(Vector2.ZERO, sway_speed * delta)
	
	if cam:
		cam.fov = lerp(cam.fov, default_fov, recovery_speed * delta)

func fire() -> void:
	if is_reloading or Time.get_ticks_msec() - last_shot_time < (fire_rate * 1000.0):
		return 
		
	if current_mag_ammo <= 0:
		return
		
	last_shot_time = Time.get_ticks_msec()
	current_mag_ammo -= 1
	update_ammo_ui()
	
	_weapon_behavior() 
	
	current_recoil_pos.z += weapon_kickback
	current_recoil_rot.x -= weapon_pitch 
	
	if cam: cam.fov += fov_punch

func reload() -> void:
	if is_reloading or current_mag_ammo == max_mag_ammo or current_reserve_ammo <= 0:
		return
		
	is_reloading = true
	_weapon_reload_behavior()
	await get_tree().create_timer(reload_time).timeout
	
	if not is_visible_in_tree():
		is_reloading = false
		return
	
	var ammo_needed = max_mag_ammo - current_mag_ammo
	var ammo_to_transfer = min(ammo_needed, current_reserve_ammo)
	
	current_mag_ammo += ammo_to_transfer
	current_reserve_ammo -= ammo_to_transfer
	
	is_reloading = false
	update_ammo_ui()

func update_ammo_ui() -> void:
	if owner and owner.has_node("HUD/AmmoLabel"):
		var label = owner.get_node("HUD/AmmoLabel") as Label
		label.text = str(current_mag_ammo) + " / " + str(current_reserve_ammo)

func _weapon_behavior() -> void: pass
func _weapon_reload_behavior() -> void: pass

func add_ammo(amount: int) -> void:
	current_reserve_ammo += amount
	if current_reserve_ammo > max_reserve_ammo:
		current_reserve_ammo = max_reserve_ammo
		
	update_ammo_ui()
