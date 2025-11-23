extends BaseEntity

## Defender-specific signals
signal defeated()
signal attacked_player(damage: float)

## Defender-specific exported variables
@export var defender_type: String = "basic"

## Internal variables
var health_bar: TextureProgressBar = null

func _ready() -> void:
	# Call parent _ready to initialize health system and attack logic
	super._ready()

	# Set default stats for basic defender
	max_health = 50.0
	current_health = max_health
	physical_damage = 5.0
	physical_defense = 1.0

	# Add to seekable group for Slime auto-seek targeting
	add_to_group("seekable")

	# Get node references
	health_bar = get_node("HealthBar")

	# Connect health changed signal to update health bar
	health_changed.connect(_on_health_changed)

	# Initialize health bar
	_update_health_bar()

# Override _attack_target to emit specific signal
func _attack_target() -> void:
	super._attack_target()
	attacked_player.emit(physical_damage)

func _on_health_changed(_current: float, _max_hp: float) -> void:
	"""Update health bar when health changes"""
	_update_health_bar()

func _update_health_bar() -> void:
	"""Update the health bar visual"""
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func die() -> void:
	"""Override death behavior - emit defeated signal and remove from scene"""
	defeated.emit()
	# Call parent to emit died signal
	super.die()
	# Remove from scene after a short delay to allow signals to process
	queue_free()
