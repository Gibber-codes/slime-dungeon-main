extends BaseEntity

## Movement constants and exports
const SPEED: float = 300.0
@export var bounciness: float = 1.0
@export var momentum_damage_multiplier: float = 0.02

func _ready() -> void:
	# Call parent _ready to initialize health system
	super._ready()

	# Set default stats for slime
	max_health = 100.0
	current_health = max_health
	physical_damage = 10.0
	physical_defense = 0.0

	# Add to slime group for identification
	add_to_group("slime")

	# Start moving automatically
	_initialize_random_velocity()

func _physics_process(delta: float) -> void:
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision:
		_handle_collision_damage(collision)
		_handle_bounce(collision)

	# Maintain constant speed
	velocity = velocity.normalized() * SPEED

func _handle_collision_damage(collision: KinematicCollision2D) -> void:
	"""Deal damage to enemies on collision based on momentum"""
	var collider = collision.get_collider()

	# Check if we hit an enemy (has take_damage method and is not a slime)
	if collider and collider.has_method("take_damage") and not collider.is_in_group("slime"):
		# Calculate momentum-based damage
		var momentum_damage: float = momentum_damage_multiplier * velocity.length()
		var total_damage: float = physical_damage + momentum_damage

		# Deal damage to the enemy
		collider.take_damage(total_damage)

func _handle_bounce(collision: KinematicCollision2D) -> void:
	"""Handle physics bounce off surfaces"""
	var normal: Vector2 = collision.get_normal()

	# Pure bounce
	velocity = velocity.bounce(normal) * bounciness

func _initialize_random_velocity() -> void:
	"""Initialize slime with random movement direction"""
	var random_angle: float = randf() * TAU
	velocity = Vector2(cos(random_angle), sin(random_angle)) * SPEED

