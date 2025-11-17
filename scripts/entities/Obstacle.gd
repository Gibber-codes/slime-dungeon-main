extends StaticBody2D
class_name Obstacle

# Obstacle entity - static obstacles in rooms
# Supports breakable obstacles with health, damage, and destruction mechanics

## Signals
signal damaged(current_health: float, max_health: float)
signal destroyed()

## Exported Variables
@export var bounciness: float = 0.9  # How much velocity is retained when slime bounces off this obstacle
@export var is_destructible: bool = false
@export var friction: float = 0.1

# Health management (only used if is_destructible is true)
@export var max_health: float = 30.0  # Maximum health points for the obstacle
@export var physical_defense: float = 0.0  # Defense reduces incoming damage
@export var damage_flash_duration: float = 0.1  # How long to flash when damaged
@export var damage_flash_color: Color = Color.RED  # Color to flash when damaged

## Internal Variables
var current_health: float = 30.0
var _original_modulate: Color = Color.WHITE
var _is_flashing: bool = false
var _flash_timer: float = 0.0

func _ready() -> void:
	# Add to seekable group for Slime auto-seek targeting
	add_to_group("seekable")

	# Initialize health if destructible
	if is_destructible:
		current_health = max_health
		_original_modulate = modulate
	else:
		# Non-destructible obstacles don't need health tracking
		current_health = max_health

func _process(delta: float) -> void:
	"""Handle damage flash animation"""
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_is_flashing = false
			modulate = _original_modulate
		else:
			# Lerp between damage color and original color
			var progress: float = _flash_timer / damage_flash_duration
			modulate = _original_modulate.lerp(damage_flash_color, 1.0 - progress)

func take_damage(amount: float) -> void:
	"""Apply damage to the obstacle if it's destructible"""
	if not is_destructible:
		return

	# Calculate actual damage after defense
	var actual_damage: float = max(0.0, amount - physical_defense)

	# Apply damage
	current_health = max(0.0, current_health - actual_damage)

	# Emit damage signal
	damaged.emit(current_health, max_health)

	# Play damage feedback
	_play_damage_feedback()

	# Check if destroyed
	if current_health <= 0.0:
		_destroy()

func _play_damage_feedback() -> void:
	"""Play visual feedback when damaged"""
	# Flash the sprite
	_is_flashing = true
	_flash_timer = damage_flash_duration
	modulate = damage_flash_color

	# TODO: Add sound effect when audio system is implemented
	# AudioManager.play_sound("obstacle_damage")

func _destroy() -> void:
	"""Destroy the obstacle and emit signal"""
	# Emit destroyed signal
	destroyed.emit()

	# Play destruction feedback
	_play_destruction_feedback()

	# Remove from scene
	queue_free()

func _play_destruction_feedback() -> void:
	"""Play visual/audio feedback when destroyed"""
	# TODO: Spawn destruction effect (particle effect, poof, etc.)
	# var effect = DeathPoof.instantiate()
	# get_parent().add_child(effect)
	# effect.global_position = global_position

	# TODO: Play destruction sound when audio system is implemented
	# AudioManager.play_sound("obstacle_destroyed")

