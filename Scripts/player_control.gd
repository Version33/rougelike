extends CharacterBody2D
# ===================== [ EXPORT PROPERTIES - TUNE IN INSPECTOR ] =====================
# ---- Movement ----
@export_category("Movement")
@export var move_speed: float = 300.0

@export_subgroup("Roll")
@export var roll_speed: float = 600.0
@export var roll_duration: float = 0.2
@export var roll_cooldown: float = 0.5 # Add a cooldown!

# ---- Weapon ----
@export_category("Weapon")
@export var starting_weapon: PackedScene
@export var alternate_weapon: PackedScene # Add this!
var current_weapon: Weapon

# ---- Node Paths ----
@export_category("Node Paths")
@export_node_path var weapon_pivot_path: NodePath
@export_node_path var player_sprite_path: NodePath
@export_node_path var health_component_path: NodePath

# ===================== [ ONREADY NODE REFERENCES ] =====================
@onready var weapon_pivot: Node2D = get_node(weapon_pivot_path)
@onready var player_sprite: Sprite2D = get_node(player_sprite_path)
@onready var health_component: HealthComponent = get_node(health_component_path)
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite

# ===================== [ INTERNAL STATE VARIABLES ] =====================
var move_direction: Vector2 = Vector2.ZERO # Current movement input direction
var is_rolling: bool = false
var roll_timer: float = 0.0
var can_shoot: bool = true
var weapons: Array[PackedScene]
var can_roll: bool = true # Cooldown tracker


# ===================== [ GODOT ENGINE FUNCTIONS ] =====================
func _ready() -> void:
	_verify_node_paths()
	if health_component:
		health_component.health_zero.connect(_on_health_zero) # Connect HealthComponent's death signal
		health_component.health_changed.connect(_on_heal_changed) # Connect HealthComponent's change signal
	weapons = [starting_weapon, alternate_weapon]
	if starting_weapon:
		_equip_weapon(starting_weapon)


func _physics_process(delta: float) -> void:
	if is_rolling:
		_handle_roll(delta)
		return # Skip regular actions during roll

	_handle_input()
	_move_player(delta) #Move before checking for roll
	_handle_aiming()
	if Input.is_action_pressed("shoot"): # Now directly in _physics_process
		_attempt_shoot()
	if Input.is_action_just_pressed("swap_weapons"):
		_on_swap_weapon_pressed()

# ===================== [ INPUT HANDLING ] =====================
func _handle_input() -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

	if Input.is_action_just_pressed("roll") and not is_rolling and can_roll and move_direction != Vector2.ZERO:
		_start_roll()


# ===================== [ MOVEMENT FUNCTIONS ] =====================
func _move_player(delta: float) -> void:
	if !is_rolling: # Only apply normal movement if NOT rolling
		velocity = move_direction * move_speed
	move_and_slide()


# ===================== [ AIMING FUNCTIONS ] =====================
func _handle_aiming() -> void:
	if not weapon_pivot or not player_sprite: # Safety checks for nodes
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)

	player_sprite.flip_h = (weapon_pivot.rotation > deg_to_rad(90) or weapon_pivot.rotation < deg_to_rad(-90))


# ===================== [ WEAPON FUNCTIONS ] =====================
func _attempt_shoot() -> void: # New function to encapsulate the shooting attempt.
	if current_weapon:
		var mouse_position: Vector2 = get_global_mouse_position()
		var shoot_direction: Vector2 = (mouse_position - current_weapon.global_position).normalized()
		current_weapon.shoot(shoot_direction, get_parent())

func _equip_weapon(new_weapon: PackedScene) -> void:
	# current_weapon before the setting is the old weapon
	if new_weapon:
		if current_weapon:
			current_weapon.queue_free()
		current_weapon = new_weapon.instantiate()
		weapon_pivot.add_child(current_weapon)
	else:
		printerr("new_weapon is invalid, got: ", new_weapon)


# ===================== [ ROLL (DASH) FUNCTIONS ] =====================
func _start_roll() -> void:
	is_rolling = true
	can_roll = false # Start cooldown
	roll_timer = roll_duration
	velocity = move_direction * roll_speed # Use move_direction!
	#if move_direction == Vector2.ZERO: #Remove this
	#	velocity = Vector2.RIGHT * roll_speed


func _handle_roll(delta: float) -> void:
	roll_timer -= delta
	move_and_slide() #Keep this
	if roll_timer <= 0:
		is_rolling = false
		#velocity = Vector2.ZERO # DONT zero out here
		get_tree().create_timer(roll_cooldown).timeout.connect(_enable_roll)

func _enable_roll() ->void:
	can_roll = true

# ===================== [ HEALTH & DAMAGE FUNCTIONS ] =====================
func take_damage(damage_amount: int) -> void:
	if health_component != null: # Standard null check
		health_component.take_damage(damage_amount)

func _on_heal_changed() -> void:
	pass

func _on_health_zero() -> void:
	_die() # Internal die function called when HealthComponent signals health_zero


func _die() -> void:
	print("Player died!")
	queue_free() # Player-specific death action


# ===================== [ UTILITY & SETUP FUNCTIONS ] =====================
func _verify_node_paths() -> void:
	if not weapon_pivot:
		printerr("WeaponPivot node not found at path:", weapon_pivot_path)
	if not player_sprite:
		printerr("Sprite2D node not found at path:", player_sprite_path)
	if not health_component:
		printerr("HealthComponent node not found: Please add HealthComponent as a child node")

func _on_swap_weapon_pressed():
	if weapons.size() < 2 || weapons[0] == null || weapons[1] == null:
		return
	weapons.reverse()
	_equip_weapon(weapons[0])