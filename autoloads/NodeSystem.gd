extends Node

# Node upgrade system — hierarchical tree: Core → T1 → T2 → T3
# Energy flows from Core through connections into nodes.
# Each node fills up over time. At threshold capacity, click to upgrade.
# Node definitions are loaded from .tres files in resources/nodes/.

var _nodes: Dictionary = {}  # id -> NodeStat (definition, immutable)
var _children: Dictionary = {}  # parent_id -> Array of child IDs

# Runtime state kept off the resource so .tres files on disk never drift
# and the same resource instance is safe to share.
var _levels: Dictionary = {}  # id -> int
var _fills: Dictionary = {}   # id -> float

# Connections: nodes with active connections to their parent.
# Each entry uses 1 connection slot from the shared pool.
var connections: Array = []

# Energy flow (Adjust in Inspector if added as Scene Autoload)
@export_group("Energy Flow")
@export var flow_rate_per_connection: float = 3.0
@export var flow_rate_tier_mult: float = 0.8
@export var upgrade_threshold: float = 0.9

# Intelligence constants
const INTELLIGENCE_BASE_SEEK_TIME := 9.0

# T1 node order for layout (hex around core)
const T1_ORDER: Array[String] = [
	"constitution", "intelligence", "agility",
	"strength", "wisdom", "stamina",
]

func _ready() -> void:
	_load_all_nodes()
	_build_children_lists()
	SignalBus.reset_triggered.connect(_on_reset)

func _process(delta: float) -> void:
	_flow_energy(delta)

# =============================================================================
# Node Loading — from .tres resources
# =============================================================================

