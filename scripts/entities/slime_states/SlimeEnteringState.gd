extends "res://scripts/systems/state_machine/State.gd"

var entry_target: Vector2
var speed: float

func enter(msg := {}) -> void:
	# Expects the target vector in msg
	if msg.has("target"):
		entry_target = msg["target"]
	else:
		# Fallback if no target
		entry_target = entity.global_position + Vector2.UP * 100
		
	# Slightly slower entry speed as requested
	speed = entity.current_speed * 0.7

func physics_update(delta: float) -> void:
	var dir: Vector2 = (entry_target - entity.global_position).normalized()
	entity.velocity = dir * speed
	
	# Use raw positional movement to avoid bumping into the tight doorframe and aborting early
	entity.global_position += entity.velocity * delta
	
	# If we arrived at the target point, wake up and drop into Combat
	if entity.global_position.distance_to(entry_target) < 5.0:
		state_machine.transition_to("Combat")
