# Slime Dungeon - Architecture Overview

**Last Updated:** 2025-11-18  
**Purpose:** High-level system architecture and component relationships

---

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Autoload Singletons](#autoload-singletons)
3. [Scene Hierarchy](#scene-hierarchy)
4. [Data Flow](#data-flow)
5. [Signal Communication](#signal-communication)
6. [Integration Points](#integration-points)

---

## System Architecture

### High-Level Component Diagram

```mermaid
graph TB
    subgraph "Autoload Singletons"
        GM[GameManager<br/>Game State & Prestige]
        NS[NodeSystem<br/>Upgrades & Stats]
        ME[MonsterEnergy<br/>Currency]
        SB[SignalBus<br/>Event Communication]
        GL[Globals<br/>Configuration]
    end
    
    subgraph "Core Systems"
        RM[RoomManager<br/>Room Progression]
        CM[CombatManager<br/>Damage Calculation]
        PM[PhysicsManager<br/>Bounce Physics]
    end
    
    subgraph "Entities"
        SL[Slime<br/>Player Entity]
        DF[Defender<br/>Enemy Entity]
        OB[Obstacle<br/>Environment]
    end
    
    subgraph "Rooms"
        R1[Room_01]
        R2[Room_02]
        RN[Room_N<br/>40 total]
    end
    
    subgraph "UI Layer"
        HUD[HUD<br/>Health/Energy/Room]
        UM[UpgradeMenu<br/>Node Upgrades]
        RS[ResetScreen<br/>Prestige]
        PM_UI[PauseMenu]
    end
    
    GM --> RM
    GM --> NS
    GM --> ME
    GM --> SB
    
    NS --> SL
    ME --> UM
    
    RM --> R1
    RM --> R2
    RM --> RN
    
    R1 --> DF
    R1 --> OB
    
    SL --> CM
    DF --> CM
    
    CM --> ME
    CM --> SB
    
    SB --> HUD
    SB --> UM
    SB --> RS
    
    GL -.-> GM
    GL -.-> NS
    GL -.-> ME
```

### Component Responsibilities

| Component | Type | Responsibility |
|-----------|------|----------------|
| **GameManager** | Autoload | Game state, reset/prestige, save/load |
| **NodeSystem** | Autoload | 6 upgrade nodes, connections, stat bonuses |
| **MonsterEnergy** | Autoload | Currency collection, spending, tracking |
| **SignalBus** | Autoload | Decoupled event communication |
| **Globals** | Autoload | Configuration constants, enums |
| **RoomManager** | System | Room loading, transitions, difficulty scaling |
| **CombatManager** | System | Damage calculation, combat resolution |
| **PhysicsManager** | System | Bounce physics, momentum (optional) |
| **Slime** | Entity | Player character, autonomous movement |
| **Defender** | Entity | Enemy, stationary attacks |
| **Obstacle** | Entity | Environmental objects, seekable targets |
| **Room** | Scene | Individual room logic, victory conditions |
| **UI** | Layer | User interface, menus, HUD |

---

## Autoload Singletons

### Singleton Architecture

```mermaid
classDiagram
    class GameManager {
        +GameState game_state
        +float reset_multiplier
        +int total_resets
        +float lifetime_energy
        +reset_game()
        +calculate_reset_multiplier()
        +save_game()
        +load_game()
    }
    
    class NodeSystem {
        +NodeStat wisdom
        +NodeStat strength
        +NodeStat intelligence
        +NodeStat constitution
        +NodeStat stamina
        +NodeStat agility
        +Array connections
        +upgrade_node(name)
        +get_stat_bonus(stat)
        +create_connection()
    }
    
    class MonsterEnergy {
        +float total_energy
        +float lifetime_energy
        +add_energy(amount)
        +spend_energy(cost)
        +can_afford(cost)
    }
    
    class SignalBus {
        +signal room_cleared
        +signal enemy_defeated
        +signal node_upgraded
        +signal energy_changed
        +signal game_reset
    }
    
    class Globals {
        +enum GameState
        +enum NodeType
        +Dictionary config
        +get_config(key)
    }
    
    GameManager --> NodeSystem
    GameManager --> MonsterEnergy
    GameManager --> SignalBus
    NodeSystem --> SignalBus
    MonsterEnergy --> SignalBus
```

### Autoload Configuration

**File:** `project.godot`

```ini
[autoload]
Globals="*res://autoloads/Globals.gd"
GameManager="*res://autoloads/GameManager.gd"
NodeSystem="*res://autoloads/NodeSystem.gd"
MonsterEnergy="*res://autoloads/MonsterEnergy.gd"
SignalBus="*res://autoloads/SignalBus.gd"
```

**Load Order:** Globals → GameManager → NodeSystem → MonsterEnergy → SignalBus

---

## Scene Hierarchy

### Main Scene Structure

```
Main.tscn (Root Scene)
├── RoomManager (Node)
│   ├── CurrentRoom (Node2D) - Active room container
│   └── NextRoomPlaceholder (Node2D) - Preload next room
├── Slime (CharacterBody2D) - Player entity
├── UI (CanvasLayer)
│   ├── HUD (Control)
│   ├── NodeUpgradeMenu (Control)
│   ├── ResetScreen (Control)
│   └── PauseMenu (Control)
└── Camera2D - Follows slime
```

### Room Scene Structure

```
Room.tscn (Template)
├── TileMap (TileMap) - Walls, floor, decorations
├── Defenders (Node2D) - Container for enemy spawns
│   └── Defender instances (spawned at runtime)
├── Obstacles (Node2D) - Container for environmental objects
│   └── Obstacle instances
└── ExitZone (Area2D) - Triggers room completion
    └── CollisionShape2D
```

### Entity Scene Structure

```
Slime.tscn
├── Sprite2D (Slime sprite)
├── CollisionShape2D (Physics collision)
├── DetectionZone (Area2D) - Enemy detection
├── MomentumTrail (Line2D) - Visual feedback
├── FocusIndicator (Sprite2D) - Target indicator
└── AutoSeekTimer (Timer) - Auto-seek countdown

Defender.tscn
├── Sprite2D (Enemy sprite)
├── CollisionShape2D (Physics collision)
├── AttackRange (Area2D) - Attack detection
│   └── CollisionShape2D
├── HealthBar (ProgressBar) - Visual health
└── AttackTimer (Timer) - Attack cooldown

Obstacle.tscn
├── Sprite2D (Obstacle sprite)
└── CollisionShape2D (Static collision)
```

---

## Data Flow

### Game Loop Data Flow

```mermaid
flowchart TD
    Start[Game Start] --> Init[Initialize Systems]
    Init --> LoadRoom[Load Room 1]
    LoadRoom --> SpawnEnemies[Spawn Defenders]
    SpawnEnemies --> GameLoop{Game Loop}

    GameLoop --> Physics[Physics Process]
    Physics --> Collision{Collision?}

    Collision -->|Yes| Combat[Combat Resolution]
    Collision -->|No| GameLoop

    Combat --> Damage[Calculate Damage]
    Damage --> Health{Enemy Dead?}

    Health -->|Yes| Reward[Award Energy]
    Health -->|No| GameLoop

    Reward --> CheckRoom{All Enemies<br/>Defeated?}
    CheckRoom -->|No| GameLoop
    CheckRoom -->|Yes| RoomClear[Room Cleared]

    RoomClear --> CheckProgress{Room 40<br/>Cleared?}
    CheckProgress -->|No| NextRoom[Load Next Room]
    CheckProgress -->|Yes| Victory[Victory Screen]

    NextRoom --> SpawnEnemies

    GameLoop --> PlayerDead{Player Dead?}
    PlayerDead -->|Yes| GameOver[Game Over]
    PlayerDead -->|No| GameLoop

    GameOver --> Reset{Reset?}
    Victory --> Reset
    Reset -->|Yes| Prestige[Calculate Prestige]
    Reset -->|No| End[End]

    Prestige --> Init
```

### Energy Flow

```mermaid
flowchart LR
    subgraph "Collection"
        Enemy[Defeat Enemy] --> Base[Base Energy]
        Base --> Wisdom[Apply Wisdom<br/>Multiplier]
        Wisdom --> Prestige[Apply Prestige<br/>Multiplier]
    end

    subgraph "Storage"
        Prestige --> ME[MonsterEnergy<br/>total_energy]
        ME --> Lifetime[lifetime_energy]
    end

    subgraph "Spending"
        ME --> Upgrade[Node Upgrade]
        Upgrade --> Cost[Deduct Cost]
        Cost --> ME
    end

    subgraph "UI"
        ME --> Display[Update HUD]
        Upgrade --> Refresh[Refresh Menu]
    end
```

### Stat Calculation Flow

```mermaid
flowchart TD
    subgraph "Base Stats"
        BS[Base Stats<br/>Defined in Slime]
    end

    subgraph "Node Bonuses"
        Str[Strength<br/>+Damage +Momentum]
        Con[Constitution<br/>+Health]
        Sta[Stamina<br/>+Regen]
        Agi[Agility<br/>+Speed]
        Int[Intelligence<br/>-Seek Timer]
        Wis[Wisdom<br/>+Energy Yield]
    end

    subgraph "Prestige Multiplier"
        PM[Prestige Multiplier<br/>Applies to all stats]
    end

    subgraph "Final Stats"
        FS[Effective Stats<br/>Used in gameplay]
    end

    BS --> Calc[Calculate Total]
    Str --> Calc
    Con --> Calc
    Sta --> Calc
    Agi --> Calc
    Int --> Calc
    Wis --> Calc

    Calc --> PM
    PM --> FS

    FS --> Slime[Apply to Slime]
    FS --> Combat[Use in Combat]
    FS --> UI[Display in UI]
```

---

## Signal Communication

### Signal Architecture

```mermaid
sequenceDiagram
    participant S as Slime
    participant D as Defender
    participant CM as CombatManager
    participant SB as SignalBus
    participant ME as MonsterEnergy
    participant R as Room
    participant RM as RoomManager
    participant UI as UI

    S->>D: Collision
    D->>CM: calculate_damage()
    CM->>D: take_damage()
    D->>D: health -= damage

    alt Enemy Defeated
        D->>SB: enemy_defeated
        SB->>ME: add_energy()
        ME->>SB: energy_changed
        SB->>UI: update_energy_display()
        SB->>R: check_room_clear()

        alt All Enemies Defeated
            R->>SB: room_cleared
            SB->>RM: load_next_room()
            RM->>SB: room_loaded
            SB->>UI: update_room_counter()
        end
    end
```

### Key Signals

**SignalBus Signals:**
```gdscript
# Combat
signal enemy_defeated(enemy: Defender, energy_reward: float)
signal player_damaged(damage: float, current_health: float)
signal player_died()

# Room Progression
signal room_cleared(room_index: int)
signal room_loaded(room_index: int, difficulty: float)
signal all_rooms_cleared()

# Economy
signal energy_changed(current: float, delta: float)
signal energy_spent(amount: float, item: String)
signal insufficient_energy(cost: float, current: float)

# Upgrades
signal node_upgraded(node_name: String, new_level: int)
signal connection_created(from_node: String, to_node: String)
signal stat_changed(stat_name: String, new_value: float)

# Game State
signal game_reset()
signal prestige_calculated(multiplier: float)
signal game_paused(paused: bool)
signal game_over()
signal victory()
```

---

## Integration Points

### System Dependencies

```mermaid
graph LR
    subgraph "Independent Systems"
        GL[Globals]
        SB[SignalBus]
    end

    subgraph "Core Systems"
        GM[GameManager]
        ME[MonsterEnergy]
        NS[NodeSystem]
    end

    subgraph "Gameplay Systems"
        RM[RoomManager]
        CM[CombatManager]
        PM[PhysicsManager]
    end

    subgraph "Entities"
        SL[Slime]
        DF[Defender]
    end

    subgraph "UI"
        HUD[HUD]
        UM[UpgradeMenu]
    end

    GL --> GM
    GL --> NS
    GL --> ME

    SB --> GM
    SB --> RM
    SB --> CM
    SB --> HUD
    SB --> UM

    GM --> ME
    GM --> NS
    GM --> RM

    NS --> SL
    ME --> UM

    RM --> SL
    RM --> DF

    CM --> SL
    CM --> DF
    CM --> ME

    SL --> PM
```

### Critical Integration Points

| System A | System B | Integration Type | Data Exchanged |
|----------|----------|------------------|----------------|
| Slime | CombatManager | Method Call | Collision data, damage calculation |
| CombatManager | MonsterEnergy | Signal | Energy rewards |
| MonsterEnergy | UI | Signal | Energy amount, changes |
| NodeSystem | Slime | Method Call | Stat bonuses |
| Room | RoomManager | Signal | Room cleared, load next |
| GameManager | All Systems | Method Call | Reset, save/load |
| SignalBus | All Systems | Signal | Decoupled events |

---

## File Structure Reference

### Directory Organization

```
slime-dungeon-main/
├── autoloads/              # Singleton systems
│   ├── Globals.gd
│   ├── GameManager.gd
│   ├── NodeSystem.gd
│   ├── MonsterEnergy.gd
│   └── SignalBus.gd
├── scenes/
│   ├── core/
│   │   ├── Main.tscn       # Root scene
│   │   ├── GameManager.tscn
│   │   ├── NodeSystem.tscn
│   │   └── MonsterEnergy.tscn
│   ├── entities/
│   │   ├── Slime.tscn
│   │   ├── Defender.tscn
│   │   ├── Obstacle.tscn
│   │   └── Projectile.tscn
│   ├── rooms/
│   │   ├── Room.tscn       # Template
│   │   ├── Room_01.tscn
│   │   ├── Room_02.tscn
│   │   └── ... (up to Room_40.tscn)
│   ├── systems/
│   │   ├── CombatManager.tscn
│   │   ├── PhysicsManager.tscn
│   │   └── RoomScaler.tscn
│   └── ui/
│       ├── UI.tscn
│       ├── HUD.tscn
│       ├── NodeUpgradeMenu.tscn
│       ├── ResetScreen.tscn
│       └── PauseMenu.tscn
├── scripts/
│   ├── core/
│   │   ├── BaseEntity.gd
│   │   └── Utils.gd
│   ├── entities/
│   │   ├── Slime.gd
│   │   ├── Defender.gd
│   │   ├── Obstacle.gd
│   │   └── Projectile.gd
│   ├── systems/
│   │   ├── Room.gd
│   │   ├── RoomManager.gd
│   │   ├── CombatManager.gd
│   │   └── NodeStat.gd
│   └── ui/
│       ├── HUD.gd
│       ├── NodeUpgradeMenu.gd
│       ├── ResetScreen.gd
│       └── PauseMenu.gd
├── resources/
│   ├── nodes/              # NodeStat resources
│   │   ├── Wisdom.tres
│   │   ├── Strength.tres
│   │   ├── Intelligence.tres
│   │   ├── Constitution.tres
│   │   ├── Stamina.tres
│   │   └── Agility.tres
│   ├── defenders/          # Defender configurations
│   └── configs/            # Game configuration resources
└── docs/                   # Documentation
    ├── ARCHITECTURE.md (this file)
    ├── systems/
    │   ├── PHYSICS.md
    │   ├── COMBAT.md
    │   └── NODES.md
    └── ...
```

---

## Next Steps

For detailed system designs, see:
- [Physics System Design](systems/PHYSICS.md)
- [Combat System Design](systems/COMBAT.md)
- [Core Loop Design](GAME_DESIGN.md#core-loop)
- [Progression System Design](GAME_DESIGN.md#progression-system)
- [Node System Design](systems/NODES.md)
- [Energy System Design](GAME_DESIGN.md#energy-economy)
- [Prestige System Design](GAME_DESIGN.md#prestige-system)
- [UI System Design](systems/UI.md)

