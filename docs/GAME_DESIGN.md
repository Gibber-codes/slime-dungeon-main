# Slime Dungeon - Design Summary

**Last Updated:** 2025-11-18  
**Purpose:** Quick reference guide to all system designs

---

## 📚 Documentation Index

### Core Documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - High-level system architecture with Mermaid diagrams
- **[ROADMAP.md](ROADMAP.md)** - Step-by-step implementation guide with time estimates
- **[STATUS.md](STATUS.md)** - Current implementation status tracking

### System Design Documents
- **[systems/PHYSICS.md](systems/PHYSICS.md)** - Autonomous movement, bouncing, momentum, auto-seek
- **[systems/COMBAT.md](systems/COMBAT.md)** - Collision-based combat, damage calculation
- **[systems/NODES.md](systems/NODES.md)** - 6 upgrade nodes with formulas and effects

### Reference Documentation
- **[README.md](README.md)** - Project information and game concept
- **[ENTITIES.md](ENTITIES.md)** - Entity hierarchy and specifications
- **[SYSTEMS.md](SYSTEMS.md)** - System responsibilities and interfaces
- **[CODING_STANDARDS.md](CODING_STANDARDS.md)** - GDScript style guide

---

## 🎮 Core Game Design

### Unique Selling Point
**Autonomous Physics-Based Dungeon Crawler**
- Player does NOT control slime direction
- Slime bounces automatically using physics
- Player influences through upgrades and strategy
- Incremental/idle game meets physics puzzler

### Core Loop
```
Slime bounces → Collides with enemies → Deals damage → Enemy dies
→ Collect energy → Upgrade nodes → Slime gets stronger → Progress rooms
→ Reach room 40 or die → Reset with prestige bonus → Repeat stronger
```

### Key Mechanics
1. **Bouncing Physics** - Slime bounces off walls, obstacles, enemies
2. **Momentum System** - Speed builds up, increases damage
3. **Auto-Seek** - After 9 seconds, targets nearest enemy/obstacle
4. **Node Upgrades** - 6 nodes enhance different aspects
5. **Prestige Reset** - Reset for permanent multiplier bonus

---

## 🏗️ System Architecture

### Autoload Singletons (5)

| Singleton | Purpose | Key Responsibilities |
|-----------|---------|---------------------|
| **Globals** | Configuration | Enums, constants, config values |
| **GameManager** | Game State | State management, prestige, save/load |
| **NodeSystem** | Upgrades | 6 nodes, connections, stat bonuses |
| **MonsterEnergy** | Currency | Energy collection, spending, tracking |
| **SignalBus** | Events | Decoupled communication between systems |

### Core Systems

| System | Type | Purpose |
|--------|------|---------|
| **RoomManager** | Scene Manager | Load rooms, transitions, difficulty scaling |
| **CombatManager** | Calculator | Damage calculation, combat resolution |
| **PhysicsManager** | Helper (Optional) | Bounce calculations, target finding |

### Entities

| Entity | Base Class | Role |
|--------|------------|------|
| **Slime** | BaseEntity (CharacterBody2D) | Player character, autonomous movement |
| **Defender** | BaseEntity (CharacterBody2D) | Enemy, stationary attacks |
| **Obstacle** | StaticBody2D | Environmental objects, seekable targets |

---

## ⚙️ Physics System

### Movement States
1. **Bouncing** - Normal physics-based movement
2. **Seeking** - Direct movement toward target
3. **Idle** - Low velocity, momentum decaying

### Key Formulas

**Bounce Reflection:**
```
v_reflected = v - 2 * (v · n) * n
v_final = v_reflected * bounciness (0.8)
```

**Momentum:**
```
Gain: momentum += gain_rate * delta * velocity_factor
Decay: momentum -= decay_rate * delta
Damage Bonus: bonus = momentum * 0.1
```

**Auto-Seek:**
```
Base Timer: 9.0 seconds
Intelligence Reduction: -0.5 sec per level
Minimum: 2.0 seconds
```

---

## ⚔️ Combat System

### Damage Formulas

**Slime Damage:**
```
base = slime.physical_damage
node_bonus = NodeSystem.get_stat_bonus("physical_damage")
momentum_bonus = slime.momentum * 0.1
prestige_mult = GameManager.reset_multiplier

total = (base + node_bonus + momentum_bonus) * prestige_mult
final = max(total - defender.defense, 1.0)
```

