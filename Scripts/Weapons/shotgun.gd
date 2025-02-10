extends Weapon
## Shotgun weapon - extends base weapon, overrides shoot() for spread shot.

@export var num_pellets: int = 8 # Number of pellets per shot
@export var spread_angle: float = 30.0 # Spread angle in degrees

func shoot(direction: Vector2, parent_node: Node2D) -> void: # Override base shoot() function
	if can_shoot and bullet_scene and muzzle_position:
		_spawn_bullets(direction, parent_node)
		_start_cooldown()


func _spawn_bullets(direction: Vector2, parent_node: Node2D) -> void:
	var angle_step = spread_angle / (num_pellets -1)
	var start_angle = -spread_angle/2

	for i in num_pellets:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_position = muzzle_position.global_position

		var current_angle = start_angle + i * angle_step

		var spread_direction = direction.rotated(deg_to_rad(current_angle))
		bullet_instance.set_direction(spread_direction)

		bullet_instance.speed = bullet_speed
		bullet_instance.damage = bullet_damage
		parent_node.add_child(bullet_instance)

func _start_cooldown() -> void:
	## Starts the shooting cooldown timer.
	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true