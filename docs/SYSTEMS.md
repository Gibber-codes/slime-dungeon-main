# Slime Dungeon - Systems Reference

## System Overview

The game is built around several core systems that manage different aspects of gameplay:

1. **GameManager** - Overall game state and progression
2. **RoomManager** - Room loading and transitions
3. **NodeSystem** - 6 Tier 1 upgrade nodes with connections
4. **MonsterEnergy** - Currency and upgrade system
5. **Room** - Individual room logic
6. **UI System** - User interface management

> **Important design note:** The Slime's movement is **automatic and physics-driven** (bouncing, momentum). Players do **not** directly control the Slime with keyboard/mouse/gamepad. Instead, player interaction flows through systems like **MonsterEnergy**, **NodeSystem**, menus, and upgrade screens, making this closer to a physics-based incremental/idle game than a traditional action game.

---

## GameManager

**Scene:** `scenes/core/GameManager.tscn` (stub exists)
**Script:** `autoloads/GameManager.gd` (autoload singleton, stub)
**Node Type:** `Node`
**Autoload:** ✅ Configured (`GameManager` singleton in `project.godot`)

### Purpose
Central hub for game state management, reset/prestige mechanics, and global progression tracking.

### Reset/Prestige System (MVP)

**When:** Player manually resets (or dies/gets stuck)

**Reward:** Permanent multiplier based on total Monster Energy collected

**Multiplier Formula:** (To be defined, example: `1 + (Total Energy / 10000)`)

**Multiplier Effect:** Applies to all future Monster Energy gains AND base stats

**Node Progress:** Resets to zero (must re-upgrade nodes)

**Purpose:** Encourages strategic resets for faster long-term progression

**Expected Timing:**
- First reset: ~10-15 minutes of play (room 8-12)
- Second reset: ~8-12 minutes (room 15-20)
- Progression: Feeling of meaningful power increase per reset

### Exported Variables (Planned)
```gdscript
@export var starting_health: float = 100.0
@export var reset_multiplier_divisor: float = 10000.0  # For formula: 1 + (Total Energy / divisor)
```

### Properties (Planned)
```gdscript
var reset_multiplier: float = 1.0
var total_resets: int = 0
var lifetime_energy: float = 0.0  # Total energy collected across all runs
var current_run_energy: float = 0.0
var game_state: GameState = GameState.PLAYING
```

### Signals (Planned)
```gdscript
signal reset_triggered()
signal game_over()
signal game_won()
signal multiplier_changed(new_multiplier: float)
```

### Key Methods (Planned)
```gdscript
func reset_game() -> void
func calculate_reset_multiplier(total_energy: float) -> float
func apply_reset_bonus() -> void
func save_game() -> void
func load_game() -> void
func _on_player_died() -> void
func _on_all_rooms_cleared() -> void
```

### Current Status
❌ **Not implemented** - Needs to be created

### Responsibilities
- Track game state (playing, paused, game over)
- Handle reset/prestige logic
- Calculate and apply permanent multipliers
- Track lifetime energy across resets
- Save/load game data
- Coordinate between other systems

---

## RoomManager

**Scene:** `scenes/core/RoomManager.tscn`  
**Script:** `scripts/systems/RoomManager.gd`  
**Node Type:** `Node`

### Purpose
Manages room progression, loading, transitions, and difficulty scaling across the 40-room dungeon.

### Exported Variables (Planned)
```gdscript
@export var total_rooms: int = 40
@export var room_templates: Array[PackedScene] = []
@export var difficulty_curve: Curve
```

### Properties (Planned)
```gdscript
var current_room_index: int = 0
var current_room: Room = null
var next_room: Room = null
```

### Signals (Planned)
```gdscript
signal room_loaded(room_index: int)
signal room_cleared(room_index: int)
signal all_rooms_cleared()
signal room_transition_started()
signal room_transition_completed()
```

### Key Methods (Planned)
```gdscript
func load_next_room() -> void
func load_room(index: int) -> void
func get_room_difficulty(index: int) -> float
func _on_room_cleared() -> void
func reset_progression() -> void
```

### Scene Structure
```
RoomManager (Node)
├── CurrentRoom (Node2D) - Container for active room
└── NextRoomPlaceholder (Node2D) - Preload next room
```

### Current Status
⚠️ **Stub implementation** - Scene exists, script is placeholder

### Planned Features
- [ ] Room template loading
- [ ] Difficulty scaling based on room index
- [ ] Smooth room transitions
- [ ] Room preloading for performance
- [ ] Procedural room generation (optional)

---

## Room

**Scene:** `scenes/rooms/Room.tscn`  
**Script:** `scripts/systems/Room.gd`  
**Node Type:** `Node2D`

