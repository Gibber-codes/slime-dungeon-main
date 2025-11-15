# Slime Dungeon - Architecture

## Project Structure

```
slime-dungeon-main/
├── assets/              # All game assets
│   ├── audio/          # Sound effects and music
│   ├── fonts/          # UI fonts
│   ├── sprites/        # 2D textures and sprites
│   └── tilesets/       # Tilemap resources
├── autoloads/          # Global singleton scripts (Godot autoloads: Globals, GameManager, NodeSystem, MonsterEnergy, SignalBus)
├── docs/               # Project documentation
├── effects/            # Visual and audio effect scenes
├── resources/          # Godot resource files
│   ├── configs/        # Configuration resources
│   ├── defenders/      # Defender type definitions
│   └── nodes/          # Custom node resources
├── scenes/             # Scene files (.tscn)
│   ├── core/          # Core game scenes (Main, managers)
│   ├── entities/      # Entity scenes (Slime, Defender)
│   ├── rooms/         # Room templates
│   ├── systems/       # System scenes
│   └── ui/            # User interface scenes
├── scripts/            # GDScript files
│   ├── core/          # Base classes and core logic
│   ├── entities/      # Entity scripts
│   ├── systems/       # Game system scripts
│   └── ui/            # UI controller scripts
├── tests/              # Unit and integration tests
└── project.godot       # Godot project configuration
```

## Scene Hierarchy

### Main Scene (`scenes/core/Main.tscn`)

```
Main (Node)
├── UI (CanvasLayer)
│   └── HUD (Control)
│       ├── HealthBar (TextureProgressBar)
│       ├── EnergyCounter (Label)
│       ├── RoomCounter (Label)
│       └── ResetButton (Button)
├── RoomManager (Node)
│   ├── CurrentRoom (Node2D)
│   └── NextRoomPlaceholder (Node2D)
├── GameManager (Node) - [Not yet implemented]
└── Slime (CharacterBody2D)
    ├── Sprite2D
    ├── CollisionShape2D
    ├── Area2D (for detection)
    ├── MomentumTrail (Line2D)
    └── FocusIndicator (Sprite2D)
```

### Room Scene (`scenes/rooms/Room.tscn`)

```
Room (Node2D)
├── TileMap (TileMap) - Walls and floor
├── Defenders (Node2D) - Container for defender instances
├── Obstacles (Node2D) - Container for obstacles
└── ExitZone (Area2D) - Triggers room completion
```

### Entity Scenes

**Slime** (`scenes/entities/Slime.tscn`)
```
Slime (CharacterBody2D)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
├── Area2D - Detection zone
├── MomentumTrail (Line2D) - Visual feedback
├── FocusIndicator (Sprite2D) - Target indicator
└── Timer - For various timing needs
```

**Defender** (`scenes/entities/Defender.tscn`)
```
Defender (CharacterBody2D)
├── Sprite2D - Visual representation
├── CollisionShape2D - Physics collision
├── AttackRange (Area2D) - Attack detection zone
│   └── CollisionShape2D
└── HealthBar (ProgressBar) - Visual health indicator
```

## System Architecture

### Core Systems

1. **GameManager** (Planned)
   - Game state management
   - Reset/prestige logic
   - Multiplier tracking
   - Save/load system

2. **RoomManager** (`scripts/systems/RoomManager.gd`)
   - Room loading and transitions
   - Difficulty scaling
   - Room progression tracking

3. **MonsterEnergy** (Planned)
   - Energy collection
   - Energy spending
   - Upgrade purchases

### Entity System

**BaseEntity** (`scripts/core/BaseEntity.gd`)
- Abstract base class (script only, no scene)
- Shared stats: health, damage, defense, regen
- Common methods: `take_damage()`, `die()`
- Inherited by Slime and Defender

### Signal Flow

```
Defender.defeated
    ↓
Room._on_defender_defeated()
    ↓
Room.room_cleared
    ↓
RoomManager.load_next_room()

Slime.enemy_defeated
    ↓
GameManager (collect energy)
    ↓
MonsterEnergy.add_energy()
```

## Data Flow

### Combat System
```
Collision Detection → Damage Calculation → Health Update → Death Check → Signal Emission
```

### Room Progression
```
Room Start → Spawn Defenders → Combat Loop → All Defeated → Room Cleared → Load Next Room
```

## Autoloads (Configured)

The project uses the following global singletons configured in `project.godot`:

- **Globals** (`res://autoloads/Globals.gd`) - Constants and shared enums
- **GameManager** (`res://autoloads/GameManager.gd`) - Global game state and progression
- **NodeSystem** (`res://autoloads/NodeSystem.gd`) - Upgrade and meta-progression logic
- **MonsterEnergy** (`res://autoloads/MonsterEnergy.gd`) - Global currency system
- **SignalBus** (`res://autoloads/SignalBus.gd`) - Global signal/event routing

Planned additional autoloads (not yet implemented):

- **AudioManager** - Global audio control

## Resource Architecture

### Custom Resources (Planned)

- **DefenderData** - Defender type definitions (stats, behavior)
- **RoomConfig** - Room generation parameters
- **UpgradeData** - Upgrade definitions
- **GameConfig** - Global game settings

## Notes

- Scene/script structure mirrors each other for easy navigation
- Managers are Node-based for signal communication
- Entities use CharacterBody2D for physics integration
- UI is separated into CanvasLayer for proper rendering order
- The **Slime is not directly player-controlled**: its movement is autonomous and physics-driven (bouncing, momentum). Player interaction is primarily via UI/menus, upgrades, and meta-progression systems, not direct WASD/arrow/gamepad control.

