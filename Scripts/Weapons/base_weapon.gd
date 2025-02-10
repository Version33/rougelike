class_name Weapon extends Node2D
## Base class for all weapons in the game.
## Provides common properties and functions for shooting and weapon behavior.

# Placeholder stats, tune in inspector
@export_category("Weapon Info")
@export var weapon_name: String = "Base Weapon"
@export var weapon_description: String = "A base weapon class."
@export var bullet_speed: float = 500.0
@export var bullet_damage: int = 5
@export var fire_rate: float = 0.3 # Cooldown between shots in seconds
@export var automatic: bool = false # not implemented

@onready var muzzle_position: Marker2D = $MuzzlePosition

@export_category("Bullet Info")
@export var bullet_scene: PackedScene

var can_shoot: bool = true # Cooldown flag

func _ready() -> void:
	## Called when the weapon scene is ready.
	if not muzzle_position:
		printerr("Error: MuzzlePosition node not found in weapon scene: ", weapon_name)

func shoot(direction: Vector2, parent_node: Node2D) -> void:
	## Base shoot function - can be overridden by child weapon scripts for custom behavior.
	if can_shoot and bullet_scene and muzzle_position:
		_spawn_bullet(direction, parent_node)
		_start_cooldown()


func _spawn_bullet(direction: Vector2, parent_node: Node2D) -> void:
	## Spawns a bullet instance and sets its properties.
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.global_position = muzzle_position.global_position # Apply muzzle offset
	bullet_instance.set_direction(direction)
	bullet_instance.speed = bullet_speed # Use the values that might be overridden by child classes.
	bullet_instance.damage = bullet_damage # Use the values that might be overridden by child classes.
	parent_node.add_child(bullet_instance) # Add bullet to the provided parent node

func _start_cooldown() -> void:
	## Starts the shooting cooldown timer.
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true