### Purpose
Individual room instance that manages defenders, obstacles, and victory conditions.

### Exported Variables (Planned)
```gdscript
@export var room_difficulty: float = 1.0
@export var defender_count: int = 3
@export var energy_reward: float = 10.0
```

### Signals (Planned)
```gdscript
signal room_cleared()
signal defender_spawned(defender: Defender)
signal all_defenders_defeated()
```

### Key Methods (Planned)
```gdscript
func _ready() -> void
func spawn_defenders() -> void
func _on_defender_defeated() -> void
func _all_defenders_defeated() -> bool
func _on_exit_zone_entered(body: Node2D) -> void
```

### Scene Structure
```
Room (Node2D)
├── TileMap (TileMap) - Walls, floor, decorations
├── Defenders (Node2D) - Container for defender instances
├── Obstacles (Node2D) - Container for obstacles
└── ExitZone (Area2D) - Triggers room completion
```

### Current Status
⚠️ **Stub implementation** - Scene exists, script is placeholder

### Planned Features
- [ ] Dynamic defender spawning
- [ ] Victory condition checking
- [ ] Exit zone activation after clear
- [ ] Obstacle placement
- [ ] Energy drop on completion

---

## NodeSystem

**Script:** `autoloads/NodeSystem.gd` (autoload singleton, partial implementation)
**Node Type:** `Node`
**Autoload:** ✅ Configured (`NodeSystem` singleton in `project.godot`)
**Resources:** `resources/nodes/*.tres` (6 NodeStat resources)

### Purpose
Manages the 6 Tier 1 upgrade nodes that enhance the slime's capabilities. Each node has specific effects, upgrade costs, and can be connected to other nodes via Constitution's connection system.

### Tier 1 Nodes (MVP Only)

#### 1. Wisdom
- **Primary Effect:** Monster Energy Yield
- **Per Level:** +X% Monster Energy gained from defeated defenders
- **Suggested Scaling:** +2-5% per level (to be balanced)
- **Resource:** `resources/nodes/wisdom.tres`

#### 2. Strength
- **Primary Effect:** Damage & Momentum
- **Per Level:**
  - +X% Physical Damage
  - +X% Momentum Gain (more damage)
- **Suggested Scaling:** +5-10% per level (to be balanced)
- **Resource:** `resources/nodes/strength.tres`

#### 3. Intelligence
- **Primary Effect:** Auto-Seek & Focus State
- **Auto-Seek Timer:**
  - Level 1: 9 seconds until auto-seek activates
  - Each level: Reduces timer by X seconds
  - Auto-seek: Slime automatically targets nearest defender
- **Focus Mode:**
  - Unlocks/upgrades every few levels
  - Focus triggers when X or fewer entities remain in room
  - Focus effect: Enhanced damage/speed/targeting (to be defined)
- **Resource:** `resources/nodes/intelligence.tres`

#### 4. Constitution
- **Primary Effect:** Node Connections & Health
- **Node Connections:**
  - Start: 1 connection slot
  - Every few levels: +1 connection slot
  - Maximum: 3 connections (for MVP)
  - Note: Connections can be cut and reconnected freely
- **Health:** +X HP per level
- **Resource:** `resources/nodes/constitution.tres`

#### 5. Stamina
- **Primary Effect:** Health Regeneration
- **Per Level:** +X HP regeneration per second
- **Suggested Scaling:** +0.5-2 HP/sec per level (to be balanced)
- **Resource:** `resources/nodes/stamina.tres`

#### 6. Agility
- **Primary Effect:** Movement Speed
- **Per Level:** +X% Movement Speed
- **Suggested Scaling:** +3-8% per level (to be balanced)
- **Resource:** `resources/nodes/agility.tres`

### Node Upgrade Costs

**Formula:** `Base Cost × (Multiplier ^ Current Level)`

**Example:** `50 Energy × (1.5 ^ Level)`
- Level 1→2: 50 Energy
- Level 2→3: 75 Energy
- Level 3→4: 112.5 Energy
- And so on...

### Properties (Planned)
```gdscript
@export var wisdom: NodeStat
@export var strength: NodeStat
@export var intelligence: NodeStat
@export var constitution: NodeStat
@export var stamina: NodeStat
@export var agility: NodeStat

var active_connections: Array[Connection] = []
var max_connections: int = 1  # Increased by Constitution
```

### Signals (Planned)
```gdscript
signal node_upgraded(node_name: String, new_level: int)
signal connection_created(from_node: String, to_node: String)
signal connection_removed(from_node: String, to_node: String)
signal auto_seek_activated()
signal focus_mode_triggered()
```

