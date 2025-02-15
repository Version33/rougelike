extends CharacterBody2D

# ===== [ DEBUG ] =====
@onready var debug_label: Label = get_node("DebugLabel")

# ===================== [ EXPORT PROPERTIES - TUNE IN INSPECTOR ] =====================
# ---- Movement ----
@export_category("Movement")
@export var move_speed: float = 300.0

@export_subgroup("Roll")
@export var roll_speed: float = 600.0
@export var roll_duration: float = 0.2
@export var roll_cooldown: float = 0.5

# ---- Weapon ----
@export_category("Weapon")
@export var starting_weapon: PackedScene
@export var alternate_weapon: PackedScene
@export var current_weapon: Weapon
@export var max_weapons: int = 2

# ---- Node Paths ----
@export_category("Node Paths")
@export_node_path var weapon_pivot_path: NodePath
@export_node_path var player_sprite_path: NodePath
@export_node_path var health_component_path: NodePath
@export_node_path var interact_box_path: NodePath

# ===================== [ ONREADY NODE REFERENCES ] =====================
@onready var weapon_pivot: Node2D = get_node(weapon_pivot_path)
@onready var player_sprite: Sprite2D = get_node(player_sprite_path)
@onready var health_component: HealthComponent = get_node(health_component_path)
@onready var interact_box: Area2D = get_node(interact_box_path)

# ===================== [ INTERNAL STATE VARIABLES ] =====================
var move_direction: Vector2 = Vector2.ZERO # Current movement input direction
var is_rolling: bool = false
var roll_timer: float = 0.0
var can_shoot: bool = true
var can_roll: bool = true # Cooldown tracker
var targeted_weapon: Weapon = null

# ===================== [ GODOT ENGINE FUNCTIONS ] =====================
func _ready() -> void:
	_verify_node_paths()
	_connect_signals()

func _physics_process(delta: float) -> void:
	if is_rolling:
		_handle_roll(delta)
		return # Skip regular actions during roll

	_handle_input()
	_move_player(delta) #Move before checking for roll
	_handle_aiming()

	_update_debug_label()

# ===================== [ INPUT HANDLING ] =====================
func _handle_input() -> void:
	move_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()

	if Input.is_action_just_pressed("roll") and not is_rolling and can_roll and move_direction != Vector2.ZERO:
		_start_roll()
	if current_weapon:
		current_weapon.is_trigger_pulled = Input.is_action_pressed("shoot")
	if Input.is_action_just_pressed("cycle_weapon"):
		_cycle_weapon()
	if Input.is_action_just_pressed("interact"):
		_attempt_pickup()
	if Input.is_action_just_pressed("drop_weapon"):
		drop_weapon()



# ===================== [ MOVEMENT FUNCTIONS ] =====================
func _move_player(delta: float) -> void:
	if !is_rolling: # Only apply normal movement if NOT rolling
		velocity = move_direction * move_speed
	move_and_slide()


# ===================== [ AIMING FUNCTIONS ] =====================
func _handle_aiming() -> void:
	if not player_sprite or not current_weapon: # Safety checks for nodes
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	current_weapon.look_at(mouse_pos)

	player_sprite.flip_h = (current_weapon.rotation > deg_to_rad(90) or current_weapon.rotation < deg_to_rad(-90))


# ===================== [ WEAPON FUNCTIONS ] =====================
func _equip_weapon(new_weapon: Weapon) -> void:
	if current_weapon == new_weapon: # do nothing if the same weapon
		return

	if new_weapon:
		new_weapon.set_is_equipped(true)
		current_weapon = new_weapon
	else:
		current_weapon = null

