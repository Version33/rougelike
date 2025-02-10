class_name HealthComponent extends Node

signal health_changed(current_health: int, max_health: int, change_amount: int) # Modified signal to include change_amount
signal health_zero # Signal emitted when health reaches zero

@export var max_health: int = 100
@export var current_health: int = 100:
	set(value):
		var previous_health = current_health # Store previous health value
		current_health = value
		current_health = clamp(current_health, 0, max_health)
		var actual_change = current_health - previous_health # Calculate the actual change
		health_changed.emit(current_health, max_health, actual_change) # Emit signal with change_amount
		if current_health <= 0:
			health_zero.emit()


func _ready() -> void:
	current_health = max_health


func take_damage(damage_amount: int) -> void:
	if current_health > 0:
		var previous_health = current_health # Store previous health before damage
		current_health -= damage_amount
		var actual_damage = previous_health - current_health # Damage is positive change in negative direction
		health_changed.emit(current_health, max_health, -actual_damage) # Emit signal with negative damage amount (health decrease)
		print(owner.name, " took ", damage_amount, " damage! Health: ", current_health, "/", max_health)


func heal(heal_amount: int) -> void:
	var previous_health = current_health # Store previous health before heal
	current_health += heal_amount
	var actual_heal = current_health - previous_health # Heal is positive change
	health_changed.emit(current_health, max_health, actual_heal) # Emit signal with positive heal amount (health increase)
	print(owner.name, " healed for ", heal_amount, " health! Health: ", current_health, "/", max_health)


func is_alive() -> bool:
	return current_health > 0


func get_health_ratio() -> float:
	return float(current_health) / float(max_health)