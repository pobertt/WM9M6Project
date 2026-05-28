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

func _ready() -> void:
	current_mag_ammo = max_mag_ammo
	current_reserve_ammo = max_reserve_ammo
	update_ammo_ui()

# The manager will call this, but the specific gun decides what actually happens
func fire() -> void:
	if is_reloading:
		return
	if not can_shoot:
		return
	
	if current_mag_ammo <= 0:
		print("CLICK! Out of ammo. Press R to reload!")
		return
		
	can_shoot = false
	_weapon_behavior() # Run the specific gun's logic
	
	# Cooldown handling
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
	
	current_mag_ammo -= 1
	update_ammo_ui()

func reload() -> void:
	# Abort if: already reloading, mag is already full, or you have no reserve bullets left
	if is_reloading or current_mag_ammo == max_mag_ammo or current_reserve_ammo <= 0:
		return
		
	is_reloading = true
	print("Reloading USP-S... (Brain is sleeping, off event tick!)")
	
	# Wait 1.8 seconds for the animation/swap to finish completely cleanly
	await get_tree().create_timer(1.8).timeout
	
	# Calculate exactly how many bullets we need to top off the magazine
	var ammo_needed = max_mag_ammo - current_mag_ammo
	
	# Make sure we don't try to take more bullets than we actually possess
	var ammo_to_transfer = min(ammo_needed, current_reserve_ammo)
	
	# Shift the bullets over
	current_mag_ammo += ammo_to_transfer
	current_reserve_ammo -= ammo_to_transfer
	
	is_reloading = false
	update_ammo_ui()

func update_ammo_ui() -> void:
	# Safely reach out to the root Player, find the HUD, and grab the label
	if owner and owner.has_node("HUD/AmmoLabel"):
		var label = owner.get_node("HUD/AmmoLabel") as Label
		label.text = str(current_mag_ammo) + " / " + str(current_reserve_ammo)

# This is a placeholder that specific weapons will overwrite
func _weapon_behavior() -> void:
	pass
