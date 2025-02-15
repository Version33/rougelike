extends Weapon
# Shotgun weapon - extends base weapon, overrides shoot() for spread shot.

@export var num_pellets: int = 8 # Number of pellets per shot
@export var spread_angle: float = 30.0 # Spread angle in degrees

func _do_shoot() -> void:
	var angle_step = spread_angle / (num_pellets -1)
	var start_angle = -spread_angle/2

	for i in num_pellets:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_position = muzzle_position.global_position

		var current_angle = start_angle + i * angle_step

		var spread_direction = transform.x.rotated(deg_to_rad(current_angle))
		bullet_instance.set_direction(spread_direction)
		bullet_instance.rotation = rotation + deg_to_rad(current_angle)
		bullet_instance.speed = bullet_speed
		bullet_instance.damage = bullet_damage
		add_child(bullet_instance)