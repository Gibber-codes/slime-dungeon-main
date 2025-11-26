extends BaseEntity
class_name Pillar

# Pillar - static indestructible obstacle in dungeons
# Slime bounces off during autonomous movement

## Exported Variables
@export var bounciness: float = 0.9  # How much velocity is retained when slime bounces off this obstacle

func _ready() -> void:
	# Set pillar-specific stats before calling parent
	max_health = 999.0  # High value for indestructible
	physical_defense = 999.0  # Effectively immune to damage

	# Call parent _ready to initialize health system
	super._ready()

