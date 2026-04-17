extends "res://scripts/systems/state_machine/State.gd"

var pre_exit_target: Vector2
var speed: float

func enter(msg := {}) -> void:
	if msg.has("target"):
		pre_exit_target = msg["target"]
	else:
		pre_exit_target = entity.global_position
		
	# Move fast towards the pre-exit point
	speed = entity.momentum_speed

func physics_update(delta: float) -> void:
	# Move strictly in a straight line directly to the target point
	var dir: Vector2 = (pre_exit_target - entity.global_position).normalized()
	entity.velocity = dir * speed
	
	# Pass straight through any remaining boxes/walls to ensure we never get stuck
	entity.global_position += entity.velocity * delta
		
	if entity.global_position.distance_to(pre_exit_target) < 15.0:
		# Arrived at the pre-exit spot, now switch to Exiting state to walk straight out
		var exit_target = pre_exit_target + Vector2.UP * 100 # Default assumption, passing through door
		state_machine.transition_to("Exiting", {"target": exit_target})
