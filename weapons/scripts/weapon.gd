class_name Weapon
extends Node3D

@export var damage: int = 10
@export var fire_rate: float = 0.25
@export var is_full_auto: bool = false
var last_shot_time: int = 0

@export_group("Ammo Settings")
@export var max_mag_ammo: int = 12       # Capacity of one magazine
@export var max_reserve_ammo: int = 36   # Total extra bullets you carry
@export var reload_time: float = 1.8

var current_mag_ammo: int
var current_reserve_ammo: int
var is_reloading: bool = false

# --- GUN JUICE SETTINGS ---
@export_group("Gun Juice")
@export var weapon_kickback: float = 0.1    # Pushes gun backward toward the camera
@export var weapon_pitch: float = 0.15      # Tilts the barrel upward
@export var fov_punch: float = 2.0          # How hard the camera concusses
@export var recovery_speed: float = 15.0    # How fast everything springs back

# --- WEAPON SWAY SETTINGS ---
@export_group("Weapon Sway")
@export var sway_amount: float = 0.002    # How far the gun drags
@export var sway_speed: float = 5.0       # How fast it snaps back to center

var current_recoil_pos: Vector3 = Vector3.ZERO
var current_recoil_rot: Vector3 = Vector3.ZERO

var mouse_delta: Vector2 = Vector2.ZERO

var resting_position: Vector3
var resting_rotation: Vector3
var default_fov: float

# Automatically find the player's camera
@onready var cam: Camera3D = get_viewport().get_camera_3d()

func _ready() -> void:
	current_mag_ammo = max_mag_ammo
	current_reserve_ammo = max_reserve_ammo
	update_ammo_ui()
	
	# Memorize our starting layout for the spring-back engine
	resting_position = position
	resting_rotation = rotation
	if cam:
		default_fov = cam.fov

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Use += instead of = so rapid mouse flicks aren't lost between physics frames!
		mouse_delta += event.relative
		
func _physics_process(delta: float) -> void:
	# 1. Drain the recoil trackers back to zero over time
	current_recoil_pos = current_recoil_pos.lerp(Vector3.ZERO, recovery_speed * delta)
	current_recoil_rot = current_recoil_rot.lerp(Vector3.ZERO, recovery_speed * delta)
	
	# 2. Calculate the mouse sway offset
	var sway_offset = Vector3(
		mouse_delta.x * sway_amount, 
		-mouse_delta.y * sway_amount, 
		0
	)
	
	# Clamp it so snapping your mouse doesn't throw the gun off the screen!
	sway_offset.x = clamp(sway_offset.x, -0.1, 0.1)
	sway_offset.y = clamp(sway_offset.y, -0.1, 0.1)
	
	# 3. THE BULLETPROOF LOCK: Apply everything strictly relative to the resting baseline
	position = resting_position + sway_offset + current_recoil_pos
	rotation = resting_rotation + current_recoil_rot
	
	# 4. RESET MOUSE DELTA AND FOV
	# Smoothly drain the mouse movement back to zero
	mouse_delta = mouse_delta.lerp(Vector2.ZERO, sway_speed * delta)
	
	# Smoothly pull the camera's FOV back to normal
	if cam:
		cam.fov = lerp(cam.fov, default_fov, recovery_speed * delta)

func fire() -> void:
	if is_reloading:
		return
		
	# Calculate fire rate using the system clock!
	var current_time = Time.get_ticks_msec()
	if current_time - last_shot_time < (fire_rate * 1000.0):
		return # The gun is still cooling down, ignore the click!
	
	if current_mag_ammo <= 0:
		print("CLICK! Out of ammo. Press R to reload!")
		return
		
	# Lock the gun's cooldown
	last_shot_time = current_time
	
	current_mag_ammo -= 1
	update_ammo_ui()
	
	_weapon_behavior() 
	
	# THE JUICE AFTERWARD (Added to our independent trackers, NOT the raw position)
	current_recoil_pos.z += weapon_kickback
	current_recoil_rot.x -= weapon_pitch 
	
	if cam:
		cam.fov += fov_punch

func reload() -> void:
	if is_reloading or current_mag_ammo == max_mag_ammo or current_reserve_ammo <= 0:
		return
		
	is_reloading = true
	print("Reloading...")
	
	_weapon_reload_behavior()
	await get_tree().create_timer(reload_time).timeout
	
	# SAFETY CHECK: Did the player swap weapons while we were waiting?
	# If this weapon is hidden, cancel the reload completely!
	if not is_visible_in_tree():
		is_reloading = false
		print("Reload canceled! Weapon was stowed.")
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

# This is a placeholder that specific weapons will overwrite
func _weapon_behavior() -> void:
	pass

# This is a placeholder for visual reloads
func _weapon_reload_behavior() -> void:
	pass
