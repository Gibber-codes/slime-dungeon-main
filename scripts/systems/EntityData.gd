extends Resource
class_name EntityData

# Data-driven entity definition — the entity equivalent of NodeStat.
# Save as .tres files in resources/entities/ for Inspector editing.
# Each entity type (rat defender, vase, archer, etc.) gets its own .tres file.

# =============================================================================
# Identity
# =============================================================================

enum Category { DEFENDER, OBJECT, TREASURE, HERO }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var entity_category: Category = Category.DEFENDER

## Path to the PackedScene to instantiate for this entity type.
## Use a string path instead of a PackedScene reference to avoid circular
## resource loading (scene references .tres, .tres references scene).
## e.g. "res://scenes/entities/Defender.tscn"
@export var scene_path: String = ""

# =============================================================================
# Base Stats
# =============================================================================

@export_group("Stats")
@export var max_health: float = 100.0
@export var physical_damage: float = 0.0
@export var physical_defense: float = 0.0
@export var health_regen: float = 0.0
@export var bounciness: float = 0.5

# =============================================================================
# Combat (Defender-specific, ignored by non-attackers)
# =============================================================================

@export_group("Combat")
@export var can_attack: bool = false
@export var attack_range: float = 38.4
@export var attack_speed: float = 0.2      ## Charge-up duration (seconds)
@export var attack_cooldown: float = 2.0   ## Idle wait between attacks (seconds)

# =============================================================================
# Difficulty Scaling (per-entity multipliers applied by Room)
# =============================================================================

@export_group("Scaling")
@export var health_scale: float = 1.12   ## pow(health_scale, room_index) multiplier
@export var damage_scale: float = 1.08
@export var defense_scale: float = 1.05

# =============================================================================
# Rewards
# =============================================================================

@export_group("Rewards")
@export var energy_reward: float = 5.0   ## Base ME reward when defeated
@export var xp_reward: float = 5.0       ## Base XP reward when defeated

# =============================================================================
# Visuals
# =============================================================================

@export_group("Visuals")
@export var sprite_texture: Texture2D = null
@export var sprite_scale: Vector2 = Vector2(0.019, 0.019)
@export var sprite_offset: Vector2 = Vector2(0, -8)
@export var draw_color: Color = Color(0.6, 0.4, 0.25)  ## Primary procedural draw color

# =============================================================================
# Behavior Flags
# =============================================================================

@export_group("Behavior")
@export var is_destructible: bool = true     ## Can be destroyed by the slime
@export var blocks_room_clear: bool = true   ## Room won't clear until this is dead
@export var groups: Array[String] = []       ## Godot groups to add this entity to
