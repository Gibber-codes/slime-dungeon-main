extends CanvasLayer

## UI Bar References
@onready var health_bar: ProgressBar = $VBoxContainer/HealthContainer/SlimeHealth
@onready var speed_bar: ProgressBar = $VBoxContainer/SpeedContainer/SpeedBar
@onready var momentum_bar: ProgressBar = $VBoxContainer/MomentumContainer/MomentumBar

## UI Label References (for numeric values)
@onready var health_value: Label = $VBoxContainer/HealthContainer/HealthValue
@onready var speed_value: Label = $VBoxContainer/SpeedContainer/SpeedValue
@onready var momentum_value: Label = $VBoxContainer/MomentumContainer/MomentumValue

## Slime reference
var slime: CharacterBody2D = null

func _ready() -> void:
	# Get reference to the Slime
	slime = get_tree().get_first_node_in_group("slime")

	if slime:
		# Connect to health changes
		slime.health_changed.connect(_on_slime_health_changed)

		# Initialize speed bar (max speed is constant)
		speed_bar.max_value = slime.SPEED
		speed_bar.value = 0

		# Initialize momentum bar (shows bonus damage from speed)
		# Max momentum damage = SPEED * momentum_damage_multiplier
		momentum_bar.max_value = slime.SPEED * slime.momentum_damage_multiplier
		momentum_bar.value = 0

func _process(_delta: float) -> void:
	# Update speed and momentum bars every frame
	if slime:
		# Speed bar shows current velocity magnitude
		var current_speed: float = slime.velocity.length()
		speed_bar.value = current_speed
		speed_value.text = "%d/%d" % [current_speed, slime.SPEED]

		# Momentum bar shows the bonus damage from current speed
		var momentum_damage: float = current_speed * slime.momentum_damage_multiplier
		momentum_bar.value = momentum_damage
		var max_momentum: float = slime.SPEED * slime.momentum_damage_multiplier
		momentum_value.text = "%.1f/%.1f" % [momentum_damage, max_momentum]

func _on_slime_health_changed(current: float, max_health: float) -> void:
	"""Update health bar when Slime takes damage or heals"""
	health_bar.max_value = max_health
	health_bar.value = current
	health_value.text = "%.0f/%.0f" % [current, max_health]
