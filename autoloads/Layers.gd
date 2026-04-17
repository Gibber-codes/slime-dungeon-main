extends Node

# Collision layer / mask constants — mirrors the named layers in project.godot.
# Use these in code (collision_layer = Layers.ENEMIES) instead of magic numbers.
# Scene files (.tscn) still need raw integers; the editor's named layers UI handles
# them visually via the project layer names.

# Bit values (1 << layer_index)
const WORLD: int       = 1   # Layer 1 — walls, obstacles, breakables
const PLAYER: int      = 2   # Layer 2 — slime
const ENEMIES: int     = 4   # Layer 3 — defenders, heroes, breakables
const PROJECTILES: int = 8   # Layer 4 — future
const ZONES: int       = 16  # Layer 5 — exit triggers

# Common combined masks
const PLAYER_AND_WORLD: int = PLAYER | WORLD       # = 3 (slime + walls)
const WORLD_AND_ZONES: int  = WORLD | ZONES         # = 17

# Helper: build a mask from layer numbers (1-indexed to match Godot's UI)
static func mask_of(layer_numbers: Array[int]) -> int:
	var m: int = 0
	for n in layer_numbers:
		m |= 1 << (n - 1)
	return m
