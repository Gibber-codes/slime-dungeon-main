extends StaticBody2D
class_name BaseEntity

# Abstract base class for all game entities (Slime, Defender, etc.)
# This script is not attached to any scene - it's inherited by entity scripts

## Signals
signal health_changed(current: float, max_health: float)
signal died()

## Exported Variables
@export var max_health: float = 100.0
@export var physical_damage: float = 10.0
@export var physical_defense: float = 2.0
@export var health_regen: float = 0.0  # HP restored per second
@export var contact_damage: float = 0.0  # Damage dealt when something touches this entity
@export var bounciness: float = 0.8  # How much velocity is retained when bouncing off this entity
@export var attack_cooldown: float = 1.0  # Time between attacks

## Internal Variables
var current_health: float = 100.0
var attack_timer: Timer = null
var attack_target: Node2D = null

func _ready() -> void:
	# Initialize health to max
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
	# Ensure default collision layers for entities (Layer 3: Enemies/Obstacles)
	# This ensures Slime (Layer 2) can collide with them
	collision_layer = 4
	collision_mask = 3

	# Setup attack system if AttackRange node exists
	var attack_range = get_node_or_null("AttackRange")
	if attack_range and attack_range is Area2D:
		attack_range.body_entered.connect(_on_attack_range_body_entered)
		attack_range.body_exited.connect(_on_attack_range_body_exited)
		
		# Create attack timer
		attack_timer = Timer.new()
		attack_timer.wait_time = attack_cooldown
		attack_timer.one_shot = false
		attack_timer.timeout.connect(_attack_target)
		add_child(attack_timer)

func _on_attack_range_body_entered(body: Node2D) -> void:
	"""Handle target entering attack range"""
	if body.is_in_group("slime"):
		attack_target = body
		if attack_timer:
			attack_timer.start()
			_attack_target()  # Attack immediately

func _on_attack_range_body_exited(body: Node2D) -> void:
	"""Handle target leaving attack range"""
	if body == attack_target:
		attack_target = null
		if attack_timer:
			attack_timer.stop()

func _attack_target() -> void:
	"""Deal damage to the current target"""
	if attack_target and attack_target.has_method("take_damage"):
		attack_target.take_damage(physical_damage)
		# Optional: Emit signal or play sound here if needed by child classes

func _on_collision(collider: Node) -> void:
	"""Handle being collided with by another object"""
	pass  # Override in child classes for specific behavior

func _process(delta: float) -> void:
	# Update z-index based on Y position for depth sorting
	z_index = int(global_position.y)

	# Handle health regeneration
	if health_regen > 0.0 and current_health < max_health:
		_process_regen(delta)

func _process_regen(delta: float) -> void:
	"""Process health regeneration per frame"""
	var regen_amount: float = health_regen * delta
	heal(regen_amount)

func take_damage(amount: float) -> void:
	"""Apply damage with defense calculation"""
	# Calculate damage after defense
	var actual_damage: float = max(0.0, amount - physical_defense)

	# Apply damage
	current_health = max(0.0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)

	# Check for death
	if current_health <= 0.0:
		die()

func heal(amount: float) -> void:
	"""Restore health, clamped to max_health"""
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die() -> void:
	"""Handle entity death - can be overridden by child classes"""
	died.emit()
	# Default behavior: remove from scene
	queue_free()
