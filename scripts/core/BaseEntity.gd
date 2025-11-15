extends CharacterBody2D
class_name BaseEntity

# Abstract base class for all game entities (Slime, Defender, etc.)
# This script is not attached to any scene - it's inherited by entity scripts

## Signals
signal health_changed(current: float, max_health: float)
signal died()

## Exported Variables
@export var max_health: float = 100.0
@export var physical_damage: float = 10.0
@export var physical_defense: float = 2.0
@export var health_regen: float = 0.0  # HP restored per second

## Internal Variables
var current_health: float = 100.0

func _ready() -> void:
	# Initialize health to max
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	# Handle health regeneration
	if health_regen > 0.0 and current_health < max_health:
		_process_regen(delta)

func _process_regen(delta: float) -> void:
	"""Process health regeneration per frame"""
	var regen_amount: float = health_regen * delta
	heal(regen_amount)

func take_damage(amount: float) -> void:
	"""Apply damage with defense calculation"""
	# Calculate damage after defense
	var actual_damage: float = max(0.0, amount - physical_defense)

	# Apply damage
	current_health = max(0.0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)

	# Check for death
	if current_health <= 0.0:
		die()

func heal(amount: float) -> void:
	"""Restore health, clamped to max_health"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die() -> void:
	"""Handle entity death - can be overridden by child classes"""
	died.emit()
	# Child classes should override this for custom death behavior
	# (e.g., Defender emits defeated signal, Slime triggers game over)
