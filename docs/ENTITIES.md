# Slime Dungeon - Entities Reference

## Entity Hierarchy

```
BaseEntity (Abstract - CharacterBody2D)
├── Slime (Player)
└── Defender (Enemy)

Obstacle (StaticBody2D - separate from BaseEntity)
├── Barrel
├── Crate
└── Other environmental objects

Targeting System: Uses Godot groups
├── "seekable" group - Defenders and Obstacles that Slime can auto-seek
├── "slime" group - The player Slime entity
└── "defender" group - Enemy entities
```

---

## BaseEntity (Abstract Base Class)

**Type:** Script only (no scene)  
**Path:** `scripts/core/BaseEntity.gd`  
**Node Type:** `extends Node` (currently - should be CharacterBody2D)

### Purpose
Provides shared functionality for all game entities (Slime and Defender). Handles common stats, damage calculation, and death logic.

### Exported Variables (Planned)
```gdscript
@export var max_health: float = 100.0
@export var current_health: float = 100.0
@export var physical_damage: float = 10.0
@export var physical_defense: float = 2.0
@export var health_regen: float = 0.0
```

### Methods (Planned)
- `take_damage(amount: float)` - Apply damage with defense calculation
- `heal(amount: float)` - Restore health
- `die()` - Handle entity death
- `_process_regen(delta: float)` - Handle health regeneration

### Current Status
⚠️ **Stub implementation** - Currently empty placeholder

---

## Slime (Player Entity)

**Scene:** `scenes/entities/Slime.tscn`  
**Script:** `scripts/entities/Slime.gd`  
**Node Type:** `CharacterBody2D`

### Purpose
The player character entity, but **not** directly player-controlled. The Slime moves autonomously using physics-based bouncing and momentum. The player does **not** steer the Slime with keyboard/mouse/gamepad input; instead, they influence its effectiveness indirectly through upgrades, NodeSystem stats, and meta-progression.

### Slime Stats (MVP)

**Core Stats:**
- **Physical Damage:** Base damage dealt on collision with defenders
- **Physical Defense:** Damage reduction from defender attacks
- **Health:** Current/Maximum HP
- **Health Regen:** HP restored per second (from Stamina node)
- **Movement Speed:** Bounce speed through rooms (from Agility node)
- **Momentum:** Adds to physical damage based on velocity (from Strength node)

**Derived from NodeSystem:**
- Physical Damage: Base + Strength bonuses + Momentum
- Physical Defense: Base value (no node affects this in MVP)
- Max Health: Base + Constitution bonuses
- Health Regen: Stamina node levels
- Movement Speed: Base + Agility bonuses
- Monster Energy Yield: Wisdom node bonuses

### Exported Variables (Current)
```gdscript
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
```

### Exported Variables (Planned)
```gdscript
@export var base_physical_damage: float = 10.0
@export var base_physical_defense: float = 2.0
@export var base_max_health: float = 100.0
@export var base_movement_speed: float = 300.0
@export var bounce_force: float = 300.0
@export var bounciness: float = 0.8  # Velocity retention on bounce
@export var momentum_damage_multiplier: float = 0.1  # Converts velocity to damage
@export var auto_seek_speed: float = 50.0
@export var auto_seek_timer: float = 9.0  # Reduced by Intelligence node
@export var focus_mode_enabled: bool = false
```

### Signals (Planned)
```gdscript
signal enemy_defeated(enemy: Defender)
signal monster_energy_gained(amount: float)
signal health_changed(current: float, max: float)
signal died()
```

### Key Methods (Planned)
- `_physics_process(delta)` - Handle movement and physics
- `_handle_bounce(collision: KinematicCollision2D)` - Bounce logic
- `_handle_collision_damage(body: Node2D)` - Combat on collision
- `toggle_focus_mode()` - Enable/disable auto-targeting
- `_seek_nearest_enemy(delta)` - Auto-seek behavior

### Scene Structure
```
Slime (CharacterBody2D)
├── Sprite2D
│   └── texture: res://assets/sprites/Slime.png
│   └── scale: Vector2(0.05, 0.05)
├── CollisionShape2D (CircleShape2D)
├── Area2D - Detection zone for enemies
│   └── CollisionShape2D (CircleShape2D)
├── MomentumTrail (Line2D) - Visual momentum indicator
├── FocusIndicator (Sprite2D) - Shows target when in focus mode
└── Timer - Multipurpose timer
```

