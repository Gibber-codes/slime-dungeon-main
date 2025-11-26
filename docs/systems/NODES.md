# Node System Design

**Last Updated:** 2025-11-18  
**Status:** Design Complete - Ready for Implementation  
**Priority:** High (Progression System)

---

## Table of Contents
1. [Overview](#overview)
2. [Node Architecture](#node-architecture)
3. [The 6 Tier 1 Nodes](#the-6-tier-1-nodes)
4. [Connection System](#connection-system)
5. [Upgrade Mechanics](#upgrade-mechanics)
6. [File Structure](#file-structure)
7. [Implementation Steps](#implementation-steps)

---

## Overview

### Purpose
The Node System provides the primary progression mechanism through 6 upgradeable nodes that enhance the Slime's capabilities. Each node has unique effects and can be connected to other nodes via Constitution's connection system.

### Key Design Principles
- **6 Nodes Only (MVP):** Wisdom, Strength, Intelligence, Constitution, Stamina, Agility
- **Exponential Costs:** Each level costs more than the last
- **Connection System:** Constitution unlocks 1-3 connection slots
- **Persistent Connections:** Connection count survives prestige resets
- **Stat Bonuses:** Nodes provide multiplicative and additive bonuses

---

## Node Architecture

### Node Tree Diagram

> [!NOTE]
> Node Tree Diagram removed.

### Class Diagram

> [!NOTE]
> Class Diagram removed.

---

## The 6 Tier 1 Nodes

### 1. Wisdom (Energy Yield)

**Primary Effect:** Increases Monster Energy gained from defeated enemies

**Per Level Bonus:**
```
energy_multiplier = 1.0 + (wisdom_level * 0.03)

Example:
- Level 0: 1.0x (100%)
- Level 10: 1.3x (130%)
- Level 20: 1.6x (160%)
```

**Upgrade Cost:**
```
cost = 50 * (1.5 ^ current_level)

Example:
- Level 0→1: 50 energy
- Level 1→2: 75 energy
- Level 2→3: 112.5 energy
```

**Resource File:** `resources/nodes/Wisdom.tres`

**NodeStat Configuration:**
```gdscript
node_name = "wisdom"
current_level = 0
base_cost = 50.0
cost_multiplier = 1.5
effects = {
    "energy_yield": 0.03  # +3% per level
}
```

---

### 2. Strength (Damage & Momentum)

**Primary Effects:**
- Increases Physical Damage
- Increases Momentum Gain Rate

**Per Level Bonus:**
```
damage_multiplier = 1.0 + (strength_level * 0.05)
momentum_gain_multiplier = 1.0 + (strength_level * 0.04)

Example at Level 10:
- Damage: 1.5x (150%)
- Momentum Gain: 1.4x (140%)
```

**Upgrade Cost:**
```
cost = 75 * (1.5 ^ current_level)
```

**Resource File:** `resources/nodes/Strength.tres`

**NodeStat Configuration:**
```gdscript
node_name = "strength"
current_level = 0
base_cost = 75.0
cost_multiplier = 1.5
effects = {
    "physical_damage": 0.05,  # +5% per level
    "momentum_gain": 0.04     # +4% per level
}
```

---

### 3. Intelligence (Auto-Seek & Focus)

**Primary Effects:**
- Reduces Auto-Seek Timer
- Unlocks/Enhances Focus Mode

**Auto-Seek Timer:**
```
timer_reduction = intelligence_level * 0.5
effective_timer = max(base_timer - timer_reduction, 2.0)

Example:
- Level 0: 9.0 seconds
- Level 5: 6.5 seconds
- Level 10: 4.0 seconds
- Level 14+: 2.0 seconds (minimum)
```

**Focus Mode:**
```
Unlocks at Level 5
Triggers when <= 3 enemies remain in room
Effects:
- Enhanced targeting
- +20% damage (base)
- +10% speed (base)
- Additional +2% damage per Intelligence level above 5
```

**Upgrade Cost:**
```
cost = 100 * (1.5 ^ current_level)
```

**Resource File:** `resources/nodes/Intelligence.tres`

**NodeStat Configuration:**
```gdscript
node_name = "intelligence"
current_level = 0
base_cost = 100.0
cost_multiplier = 1.5
effects = {
    "auto_seek_reduction": 0.5,  # -0.5 sec per level
    "focus_unlock_level": 5,
    "focus_damage_bonus": 0.02,  # +2% per level above 5
    "focus_speed_bonus": 0.01    # +1% per level above 5
}
```

---

### 4. Constitution (Connections & Health)

**Primary Effects:**
- Unlocks Node Connection Slots
- Increases Max Health

**Connection Slots:**
```
Level 0-4: 1 connection slot
Level 5-9: 2 connection slots
Level 10+: 3 connection slots

Formula:
max_connections = 1 + floor(constitution_level / 5)
max_connections = min(max_connections, 3)
```

**Health Bonus:**
```
health_bonus = constitution_level * 10

Example:
- Level 0: +0 HP
- Level 10: +100 HP
- Level 20: +200 HP
```

**Upgrade Cost:**
```
cost = 60 * (1.5 ^ current_level)
```

**Resource File:** `resources/nodes/Constitution.tres`

**NodeStat Configuration:**
```gdscript
node_name = "constitution"
current_level = 0
base_cost = 60.0
cost_multiplier = 1.5
effects = {
    "max_health": 10.0,          # +10 HP per level
    "connection_unlock_interval": 5  # New slot every 5 levels
}
```

**Special Note:** Connection slot count persists through prestige resets!

---

### 5. Stamina (Health Regeneration)

**Primary Effect:** Increases Health Regeneration per second

**Per Level Bonus:**
```
health_regen = stamina_level * 1.0

Example:
- Level 0: 0 HP/sec
- Level 5: 5 HP/sec
- Level 10: 10 HP/sec
```

**Upgrade Cost:**
```
cost = 40 * (1.5 ^ current_level)
```

**Resource File:** `resources/nodes/Stamina.tres`

**NodeStat Configuration:**
```gdscript
node_name = "stamina"
current_level = 0
base_cost = 40.0
cost_multiplier = 1.5
effects = {
    "health_regen": 1.0  # +1 HP/sec per level
}
```

---

### 6. Agility (Movement Speed)

**Primary Effect:** Increases Movement Speed

**Per Level Bonus:**
```
speed_multiplier = 1.0 + (agility_level * 0.04)

Example:
- Level 0: 1.0x (100%)
- Level 10: 1.4x (140%)
- Level 25: 2.0x (200%)
```

**Upgrade Cost:**
```
cost = 55 * (1.5 ^ current_level)
```

**Resource File:** `resources/nodes/Agility.tres`

**NodeStat Configuration:**
```gdscript
node_name = "agility"
current_level = 0
base_cost = 55.0
cost_multiplier = 1.5
effects = {
    "movement_speed": 0.04  # +4% per level
}
```

---

## Connection System

### Connection Mechanics

**Purpose:** Connections allow nodes to share or enhance effects (future expansion)

**MVP Implementation:** Connections are cosmetic/preparatory
- Constitution unlocks 1-3 slots
- Player can connect any nodes
- Connections can be freely changed
- Connection COUNT persists through prestige
- Connection TARGETS reset on prestige

**Future (Post-MVP):** Connections could provide:
- Synergy bonuses
- Shared effects
- Unlock special abilities


