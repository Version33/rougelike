extends CharacterBody2D

@export var speed = 300.0  # Player movement speed
@export var roll_speed = 600.0 # Dodge roll speed
@export var roll_duration = 0.2 # Dodge roll duration
@export var health = 100
@export var bullet_scene : PackedScene # Assign your bullet scene in the inspector

@onready var weapon_pivot = $WeaponPivot
@onready var muzzle_position = $WeaponPivot/MuzzlePosition
@onready var sprite = $Sprite2D # Or $AnimatedSprite2D

var direction = Vector2.ZERO  # Current movement direction
var is_rolling = false
var roll_timer = 0.0
var can_shoot = true # Example: Can add cooldowns later

func _ready():
	pass # Initialization code if needed

func _physics_process(delta):
	if is_rolling:
		handle_roll(delta)
		return # Skip normal movement and actions during roll

	handle_input()
	move_player(delta)
	handle_aiming()
	handle_shooting()

func handle_input():
	# Get input vector for movement (WASD or Arrow Keys)
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = direction.normalized() # Normalize to keep speed consistent in diagonals

	if Input.is_action_just_pressed("roll") and not is_rolling:
		start_roll()

func move_player(delta):
	velocity = direction * speed
	move_and_slide() # Use move_and_slide for CharacterBody2D collision

func handle_aiming():
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	# Make the weapon pivot look at the mouse
	weapon_pivot.look_at(mouse_pos)

	# Flip sprite if aiming to the left (optional, depends on your sprite)
	if weapon_pivot.rotation > deg_to_rad(90) or weapon_pivot.rotation < deg_to_rad(-90):
		sprite.flip_h = true # Flip horizontally
	else:
		sprite.flip_h = false

func handle_shooting():
	if Input.is_action_pressed("shoot") and can_shoot:
		shoot()
		can_shoot = false # Example cooldown - reset later or use a timer
		await get_tree().create_timer(0.2).timeout # Example cooldown timer
		can_shoot = true


func shoot():
	if bullet_scene:
		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.global_position = muzzle_position.global_position
		bullet_instance.rotation = weapon_pivot.global_rotation # Bullet direction
		get_parent().add_child(bullet_instance) # Add bullet to the scene (adjust parent if needed)
		# Optionally play shooting sound, muzzle flash animation, etc.


func start_roll():
	is_rolling = true
	roll_timer = roll_duration
	# Optionally play roll animation
	# Set velocity for roll (in the current movement direction or a fixed direction)
	velocity = direction * roll_speed # Roll in movement direction, or:
	# velocity = Vector2.RIGHT * roll_speed # Example: Roll always to the right (adjust as needed)
	if direction == Vector2.ZERO: # If not moving, roll forward (or a default direction)
		velocity = Vector2.RIGHT * roll_speed # Or Vector2.UP, etc.


func handle_roll(delta):
	roll_timer -= delta
	move_and_slide() # Move during roll
	if roll_timer <= 0:
		is_rolling = false
		velocity = Vector2.ZERO # Stop roll velocity
		# Optionally reset animation to idle/run


func take_damage(damage_amount):
	health -= damage_amount
	print("Player took damage! Health:", health)
	if health <= 0:
		die()

func die():
	print("Player died!")
	queue_free() # Destroy the player node (or handle respawn/game over)
	# Optionally play death animation, trigger game over logic, etc.