class_name State
extends Node

# Reference to the state machine for triggering transitions
var state_machine: Node = null

# Reference to the entity this state controls
var entity: Node = null

func enter(msg := {}) -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass
