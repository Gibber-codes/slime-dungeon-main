extends "res://scripts/systems/state_machine/State.gd"

var exit_target: Vector2
var speed: float

func enter(msg := {}) -> void:
	if msg.has("target"):
		exit_target = msg["target"]
	
	# Slow down to base speed to enter the door nicely
	speed = entity.base_speed

func physics_update(delta: float) -> void:
	if exit_target:
		var dir: Vector2 = (exit_target - entity.global_position).normalized()
		entity.velocity = dir * speed
	else:
		entity.velocity = Vector2.UP * speed
		
	# Just pass through (move without needing to bounce)
	entity.global_position += entity.velocity * delta
