extends BaseEntity

## Defender-specific signals
signal defeated()
signal attacked_player(damage: float)

## Defender-specific exported variables
@export var attack_range: float = 64.0
@export var attack_cooldown: float = 1.0
@export var defender_type: String = "basic"
@export var bounciness: float = 0.6  # How much velocity is retained when slime bounces off this defender

## Internal variables
var slime_in_range: Node2D = null
var attack_timer: Timer = null
var attack_range_area: Area2D = null
var health_bar: ProgressBar = null

func _ready() -> void:
	# Call parent _ready to initialize health system
	super._ready()

	# Set default stats for basic defender
	max_health = 50.0
	current_health = max_health
	physical_damage = 5.0
	physical_defense = 1.0

	# Get node references
	attack_range_area = get_node("AttackRange")
	health_bar = get_node("HealthBar")

	# Connect attack range signals
	attack_range_area.body_entered.connect(_on_attack_range_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_body_exited)

	# Create and configure attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	attack_timer.timeout.connect(_attack_player)
	add_child(attack_timer)

	# Connect health changed signal to update health bar
	health_changed.connect(_on_health_changed)

	# Initialize health bar
	_update_health_bar()

func _on_attack_range_body_entered(body: Node2D) -> void:
	"""Detect when Slime enters attack range"""
	if body.is_in_group("slime"):
		slime_in_range = body
		# Start attacking
		attack_timer.start()
		# Attack immediately on entry
		_attack_player()

func _on_attack_range_body_exited(body: Node2D) -> void:
	"""Detect when Slime leaves attack range"""
	if body.is_in_group("slime") and body == slime_in_range:
		slime_in_range = null
		# Stop attacking
		attack_timer.stop()

func _attack_player() -> void:
	"""Deal damage to Slime if in range"""
	if slime_in_range and slime_in_range.has_method("take_damage"):
		slime_in_range.take_damage(physical_damage)
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
