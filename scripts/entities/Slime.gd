
extends CharacterBody2D

const SPEED: float = 300.0
@export var bounciness: float = 1.0

signal health_changed(current: float, max_health: float)

@export var max_health: float = 100.0
var current_health: float = 100.0

func _ready():
    add_to_group("slime")
    current_health = max_health
    health_changed.emit(current_health, max_health)
    _initialize_random_velocity()  # Start moving automatically

func take_damage(amount: float):
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
    var collision: KinematicCollision2D = move_and_collide(velocity * delta)
    
    if collision:
        _handle_bounce(collision)
    
    # Maintain constant speed
    velocity = velocity.normalized() * SPEED

func _handle_bounce(collision: KinematicCollision2D) -> void:
    var normal: Vector2 = collision.get_normal()
    
    # Pure bounce first
    velocity = velocity.bounce(normal) * bounciness
    
    # THEN add random perturbation (can go either direction)
    var perturbation_angle: float = randf_range(-0.26, 0.26)
    velocity = velocity.rotated(perturbation_angle)

func _initialize_random_velocity() -> void:
    var random_angle: float = randf() * TAU
    velocity = Vector2(cos(random_angle), sin(random_angle)) * SPEED

