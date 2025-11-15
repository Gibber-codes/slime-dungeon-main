# Slime Dungeon - Project Overview

## Project Information

**Project Name:** Slime Dungeon
**Godot Version:** 4.5.1 (GL Compatibility)
**Language:** GDScript
**Genre:** 2D Physics-Based Incremental/Idle Dungeon Crawler (autonomous movement)
**Main Scene:** `res://scenes/core/Main.tscn`
**MVP Version:** 1.0 (Ready for Beta Testing)
**MVP Date:** November 11, 2025

## Game Concept

Slime Dungeon is a physics-based dungeon crawler where a bouncing slime moves **autonomously** through procedurally generated rooms filled with defenders (enemies) and obstacles. The player does **not** directly control the slime; instead, they influence its power and progression via upgrades, NodeSystem stats, and prestige/meta systems. The game features:

- **Bouncing Physics**: Core movement mechanic based on momentum and collision
- **Room Progression**: 40 rooms with increasing difficulty
- **Combat System**: Collision-based damage between slime and defenders
- **Prestige/Reset System**: Reset with multipliers for meta-progression
- **Monster Energy**: Currency system for upgrades and progression

## Core Gameplay Loop

1. **Watch the Slime Navigate**: The slime moves and bounces **automatically** using physics (no direct WASD/arrow/gamepad control).
2. **Defeat Defenders**: The slime collides with enemies to damage them based on its stats and momentum.
3. **Clear Room**: When all defenders are defeated, the room is cleared and the exit unlocks.
4. **Progress**: Advance to the next room with increased difficulty.
5. **Collect Energy**: Gather Monster Energy from defeated enemies.
6. **Upgrade**: Spend energy on permanent upgrades and NodeSystem stats via menus (this is the primary form of player interaction).
7. **Reset**: Optional prestige reset for multipliers and long-term incremental progression.

> **Design Note:** Slime Dungeon plays more like a **physics-based incremental/idle game** than a traditional action game. The player focuses on upgrades, builds, and meta choices rather than direct character movement.

## Target Platforms

- **Primary**: Windows (GL Compatibility renderer)
- **Potential**: Linux, macOS, Web (HTML5)

## Development Status

**Current Phase:** Early Development / MVP  
**Status:** Core structure in place, implementing game mechanics

See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for detailed progress tracking.

## MVP Scope (Version 1.0)

### Included in MVP
- ✅ **6 Tier 1 Nodes Only**: Wisdom, Strength, Intelligence, Constitution, Stamina, Agility
- ✅ **Physical Damage/Defense Only**: No elemental damage types
- ✅ **40 Rooms Maximum**: Difficulty scales progressively
- ✅ **Active Play Only**: No offline/idle progression for MVP
- ✅ **Collision-Based Combat**: Slime bounces into stationary defenders
- ✅ **Monster Energy System**: Currency for node upgrades
- ✅ **Reset/Prestige System**: Permanent multipliers based on total energy collected
- ✅ **Node Upgrade System**: Exponential cost scaling (Base Cost × Multiplier ^ Level)
- ✅ **Auto-Seek Mechanic**: Intelligence node unlocks automatic targeting
- ✅ **Focus Mode**: Intelligence node triggers enhanced state when few enemies remain
- ✅ **Node Connections**: Constitution node provides 1-3 connection slots

### Explicitly Removed from MVP (Future Updates)
- ❌ **Frenzy System**
- ❌ **Elemental Core** (Fire/Ice/Lightning damage)
- ❌ **Status Effects** (Burn, Freeze, Shock, Bleed, etc.)
- ❌ **Size Mechanics** (Slime growth/shrinkage)
- ❌ **Tier 2+ Nodes**
- ❌ **Heroes/Companions**
- ❌ **Treasure Chests/Loot**
- ❌ **Fixtures** (environmental energy sources)
- ❌ **Initiative System**
- ❌ **Offline/Idle Progression**
- ❌ **Rooms Beyond 40**

## Balance Targets (MVP)

- **First Reset**: ~10-15 minutes of play (room 8-12)
- **Second Reset**: ~8-12 minutes (room 15-20)
- **Node Balance**: All 6 nodes should feel valuable and worth upgrading
- **Progression Feel**: Meaningful power increase per reset
- **Reset Timing**: Players should feel encouraged to reset around room 10 initially

## Project Goals

1. **Fun Physics**: Satisfying bouncing mechanics that feel responsive
2. **Strategic Depth**: Meaningful choices in upgrades and combat
3. **Replayability**: Prestige system encourages multiple runs
4. **Polish**: Juice and feedback for all player actions
5. **Accessibility**: Easy to learn, hard to master

## References

- [ARCHITECTURE.md](ARCHITECTURE.md) - System design and folder structure
- [ENTITIES.md](ENTITIES.md) - Entity documentation
- [SYSTEMS.md](SYSTEMS.md) - Game systems and managers
- [CODING_STANDARDS.md](CODING_STANDARDS.md) - Code conventions
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) - Development progress

