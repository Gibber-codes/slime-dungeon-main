extends PanelContainer
class_name StatsMenu

## Slime reference
var slime: CharacterBody2D = null

## Base stat storage (for calculating modifiers)
var base_max_health: float = 0.0
var base_health_regen: float = 0.0
var base_speed: float = 0.0
var base_physical_damage: float = 0.0
var base_physical_defense: float = 0.0
var base_bounciness: float = 0.0
var base_momentum_multiplier: float = 0.0

func _ready() -> void:
	# Find the slime
	await get_tree().process_frame
	slime = get_tree().get_first_node_in_group("slime")
	
	if slime:
		# Store base values (before any modifiers)
		_store_base_values()
		
		# Connect to health changes
		if slime.has_signal("health_changed"):
			slime.health_changed.connect(_on_health_changed)
		
		# Initial update
		_update_all_stats()

func _process(_delta: float) -> void:
	if slime:
		# Update dynamic stats every frame
		_update_dynamic_stats()

func _store_base_values() -> void:
	"""Store the base stat values for modifier calculation"""
	base_max_health = slime.max_health
	base_health_regen = slime.health_regen
	base_speed = slime.SPEED
	base_physical_damage = slime.physical_damage
	base_physical_defense = slime.physical_defense
	base_bounciness = slime.bounciness
	base_momentum_multiplier = slime.momentum_damage_multiplier

func _update_all_stats() -> void:
	"""Update all stat displays"""
	_update_health_stats()
	_update_movement_stats()
	_update_combat_stats()

func _update_health_stats() -> void:
	"""Update health-related stats"""
	# Current Health
	var current_health_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/HealthSection/CurrentHealth/Value")
	current_health_label.text = "%.0f" % slime.current_health
	
	# Max Health
	var max_health_modifier = slime.max_health - base_max_health
	var max_health_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/HealthSection/MaxHealth/Value")
	max_health_label.text = "%.0f (%.0f %s %.0f)" % [
		slime.max_health,
		base_max_health,
		"+" if max_health_modifier >= 0 else "-",
		abs(max_health_modifier)
	]
	
	# Health Regen
	var regen_modifier = slime.health_regen - base_health_regen
	var regen_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/HealthSection/HealthRegen/Value")
	regen_label.text = "%.1f (%.1f %s %.1f)" % [
		slime.health_regen,
		base_health_regen,
		"+" if regen_modifier >= 0 else "-",
		abs(regen_modifier)
	]

func _update_movement_stats() -> void:
	"""Update movement-related stats"""
	# Current Speed (dynamic)
	var current_speed = slime.velocity.length()
	var speed_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/MovementSection/CurrentSpeed/Value")
	speed_label.text = "%.0f" % current_speed
	
	# Max Speed
	var speed_modifier = slime.SPEED - base_speed
	var max_speed_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/MovementSection/MaxSpeed/Value")
	max_speed_label.text = "%.0f (%.0f %s %.0f)" % [
		slime.SPEED,
		base_speed,
		"+" if speed_modifier >= 0 else "-",
		abs(speed_modifier)
	]
	
	# Bounciness
	var bounce_modifier = slime.bounciness - base_bounciness
	var bounce_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/MovementSection/Bounciness/Value")
	bounce_label.text = "%.2f (%.2f %s %.2f)" % [
		slime.bounciness,
		base_bounciness,
		"+" if bounce_modifier >= 0 else "-",
		abs(bounce_modifier)
	]

func _update_combat_stats() -> void:
	"""Update combat-related stats"""
	# Physical Damage
	var damage_modifier = slime.physical_damage - base_physical_damage
	var damage_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/PhysicalDamage/Value")
	damage_label.text = "%.1f (%.1f %s %.1f)" % [
		slime.physical_damage,
		base_physical_damage,
		"+" if damage_modifier >= 0 else "-",
		abs(damage_modifier)
	]
	
	# Momentum Damage (dynamic - based on current speed)
	var current_speed = slime.velocity.length()
	var momentum_dmg = current_speed * slime.momentum_damage_multiplier
	var momentum_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/MomentumDamage/Value")
	momentum_label.text = "%.1f" % momentum_dmg
	
	# Total Damage
	var total_dmg = slime.physical_damage + momentum_dmg
	var total_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/TotalDamage/Value")
	total_label.text = "%.1f" % total_dmg
	
	# Physical Defense
	var defense_modifier = slime.physical_defense - base_physical_defense
	var defense_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/PhysicalDefense/Value")
	defense_label.text = "%.1f (%.1f %s %.1f)" % [
		slime.physical_defense,
		base_physical_defense,
		"+" if defense_modifier >= 0 else "-",
		abs(defense_modifier)
	]
	
	# Momentum Multiplier
	var multi_modifier = slime.momentum_damage_multiplier - base_momentum_multiplier
	var multi_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/MomentumMultiplier/Value")
	multi_label.text = "%.3f (%.3f %s %.3f)" % [
		slime.momentum_damage_multiplier,
		base_momentum_multiplier,
		"+" if multi_modifier >= 0 else "-",
		abs(multi_modifier)
	]

func _update_dynamic_stats() -> void:
	"""Update stats that change frequently (speed, momentum damage, total damage)"""
	if not slime:
		return
	
	# Current Speed
	var current_speed = slime.velocity.length()
	var speed_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/MovementSection/CurrentSpeed/Value")
	speed_label.text = "%.0f" % current_speed
	
	# Momentum Damage
	var momentum_dmg = current_speed * slime.momentum_damage_multiplier
	var momentum_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/MomentumDamage/Value")
	momentum_label.text = "%.1f" % momentum_dmg
	
	# Total Damage
	var total_dmg = slime.physical_damage + momentum_dmg
	var total_label = get_node("MarginContainer/VBoxContainer/ScrollContainer/StatsContent/CombatSection/TotalDamage/Value")
	total_label.text = "%.1f" % total_dmg

func _on_health_changed(_current: float, _max_health: float) -> void:
	"""Update health display when slime health changes"""
	_update_health_stats()
