class_name StateMachine
extends Node

signal transitioned(state_name: String)

@export var initial_state: NodePath
var current_state: Node

func _ready() -> void:
	var entity = get_parent()
	
	for child in get_children():
		if "state_machine" in child:
			child.state_machine = self
			child.entity = entity
			
	if initial_state.is_empty():
		return
		
	var state = get_node_or_null(initial_state)
	if state and "state_machine" in state:
		current_state = state
		current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_name):
		push_warning("StateMachine: Cannot find state " + target_state_name)
		return
		
	var target_state = get_node(target_state_name)
	if not "state_machine" in target_state:
		return
		
	if current_state:
		current_state.exit()
		
	current_state = target_state
	current_state.enter(msg)
	transitioned.emit(target_state.name)