### Current Status
⚠️ **Basic platformer implementation** - Has gravity and jump, needs bouncing physics and autonomous, non-input-driven movement

### Auto-Seek Behavior

The Slime features an **autonomous targeting system** that automatically seeks objects in the room when idle. This system is completely independent of player control.

**How It Works:**

1. **Auto-Seek Timer**
   - Default duration: `9.0` seconds (configurable via `auto_seek_timer`)
   - Counts down continuously during gameplay
   - Reduced by the **Intelligence node** upgrade level

2. **Timer Reset Conditions**
   - Timer resets whenever the Slime collides with:
     - Defenders (enemies)
     - Obstacles (barrels, crates, etc.)
     - Any object in the `"seekable"` group
   - Timer does **NOT** reset when colliding with walls (TileMap collision)

3. **Seeking Behavior (Timer Expires)**
   - When timer reaches `0.0`, the Slime enters auto-seek mode
   - Finds the nearest object in the `"seekable"` group
   - Moves directly toward the target at `auto_seek_speed` (default: `50.0`)
   - Continues seeking until collision occurs (which resets the timer)

4. **Seekable Targets**
   - **Defenders** - Enemy entities (always seekable)
   - **Obstacles** - Barrels, crates, and other environmental objects
   - Any Node2D added to the `"seekable"` group

**Intelligence Node Effect:**
- Each level of Intelligence reduces `auto_seek_timer` duration
- Formula: `effective_timer = base_auto_seek_timer - (intelligence_level * reduction_per_level)`
- Higher Intelligence = more frequent auto-seeking = more aggressive Slime

**Implementation Notes:**
- Auto-seek is **not** player-controlled; it's fully autonomous
- The player influences this indirectly through Intelligence upgrades
- Seeking uses simple direct movement, not physics-based bouncing
- Once a collision occurs, normal bouncing physics resume

### Planned Features
- [x] Bouncing physics system
- [x] Momentum-based movement
- [x] Collision damage
- [ ] Auto-seek/focus mode (timer and seeking logic)
- [ ] Visual momentum trail
- [ ] Focus indicator
- [ ] Explicitly **no direct WASD/arrow/gamepad control**; movement remains fully physics-driven and autonomous

---

## Defender (Enemy Entity)

**Scene:** `scenes/entities/Defender.tscn`  
**Script:** `scripts/entities/Defender.gd`  
**Node Type:** `CharacterBody2D`

### Purpose
Stationary enemy that attacks the player when in range. Emits signals when defeated.

### Defender Stats (MVP)

**Core Stats:**
- **Health:** HP pool (scales with room number)
- **Physical Damage:** Damage dealt to slime when in attack range
- **Physical Defense:** Damage reduction from slime collisions
- **Attack Range:** Circle radius around defender (triggers attacks when slime enters)

**Behavior (MVP):**
- **Stationary:** Defenders do not move
- **Attack Trigger:** When slime enters attack range (circular area)
- **Attack Pattern:** Deals damage in circular area around themselves
- **No Abilities:** No special attacks, status effects, or elemental damage in MVP
- **Scaling:** HP, damage, and defense increase with room number
- **Seekable:** Defenders are auto-seek targets for the Slime (added to `"seekable"` group)

### Exported Variables (Planned)
```gdscript
@export var base_health: float = 50.0
@export var base_physical_damage: float = 5.0
@export var base_physical_defense: float = 1.0
@export var attack_range: float = 64.0
@export var attack_cooldown: float = 1.0
@export var defender_type: String = "basic"
@export var room_scaling_multiplier: float = 1.1  # HP/damage scale per room
```

### Signals (Planned)
```gdscript
signal defeated()
signal attacked_player(damage: float)
```

### Key Methods (Planned)
- `_ready()` - Setup attack range detection
- `_on_attack_range_body_entered(body)` - Detect player in range
- `_on_attack_range_body_exited(body)` - Player left range
- `_attack_player()` - Deal damage to player
- `die()` - Override from BaseEntity, emit defeated signal

