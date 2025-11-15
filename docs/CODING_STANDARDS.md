# Slime Dungeon - Coding Standards

## GDScript Style Guide

This document outlines the coding conventions and best practices for the Slime Dungeon project.

---

## File Organization

### Naming Conventions

**Files and Folders:**
- Use PascalCase for scene files: `Slime.tscn`, `GameManager.tscn`
- Use PascalCase for script files: `Slime.gd`, `GameManager.gd`
- Use lowercase with underscores for folders: `scripts/entities/`, `scenes/ui/`

**Scripts:**
- Class names match file names: `class_name Slime`
- One class per file

### File Structure

```gdscript
# Script header (optional but recommended)
# Slime.gd
# Player entity with bouncing physics

extends CharacterBody2D
class_name Slime

# === SIGNALS ===
signal enemy_defeated(enemy: Defender)
signal health_changed(current: float, max: float)

# === CONSTANTS ===
const SPEED: float = 300.0
const JUMP_VELOCITY: float = -400.0

# === EXPORTED VARIABLES ===
@export var bounce_force: float = 300.0
@export var bounciness: float = 0.8

# === PUBLIC VARIABLES ===
var velocity: Vector2 = Vector2.ZERO
var is_bouncing: bool = false

# === PRIVATE VARIABLES ===
var _momentum: float = 0.0
var _target_enemy: Defender = null

# === ONREADY VARIABLES ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# === LIFECYCLE METHODS ===
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

# === PUBLIC METHODS ===
func take_damage(amount: float) -> void:
    pass

func bounce(normal: Vector2) -> void:
    pass

# === PRIVATE METHODS ===
func _calculate_bounce_velocity(normal: Vector2) -> Vector2:
    pass

func _find_nearest_enemy() -> Defender:
    pass

# === SIGNAL CALLBACKS ===
func _on_area_entered(area: Area2D) -> void:
    pass

func _on_health_depleted() -> void:
    pass
```

---

## Naming Conventions

### Variables
```gdscript
# Use snake_case for variables
var player_health: float = 100.0
var is_alive: bool = true
var enemy_count: int = 0

# Private variables start with underscore
var _internal_state: int = 0
var _cached_position: Vector2

# Constants use UPPER_SNAKE_CASE
const MAX_HEALTH: float = 100.0
const GRAVITY: float = 980.0
```

### Functions
```gdscript
# Use snake_case for functions
func calculate_damage(base: float, defense: float) -> float:
    return max(base - defense, 0.0)

# Private functions start with underscore
func _update_internal_state() -> void:
    pass

# Boolean functions use is/has/can prefix
func is_alive() -> bool:
    return current_health > 0

func has_target() -> bool:
    return _target_enemy != null

func can_attack() -> bool:
    return is_alive() and has_target()
```

### Signals
```gdscript
# Use past tense for events that happened
signal died()
signal enemy_defeated(enemy: Defender)
signal health_changed(current: float, max: float)

# Use present tense for state changes
signal attacking(target: Node2D)
signal moving(direction: Vector2)
```

---

## Type Annotations

**Always use type annotations** for clarity and error prevention:

```gdscript
# Variables
var health: float = 100.0
var enemies: Array[Defender] = []
var config: Dictionary = {}

# Function parameters and return types
func take_damage(amount: float) -> void:
    current_health -= amount

func get_nearest_enemy() -> Defender:
    return _target_enemy

func calculate_score(base: int, multiplier: float) -> int:
    return int(base * multiplier)
```

---

## Code Style

### Indentation
- Use **tabs** (Godot default)
- Consistent indentation for readability

### Spacing
```gdscript
# Space after commas
func example(a: int, b: int, c: int) -> void:
    pass

# Space around operators
var result: int = (a + b) * c
var is_valid: bool = health > 0 and stamina > 0

# No space for unary operators
var negative: int = -5
var inverted: bool = !is_alive

# Blank lines between logical sections
func complex_function() -> void:
    var setup_value: int = 10
    
    for i in range(setup_value):
        process_item(i)
    
    finalize_processing()
```

