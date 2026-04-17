extends Node

# Truly global game settings.
# Per-entity stats live in EntityData .tres files (resources/entities/).
# Per-slime tuning lives in SlimeData (resources/entities/slime.tres).

@export_group("Testing & Cheats")
@export var enable_testing_cheats: bool = false
@export var testing_multiplier: float = 1.0
@export var testing_god_mode: bool = false
@export var testing_insta_kill: bool = false

# Room progression
const TOTAL_ROOMS: int = 40
const BASE_DEFENDERS_PER_ROOM: int = 3
const MAX_DEFENDERS_PER_ROOM: int = 8

# Breakable spawn counts per room
const BASE_BREAKABLES_PER_ROOM: int = 30
const MAX_BREAKABLES_PER_ROOM: int = 50

# Room-level reward bonus (added on top of per-entity rewards)
const ENERGY_ROOM_BONUS: float = 2.0

# Difficulty scaling (room progression)
const DEFENDER_COUNT_SCALE_INTERVAL: int = 5

# Prestige
const RESET_MULTIPLIER_DIVISOR: float = 500.0
