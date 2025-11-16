extends CanvasLayer

# UI controller for displaying slime stats in real-time
# Manages health bar, speed bar, and momentum bar updates

## Private Variables
var _slime: CharacterBody2D = null

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

	# Speed bar: Show final speed (base_speed + max_momentum * multiplier)
	var max_final_speed: float = _slime.base_speed + (_slime.max_momentum * _slime.momentum_speed_multiplier)
	speed_bar.max_value = max_final_speed
	speed_bar.min_value = 0.0
	speed_bar.value = _slime.base_speed

	# Momentum bar: Show current momentum value directly
	momentum_bar.max_value = _slime.max_momentum
	momentum_bar.min_value = 0.0
	momentum_bar.value = 0.0

func _update_speed_bar() -> void:
	"""Update speed bar to show final speed (base_speed + momentum * multiplier)"""
	var final_speed: float = _slime.base_speed + (_slime.momentum * _slime.momentum_speed_multiplier)
	speed_bar.value = final_speed

func _update_momentum_bar() -> void:
	"""Update momentum bar to show current momentum value"""
	momentum_bar.value = _slime.momentum

func _on_slime_health_changed(current: float, max_health: float) -> void:
	"""Update health bar when slime's health changes"""
	health_bar.max_value = max_health
	health_bar.value = current
