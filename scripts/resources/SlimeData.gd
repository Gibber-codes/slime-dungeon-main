extends Resource
class_name SlimeData

# Data-driven slime tuning — all the constants that used to live in Globals.gd.
# Save as .tres files in resources/entities/ for Inspector editing.
# Different slime variants (cosmetic skins, prestige forms) can each have their
# own tuning resource without touching code.

# =============================================================================
# Identity
# =============================================================================

@export var id: String = "default_slime"
@export var display_name: String = "Slime"

# =============================================================================
# Base Stats (pre-node-bonus)
# =============================================================================

@export_group("Base Stats")
@export var base_health: float = 200.0
@export var base_speed: float = 300.0
@export var base_damage: float = 8.0
@export var base_defense: float = 0.0

# =============================================================================
# Momentum tuning
# =============================================================================

@export_group("Momentum")
## Multiplier on velocity for added momentum damage. Higher = momentum hits harder.
@export var momentum_damage_multiplier: float = 0.06
## % per second gained while moving freely.
@export var momentum_gain_rate: float = 0.15
## % per second lost while not hitting anything.
@export var momentum_decay_rate: float = 0.25
## At full momentum, speed is base * (1 + this).
@export var max_speed_bonus: float = 0.5
## % momentum gained per entity hit (small reward).
@export var hit_boost: float = 0.03
## % momentum lost per wall bounce.
@export var bounce_decay: float = 0.20
## % momentum lost per entity hit (offsets hit_boost early on).
@export var entity_hit_decay: float = 0.12

# =============================================================================
# Physics / Visual
# =============================================================================

@export_group("Physics")
@export var bounciness: float = 1.0

# =============================================================================
# Visuals
# =============================================================================

@export_group("Visuals")
@export var sprite_texture: Texture2D = null
@export var sprite_scale: Vector2 = Vector2(0.05, 0.05)
@export var sprite_offset: Vector2 = Vector2(0, -8)