### Line Length
- Aim for **100 characters max** per line
- Break long lines logically:

```gdscript
# Good
var long_calculation: float = (
    base_damage * multiplier 
    + bonus_damage 
    - defense_reduction
)

# Good
signal complex_event(
    entity: Node2D,
    damage: float,
    damage_type: String,
    is_critical: bool
)
```

---

## Best Practices

### Exports
```gdscript
# Group related exports
@export_group("Movement")
@export var speed: float = 300.0
@export var acceleration: float = 50.0

@export_group("Combat")
@export var damage: float = 10.0
@export var attack_range: float = 64.0

# Use export hints for better editor experience
@export_range(0, 100) var health: float = 100.0
@export_enum("Basic", "Elite", "Boss") var enemy_type: String = "Basic"
```

### Signals
```gdscript
# Define signals at the top
signal health_changed(current: float, max: float)

# Emit with descriptive parameters
func take_damage(amount: float) -> void:
    current_health -= amount
    health_changed.emit(current_health, max_health)

# Connect signals in _ready
func _ready() -> void:
    health_changed.connect(_on_health_changed)
    enemy_defeated.connect(_on_enemy_defeated)
```

### Node References
```gdscript
# Use @onready for node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer

# Cache frequently accessed nodes
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

# Use typed references
@onready var health_bar: ProgressBar = $HealthBar
```

### Error Handling
```gdscript
# Check for null before using
func attack_target() -> void:
    if _target_enemy == null:
        push_warning("No target to attack")
        return
    
    _target_enemy.take_damage(damage)

# Validate parameters
func set_health(value: float) -> void:
    if value < 0:
        push_error("Health cannot be negative")
        return
    
    current_health = clamp(value, 0, max_health)
```

---

## Comments

### When to Comment
```gdscript
# Good: Explain WHY, not WHAT
# Reduce damage by 50% during invincibility frames
var reduced_damage: float = damage * 0.5

# Bad: Obvious comment
# Set health to 100
var health: float = 100.0

# Good: Complex logic explanation
# Use quadratic easing for smooth deceleration
var eased_value: float = 1.0 - pow(1.0 - t, 2)
```

### Documentation Comments
```gdscript
## Calculates damage after applying defense reduction.
## Returns the final damage value, minimum 0.
func calculate_damage(base_damage: float, defense: float) -> float:
    return max(base_damage - defense, 0.0)
```

---

## Godot-Specific Patterns

### Physics
```gdscript
func _physics_process(delta: float) -> void:
    # Always use delta for frame-independent movement
    velocity += acceleration * delta
    
    # Use move_and_slide for CharacterBody2D
    move_and_slide()
    
    # Check collisions after movement
    for i in get_slide_collision_count():
        var collision: KinematicCollision2D = get_slide_collision(i)
        _handle_collision(collision)
```

### Signals vs Direct Calls
```gdscript
# Use signals for decoupled communication
signal enemy_defeated(enemy: Defender)

# Use direct calls for tightly coupled logic
func take_damage(amount: float) -> void:
    _update_health(amount)  # Direct call to private method
```

---

## Anti-Patterns to Avoid

```gdscript
# ❌ Don't use magic numbers
velocity.x = 300

# ✅ Use named constants
const SPEED: float = 300.0
velocity.x = SPEED

# ❌ Don't modify exported variables at runtime
@export var max_health: float = 100.0
func _ready() -> void:
    max_health = 200.0  # Bad!

# ✅ Use separate runtime variables
@export var base_max_health: float = 100.0
var max_health: float

func _ready() -> void:
    max_health = base_max_health * multiplier

# ❌ Don't use get_node in _process
func _process(delta: float) -> void:
    var sprite: Sprite2D = get_node("Sprite2D")  # Called every frame!

# ✅ Cache node references
@onready var sprite: Sprite2D = $Sprite2D

func _process(delta: float) -> void:
    sprite.modulate = Color.RED
```