**Defender Damage:**
```
base = defender.physical_damage
scaling = defender.room_scaling_multiplier ^ room_number
total = base * scaling
final = max(total - slime.defense, 1.0)
```

### Combat Flow
1. Slime collides with Defender
2. CombatManager calculates damage
3. Defender takes damage
4. If health <= 0, Defender dies
5. MonsterEnergy rewards granted
6. Room checks if all enemies defeated
7. If yes, room clears and loads next

---

## 📈 Node System (6 Nodes)

### Node Effects

| Node | Primary Effect | Formula | Base Cost |
|------|---------------|---------|-----------|
| **Wisdom** | Energy Yield | +3% per level | 50 |
| **Strength** | Damage & Momentum | +5% damage, +4% momentum | 75 |
| **Intelligence** | Auto-Seek Timer | -0.5 sec per level (min 2.0) | 100 |
| **Constitution** | Connections & Health | +1 slot per 5 levels, +10 HP | 60 |
| **Stamina** | Health Regen | +1 HP/sec per level | 40 |
| **Agility** | Movement Speed | +4% per level | 55 |

### Upgrade Cost Formula
```
cost = base_cost * (1.5 ^ current_level)

Example (Wisdom):
Level 0→1: 50
Level 1→2: 75
Level 2→3: 112.5
Level 3→4: 168.75
```

### Connection System
- Constitution unlocks 1-3 connection slots
- Connections are cosmetic in MVP (future: synergy bonuses)
- Connection COUNT persists through prestige
- Connection TARGETS reset on prestige

---

## 🔄 Prestige System

### Reset Mechanics

**When:** Player manually resets or dies

**Multiplier Formula:**
```
multiplier = 1.0 + (lifetime_energy / 10000.0)

Example:
- 10,000 energy: 2.0x multiplier
- 50,000 energy: 6.0x multiplier
- 100,000 energy: 11.0x multiplier
```

**What Resets:**
- ✅ Node levels → 0
- ✅ Current energy → 0
- ✅ Room progress → Room 1
- ✅ Slime health → Full
- ✅ Node connections (targets)

**What Persists:**
- ✅ Prestige multiplier
- ✅ Lifetime energy total
- ✅ Connection slot count (from Constitution)
- ✅ Total reset count

**Multiplier Effect:**
- Applies to all energy gains
- Applies to base stats (optional)
- Stacks with node bonuses

---

## 🎯 Progression System

### Room Progression
- **Total Rooms:** 40
- **Difficulty Scaling:** Exponential
- **Victory Condition:** Clear Room 40

**Difficulty Formula:**
```
difficulty = 1.0 + (room_number * 0.1)
enemy_health *= difficulty
enemy_damage *= difficulty
enemy_count = base_count + floor(room_number / 5)
```

### Energy Economy

**Sources:**
- Defeating Defenders (base amount * Wisdom * Prestige)

**Sinks:**
- Node upgrades (exponential cost)

**Balance Target:**
- First reset: ~10-15 minutes (Room 8-12)
- Second reset: ~8-12 minutes (Room 15-20)
- Each reset should feel meaningfully faster

---

## 📁 File Structure

### Key Files to Implement

**Autoloads (Critical):**
```
autoloads/Globals.gd          - Configuration
autoloads/GameManager.gd      - Game state
autoloads/NodeSystem.gd       - Upgrades
autoloads/MonsterEnergy.gd    - Currency
autoloads/SignalBus.gd        - Events
```

**Entities (Critical):**
```
scripts/core/BaseEntity.gd    - Health/damage base
scripts/entities/Slime.gd     - Player physics
scripts/entities/Defender.gd  - Enemy AI
```

**Systems (High Priority):**
```
scripts/systems/Room.gd           - Room logic
scripts/systems/RoomManager.gd    - Progression
scripts/systems/CombatManager.gd  - Damage calc
scripts/systems/NodeStat.gd       - Node resource
```

**UI (High Priority):**
```
scripts/ui/HUD.gd                - Health/energy display
scripts/ui/NodeUpgradeMenu.gd    - Upgrade interface
scripts/ui/ResetScreen.gd        - Prestige UI
```

