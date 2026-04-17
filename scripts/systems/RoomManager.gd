extends Node

# Manages room progression, loading, transitions, and difficulty scaling.
# Uses EntityRegistry to determine which entities to spawn, making it easy
# to add new entity types without touching this code.

var room_scene: PackedScene = preload("res://scenes/rooms/Room.tscn")

var current_room: Node2D = null
var current_room_index: int = 0

# Cached ref to the Main node. Found lazily on first use so we don't walk the
# tree every spawn. Cleared on reset in case the tree was rebuilt.
var _main_node: Node = null

func _ready() -> void:
	SignalBus.room_cleared.connect(_on_room_cleared)
	SignalBus.reset_triggered.connect(_on_reset)
	call_deferred("_load_initial_room")

func _get_main_node() -> Node:
	if _main_node and is_instance_valid(_main_node):
		return _main_node
	# Prefer the "main" group (set in Main.gd) — falls back to a tree walk once.
	_main_node = get_tree().get_first_node_in_group("main")
	if not _main_node:
		_main_node = get_tree().root.find_child("Main", true, false)
	return _main_node

func _load_initial_room() -> void:
	var existing_room: Node = get_tree().root.find_child("Room", true, false)
	if existing_room:
		existing_room.get_parent().remove_child(existing_room)
		existing_room.queue_free()

	current_room_index = GameManager.current_room_index
	_spawn_room(current_room_index)

func _spawn_room(index: int) -> void:
	SignalBus.room_transition_started.emit()

	if current_room and is_instance_valid(current_room):
		if current_room.has_method("deactivate"):
			current_room.deactivate()
		current_room.queue_free()
		current_room = null

	current_room = room_scene.instantiate()
	var main_node: Node = _get_main_node()
	if not main_node:
		push_error("RoomManager: Main node not found — cannot spawn room")
		return
	main_node.add_child(current_room)

	# Add extras BEFORE setup so they get counted
	_add_scaled_defenders(index)
	_add_breakables(index)

	var difficulty: float = get_room_difficulty(index)
	current_room.setup_room(index, difficulty)

	SignalBus.room_loaded.emit(index)
	SignalBus.room_transition_completed.emit()

# =============================================================================
# Entity Spawning — data-driven via EntityRegistry
# =============================================================================

func _add_scaled_defenders(index: int) -> void:
	var extra: int = index / Globals.DEFENDER_COUNT_SCALE_INTERVAL
	var defenders_root: Node2D = current_room.get_node_or_null("Defenders")
	if not defenders_root:
		return

	# Get all available defender types from the registry
	var defender_types := EntityRegistry.get_entities_by_category(EntityData.Category.DEFENDER)
	if defender_types.is_empty():
		return

	for i in range(extra):
		if defenders_root.get_child_count() >= Globals.MAX_DEFENDERS_PER_ROOM:
			break
		# Pick a random defender type and spawn it
		var data: EntityData = defender_types[randi() % defender_types.size()]
		var entity: Node = _spawn_entity(data)
		if entity:
			defenders_root.add_child(entity)

func _add_breakables(index: int) -> void:
	var defenders_root: Node2D = current_room.get_node_or_null("Defenders")
	if not defenders_root:
		return

	# Get all available object types from the registry
	var object_types := EntityRegistry.get_entities_by_category(EntityData.Category.OBJECT)
	if object_types.is_empty():
		return

	var count: int = Globals.BASE_BREAKABLES_PER_ROOM + index / 2
	count = mini(count, Globals.MAX_BREAKABLES_PER_ROOM)
	for i in range(count):
		# Pick a random breakable type
		var data: EntityData = object_types[randi() % object_types.size()]
		var entity: Node = _spawn_entity(data)
		if entity:
			defenders_root.add_child(entity)

## Instantiate an entity from its EntityData, assigning the resource to it.
func _spawn_entity(data: EntityData) -> Node:
	if not data or data.scene_path.is_empty():
		push_warning("RoomManager: EntityData '%s' has no scene_path assigned" % (data.id if data else "null"))
		return null
	var packed: PackedScene = load(data.scene_path)
	if not packed:
		push_warning("RoomManager: Could not load scene '%s' for entity '%s'" % [data.scene_path, data.id])
		return null
	var entity: Node = packed.instantiate()
	if entity.has_method("_apply_entity_data") or "entity_data" in entity:
		entity.entity_data = data
	return entity

func get_room_difficulty(index: int) -> float:
	return pow(1.05, index)

func _on_room_cleared(_room_index: int) -> void:
	current_room_index += 1
	GameManager.current_room_index = current_room_index

	if current_room_index >= Globals.TOTAL_ROOMS:
		SignalBus.all_rooms_cleared.emit()
		return

	await get_tree().create_timer(0.5).timeout
	_spawn_room(current_room_index)

func _on_reset() -> void:
	current_room_index = 0
	await get_tree().create_timer(0.1).timeout
	_spawn_room(0)
