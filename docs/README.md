# Slime Dungeon - Documentation

Welcome to the Slime Dungeon project documentation! This directory contains comprehensive reference materials for understanding and working with the codebase.

**MVP Version:** 1.0 (Ready for Beta Testing)
**MVP Date:** November 11, 2025

---

## 📚 Documentation Index

### [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
High-level overview of the Slime Dungeon project including:
- Project information and goals
- **MVP scope and removed features**
- **Balance targets for MVP**
- Game concept and core gameplay loop
- Development status and roadmap
- Key features and phases

**Start here** if you're new to the project!

---

### [ARCHITECTURE.md](ARCHITECTURE.md)
Technical architecture and project structure:
- Complete folder structure breakdown
- Scene hierarchy diagrams
- System architecture overview
- Signal flow and data flow
- Resource architecture

**Use this** to understand how the project is organized.

---

### [ENTITIES.md](ENTITIES.md)
Detailed documentation of all game entities:
- BaseEntity (abstract base class)
- Slime (player entity with **detailed stat list**)
- Defender (enemy entity with **stationary behavior and attack ranges**)
- **Obstacle (environmental objects for bouncing)**
- **Combat mechanics (collision-based damage)**
- Entity interaction and collision
- Future entity types

**Reference this** when working with game entities.

---

### [SYSTEMS.md](SYSTEMS.md)
Game systems and managers documentation:
- GameManager (game state and reset/prestige system)
- RoomManager (room progression)
- **NodeSystem (6 Tier 1 nodes with detailed mechanics)**
- MonsterEnergy (currency system)
- Room (individual room logic)
- UI System
- System communication patterns

**Reference this** when working with game systems.

---

### [CODING_STANDARDS.md](CODING_STANDARDS.md)
GDScript coding conventions and best practices:
- File organization and naming
- Code style and formatting
- Type annotations
- Best practices and patterns
- Anti-patterns to avoid

**Follow this** when writing code for the project.

---

### [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)
Current implementation status tracker:
- Feature completion status
- **Features removed from MVP (out of scope)**
- System-by-system breakdown
- Priority roadmap
- Known issues

**Check this** to see what's done and what needs work.

---

## 🎯 Quick Start Guide

### For AI Assistants
When helping with this project, please:

1. **Read PROJECT_OVERVIEW.md first** to understand the game concept
2. **Check IMPLEMENTATION_STATUS.md** to see what's already done
3. **Reference ARCHITECTURE.md** to understand the structure
4. **Follow CODING_STANDARDS.md** when writing code
5. **Consult ENTITIES.md or SYSTEMS.md** for specific implementation details

### For Developers
1. Review all documentation files to understand the project
2. Check IMPLEMENTATION_STATUS.md for current priorities
3. Follow CODING_STANDARDS.md when contributing
4. Update documentation when making significant changes

---

## 🔄 Keeping Documentation Updated

When making changes to the project:

- **New Features**: Update IMPLEMENTATION_STATUS.md
- **Architecture Changes**: Update ARCHITECTURE.md
- **New Entities/Systems**: Update ENTITIES.md or SYSTEMS.md
- **Code Patterns**: Update CODING_STANDARDS.md if introducing new patterns
- **Major Milestones**: Update PROJECT_OVERVIEW.md roadmap

---

## 📋 Document Relationships

```
PROJECT_OVERVIEW.md (Start Here)
    ├── ARCHITECTURE.md (How it's built)
    │   ├── ENTITIES.md (Game objects)
    │   └── SYSTEMS.md (Game logic)
    ├── CODING_STANDARDS.md (How to write code)
    └── IMPLEMENTATION_STATUS.md (What's done/todo)
```

---

## 🛠️ Project Information

**Godot Version:** 4.5.1  
**Language:** GDScript  
**Project Type:** 2D Dungeon Crawler / Roguelike  

**Main Scene:** `res://scenes/core/Main.tscn`  
**Godot Executable:** `c:\Users\gabri\OneDrive\Documents\godot\Godot_v4.5.1-stable_win64.exe`

---

## 📝 Notes for AI Context

This documentation is designed to provide comprehensive context for AI assistants working on the Slime Dungeon project. Each document serves a specific purpose:

- **PROJECT_OVERVIEW.md** - What we're building and why
- **ARCHITECTURE.md** - How everything fits together
- **ENTITIES.md** - Detailed entity specifications
- **SYSTEMS.md** - Detailed system specifications
- **CODING_STANDARDS.md** - How to write consistent code
- **IMPLEMENTATION_STATUS.md** - Current state of development

When asked to work on a feature, AI assistants should:
1. Check if it exists in IMPLEMENTATION_STATUS.md
2. Review relevant sections in ENTITIES.md or SYSTEMS.md
3. Follow patterns from CODING_STANDARDS.md
4. Understand the architecture from ARCHITECTURE.md
5. Update documentation after making changes

---

## 🎮 Game Concept Summary

Slime Dungeon is a physics-based dungeon crawler where you control a bouncing slime through 40 rooms of increasing difficulty. Defeat defenders, collect Monster Energy, purchase upgrades, and use the prestige system to become stronger with each reset.

**Core Mechanic:** Bouncing physics-based movement  
**Goal:** Clear all 40 rooms  
**Progression:** Monster Energy → Upgrades → Prestige Resets

---

## 📞 Additional Resources

- **Setup Script:** `setup_slime_dungeon.ps1` - Original project setup
- **Note Files:** Various `.txt` files in `scripts/` folders contain design notes
- **Project Config:** `project.godot` - Godot project settings

---

**Last Updated:** 2025-11-13

