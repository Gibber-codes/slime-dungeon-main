extends BaseEntity
class_name Pot

# Obstacle entity - static obstacles in rooms
# Supports breakable obstacles with health, damage, and destruction mechanics

## Signals
signal destroyed()

## Exported Variables
@export var bounciness: float = 0.9  # How much velocity is retained when slime bounces off this obstacle

func _ready() -> void:
	# Set pot-specific stats before calling parent
	max_health = 30.0
	physical_defense = 0.0

	# Call parent _ready to initialize health system
	super._ready()

	# Add to seekable group for Slime auto-seek targeting
	add_to_group("seekable")

	# Connect to died signal to handle destruction
	died.connect(_on_destroyed)

func _on_destroyed() -> void:
	"""Handle pot destruction"""
	destroyed.emit()
	queue_free()

