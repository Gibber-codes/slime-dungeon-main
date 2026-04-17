extends "res://scripts/systems/state_machine/State.gd"

func enter(msg := {}) -> void:
	# Initialize combat movement with a random direction
	entity._initialize_random_velocity()
	
	# Close the entry door behind us
	var rooms = entity.get_tree().get_nodes_in_group("rooms")
	if rooms.size() > 0 and rooms[0].has_method("close_entry_door"):
		rooms[0].close_entry_door()

func physics_update(delta: float) -> void:
	entity._process_auto_seek(delta)
	entity._check_focus_mode()

	# Calculate actual speed: base speed + momentum bonus
	var speed_bonus: float = entity.slime_data.max_speed_bonus * entity.momentum
	entity.momentum_speed = entity.current_speed * (1.0 + speed_bonus)

	var collision: KinematicCollision2D = entity.move_and_collide(entity.velocity * delta)

	if collision:
		entity._handle_collision_damage(collision)
		entity._handle_bounce(collision)

	entity.velocity = entity.velocity.normalized() * entity.momentum_speed

	# Safety net: clamp slime inside the current room boundaries
	entity._clamp_to_room_bounds()
