extends Weapon

@export var max_spread_angle: float = 50.0  # Maximum spread angle in degrees
@export var spread_increase_rate: float = 2.0 # Degrees per shot
@export var spread_decrease_rate: float = 40.0  # Degrees per second

var current_spread_angle: float = 0.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta) # run parent _physics_process() as well

	if !is_shooting:
		current_spread_angle -= spread_decrease_rate * delta
	
	current_spread_angle = clampf(current_spread_angle,  0.0, max_spread_angle)
	print(current_spread_angle)


func _do_shoot() -> void:
	## Spawns a bullet instance and sets its properties.
	is_shooting = true
	var bullet_instance = bullet_scene.instantiate()
	add_child(bullet_instance)
	bullet_instance.global_position = muzzle_position.global_position # Apply muzzle offset
	var random_angle: float = randf_range(-current_spread_angle / 2.0, current_spread_angle / 2.0)
	bullet_instance.set_direction(transform.x.rotated(deg_to_rad(random_angle)))
	bullet_instance.rotation = rotation + deg_to_rad(random_angle)
	bullet_instance.speed = bullet_speed
	bullet_instance.damage = bullet_damage
	current_spread_angle += spread_increase_rate