**Resources (Medium Priority):**
```
resources/nodes/Wisdom.tres
resources/nodes/Strength.tres
resources/nodes/Intelligence.tres
resources/nodes/Constitution.tres
resources/nodes/Stamina.tres
resources/nodes/Agility.tres
```

---

## 🧪 Testing Strategy

### Test Scenes
- **tests/TestBounce.tscn** - Physics and movement
- **tests/TestCombat.tscn** - Combat and damage
- **tests/TestUI.tscn** - UI updates and signals

### Critical Test Cases
1. ✅ Slime bounces without player input
2. ✅ Auto-seek activates after timer
3. ✅ Collision deals damage correctly
4. ✅ Enemies die and grant energy
5. ✅ Room clears when all enemies defeated
6. ✅ Nodes upgrade and apply bonuses
7. ✅ Prestige calculates multiplier correctly
8. ✅ Reset restores game state properly

---

## ⏱️ Implementation Timeline

### Phase 1: Foundation (2-3 hours)
- BaseEntity health system
- Globals configuration
- SignalBus setup

### Phase 2: Core Gameplay (28-35 hours)
- Physics system (8-10 hours)
- Combat system (10-12 hours)
- Room system (6-8 hours)
- Basic UI (4-5 hours)

### Phase 3: Progression (43-50 hours)
- MonsterEnergy (5-6 hours)
- NodeSystem (16-18 hours)
- RoomManager (12-14 hours)
- Prestige system (10-12 hours)

### Phase 4: Polish (41-52 hours)
- Visual effects (10-12 hours)
- Audio system (8-10 hours)
- Balance tuning (15-20 hours)
- Save/load (8-10 hours)

**Total: 114-140 hours (14-18 days)**  
**MVP (Phases 1-3): 73-88 hours (9-11 days)**

---

## 🚀 Quick Start Guide

### For Developers

1. **Read Documentation:**
   - Start with [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)
   - Review [IMPLEMENTATION_ROADMAP.md](IMPLEMENTATION_ROADMAP.md)
   - Check [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)

2. **Begin Implementation:**
   - Follow roadmap Phase 1 → Phase 2 → Phase 3
   - Test frequently using test scenes
   - Commit after each major milestone

3. **Key Principles:**
   - NO player control of slime direction
   - Physics-driven autonomous movement
   - Signal-based communication
   - Exponential progression curves

### For Designers

1. **Balance Tuning:**
   - Adjust node costs in NodeStat resources
   - Modify difficulty curve in RoomManager
   - Tweak prestige formula in GameManager

2. **Content Creation:**
   - Design 40 room layouts
   - Create defender variants
   - Design obstacle placements

---

## 📊 Mermaid Diagrams Available

All system design documents include interactive Mermaid diagrams:

- **Architecture Overview:** System component relationships
- **Physics System:** Movement state machine, bounce flow
- **Combat System:** Damage calculation flow, combat sequence
- **Node System:** Node tree, upgrade flow
- **Game Loop:** Main game flow, data flow

View diagrams in the respective system design documents.

---

## 🎓 Design Decisions

### Why Autonomous Movement?
- Unique gameplay differentiator
- Reduces player skill ceiling (accessibility)
- Creates emergent physics-based gameplay
- Fits incremental/idle game genre
- Makes upgrades feel more impactful

### Why 6 Nodes Only?
- Focused progression for MVP
- Each node has clear purpose
- Easier to balance
- Room for expansion (Tier 2+ post-MVP)

### Why Collision-Based Combat?
- Synergizes with physics movement
- Momentum matters (risk/reward)
- Real-time action feel
- Simple to understand

### Why Prestige System?
- Encourages strategic resets
- Provides long-term progression
- Solves difficulty wall problem
- Adds replayability

---

## 📝 Next Steps

1. ✅ Review all documentation
2. ⬜ Set up task tracking
3. ⬜ Begin Phase 1 implementation
4. ⬜ Test each system as completed
5. ⬜ Iterate based on playtesting
6. ⬜ Balance and polish
7. ⬜ Release MVP

---

**For Questions or Clarifications:**
- Refer to specific system design documents
- Check implementation roadmap for dependencies
- Review architecture overview for integration points
- Consult coding standards for style guidelines

