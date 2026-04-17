extends CharacterBody2D
class_name BaseEntity

# Abstract base class for all game entities.
# Assign an EntityData resource in the Inspector to auto-populate stats.

signal health_changed(current: float, max_health: float)
signal died()

@export var entity_data: EntityData = null

@export var max_health: float = 100.0
@export var physical_damage: float = 10.0
@export var physical_defense: float = 2.0
@export var health_regen: float = 0.0

## Per-entity energy reward (set from entity_data or by Room)
var energy_reward: float = 0.0
## Per-entity XP reward (set from entity_data or by Room)
var xp_reward: float = 0.0

var current_health: float = 100.0

func _ready() -> void:
	_apply_entity_data()
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if health_regen > 0.0 and current_health < max_health:
		var regen_amount: float = health_regen * delta
		heal(regen_amount)

## Populate stats, groups, and sprite from the EntityData resource (if assigned).
## Called automatically in _ready(). Subclasses that override _ready() should
## call super._ready() or _apply_entity_data() directly.
func _apply_entity_data() -> void:
	if not entity_data:
		return
	max_health = entity_data.max_health
	physical_damage = entity_data.physical_damage
	physical_defense = entity_data.physical_defense
	health_regen = entity_data.health_regen
	energy_reward = entity_data.energy_reward
	xp_reward = entity_data.xp_reward

	# Apply sprite fields if a Sprite2D child exists and the resource has a texture set.
	# Lets you swap entity art by editing the .tres without touching the scene.
	if entity_data.sprite_texture:
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.texture = entity_data.sprite_texture
			sprite.scale = entity_data.sprite_scale
			sprite.position = entity_data.sprite_offset

	# Auto-add to groups defined in the resource
	for group_name in entity_data.groups:
		if not is_in_group(group_name):
			add_to_group(group_name)

## Apply difficulty scaling using per-entity multipliers from EntityData.
## Subclasses can override for custom scaling behavior.
func apply_difficulty(difficulty: float, room_index: int) -> void:
	if entity_data:
		max_health = entity_data.max_health * difficulty
		physical_damage = entity_data.physical_damage * pow(entity_data.damage_scale, room_index)
		physical_defense = entity_data.physical_defense * pow(entity_data.defense_scale, room_index)
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> void:
	if is_in_group("slime") and Globals.testing_god_mode:
		return
	var actual_damage: float = max(0.0, amount - physical_defense)
	current_health = max(0.0, current_health - actual_damage)
	health_changed.emit(current_health, max_health)
	if actual_damage > 0:
		_flash_hit()
	if current_health <= 0.0:
		die()

func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func _flash_hit() -> void:
	modulate = Color(3, 3, 3)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SignalBus.entity_selected.emit(self)

func die() -> void:
	died.emit()
