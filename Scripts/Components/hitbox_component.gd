class_name HitboxComponent extends Area2D

@onready var hitbox_shape: CollisionShape2D = $HitboxShape

# Export properties to configure collision layers and masks in the Inspector
@export var collision_layer_value: int = 1:
	set(value):
		collision_layer_value = value
		set_collision_layer_value(collision_layer_value, true)

@export var collision_mask_value: int = 1:
	set(value):
		collision_mask_value = value
		set_collision_mask_value(collision_mask_value, true)


func _ready() -> void:
	pass # Initialization if needed


func set_enabled(enabled: bool) -> void:
	monitoring = enabled # Area2D property to enable/disable monitoring for collisions
	if enabled:
		set_process_mode(PROCESS_MODE_INHERIT)
	else:
		set_process_mode(PROCESS_MODE_DISABLED)


func get_shape() -> CollisionShape2D:
	return hitbox_shape