extends Node2D

signal room_cleared()

# Required scene children — use $ so a missing node fails loudly instead of
# silently turning every downstream call into a no-op.
@onready var defenders_root: Node2D = $Defenders
@onready var exit_zone: Area2D = $ExitZone
@onready var slime_spawn: Marker2D = $SlimeSpawn
@onready var _exit_door_wall: StaticBody2D = $ExitDoor
@onready var _entry_door_wall: StaticBody2D = $EntryDoor

@export var room_index: int = 0
@export var energy_reward: float = 10.0

# Grid layout — keep these synced with the wall geometry baked into Room.tscn
@export_group("Grid")
@export var grid_cols: int = 10
@export var grid_rows: int = 10
@export var cell_size: float = 32.0
const WALL_THICK := 16.0
const DOOR_GAP := 48.0

# Computed dimensions (recomputed in _ready in case @export values change)
var ROOM_W: float = 320.0
var ROOM_H: float = 320.0
var HALF_W: float = 160.0
var HALF_H: float = 160.0

# State
var _remaining_entities: int = 0
var _room_cleared: bool = false
var _room_active: bool = false
var _exit_open: bool = false
var _entry_closed: bool = false
var _door_pulse: float = 0.0
var _occupied_cells: Array[Vector2i] = []

var energy_float_scene: PackedScene = preload("res://effects/EnergyFloat.tscn")
var death_burst_scene: PackedScene = preload("res://effects/DeathPoof.tscn")

# 3/4 perspective wall height (visible depth on front-facing surfaces)
const WALL_HEIGHT := 12.0

# Colors
const C_FLOOR := Color(0.10, 0.10, 0.14)
const C_FLOOR_LIGHT := Color(0.12, 0.12, 0.17)
const C_GRID := Color(0.13, 0.13, 0.18)
const C_WALL_TOP := Color(0.32, 0.30, 0.28)       # Top face of walls
const C_WALL_FRONT := Color(0.22, 0.20, 0.18)      # Front-facing (south) face
const C_WALL_SIDE_L := Color(0.25, 0.23, 0.21)     # Left-facing inner side
const C_WALL_SIDE_R := Color(0.20, 0.18, 0.16)     # Right-facing inner side (darker)
const C_WALL_EDGE := Color(0.38, 0.35, 0.30)
const C_DOOR_LOCKED := Color(0.75, 0.15, 0.15)
const C_DOOR_LOCKED_FRONT := Color(0.55, 0.10, 0.10)
const C_DOOR_OPEN := Color(0.2, 0.8, 0.3)
const C_DOOR_OPEN_FRONT := Color(0.15, 0.6, 0.22)
const C_DOOR_ENTRY := Color(0.25, 0.6, 0.35, 0.5)
const C_DOOR_CLOSED := Color(0.55, 0.35, 0.15)
const C_DOOR_CLOSED_FRONT := Color(0.40, 0.25, 0.10)

# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	add_to_group("rooms")
	y_sort_enabled = true
	_recompute_dimensions()
	if slime_spawn:
		# Spawn exactly in the entry doorway (bottom center)
		slime_spawn.position = Vector2(0, HALF_H + 20.0)
	call_deferred("_position_slime")
	# Entry door starts open so the slime can walk through
	_entry_closed = false
	_set_door_collision(_entry_door_wall, false)
	# Exit door starts closed (blocks until room is cleared)
	if exit_zone:
		_set_exit_enabled(false)
		exit_zone.body_entered.connect(_on_exit_zone_body_entered)

func close_entry_door() -> void:
	if not _entry_closed:
		_entry_closed = true
		_set_door_collision(_entry_door_wall, true)
		queue_redraw()

func _recompute_dimensions() -> void:
	ROOM_W = grid_cols * cell_size
	ROOM_H = grid_rows * cell_size
	HALF_W = ROOM_W / 2.0
	HALF_H = ROOM_H / 2.0

func _process(delta: float) -> void:
	if _exit_open:
		_door_pulse += delta * 3.0
	queue_redraw()

func setup_room(index: int, difficulty: float) -> void:
	room_index = index
	# Fallback energy reward for entities without EntityData.
	# Per-entity rewards are now read from entity_data.energy_reward in _on_defender_exiting_tree.
	energy_reward = 5.0 + (index * Globals.ENERGY_ROOM_BONUS)

	if defenders_root:
		for defender in defenders_root.get_children():
			# Auto-assign EntityData to scene-baked entities that don't have one
			if "entity_data" in defender and defender.entity_data == null:
				var fallback_data: EntityData = EntityRegistry.get_entity("basic_defender")
				if fallback_data:
					defender.entity_data = fallback_data
					defender._apply_entity_data()
			if defender.has_method("apply_difficulty"):
				defender.apply_difficulty(difficulty, index)

	_place_defenders_on_grid()
	_setup_defenders()
	_room_active = true
	queue_redraw()

# =============================================================================
# Grid System
# =============================================================================

