extends CanvasLayer

# UI controller for displaying slime stats in real-time
# Manages health bar, speed bar, and momentum bar updates

## Constants
const SPEED_MAX: float = 300.0  # Maximum speed value for the speed bar

## Private Variables
var _slime: CharacterBody2D = null
var _max_momentum_damage: float = 24.0  # Will be calculated based on slime's stats

## OnReady Variables
@onready var health_bar: ProgressBar = $SlimeHealth
@onready var speed_bar: ProgressBar = $SpeedBar
@onready var momentum_bar: ProgressBar = $momentiumBar

func _ready() -> void:
	# Find the slime in the scene tree
	_slime = get_tree().get_first_node_in_group("slime")
	
	if not _slime:
		push_error("SlimeUI: Could not find slime in scene tree!")
		return
	
	# Connect to slime's health_changed signal
	if _slime.has_signal("health_changed"):
		_slime.health_changed.connect(_on_slime_health_changed)
	else:
		push_warning("SlimeUI: Slime does not have health_changed signal")
	
	# Initialize progress bars with appropriate max values
	_initialize_progress_bars()

func _process(_delta: float) -> void:
	if not _slime:
		return
	
	# Update speed bar with current velocity magnitude
	_update_speed_bar()
	
	# Update momentum bar with momentum damage value
	_update_momentum_bar()

func _initialize_progress_bars() -> void:
	"""Set up max values and initial states for all progress bars"""
	if not _slime:
		return
	
	# Health bar: Use slime's max_health
	health_bar.max_value = _slime.max_health
	health_bar.value = _slime.current_health
	health_bar.min_value = 0.0
	
	# Speed bar: Use SPEED constant (300.0)
	speed_bar.max_value = SPEED_MAX
	speed_bar.min_value = 0.0
	speed_bar.value = 0.0
	
	# Momentum bar: Calculate max momentum damage
	# Max momentum damage = momentum_damage_multiplier * max_speed
	_max_momentum_damage = _slime.momentum_damage_multiplier * SPEED_MAX

	momentum_bar.max_value = _max_momentum_damage
	momentum_bar.min_value = 0.0
	momentum_bar.value = 0.0

func _update_speed_bar() -> void:
	"""Update speed bar to show current velocity magnitude"""
	var current_speed: float = _slime.velocity.length()
	speed_bar.value = current_speed

func _update_momentum_bar() -> void:
	"""Update momentum bar to show current momentum-based damage potential"""
	var current_speed: float = _slime.velocity.length()
	var momentum_damage: float = _slime.momentum_damage_multiplier * current_speed
	momentum_bar.value = momentum_damage

func _on_slime_health_changed(current: float, max_health: float) -> void:
	"""Update health bar when slime's health changes"""
	health_bar.max_value = max_health
	health_bar.value = current
