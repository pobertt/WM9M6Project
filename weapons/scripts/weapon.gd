class_name Weapon
extends Node3D

@export var damage: int = 10
@export var fire_rate: float = 0.25
var can_shoot: bool = true

@export_group("Ammo Settings")
@export var max_mag_ammo: int = 12       # Capacity of one magazine
@export var max_reserve_ammo: int = 36   # Total extra bullets you carry

var current_mag_ammo: int
var current_reserve_ammo: int
var is_reloading: bool = false

# --- GUN JUICE SETTINGS ---
@export_group("Gun Juice")
@export var weapon_kickback: float = 0.1    # Pushes gun backward toward the camera
@export var weapon_pitch: float = 0.15      # Tilts the barrel upward
@export var fov_punch: float = 2.0          # How hard the camera concusses
@export var recovery_speed: float = 15.0    # How fast everything springs back

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

func _process(delta: float) -> void:
	# Smoothly pull the gun back to its resting coordinates
	position = position.lerp(resting_position, recovery_speed * delta)
	rotation = rotation.lerp(resting_rotation, recovery_speed * delta)
	
	# Smoothly pull the camera's FOV back to normal
	if cam:
		cam.fov = lerp(cam.fov, default_fov, recovery_speed * delta)

# The manager will call this, but the specific gun decides what actually happens
func fire() -> void:
	if is_reloading or not can_shoot:
		return
	
	if current_mag_ammo <= 0:
		print("CLICK! Out of ammo. Press R to reload!")
		return
		
	can_shoot = false
	
	# 1. Spend the bullet instantly so the UI feels snappy
	current_mag_ammo -= 1
	update_ammo_ui()
	
	# 2. SHOOT FIRST: Run the raycast and spawn bullet holes while the gun is perfectly straight!
	_weapon_behavior() 
	
	# 3. THE JUICE AFTERWARD: Now that the bullet has left, apply the recoil.
	# (Note: we use -= for pitch so the barrel kicks UP toward the ceiling, not down)
	position.z += weapon_kickback
	rotation.x -= weapon_pitch 
	
	if cam:
		cam.fov += fov_punch
	
	# 4. Cooldown handling
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func reload() -> void:
	if is_reloading or current_mag_ammo == max_mag_ammo or current_reserve_ammo <= 0:
		return
		
	is_reloading = true
	print("Reloading... (Brain is sleeping, off event tick!)")
	
	await get_tree().create_timer(1.8).timeout
	
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