func _load_all_nodes() -> void:
	_nodes.clear()
	_levels.clear()
	_fills.clear()
	var dir_path := "res://resources/nodes/"
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("NodeSystem: Cannot open " + dir_path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(dir_path + file_name)
			if res is NodeStat and res.id != "":
				if _nodes.has(res.id):
					push_warning("NodeSystem: duplicate id '%s' — %s overwrites previous entry" % [res.id, file_name])
				_nodes[res.id] = res
				_levels[res.id] = 0
				_fills[res.id] = 0.0
		file_name = dir.get_next()
	dir.list_dir_end()

func _build_children_lists() -> void:
	_children.clear()
	for id in _nodes:
		var pid: String = _nodes[id].parent_id
		if pid != "":
			if not _children.has(pid):
				_children[pid] = []
			_children[pid].append(id)

func get_node_children(node_name: String) -> Array:
	return _children.get(node_name.to_lower(), [])

# =============================================================================
# Bonus Aggregation
# =============================================================================

func get_all_bonuses() -> Dictionary:
	var result := {}
	for id in _nodes:
		var stat: NodeStat = _nodes[id]
		var b := NodeEffects.get_bonus(stat, _levels.get(id, 0))
		for key in b:
			result[key] = result.get(key, 0.0) + b[key]
	return result

# =============================================================================
# Energy Flow
# =============================================================================

func get_node_tier(node_name: String) -> int:
	# Reads the exported tier field — no recursion needed.
	var stat: NodeStat = get_node_stat(node_name)
	if not stat:
		return 1
	return stat.tier

func _flow_energy(delta: float) -> void:
	if connections.is_empty():
		return
	if MonsterEnergy.current_energy <= 0.0:
		pass # We still process flow between nodes even if core is empty.

	# Allow Thought node to speed up flow
	var bonuses := get_all_bonuses()
	var flow_mult: float = 1.0 + bonuses.get("flow_speed_mult", 0.0)

	for node_name in connections:
		if not is_receiving_energy(node_name):
			continue
		var stat: NodeStat = get_node_stat(node_name)
		if not stat:
			continue
		var node_capacity: float = get_upgrade_cost(node_name)
		var cur_fill: float = _fills.get(node_name, 0.0)
		if cur_fill >= node_capacity:
			continue

		var rate_for_tier: float = flow_rate_per_connection * flow_mult * delta * pow(flow_rate_tier_mult, stat.tier - 1)
		var room_left: float = node_capacity - cur_fill
		var available: float = 0.0

		# Determine where we are pulling from
		if stat.parent_id == "":
			# Tier 1 nodes pull from Core
			available = minf(rate_for_tier, MonsterEnergy.current_energy)
			var transfer: float = minf(available, room_left)
			if transfer > 0:
				MonsterEnergy.current_energy -= transfer
				_fills[node_name] = cur_fill + transfer
				SignalBus.energy_changed.emit(MonsterEnergy.current_energy, -transfer)
		else:
			# Tier 2+ nodes pull from Parent
			var parent_fill: float = _fills.get(stat.parent_id, 0.0)
			if parent_fill > 0.0:
				available = minf(rate_for_tier, parent_fill)
				var transfer: float = minf(available, room_left)
				if transfer > 0:
					_fills[stat.parent_id] = parent_fill - transfer
					_fills[node_name] = cur_fill + transfer

# =============================================================================
# Connection System
# =============================================================================

func get_max_connections() -> int:
	# Base 1 slot + Constitution thresholds + Balance levels
	var bonuses := get_all_bonuses()
	return 1 + int(bonuses.get("connection_slots", 0.0))

func is_connected_to_core(node_name: String) -> bool:
	return node_name.to_lower() in connections

func is_receiving_energy(node_name: String) -> bool:
	node_name = node_name.to_lower()
	if not is_connected_to_core(node_name):
		return false
	var stat: NodeStat = get_node_stat(node_name)
	if not stat:
		return false
	if stat.parent_id == "":
		return true
	return is_receiving_energy(stat.parent_id)

func connect_to_core(node_name: String) -> bool:
	node_name = node_name.to_lower()
	var stat: NodeStat = get_node_stat(node_name)
	if not stat or not stat.is_implemented:
		return false
	if node_name in connections:
		return false
	if connections.size() >= get_max_connections():
		return false
	if stat.parent_id != "":
		# Parent must be connected AND invested in (level >= 1) before children can draw energy.
		if not is_connected_to_core(stat.parent_id):
			return false
		if _levels.get(stat.parent_id, 0) < 1:
			return false
	connections.append(node_name)
	SignalBus.stats_changed.emit()
	return true

func disconnect_from_core(node_name: String) -> bool:
	node_name = node_name.to_lower()
	var idx: int = connections.find(node_name)
	if idx == -1:
		return false
	connections.remove_at(idx)
	_cascade_disconnect(node_name)
	SignalBus.stats_changed.emit()
	return true

func _cascade_disconnect(parent_name: String) -> void:
	var child_ids: Array = get_node_children(parent_name)
	for child_id in child_ids:
		if child_id in connections:
			connections.erase(child_id)
			_cascade_disconnect(child_id)

# =============================================================================
# Node Queries
# =============================================================================

func get_node_stat(node_name: String) -> NodeStat:
	return _nodes.get(node_name.to_lower(), null)

func get_node_level(node_name: String) -> int:
	return _levels.get(node_name.to_lower(), 0)

func get_upgrade_cost(node_name: String) -> float:
	var stat: NodeStat = get_node_stat(node_name)
	if not stat:
		return INF
	var lvl: int = _levels.get(stat.id, 0)
	return stat.base_cost * pow(stat.cost_multiplier, lvl)

func get_node_fill(node_name: String) -> float:
	return _fills.get(node_name.to_lower(), 0.0)

func get_fill_ratio(node_name: String) -> float:
	var node_capacity: float = get_upgrade_cost(node_name)
	if node_capacity <= 0:
		return 0.0
	return get_node_fill(node_name) / node_capacity

func is_level_capped(node_name: String) -> bool:
	var stat: NodeStat = get_node_stat(node_name)
	if not stat or stat.parent_id == "":
		return false
	var parent: NodeStat = get_node_stat(stat.parent_id)
	if not parent:
		return false
	return _levels.get(stat.id, 0) >= _levels.get(parent.id, 0)

func is_upgrade_ready(node_name: String) -> bool:
	var stat: NodeStat = get_node_stat(node_name)
	if not stat or not stat.is_implemented:
		return false
	if is_level_capped(node_name):
		return false
	return get_fill_ratio(node_name) >= upgrade_threshold

func can_upgrade(node_name: String) -> bool:
	return is_upgrade_ready(node_name)

func upgrade_node(node_name: String) -> bool:
	if not is_upgrade_ready(node_name):
		return false
	var stat: NodeStat = get_node_stat(node_name)
	var req_fill: float = get_upgrade_cost(node_name) * upgrade_threshold
	var new_fill: float = _fills.get(stat.id, 0.0) - req_fill
	if new_fill < 0.0:
		new_fill = 0.0
	_fills[stat.id] = new_fill
	var new_level: int = _levels.get(stat.id, 0) + 1
	_levels[stat.id] = new_level
	SignalBus.node_upgraded.emit(node_name, new_level)
	SignalBus.stats_changed.emit()
	return true

func get_node_names() -> Array[String]:
	var names: Array[String] = []
	for key in _nodes:
		names.append(key)
	return names

# =============================================================================
# Convenience — Intel-specific (read from .tres data)
# =============================================================================

func get_seek_time() -> float:
	var lvl := float(get_node_level("intelligence"))
	return 3.0 + 6.0 * pow(0.90, lvl)

func get_focus_threshold() -> int:
	var lvl := float(get_node_level("focus"))
	if lvl <= 0.0:
		return 0
	return int(floor((-1.0 + sqrt(1.0 + 8.0 * lvl)) / 2.0))

# =============================================================================
# Reset
# =============================================================================

func reset_all_nodes() -> void:
	for key in _nodes:
		_levels[key] = 0
		_fills[key] = 0.0
	connections.clear()
	SignalBus.stats_changed.emit()

# =============================================================================
# Testing helpers (public API so UI doesn't poke private state)
# =============================================================================

## Unlock every implemented node to level 1 and auto-connect it.
## Used by the Settings/cheats panel — do not call from gameplay code.
func unlock_all_for_testing() -> void:
	for key in _nodes:
		var stat: NodeStat = _nodes[key]
		if stat.is_implemented:
			_levels[key] = maxi(1, _levels.get(key, 0))
			if not connections.has(key):
				connections.append(key)
	SignalBus.stats_changed.emit()

func _on_reset() -> void:
	reset_all_nodes()

# =============================================================================
# Save/Load
# =============================================================================

func get_save_data() -> Dictionary:
	var levels: Dictionary = {}
	var fills: Dictionary = {}
	for key in _nodes:
		var lvl: int = _levels.get(key, 0)
		var fl: float = _fills.get(key, 0.0)
		if lvl > 0 or fl > 0.0:
			levels[key] = lvl
			fills[key] = fl
	return {"levels": levels, "fills": fills, "connections": connections}

func load_save_data(data: Dictionary) -> void:
	if data.has("levels"):
		for key in data["levels"]:
			if _nodes.has(key):
				_levels[key] = int(data["levels"][key])
	if data.has("fills"):
		for key in data["fills"]:
			if _nodes.has(key):
				_fills[key] = float(data["fills"][key])
	if data.has("connections"):
		connections = data["connections"]
	SignalBus.stats_changed.emit()
