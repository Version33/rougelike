class_name Bullet extends Area2D

# Overridden by the gun that shoots it
var speed: float = 1.0
var lifetime: float = 1.0
var damage: int = 1

var direction: Vector2 = Vector2.RIGHT # Default direction
var timer: float = 0.0

func _ready() -> void:
	pass # No need to set linear_velocity for Area2D

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free() # Destroy bullet after lifetime

	# Area2D movement - directly update position based on direction and speed
	position += direction * speed * delta


func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized() # Normalize direction for consistent speed


func _on_body_entered(body: Node2D) -> void:
	# Example collision handling - check if it's an enemy
	if body.is_in_group("enemy"):
		# Assuming enemies have a HealthComponent
		if body.has_node("HealthComponent"):
			var health_component = body.get_node("HealthComponent") as HealthComponent
			health_component.take_damage(damage)
			queue_free() # Destroy bullet after hitting enemy
	elif body.is_in_group("wall"): # Example: Destroy bullet on walls
		queue_free() # Destroy bullet on wall
	# You can add more collision handling logic here