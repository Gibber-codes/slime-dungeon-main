extends Control

# Visual node tree: hierarchical Core → T1 → T2 → T3 layout
# Click a node to view info. Use +/- button on connection lines to connect/disconnect.
# When upgrade ready on implemented nodes, click the upgrade badge.
# Scroll to zoom, drag to pan.

# --- Base radii (scaled by zoom) ---
const BASE_CORE_RADIUS := 28.0
const BASE_T1_RADIUS := 32.0
const BASE_T2_RADIUS := 24.0
const BASE_T3_RADIUS := 18.0
const BASE_T1_ORBIT := 130.0
const BASE_T2_ORBIT := 250.0
const BASE_T3_ORBIT := 350.0
const BASE_CONN_WIDTH := 4.0

# Angular spreads (radians)
const T2_SPREAD := 0.35   # ~20° between T2 siblings
const T3_SPREAD := 0.14   # ~8° between T3 siblings

# Zoom
var _zoom: float = 0.8
const ZOOM_MIN := 0.3
const ZOOM_MAX := 2.5
const ZOOM_STEP := 0.15

# Scaled values (computed in _apply_zoom)
var CORE_RADIUS: float = BASE_CORE_RADIUS
var T1_RADIUS: float = BASE_T1_RADIUS
var T2_RADIUS: float = BASE_T2_RADIUS
var T3_RADIUS: float = BASE_T3_RADIUS
var T1_ORBIT: float = BASE_T1_ORBIT
var T2_ORBIT: float = BASE_T2_ORBIT
var T3_ORBIT: float = BASE_T3_ORBIT
var CONN_WIDTH: float = BASE_CONN_WIDTH

# Panning
var _pan_offset: Vector2 = Vector2.ZERO
var _mouse_pressed: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _is_panning: bool = false
const PAN_THRESHOLD := 5.0

const FLOW_DOT_SPEED := 80.0

# Colors
const BG_COLOR := Color(0.06, 0.06, 0.09, 0.85)
const CORE_COLOR := Color(0.4, 0.4, 0.48)
const CORE_RING := Color(0.6, 0.6, 0.65)
const CORE_ACTIVE := Color(0.55, 0.75, 0.9)
const TEXT_COLOR := Color(0.9, 0.9, 0.9)
const LEVEL_COLOR := Color(0.7, 0.7, 0.7)
const CONN_LINE_DIM := Color(0.25, 0.25, 0.3, 0.2)
const CONN_LINE_ACTIVE := Color(0.5, 0.7, 0.9, 0.7)
const CONN_LINE_LOCKED := Color(0.18, 0.18, 0.22, 0.12)
const FILL_BG := Color(0.15, 0.15, 0.2)
const READY_GLOW := Color(0.3, 1.0, 0.3, 0.3)
const HOVER_BORDER := Color(1.0, 1.0, 1.0, 0.45)
const LOCKED_COLOR := Color(0.3, 0.3, 0.35)

var _pulse: float = 0.0
var _hover_node: String = ""
var _hover_line_node: String = ""
var _hover_line_t: float = 0.5
var _hover_upgrade: String = ""
var _mouse_pos: Vector2 = Vector2.ZERO
var _node_positions: Dictionary = {}  # node_name -> Vector2 offset from visual center
var _flow_dots: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	SignalBus.stats_changed.connect(func(): queue_redraw())
	SignalBus.node_upgraded.connect(func(_n, _l): queue_redraw())
	SignalBus.energy_changed.connect(func(_c, _d): queue_redraw())
	resized.connect(_on_resized)
	call_deferred("_on_resized")

func _on_resized() -> void:
	_apply_zoom()

func _apply_zoom() -> void:
	var min_dim: float = minf(size.x, size.y)
	var auto_scale: float = clampf(min_dim / 700.0, 0.4, 2.0)
	var total_scale: float = auto_scale * _zoom
	CORE_RADIUS = BASE_CORE_RADIUS * total_scale
	T1_RADIUS = BASE_T1_RADIUS * total_scale
	T2_RADIUS = BASE_T2_RADIUS * total_scale
	T3_RADIUS = BASE_T3_RADIUS * total_scale
	T1_ORBIT = BASE_T1_ORBIT * total_scale
	T2_ORBIT = BASE_T2_ORBIT * total_scale
	T3_ORBIT = BASE_T3_ORBIT * total_scale
	CONN_WIDTH = BASE_CONN_WIDTH * total_scale

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	_update_flow_dots(delta)
	queue_redraw()

