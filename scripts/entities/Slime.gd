extends BaseEntity

## Signals
signal enemy_defeated(enemy: Node2D)
signal monster_energy_gained(amount: float)

## Movement constants and exports
@export var base_speed: float = 100.0  # Constant base movement speed
@export var max_momentum: float = 400.0  # Maximum momentum bonus
@export var momentum_gain_rate: float = 50.0  # How fast momentum builds per second
@export var momentum_speed_multiplier: float = 1.0  # What fraction of momentum adds to speed (0.0 to 1.0)

## Internal movement variables
var momentum: float = 0.0  # Current momentum value (0 to max_momentum)

## Slime-specific exported variables
@export var base_physical_damage: float = 10.0
@export var base_physical_defense: float = 2.0
@export var base_max_health: float = 100.0
@export var base_movement_speed: float = 300.0
@export var bounce_force: float = 300.0
@export var bounciness: float = 0.8  # Default bounciness when collided object has no bounciness property
@export var momentum_damage_multiplier: float = 0.1
@export var auto_seek_speed: float = 50.0
@export var auto_seek_timer: float = 9.0
@export var focus_mode_enabled: bool = false

func _ready() -> void:
	# Call parent _ready to initialize health system
	super._ready()

	# Initialize slime stats from base variables
	max_health = base_max_health
	current_health = max_health
	physical_damage = base_physical_damage
	physical_defense = base_physical_defense

	# Initialize momentum system
	momentum = 0.0

	# Add to slime group for identification
	add_to_group("slime")

	# Start moving automatically
	_initialize_random_velocity()

func _physics_process(delta: float) -> void:
	# Build momentum over time up to max_momentum
	momentum = min(momentum + momentum_gain_rate * delta, max_momentum)

	# Calculate final speed: base speed + (momentum * multiplier)
	var final_speed: float = base_speed + (momentum * momentum_speed_multiplier)

	var collision: KinematicCollision2D = move_and_collide(velocity * delta)

	if collision:
		_handle_collision_damage(collision)
		
		# Get surface bounciness before bouncing
		var collider = collision.get_collider()
		var surface_bounciness: float = bounciness
		if collider and "bounciness" in collider:
			surface_bounciness = collider.bounciness
		
		_handle_bounce(collision)
		
		# Only reduce momentum if surface isn't perfectly bouncy
		if surface_bounciness < 1.0:
			momentum = max(momentum * surface_bounciness, 0.0)
	else:
		# Maintain final speed in the direction of velocity
		velocity = velocity.normalized() * final_speed

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
	"""Handle physics bounce off surfaces using the collided object's bounciness"""
	var normal: Vector2 = collision.get_normal()
	var collider = collision.get_collider()

	# Check if the collided object has a bounciness property
	var surface_bounciness: float = bounciness  # Default fallback
	if collider and "bounciness" in collider:
		surface_bounciness = collider.bounciness

	# Store original speed for perfect bounces
	var original_speed: float = velocity.length()
	
	# Bounce using the surface's bounciness value
	velocity = velocity.bounce(normal) * surface_bounciness
	
	# For perfect bounces (1.0), ensure no speed loss
	if surface_bounciness >= 1.0:
		velocity = velocity.normalized() * original_speed

func _initialize_random_velocity() -> void:
	"""Initialize slime with random movement direction at base speed"""
	var random_angle: float = randf() * TAU
	velocity = Vector2(cos(random_angle), sin(random_angle)) * base_speed



