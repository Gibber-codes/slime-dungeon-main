extends Node2D

@onready var slime: Node2D = $Slime
@onready var speed_bar: TextureProgressBar = $statsBars/slimeSpeedBar
@onready var frenzy_bar: TextureProgressBar = $statsBars/slimeFrenzyBar
@onready var momentum_bar: TextureProgressBar = $statsBars/slimeMomentumBar
@onready var auto_seek_bar: TextureProgressBar = $statsBars/slimeAutoSeekBar
@onready var health_bar: TextureProgressBar = $statsBars/slimeHealthBar

func _ready() -> void:
	if slime:
		# Connect health changed signal
		if slime.has_signal("health_changed"):
			slime.health_changed.connect(_on_health_changed)
			# Initialize health bar
			_on_health_changed(slime.current_health, slime.max_health)
		
		# Connect died signal
		if slime.has_signal("died"):
			slime.died.connect(_on_slime_died)

func _on_slime_died() -> void:
	"""Reload the scene when slime dies"""
	get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	if is_instance_valid(slime):
		# Update Speed Bar
		# Base speed is around 100-300. Let's assume max displayable speed is 400 for now.
		var current_speed = slime.velocity.length()
		speed_bar.value = (current_speed / 400.0) * 100.0
		
		# Update Momentum Bar
		if "momentum" in slime and "max_momentum" in slime:
			momentum_bar.value = (slime.momentum / slime.max_momentum) * 100.0
		
		# Update Auto Seek Bar
		if "current_seek_timer" in slime and "auto_seek_timer" in slime:
			auto_seek_bar.value = (slime.current_seek_timer / slime.auto_seek_timer) * 100.0
		
		# Frenzy Bar (Not implemented yet)
		frenzy_bar.value = 0.0

func _on_health_changed(current: float, max_health: float) -> void:
	if max_health > 0:
		health_bar.value = (current / max_health) * 100.0
	else:
		health_bar.value = 0.0
