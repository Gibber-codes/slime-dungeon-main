extends Resource
class_name NodeStat

# Node stat resource — immutable definition of a node upgrade.
# Save as .tres files in resources/nodes/ for Inspector editing.
# Runtime state (level, fill) lives in NodeSystem — this resource is definition-only
# so the .tres on disk never drifts and instances can be safely shared.

# --- Identity ---
@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var tier: int = 1
@export var parent_id: String = ""
@export var branch: String = ""
@export var is_implemented: bool = false

# --- Cost ---
@export var base_cost: float = 50.0
@export var cost_multiplier: float = 1.12

# --- Primary Effect ---
@export var bonus_key: String = ""           # stat key, e.g. "max_hp", "damage_mult"
@export var value_per_level: float = 0.0     # added/multiplied per level

# --- Secondary Effect (optional) ---
@export var bonus_key_2: String = ""
@export var value_per_level_2: float = 0.0

# --- Threshold Effect (e.g. Constitution connection slots at Lv.1, 5, 10) ---
@export var threshold_levels: Array[int] = []
@export var threshold_bonus_key: String = ""
