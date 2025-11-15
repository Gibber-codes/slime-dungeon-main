extends Resource
class_name NodeStat

# Node stat resource - represents individual node upgrade stats

@export var name: String
@export var level: int = 0
@export var base_cost: float = 10.0
@export var cost_multiplier: float = 1.15
@export var value_per_level: float = 1.0