func pickup_weapon(new_weapon: Weapon) -> void:
	if weapon_pivot.get_child_count() >= max_weapons:
		drop_weapon()
	if current_weapon:
		current_weapon.set_is_equipped(false) # Hide current weapon

	new_weapon.get_parent().remove_child(new_weapon) # Remove from level
	weapon_pivot.add_child(new_weapon) # Attach to player
	new_weapon.position = Vector2(0,0)
	new_weapon.rotation = 0

	weapon_pivot.move_child(new_weapon, 0) # Move new_weapon to the top
	new_weapon.set_is_held(true) # Weapon is now held by the player
	_equip_weapon(weapon_pivot.get_child(0) if weapon_pivot.get_child_count() > 0 else null)

func drop_weapon() -> void:
	if current_weapon:
		var weapon_to_drop = current_weapon
		weapon_to_drop.is_trigger_pulled = false
		weapon_to_drop.get_parent().remove_child(weapon_to_drop) # remove from pivot
		get_parent().add_child(weapon_to_drop) # add to same parent as the player
		weapon_to_drop.global_position = global_position # at player's position
		#weapon_to_drop.rotation_degrees = weapon_pivot.rotation_degrees # at player's rotation

		weapon_to_drop.set_is_held(false)
		weapon_to_drop.set_is_equipped(false)
		_equip_weapon(weapon_pivot.get_child(0) if weapon_pivot.get_child_count() > 0 else null) # Equip next weapon, or null if none

func _attempt_pickup() -> void:
	if targeted_weapon: # Check if a weapon is targeted
		pickup_weapon(targeted_weapon)
		targeted_weapon = null  # Clear the target after pickup
		var prompt_label = get_node_or_null("PromptLabel")
		if prompt_label:
			prompt_label.hide()

func _cycle_weapon() -> void:
	if weapon_pivot.get_child_count() < 2:
		return # Not enough weapons to cycle

	current_weapon.set_is_equipped(false)
	current_weapon.is_trigger_pulled = false
	weapon_pivot.move_child(current_weapon, -1) # Move top weapon to the end
	_equip_weapon(weapon_pivot.get_child(0)) #equip the new top weapon


# --- InteractBox Callbacks ---
func _on_interact_box_entered(body: Node2D) -> void:
	var weapon = body.get_parent()
	if weapon is Weapon and not weapon.is_equipped:
		targeted_weapon = weapon
		var prompt_label = get_node_or_null("PromptLabel")
		if prompt_label:
			prompt_label.show()

func _on_interact_box_exited(body: Node2D) -> void:
	var weapon = body.get_parent()
	if weapon == targeted_weapon: # Only clear if it's the *current* target
		targeted_weapon = null
		var prompt_label = get_node_or_null("PromptLabel")
		if prompt_label:
			prompt_label.hide()


# ===================== [ ROLL (DASH) FUNCTIONS ] =====================
func _start_roll() -> void:
	is_rolling = true
	can_roll = false # Start cooldown
	roll_timer = roll_duration
	velocity = move_direction * roll_speed


func _handle_roll(delta: float) -> void:
	roll_timer -= delta
	move_and_slide() #Keep this
	if roll_timer <= 0:
		is_rolling = false
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
func _update_debug_label() -> void:
	if current_weapon:
		debug_label.text = "Cooldown: %10.3f\nCan Shoot: %s\nTrigger Pulled: %s\n Is Shooting: %s" % [current_weapon.cooldown, current_weapon.can_shoot, current_weapon.is_trigger_pulled, current_weapon.is_shooting]
	else:
		debug_label.text = "No Weapon"


func _verify_node_paths() -> void:
	if not weapon_pivot:
		printerr("WeaponPivot node not found at path:", weapon_pivot_path)
	if not player_sprite:
		printerr("Sprite2D node not found at path:", player_sprite_path)
	if not health_component:
		printerr("HealthComponent node not found: Please add HealthComponent as a child node")
	if not interact_box:
		printerr("InteractBox node not found at path:", interact_box_path)

func _connect_signals() -> void:
	if health_component:
		health_component.health_zero.connect(_on_health_zero) # Connect HealthComponent's death signal
		health_component.health_changed.connect(_on_heal_changed) # Connect HealthComponent's change signal