### Key Methods (Planned)
```gdscript
func upgrade_node(node_name: String) -> bool
func get_node_level(node_name: String) -> int
func get_upgrade_cost(node_name: String) -> float
func can_upgrade(node_name: String) -> bool
func create_connection(from_node: String, to_node: String) -> bool
func remove_connection(from_node: String, to_node: String) -> void
func get_total_stat_bonus(stat_name: String) -> float
func reset_all_nodes() -> void  # Called on prestige reset
```

### Current Status
⚠️ **Partial** - NodeStat resources created, upgrade logic needs implementation

### Planned Features
- [ ] Node upgrade cost calculation
- [ ] Connection system (1-3 slots from Constitution)
- [ ] Auto-seek timer and targeting (Intelligence)
- [ ] Focus mode trigger and effects (Intelligence)
- [ ] Stat bonus aggregation
- [ ] Reset functionality (preserve connections count from Constitution)
- [ ] UI integration for node tree visualization

---

## MonsterEnergy

**Script:** `autoloads/MonsterEnergy.gd` (autoload singleton, stub)
**Node Type:** `Node`
**Autoload:** ✅ Configured (`MonsterEnergy` singleton in `project.godot`)

### Purpose
Manages the Monster Energy currency system - collection, spending, and upgrade purchases.

### Properties (Planned)
```gdscript
var total_energy: float = 0.0
var lifetime_energy: float = 0.0
var current_run_energy: float = 0.0
```

### Signals (Planned)
```gdscript
signal energy_changed(current: float, delta: float)
signal energy_spent(amount: float, item: String)
signal insufficient_energy(cost: float, current: float)
```

### Key Methods (Planned)
```gdscript
func add_energy(amount: float) -> void
func spend_energy(cost: float) -> bool
func can_afford(cost: float) -> bool
func reset_current_run() -> void
func get_total_energy() -> float
```

### Current Status
❌ **Not implemented** - Needs to be created

### Planned Features
- [ ] Energy collection from defeated enemies
- [ ] Energy spending validation
- [ ] Persistent energy tracking
- [ ] UI integration for display
- [ ] Save/load energy data

---

## UI System

**Scene:** `scenes/ui/UI.tscn` (planned)  
**Scripts:** `scripts/ui/` (not yet created)  
**Node Type:** `CanvasLayer`

### Purpose
Manages all user interface elements including HUD, menus, and upgrade screens.

### Components (Planned)

#### HUD
```gdscript
# scripts/ui/HUD.gd
- HealthBar (TextureProgressBar)
- EnergyCounter (Label)
- RoomCounter (Label)
- ResetButton (Button)
```

#### Upgrade Menu
```gdscript
# scripts/ui/UpgradeMenu.gd
- Upgrade list
- Purchase buttons
- Cost display
- Description panels
```

#### Pause Menu
```gdscript
# scripts/ui/PauseMenu.gd
- Resume button
- Settings
- Quit to menu
```

### Current Status
⚠️ **Partially implemented** - Basic HUD structure exists in Main.tscn

---

## System Communication

### Signal Flow Diagram
```
Player defeats Defender
    ↓
Defender.defeated → Room._on_defender_defeated()
    ↓
Room checks if all defeated
    ↓
Room.room_cleared → RoomManager._on_room_cleared()
    ↓
RoomManager.load_next_room()
    ↓
New Room loaded → Room.spawn_defenders()
```

### Energy Collection Flow
```
Defender.defeated
    ↓
Slime.enemy_defeated(defender)
    ↓
GameManager._on_enemy_defeated()
    ↓
MonsterEnergy.add_energy(amount)
    ↓
MonsterEnergy.energy_changed
    ↓
UI updates energy display
```

---

## Autoloads (Configured)

Configured in `project.godot`:

```ini
[autoload]
Globals="*res://autoloads/Globals.gd"
GameManager="*res://autoloads/GameManager.gd"
NodeSystem="*res://autoloads/NodeSystem.gd"
MonsterEnergy="*res://autoloads/MonsterEnergy.gd"
SignalBus="*res://autoloads/SignalBus.gd"
```

Planned additional autoloads (not yet implemented):

```ini
[autoload]
AudioManager="*res://scripts/systems/AudioManager.gd" ; planned
```

---

## Future Systems (Planned)

### AudioManager
- Music playback
- Sound effect management
- Volume control
- Audio mixing

### EventBus
- Global event system
- Decoupled communication
- Event history/logging

### UpgradeSystem
- Upgrade definitions
- Purchase validation
- Effect application
- Upgrade tree logic

### SaveSystem
- Save game data
- Load game data
- Auto-save functionality
- Multiple save slots