func grid_to_local(col: int, row: int) -> Vector2:
	return Vector2(
		-HALF_W + cell_size / 2.0 + col * cell_size,
		-HALF_H + cell_size / 2.0 + row * cell_size,
	)

func _get_available_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for col in range(grid_cols):
		for row in range(grid_rows):
			if row >= 8 and col >= 3 and col <= 6:
				continue
			if row <= 1 and col >= 3 and col <= 6:
				continue
			if Vector2i(col, row) in _occupied_cells:
				continue
			cells.append(Vector2i(col, row))
	return cells

func _place_defenders_on_grid() -> void:
	if not defenders_root:
		return
	_occupied_cells.clear()
	var available := _get_available_cells()
	available.shuffle()
	var idx: int = 0
	for defender in defenders_root.get_children():
		if idx < available.size():
			var cell: Vector2i = available[idx]
			defender.position = grid_to_local(cell.x, cell.y)
			_occupied_cells.append(cell)
			idx += 1

# =============================================================================
# Door Control (walls baked into Room.tscn)
# =============================================================================

func _set_door_collision(door: StaticBody2D, enabled: bool) -> void:
	if not door:
		return
	for child in door.get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", not enabled)

func _open_exit_door() -> void:
	_exit_open = true
	if _exit_door_wall:
		_set_door_collision(_exit_door_wall, false)
		_exit_door_wall.process_mode = Node.PROCESS_MODE_DISABLED
	if exit_zone:
		_set_exit_enabled(true)
	queue_redraw()

# =============================================================================
# Defender Tracking
# =============================================================================

func _setup_defenders() -> void:
	if not defenders_root:
		return
	_remaining_entities = defenders_root.get_child_count()
	if _remaining_entities <= 0:
		_on_all_defenders_defeated()
		return
	defenders_root.child_exiting_tree.connect(_on_defender_exiting_tree)

func _on_defender_exiting_tree(node: Node) -> void:
	if not _room_active:
		return
	_remaining_entities -= 1

	# Read per-entity energy reward (set by EntityData resource)
	var reward: float = energy_reward  # fallback to room-level reward
	if "energy_reward" in node and node.energy_reward > 0.0:
		reward = node.energy_reward
		
	var xp_reward := reward
	if "xp_reward" in node and node.xp_reward > 0.0:
		xp_reward = node.xp_reward
		
	var category: EntityData.Category = EntityData.Category.DEFENDER
	if "entity_data" in node and node.entity_data:
		category = node.entity_data.entity_category

	SignalBus.entity_defeated.emit(category, reward, xp_reward)

	if node is Node2D and is_inside_tree():
		var wisdom_bonus: float = 1.0 + NodeSystem.get_all_bonuses().get("energy_mult", 0.0)
		var actual_me: float = reward * wisdom_bonus * GameManager.reset_multiplier
		var float_effect: Node2D = energy_float_scene.instantiate()
		float_effect.global_position = (node as Node2D).global_position + Vector2(0, -12)
		float_effect.setup(actual_me)
		get_tree().current_scene.add_child(float_effect)

	if _remaining_entities <= 0 and not _room_cleared:
		_on_all_defenders_defeated()

func _on_all_defenders_defeated() -> void:
	_room_cleared = true
	_open_exit_door()

	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(1.5)

	# Burst effects at exit
	if is_inside_tree():
		var exit_pos: Vector2 = exit_zone.global_position if exit_zone else global_position
		for i in range(3):
			var burst: Node2D = death_burst_scene.instantiate()
			burst.global_position = exit_pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
			get_tree().current_scene.add_child(burst)

	# Tell the slime to head for the exit
	SignalBus.room_exit_opened.emit(_get_exit_global_position())

func _get_exit_global_position() -> Vector2:
	if exit_zone:
		return exit_zone.global_position
	return global_position + Vector2(0, -HALF_H)

func _set_exit_enabled(enabled: bool) -> void:
	if not exit_zone:
		return
	exit_zone.monitoring = enabled
	exit_zone.monitorable = enabled
	for child in exit_zone.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled

func _on_exit_zone_body_entered(body: Node) -> void:
	if not _room_cleared or not body.is_in_group("slime"):
		return
	room_cleared.emit()
	SignalBus.room_cleared.emit(room_index)

func _position_slime() -> void:
	if not slime_spawn or not is_inside_tree():
		return
	var slime: CharacterBody2D = get_tree().get_first_node_in_group("slime")
	if slime:
		slime.global_position = slime_spawn.global_position
		pass

# =============================================================================
# Drawing — 3/4 top-down perspective
# =============================================================================