func _get_visual_center() -> Vector2:
	return size / 2.0 + _pan_offset

func _get_tier_radius(tier: int) -> float:
	match tier:
		2: return T2_RADIUS
		3: return T3_RADIUS
		_: return T1_RADIUS

# =============================================================================
# Input
# =============================================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_pos = event.position
		if _mouse_pressed and not _is_panning:
			if event.position.distance_to(_press_pos) > PAN_THRESHOLD:
				_is_panning = true
		if _is_panning:
			_pan_offset += event.relative
			queue_redraw()
			return
		# Hover detection
		_hover_upgrade = _get_upgrade_badge_at(event.position)
		_hover_line_node = _get_line_hover(event.position)
		_hover_node = _get_node_at(event.position)
		if _hover_upgrade == "" and _hover_line_node == "" and _hover_node == "":
			_hover_node = ""

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom = clampf(_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			_apply_zoom()
			queue_redraw()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom = clampf(_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			_apply_zoom()
			queue_redraw()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_pressed = true
				_press_pos = event.position
				_is_panning = false
			else:
				_mouse_pressed = false
				if _is_panning:
					_is_panning = false
					return
				# Click (not pan) — handle interactions
				var pos: Vector2 = event.position
				# Priority 1: upgrade badge
				var badge := _get_upgrade_badge_at(pos)
				if badge != "":
					NodeSystem.upgrade_node(badge)
					return
				# Priority 2: connection line button
				var line := _get_line_hover(pos)
				if line != "":
					if NodeSystem.is_connected_to_core(line):
						NodeSystem.disconnect_from_core(line)
					else:
						NodeSystem.connect_to_core(line)
					return
				# Priority 3: node click (view info)
				var clicked := _get_node_at(pos)
				if clicked != "":
					SignalBus.upgrade_node_selected.emit(clicked)
					return

# =============================================================================
# Position Computation
# =============================================================================

func _compute_positions() -> void:
	_node_positions.clear()

	for i in range(NodeSystem.T1_ORDER.size()):
		var t1_name: String = NodeSystem.T1_ORDER[i]
		var base_angle: float = -PI / 2.0 + i * (TAU / 6.0)
		_node_positions[t1_name] = Vector2(cos(base_angle), sin(base_angle)) * T1_ORBIT

		var t2_children: Array = NodeSystem.get_node_children(t1_name)
		for ci in range(t2_children.size()):
			var t2_name: String = t2_children[ci]
			var t2_angle: float = base_angle + (ci - 1) * T2_SPREAD
			_node_positions[t2_name] = Vector2(cos(t2_angle), sin(t2_angle)) * T2_ORBIT

			var t3_children: Array = NodeSystem.get_node_children(t2_name)
			for t3i in range(t3_children.size()):
				var t3_name: String = t3_children[t3i]
				var t3_angle: float = t2_angle + (t3i * 2 - 1) * T3_SPREAD
				_node_positions[t3_name] = Vector2(cos(t3_angle), sin(t3_angle)) * T3_ORBIT

# =============================================================================
# Hit Detection
# =============================================================================

func _get_node_at(pos: Vector2) -> String:
	var center := _get_visual_center()
	for node_name in _node_positions:
		var npos: Vector2 = center + _node_positions[node_name]
		var stat: NodeStat = NodeSystem.get_node_stat(node_name)
		if not stat:
			continue
		var radius: float = _get_tier_radius(stat.tier)
		if pos.distance_to(npos) <= radius + 4:
			return node_name
	return ""

func _project_onto_line(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var dir := line_end - line_start
	var len_sq := dir.length_squared()
	if len_sq < 0.001:
		return 0.5
	return clampf(dir.dot(point - line_start) / len_sq, 0.0, 1.0)

func _get_line_hover(pos: Vector2) -> String:
	var center := _get_visual_center()
	var threshold := 18.0 * _zoom
	for node_name in _node_positions:
		var stat: NodeStat = NodeSystem.get_node_stat(node_name)
		if not stat or not stat.is_implemented:
			continue
		# Get parent position
		var parent_pos: Vector2
		var parent_radius: float
		if stat.parent_id == "":
			parent_pos = center
			parent_radius = CORE_RADIUS
		else:
			if not _node_positions.has(stat.parent_id):
				continue
			parent_pos = center + _node_positions[stat.parent_id]
			var pstat: NodeStat = NodeSystem.get_node_stat(stat.parent_id)
			parent_radius = _get_tier_radius(pstat.tier) if pstat else T1_RADIUS

		var child_pos: Vector2 = center + _node_positions[node_name]
		var child_radius: float = _get_tier_radius(stat.tier)
		var line_len: float = parent_pos.distance_to(child_pos)
		if line_len < 1.0:
			continue

		var btn_radius := 14.0 * _zoom
		var t_min: float = (parent_radius + btn_radius + 4.0) / line_len
		var t_max: float = 1.0 - (child_radius + btn_radius + 4.0) / line_len
		if t_min >= t_max:
			continue

		var t := _project_onto_line(pos, parent_pos, child_pos)
		if t < t_min - 0.05 or t > t_max + 0.05:
			continue
		var closest := parent_pos.lerp(child_pos, t)
		if pos.distance_to(closest) <= threshold:
			_hover_line_t = clampf(t, t_min, t_max)
			return node_name
	return ""

func _get_upgrade_badge_at(pos: Vector2) -> String:
	var center := _get_visual_center()
	for node_name in _node_positions:
		var stat: NodeStat = NodeSystem.get_node_stat(node_name)
		if not stat or not stat.is_implemented:
			continue
		if not NodeSystem.is_upgrade_ready(node_name):
			continue
		var radius: float = _get_tier_radius(stat.tier)
		var npos: Vector2 = center + _node_positions[node_name]
		var badge_r := radius * 0.38
		var badge_pos := npos + Vector2(radius * 0.7, radius * 0.7)
		if pos.distance_to(badge_pos) <= badge_r + 4:
			return node_name
	return ""

# =============================================================================
# Flow Dots
# =============================================================================

func _update_flow_dots(delta: float) -> void:
	const DOT_TRAVEL_TIME := 0.6
	var spawn_interval: float = 1.0 / NodeSystem.flow_rate_per_connection

	for conn_name in NodeSystem.connections:
		var fill_ratio := NodeSystem.get_fill_ratio(conn_name)
		if fill_ratio >= 1.0:
			continue
		if MonsterEnergy.current_energy <= 0.1:
			continue

		var newest_t: float = 1.0
		for dot in _flow_dots:
			if dot["connection"] == conn_name and dot["t"] < newest_t:
				newest_t = dot["t"]

		var min_spacing: float = spawn_interval / DOT_TRAVEL_TIME
		if newest_t >= min_spacing:
			_flow_dots.append({"connection": conn_name, "t": 0.0})

	var i := _flow_dots.size() - 1
	while i >= 0:
		_flow_dots[i]["t"] += delta / DOT_TRAVEL_TIME
		if _flow_dots[i]["t"] >= 1.0:
			_flow_dots.remove_at(i)
		i -= 1

# =============================================================================
# Drawing
# =============================================================================

func _draw() -> void:
	var center := _get_visual_center()
	_compute_positions()

	# Background
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	# --- Connection lines (all potential, dim) ---
	for node_name in _node_positions:
		var stat: NodeStat = NodeSystem.get_node_stat(node_name)
		if not stat:
			continue
		var child_pos: Vector2 = center + _node_positions[node_name]
		var parent_pos: Vector2
		if stat.parent_id == "":
			parent_pos = center
		elif _node_positions.has(stat.parent_id):
			parent_pos = center + _node_positions[stat.parent_id]
		else:
			continue
		var line_col: Color = CONN_LINE_LOCKED if not stat.is_implemented else CONN_LINE_DIM
		draw_line(parent_pos, child_pos, line_col, 1.5)

	# --- Active connections (bright) + flow dots ---
	for conn_name in NodeSystem.connections:
		var stat: NodeStat = NodeSystem.get_node_stat(conn_name)
		if not stat or not _node_positions.has(conn_name):
			continue
		var child_pos: Vector2 = center + _node_positions[conn_name]
		var parent_pos: Vector2
		if stat.parent_id == "":
			parent_pos = center
		elif _node_positions.has(stat.parent_id):
			parent_pos = center + _node_positions[stat.parent_id]
		else:
			continue

		var color: Color = UITheme.get_branch_color(conn_name)
		draw_line(parent_pos, child_pos, color.lerp(CONN_LINE_ACTIVE, 0.5), CONN_WIDTH)

		# Flow dots
		for dot in _flow_dots:
			if dot["connection"] == conn_name:
				var t: float = dot["t"]
				var dot_pos: Vector2 = parent_pos.lerp(child_pos, t)
				draw_circle(dot_pos, 3.0 * CONN_WIDTH / BASE_CONN_WIDTH, color.lightened(0.3))

	# --- Core ---
	var core_has_energy := MonsterEnergy.current_energy > 0.5
	var core_col: Color = CORE_ACTIVE if core_has_energy else CORE_COLOR
	draw_circle(center, CORE_RADIUS + 2, CORE_RING)
	draw_circle(center, CORE_RADIUS, core_col)

	var line_gap: float = CORE_RADIUS * 0.45
	_draw_centered_text(center + Vector2(0, -line_gap), "Core", TEXT_COLOR, _get_font_size(14))
	var me_str := "%.0f ME" % MonsterEnergy.current_energy
	_draw_centered_text(center + Vector2(0, line_gap * 0.3), me_str, UITheme.COLOR_ME, _get_font_size(10))

	var max_conn := NodeSystem.get_max_connections()
	var cur_conn := NodeSystem.connections.size()
	_draw_centered_text(center + Vector2(0, line_gap * 1.1), "%d/%d slots" % [cur_conn, max_conn], LEVEL_COLOR, _get_font_size(9))

	var total_flow := cur_conn * NodeSystem.flow_rate_per_connection
	if cur_conn > 0:
		_draw_centered_text(center + Vector2(0, line_gap * 1.8), "%.1f ME/s flow" % total_flow, Color(0.5, 0.7, 0.9, 0.8), _get_font_size(9))

	# --- All nodes ---
	for node_name in _node_positions:
		_draw_node(center, node_name)

	# --- Connection button on hover ---
	if _hover_line_node != "":
		_draw_connection_button(center, _hover_line_node)

	# --- Title ---
	_draw_centered_text(Vector2(size.x / 2.0, 24), "Slime Core", TEXT_COLOR, _get_font_size(16))

	if absf(_zoom - 0.8) > 0.05:
		_draw_centered_text(Vector2(size.x / 2.0, 44), "Zoom: %.0f%%" % (_zoom * 100.0), LEVEL_COLOR, _get_font_size(9))

	# --- Info bar ---
	var info_text := "Slots: %d/%d | Click node: info | Hover line: +/- | Scroll: zoom | Drag: pan" % [cur_conn, max_conn]
	_draw_centered_text(Vector2(size.x / 2.0, size.y - 16), info_text, Color(0.6, 0.65, 0.7), _get_font_size(10))

# =============================================================================
# Node Drawing
# =============================================================================

func _draw_node(center: Vector2, node_name: String) -> void:
	var stat: NodeStat = NodeSystem.get_node_stat(node_name)
	if not stat:
		return
	var npos: Vector2 = center + _node_positions[node_name]
	var radius: float = _get_tier_radius(stat.tier)
	var is_hover: bool = (node_name == _hover_node)

	if not stat.is_implemented:
		_draw_locked_node(center, npos, stat, radius, is_hover)
		return

	var color: Color = UITheme.get_branch_color(node_name)
	var level: int = NodeSystem.get_node_level(node_name)
	var node_connected: bool = NodeSystem.is_connected_to_core(node_name)
	var fill_ratio: float = NodeSystem.get_fill_ratio(node_name)
	var is_ready: bool = NodeSystem.is_upgrade_ready(node_name)

	# Hover glow
	if is_hover:
		draw_circle(npos, radius + 3, Color(1, 1, 1, 0.08))

	# Node circle — dark base
	draw_circle(npos, radius, Color(0.08, 0.08, 0.12))

	# Dim colored base
	var node_col: Color = color if node_connected else color.darkened(0.6)
	draw_circle(npos, radius - 1, node_col.darkened(0.5))

	# Fill-up (bottom to top)
	if fill_ratio > 0.0:
		var fill_col: Color = color.lightened(0.2) if not is_ready else Color(0.4, 1.0, 0.5)
		if not node_connected:
			fill_col = fill_col.darkened(0.3)
		_draw_circle_fill(npos, radius - 2, fill_ratio, fill_col)

	# Outer ring
	if is_ready:
		var pulse_alpha := (sin(_pulse) + 1.0) * 0.5
		var ready_ring := Color(0.3, 1.0, 0.3, 0.6 + pulse_alpha * 0.4)
		draw_arc(npos, radius, 0, TAU, 32, ready_ring, 2.5)
	elif is_hover:
		draw_arc(npos, radius, 0, TAU, 32, HOVER_BORDER, 2.0)
	else:
		draw_arc(npos, radius, 0, TAU, 32, node_col.lightened(0.1), 1.5)

	# Abbreviation text
	var abbrev: String = _get_abbrev(stat)
	var name_fs: int = _get_font_size(12 if stat.tier == 1 else (10 if stat.tier == 2 else 8))
	_draw_centered_text(npos, abbrev, TEXT_COLOR, name_fs)

	# Level badge (bottom-left)
	var badge_pos := npos + Vector2(-radius * 0.7, radius * 0.7)
	var badge_r := radius * 0.35
	draw_circle(badge_pos, badge_r + 1, node_col.lightened(0.1))
	draw_circle(badge_pos, badge_r, Color(0.1, 0.1, 0.15, 0.95))
	draw_arc(badge_pos, badge_r, 0, TAU, 16, node_col, 1.5)
	_draw_centered_text(badge_pos, "%d" % level, TEXT_COLOR, _get_font_size(9))

	# Upgrade badge (bottom-right, only when ready)
	if is_ready:
		var upgrade_pos := npos + Vector2(radius * 0.7, radius * 0.7)
		var upgrade_r := radius * 0.38
		var pulse_val := (sin(_pulse * 1.5) + 1.0) * 0.5
		var badge_col := Color(0.15, 0.6, 0.2).lerp(Color(0.3, 1.0, 0.4), pulse_val)
		var is_badge_hover := (_hover_upgrade == node_name)
		if is_badge_hover:
			badge_col = badge_col.lightened(0.3)
		draw_circle(upgrade_pos, upgrade_r + 1, Color(0.3, 1.0, 0.3, 0.4 + pulse_val * 0.3))
		draw_circle(upgrade_pos, upgrade_r, badge_col)
		if is_badge_hover:
			draw_arc(upgrade_pos, upgrade_r, 0, TAU, 16, HOVER_BORDER, 1.5)
		_draw_centered_text(upgrade_pos, "UP", Color(1, 1, 1), _get_font_size(8))

	# Display name outside the ring (radially outward)
	var dir: Vector2 = _node_positions[node_name].normalized()
	var label_dist: float = radius + 10 + _get_font_size(8) * 0.5
	var label_pos: Vector2 = npos + dir * label_dist
	var label_fs: int = _get_font_size(9 if stat.tier == 1 else (8 if stat.tier == 2 else 7))
	var label_col: Color = color.lerp(TEXT_COLOR, 0.3) if node_connected else color.darkened(0.2)
	_draw_centered_text(label_pos, stat.display_name, label_col, label_fs)

func _draw_locked_node(center: Vector2, npos: Vector2, stat: NodeStat, radius: float, is_hover: bool) -> void:
	# Greyed out unimplemented node
	if is_hover:
		draw_circle(npos, radius + 2, Color(0.3, 0.3, 0.35, 0.15))

	draw_circle(npos, radius, Color(0.08, 0.08, 0.1))
	draw_circle(npos, radius - 1, LOCKED_COLOR.darkened(0.5))
	var ring_col := Color(0.25, 0.25, 0.3) if not is_hover else Color(0.4, 0.4, 0.45)
	draw_arc(npos, radius, 0, TAU, 24, ring_col, 1.0)

	# Lock symbol (simple "X" or padlock shapes)
	var lk := radius * 0.25
	draw_line(npos + Vector2(-lk, -lk), npos + Vector2(lk, lk), Color(0.4, 0.4, 0.45, 0.6), 2.0)
	draw_line(npos + Vector2(lk, -lk), npos + Vector2(-lk, lk), Color(0.4, 0.4, 0.45, 0.6), 2.0)

	# Display name outside
	var dir: Vector2 = _node_positions[stat.id].normalized()
	var label_dist: float = radius + 10
	var label_pos: Vector2 = npos + dir * label_dist
	var label_fs: int = _get_font_size(8 if stat.tier == 2 else 7)
	_draw_centered_text(label_pos, stat.display_name, Color(0.4, 0.4, 0.45), label_fs)

func _draw_connection_button(center: Vector2, node_name: String) -> void:
	var stat: NodeStat = NodeSystem.get_node_stat(node_name)
	if not stat or not _node_positions.has(node_name):
		return

	var child_pos: Vector2 = center + _node_positions[node_name]
	var parent_pos: Vector2
	if stat.parent_id == "":
		parent_pos = center
	elif _node_positions.has(stat.parent_id):
		parent_pos = center + _node_positions[stat.parent_id]
	else:
		return

	var node_connected: bool = NodeSystem.is_connected_to_core(node_name)
	var btn_pos := parent_pos.lerp(child_pos, _hover_line_t)
	var btn_radius := 14.0 * _zoom
	var color: Color = UITheme.get_branch_color(node_name)

	draw_circle(btn_pos, btn_radius, Color(0.1, 0.1, 0.15, 0.95))
	draw_arc(btn_pos, btn_radius, 0, TAU, 16, HOVER_BORDER, 2.0)

	var symbol := "-" if node_connected else "+"
	var sym_col: Color = color if node_connected else Color(0.4, 0.9, 0.4)

	# Check if parent is connected (needed for T2/T3)
	var parent_connected := true
	if stat.parent_id != "" and not NodeSystem.is_connected_to_core(stat.parent_id):
		parent_connected = false

	if not node_connected and (NodeSystem.connections.size() >= NodeSystem.get_max_connections() or not parent_connected):
		sym_col = UITheme.COLOR_LOCKED
		symbol = "x"

	_draw_centered_text(btn_pos, symbol, sym_col, _get_font_size(16))

# =============================================================================
# Drawing Helpers
# =============================================================================

func _get_abbrev(stat: NodeStat) -> String:
	# Use first 3 chars of display_name, uppercased
	if stat.display_name.length() <= 3:
		return stat.display_name.to_upper()
	return stat.display_name.substr(0, 3).to_upper()

func _draw_circle_fill(center_pos: Vector2, radius: float, fill_ratio: float, fill_color: Color) -> void:
	if fill_ratio <= 0.0:
		return
	if fill_ratio >= 1.0:
		draw_circle(center_pos, radius, fill_color)
		return

	var fill_y: float = center_pos.y + radius - (fill_ratio * 2.0 * radius)
	var dy: float = fill_y - center_pos.y
	if absf(dy) >= radius:
		if dy < 0:
			draw_circle(center_pos, radius, fill_color)
		return

	var dx: float = sqrt(radius * radius - dy * dy)
	var left_x: float = center_pos.x - dx
	var right_x: float = center_pos.x + dx

	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2(left_x, fill_y))

	var angle_left: float = atan2(fill_y - center_pos.y, left_x - center_pos.x)
	var angle_right: float = atan2(fill_y - center_pos.y, right_x - center_pos.x)

	var segments := 24
	var arc_start: float = angle_left
	var arc_end: float = angle_right
	if arc_end > arc_start:
		arc_end -= TAU

	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var angle: float = arc_start + t * (arc_end - arc_start)
		points.append(center_pos + Vector2(cos(angle), sin(angle)) * radius)

	points.append(Vector2(right_x, fill_y))

	if points.size() >= 3:
		draw_colored_polygon(points, fill_color)

func _draw_centered_text(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(pos.x - text_size.x / 2.0, pos.y + text_size.y / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _get_font_size(base: int) -> int:
	var min_dim: float = minf(size.x, size.y)
	var auto_scale: float = clampf(min_dim / 700.0, 0.4, 2.0)
	return maxi(6, int(base * auto_scale * _zoom))
