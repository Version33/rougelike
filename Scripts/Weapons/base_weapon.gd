class_name Weapon extends Node2D
## Base class for all weapons in the game.
## Provides common properties and functions for shooting and weapon behavior.

# Placeholder stats, tune in inspector
@export_category("Weapon Info")
@export var weapon_name: String = "Base Weapon"
@export var weapon_description: String = "A base weapon class."
@export var bullet_speed: float = 500.0
@export var bullet_damage: int = 5 # not implemented
@export var fire_rate: float = 0.3 # Cooldown between shots in seconds
@export var automatic: bool = false 
@export var magazine_size: float = 10 # not implemented
@export var reload_time: float = 2 # not implemented

@onready var muzzle_position: Marker2D = $MuzzlePosition
@onready var hitbox: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

@export_category("Bullet Info")
@export var bullet_scene: PackedScene

var is_equipped: bool = false
var is_held: bool = false

var cooldown: float = 0.0 # Cooldown timer
var can_shoot: bool = true # If weapon can fire (used for semi-auto logic)
var is_trigger_pulled: bool = false
var is_shooting: bool = false

var current_ammo: float = magazine_size # not implemented

func _ready() -> void:
	## Called when the weapon scene is ready.
	if not muzzle_position:
		printerr("Error: MuzzlePosition node not found in weapon scene: ", weapon_name)

func _physics_process(delta: float) -> void:
	if is_trigger_pulled and can_shoot:
		_attempt_shoot()
	elif !is_trigger_pulled: # Must wait for the cooldown before trigger pull can shoot again
		is_shooting = false
		if cooldown == 0.0:
			can_shoot = true

	cooldown = clamp(cooldown - delta, 0, fire_rate)
	is_trigger_pulled = false # unpull the trigger, the player can still pull it again next frame, prevents the gun from shooting without something *actively* pulling the trigger*

func set_is_equipped(state: bool) -> void:
	is_equipped = state
	sprite.visible = is_equipped || !is_held

func set_is_held(state: bool) -> void:
	is_held = state
	hitbox.monitorable = !is_held

func _attempt_shoot() -> void:
	## Base shoot function - can be overridden by child weapon scripts for custom behavior.
	if cooldown == 0.0 and can_shoot and bullet_scene and muzzle_position:
		_do_shoot()
		cooldown = fire_rate
	if !automatic:
		can_shoot = false
		is_shooting = false

func _do_shoot() -> void:
	## Spawns a bullet instance and sets its properties.
	is_shooting = true
	var bullet_instance = bullet_scene.instantiate()
	add_child(bullet_instance)
	bullet_instance.global_position = muzzle_position.global_position # Apply muzzle offset
	bullet_instance.set_direction(transform.x)
	bullet_instance.rotation = rotation
	bullet_instance.speed = bullet_speed
	bullet_instance.damage = bullet_damage