func _draw() -> void:
	var half_gap := DOOR_GAP / 2.0
	var outer := HALF_W + WALL_THICK
	var wh := WALL_HEIGHT

	# --- Floor with subtle gradient (lighter at top / "far", darker at bottom / "near") ---
	for row in range(grid_rows):
		var t: float = float(row) / float(grid_rows)
		var row_color: Color = C_FLOOR_LIGHT.lerp(C_FLOOR, t)
		var ry: float = -HALF_H + row * cell_size
		draw_rect(Rect2(-HALF_W, ry, ROOM_W, cell_size), row_color)

	# Grid lines (subtle)
	for i in range(grid_cols + 1):
		var x: float = -HALF_W + i * cell_size
		draw_line(Vector2(x, -HALF_H), Vector2(x, HALF_H), C_GRID, 1.0)
	for i in range(grid_rows + 1):
		var y: float = -HALF_H + i * cell_size
		draw_line(Vector2(-HALF_W, y), Vector2(HALF_W, y), C_GRID, 1.0)

	# ===== BACK (TOP / FAR) WALL — rendered first, behind everything =====
	# Top wall segments (flat, no height — it's the far wall)
	draw_rect(Rect2(-HALF_W, -outer, HALF_W - half_gap, WALL_THICK), C_WALL_TOP)
	draw_rect(Rect2(half_gap, -outer, HALF_W - half_gap, WALL_THICK), C_WALL_TOP)
	# Top wall edge highlight
	draw_rect(Rect2(-HALF_W, -HALF_H, ROOM_W, 1), C_WALL_EDGE)

	# Exit door (top gap) — also behind entities
	var exit_rect := Rect2(-half_gap, -outer, DOOR_GAP, WALL_THICK)
	if _exit_open:
		var pulse := (sin(_door_pulse) + 1.0) * 0.5
		draw_rect(exit_rect.grow(3), Color(0.3, 1.0, 0.4, pulse * 0.25))
		draw_rect(exit_rect, C_DOOR_OPEN.lerp(Color(0.5, 1.0, 0.6), pulse * 0.4))
	else:
		draw_rect(exit_rect, C_DOOR_LOCKED)

	# ===== SIDE WALLS — 3/4 perspective shows inner face =====
	# Left wall: top surface + inner right-facing surface
	# Top surface
	draw_rect(Rect2(-outer, -outer, WALL_THICK, ROOM_H + WALL_THICK * 2), C_WALL_TOP)
	# Inner face (right-facing, lighter — catches light)
	draw_rect(Rect2(-HALF_W, -HALF_H, 3, ROOM_H), C_WALL_SIDE_L)

	# Right wall: top surface + inner left-facing surface
	# Top surface
	draw_rect(Rect2(HALF_W, -outer, WALL_THICK, ROOM_H + WALL_THICK * 2), C_WALL_TOP)
	# Inner face (left-facing, darker — in shadow)
	draw_rect(Rect2(HALF_W - 3, -HALF_H, 3, ROOM_H), C_WALL_SIDE_R)

	# Side wall edge highlights (vertical inner edges)
	draw_line(Vector2(-HALF_W, -HALF_H), Vector2(-HALF_W, HALF_H), C_WALL_EDGE, 1.0)
	draw_line(Vector2(HALF_W, -HALF_H), Vector2(HALF_W, HALF_H), C_WALL_EDGE, 1.0)

	# ===== BOTTOM (NEAR) WALL — 3/4 perspective shows front face with height =====
	# Bottom wall top surface (the part you'd see from above)
	draw_rect(Rect2(-HALF_W, HALF_H, HALF_W - half_gap, WALL_THICK), C_WALL_TOP)
	draw_rect(Rect2(half_gap, HALF_H, HALF_W - half_gap, WALL_THICK), C_WALL_TOP)
	# Bottom wall front face (the visible vertical surface facing the viewer)
	draw_rect(Rect2(-HALF_W, HALF_H + WALL_THICK, HALF_W - half_gap, wh), C_WALL_FRONT)
	draw_rect(Rect2(half_gap, HALF_H + WALL_THICK, HALF_W - half_gap, wh), C_WALL_FRONT)
	# Bottom edge highlight
	draw_rect(Rect2(-HALF_W, HALF_H, ROOM_W, 1), C_WALL_EDGE)
	# Bottom front face edge
	draw_line(Vector2(-HALF_W, HALF_H + WALL_THICK + wh), Vector2(HALF_W, HALF_H + WALL_THICK + wh), C_WALL_EDGE, 1.0)

	# Left wall front face extension at bottom
	draw_rect(Rect2(-outer, HALF_H + WALL_THICK, WALL_THICK, wh), C_WALL_FRONT)
	# Right wall front face extension at bottom
	draw_rect(Rect2(HALF_W, HALF_H + WALL_THICK, WALL_THICK, wh), C_WALL_FRONT)

	# Entry door (bottom gap) — shows front face with height
	var entry_top_rect := Rect2(-half_gap, HALF_H, DOOR_GAP, WALL_THICK)
	var entry_front_rect := Rect2(-half_gap, HALF_H + WALL_THICK, DOOR_GAP, wh)
	if _entry_closed:
		draw_rect(entry_top_rect, C_DOOR_CLOSED)
		draw_rect(entry_front_rect, C_DOOR_CLOSED_FRONT)
	else:
		draw_rect(entry_top_rect, C_DOOR_ENTRY)
		# Open entry: show dark recessed area (doorway)
		draw_rect(entry_front_rect, Color(0.06, 0.06, 0.08))

func deactivate() -> void:
	_room_active = false