### Scene Structure
```
Defender (CharacterBody2D)
├── Sprite2D
│   └── texture: res://assets/sprites/Rat_2.png
│   └── scale: Vector2(0.019, 0.019)
│   └── position: Vector2(0, -8)
├── CollisionShape2D (CircleShape2D) - Physics collision
├── AttackRange (Area2D) - Detection zone
│   └── CollisionShape2D (CircleShape2D)
└── HealthBar (ProgressBar) - Visual health display
    └── offset: above sprite
```

### Current Status
⚠️ **Stub implementation** - Scene exists, script is placeholder

### Planned Features
- [ ] Attack range detection
- [ ] Periodic damage to player in range
- [ ] Health bar updates
- [ ] Death animation
- [ ] Multiple defender types (variants)

---

## Obstacle (Environmental Objects)

**Scenes:** `scenes/obstacles/*.tscn` (planned)
**Scripts:** `scripts/obstacles/*.gd` (planned)
**Node Type:** `StaticBody2D` or `RigidBody2D`

### Purpose
Environmental objects that the slime bounces off of to create interesting physics-based movement patterns. Obstacles are also **seekable targets** for the Slime's auto-seek behavior.

### Obstacle Types (MVP)

**Included:**
- **Crates:** Destructible or indestructible boxes
- **Barrels:** Round objects for bouncing
- **Walls:** Room boundaries (TileMap collision - **not seekable**)

**Purpose in MVP:**
- Shape bounce patterns for strategic movement
- Create pinball-like physics gameplay
- Serve as auto-seek targets when Slime is idle
- No special effects or treasure drops in MVP

**Future (Post-MVP):**
- Treasure chests
- Fixtures (environmental energy sources)
- Breakable obstacles with rewards

### Properties (Planned)
```gdscript
@export var is_destructible: bool = false
@export var bounce_multiplier: float = 1.0  # Affects bounce strength
@export var friction: float = 0.1
```

### Groups
Obstacles should be added to the `"seekable"` group so the Slime can target them with auto-seek behavior.

```gdscript
func _ready() -> void:
    add_to_group("seekable")
```

### Current Status
⚠️ **Partially implemented** - Basic StaticBody2D exists, needs seekable group integration

---

## Entity Interaction

### Collision Layers (Planned)
```
Layer 1: World (walls, obstacles)
Layer 2: Player (Slime)
Layer 3: Enemies (Defenders)
Layer 4: Projectiles (future)
```

### Combat Mechanics (MVP)

**Collision-Based Damage:**
- Slime deals damage when bouncing into defenders
- Damage = Base Physical Damage + Momentum Bonus (from velocity)
- Defender takes damage reduced by their Physical Defense

**Defender Attacks:**
- Trigger when slime enters attack range (circular area)
- Defender deals Physical Damage to slime
- Slime takes damage reduced by their Physical Defense
- Attack has cooldown timer

**Pure Action-Based:**
- No turn-based mechanics
- No status effects in MVP
- No elemental damage in MVP
- Real-time physics-driven combat

### Damage Flow
```
Slime collides with Defender
    ↓
Calculate damage: Slime.physical_damage + momentum_bonus
    ↓
Defender.take_damage(damage - Defender.physical_defense)
    ↓
Defender health decreases
    ↓
If health <= 0: Defender.die()
    ↓
Defender.defeated signal emitted
    ↓
MonsterEnergy.add_energy(base_amount * Wisdom_multiplier)
    ↓
Room._on_defender_defeated()
```

---

## Future Entity Types (Planned)

### Defender Variants
- **Basic Rat** - Low health, low damage
- **Armored Defender** - High defense
- **Fast Attacker** - High attack speed
- **Tank** - High health, slow attack
- **Elite** - All stats increased

### Obstacles (Non-combat entities)
- **Spikes** - Static damage source
- **Barrels** - Destructible obstacles
- **Walls** - Bouncing surfaces

### Collectibles
- **Energy Orb** - Monster Energy pickup
- **Health Potion** - Restore health
- **Power-up** - Temporary buff

