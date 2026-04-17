extends Node

# Entity Registry — loads all EntityData .tres files from resources/entities/
# at startup. Provides lookup by id, category, and random selection.
# Mirrors the pattern used by NodeSystem for node resources.

var _entities: Dictionary = {}  # id -> EntityData

func _ready() -> void:
	_load_all_entities()

# =============================================================================
# Loading
# =============================================================================

func _load_all_entities() -> void:
	_entities.clear()
	var dir_path := "res://resources/entities/"
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("EntityRegistry: Cannot open " + dir_path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(dir_path + file_name)
			if res is EntityData and res.id != "":
				if _entities.has(res.id):
					push_warning("EntityRegistry: duplicate id '%s' — %s overwrites previous entry" % [res.id, file_name])
				_entities[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

# =============================================================================
# Queries
# =============================================================================

## Get a specific entity definition by id
func get_entity(id: String) -> EntityData:
	return _entities.get(id, null)

## Get all entity definitions for a given category
func get_entities_by_category(cat: EntityData.Category) -> Array[EntityData]:
	var result: Array[EntityData] = []
	for key in _entities:
		if _entities[key].entity_category == cat:
			result.append(_entities[key])
	return result

## Get a random entity from a given category
func get_random_entity(cat: EntityData.Category) -> EntityData:
	var pool := get_entities_by_category(cat)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]

## Get all registered entity ids
func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _entities:
		ids.append(key)
	return ids

## Get all registered entity definitions
func get_all_entities() -> Array[EntityData]:
	var result: Array[EntityData] = []
	for key in _entities:
		result.append(_entities[key])
	return result
