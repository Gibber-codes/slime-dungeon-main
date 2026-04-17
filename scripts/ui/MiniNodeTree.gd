extends Control

# Compact node tree showing Core + all T1/T2/T3 nodes in a radial layout.
# Branch coloring and node levels only — no other info.
# Hovering the view signals HUD to slide out an upgrade panel from the left.
# Clicking anywhere on the view opens the full node tree.

# --- Geometry ---
const MINI_CORE_R  := 18.0
const MINI_T1_R    := 14.0
const MINI_T2_R    := 10.0
const MINI_T3_R    :=  7.0
const MINI_CONN_W  :=  1.8
const T1_ORBIT     := 50.0
const T2_ORBIT     := 88.0
const T3_ORBIT     := 120.0
# T2_FAN: max ≈ 20° to avoid inter-sector overlap at T2_ORBIT=88px with r=10
# T3_FAN: max ≈ 6° to avoid inter-sector overlap at T3_ORBIT=120px with r=7
const T2_FAN_DEG   := 19.0
const T3_FAN_DEG   :=  5.5

# --- Tree structure (hardcoded for deterministic layout) ---
const NODE_ORDER: Array[String] = [
	"constitution", "intelligence", "agility",
	"strength", "wisdom", "stamina",
]

const T2_ORDER: Dictionary = {
	"constitution": ["mass", "aegis", "balance"],
	"intelligence": ["focus", "knowledge", "thought"],
	"agility":      ["counter", "dodge", "opportunity"],
	"strength":     ["engulf", "precision", "str_momentum"],
	"wisdom":       ["intuition", "peace", "power"],
	"stamina":      ["digestion", "frenzy", "regeneration"],
}

const T3_ORDER: Dictionary = {
	"mass":         ["defiance", "tenacity"],
	"aegis":        ["channeling", "resolve"],
	"focus":        ["focus_capacity", "rigor"],
	"knowledge":    ["analysis", "memory"],
	"counter":      ["multihit", "restitution"],
	"dodge":        ["penetration", "stealth"],
	"precision":    ["application", "reaction"],
	"str_momentum": ["burst", "drive"],
	"intuition":    ["efficiency", "sympathy"],
	"power":        ["harmony", "reflection"],
	"frenzy":       ["frenzy_burst", "frenzy_speed"],
	"regeneration": ["resilience", "toughness"],
}

# --- Colors ---
const BG_COLOR     := Color(0.06, 0.06, 0.09, 0.85)
const CORE_COLOR   := Color(0.40, 0.40, 0.48)
const CORE_ACTIVE  := Color(0.55, 0.75, 0.90)
const CONN_DIM     := Color(0.25, 0.25, 0.30, 0.12)
const TEXT_COLOR   := Color(0.85, 0.85, 0.85)
const LEVEL_COLOR  := Color(0.70, 0.70, 0.70)
const UPGRADE_GREEN := Color(0.15, 0.95, 0.30)

# --- State ---
var _pulse: float = 0.0
var _node_positions: Dictionary = {}  # node_name -> Vector2 (relative to center)
var _node_radii: Dictionary    = {}  # node_name -> float
var _hover_node: String        = ""
var _view_hovered: bool        = false
var is_full_tree_open: bool    = false

signal open_full_tree()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 278)
	size_flags_vertical = Control.SIZE_SHRINK_END
	SignalBus.stats_changed.connect(func(): queue_redraw())
	SignalBus.node_upgraded.connect(func(_n, _l): queue_redraw())
	SignalBus.energy_changed.connect(func(_c, _d): queue_redraw())

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	queue_redraw()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_view_hovered = true
			queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			_hover_node = ""
			_view_hovered = false
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_node = _get_node_at(event.position)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		open_full_tree.emit()

# =============================================================================
# Position helpers
# =============================================================================

func _get_node_at(pos: Vector2) -> String:
	var center := size / 2.0
	for node_name in _node_positions:
		var npos: Vector2 = center + _node_positions[node_name]
		var r: float = _node_radii.get(node_name, MINI_T1_R)
		if pos.distance_to(npos) <= r + 3.0:
			return node_name
	return ""

func _compute_positions() -> void:
	_node_positions.clear()
	_node_radii.clear()
	for i in range(NODE_ORDER.size()):
		var t1_name: String = NODE_ORDER[i]
		var t1_angle: float = -PI / 2.0 + i * (TAU / 6.0)
		_node_positions[t1_name] = Vector2(cos(t1_angle), sin(t1_angle)) * T1_ORBIT
		_node_radii[t1_name] = MINI_T1_R
		if not T2_ORDER.has(t1_name):
			continue
		var t2_list: Array = T2_ORDER[t1_name]
		for j in range(t2_list.size()):
			var t2_name: String = t2_list[j]
			var t2_off: float = (float(j) - float(t2_list.size() - 1) / 2.0) * deg_to_rad(T2_FAN_DEG)
			var t2_angle: float = t1_angle + t2_off
			_node_positions[t2_name] = Vector2(cos(t2_angle), sin(t2_angle)) * T2_ORBIT
			_node_radii[t2_name] = MINI_T2_R
			if not T3_ORDER.has(t2_name):
				continue
			var t3_list: Array = T3_ORDER[t2_name]
			for k in range(t3_list.size()):
				var t3_name: String = t3_list[k]
				var t3_off: float = (float(k) - float(t3_list.size() - 1) / 2.0) * deg_to_rad(T3_FAN_DEG)
				var t3_angle: float = t2_angle + t3_off
				_node_positions[t3_name] = Vector2(cos(t3_angle), sin(t3_angle)) * T3_ORBIT
				_node_radii[t3_name] = MINI_T3_R

# =============================================================================
# Draw
# =============================================================================

func _draw() -> void:
	var center := size / 2.0
	_compute_positions()

	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	# Hover glow — subtle inner border to signal the view is clickable
	if _view_hovered:
		var glow_a := 0.25 + (sin(_pulse * 1.2) + 1.0) * 0.08
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color(0.45, 0.65, 1.0, glow_a), false, 2.0)

	# Connections drawn first (behind nodes)
	_draw_all_connections(center)

	# Nodes outside-in so inner nodes render on top
	for t1_name in NODE_ORDER:
		if T2_ORDER.has(t1_name):
			for t2_name in T2_ORDER[t1_name]:
				if T3_ORDER.has(t2_name):
					for t3_name in T3_ORDER[t2_name]:
						_draw_mini_node(center, t3_name)
				_draw_mini_node(center, t2_name)
		_draw_mini_node(center, t1_name)

	# Core on top
	var core_col := CORE_ACTIVE if MonsterEnergy.current_energy > 0.5 else CORE_COLOR
	draw_circle(center, MINI_CORE_R + 2, Color(0.6, 0.6, 0.65, 0.5))
	draw_circle(center, MINI_CORE_R, core_col)
	_draw_centered_text(center + Vector2(0, -4), "ME", TEXT_COLOR, 8)
	_draw_centered_text(center + Vector2(0, 6), "%.0f" % MonsterEnergy.current_energy, UITheme.COLOR_ME, 7)

	# Expand icon at top-left
	_draw_expand_icon()

func _draw_all_connections(center: Vector2) -> void:
	for t1_name in NODE_ORDER:
		if not _node_positions.has(t1_name):
			continue
		var t1pos: Vector2 = center + _node_positions[t1_name]
		if NodeSystem.is_connected_to_core(t1_name):
			draw_line(center, t1pos, UITheme.get_branch_color(t1_name).lerp(Color.WHITE, 0.2), MINI_CONN_W)
		else:
			draw_line(center, t1pos, CONN_DIM, 1.2)

		if not T2_ORDER.has(t1_name):
			continue
		for t2_name in T2_ORDER[t1_name]:
			if not _node_positions.has(t2_name):
				continue
			var t2pos: Vector2 = center + _node_positions[t2_name]
			if NodeSystem.is_connected_to_core(t2_name):
				draw_line(t1pos, t2pos, UITheme.get_branch_color(t2_name).lerp(Color.WHITE, 0.15), MINI_CONN_W * 0.7)
			else:
				draw_line(t1pos, t2pos, CONN_DIM, 1.0)

			if not T3_ORDER.has(t2_name):
				continue
			for t3_name in T3_ORDER[t2_name]:
				if not _node_positions.has(t3_name):
					continue
				var t3pos: Vector2 = center + _node_positions[t3_name]
				if NodeSystem.is_connected_to_core(t3_name):
					draw_line(t2pos, t3pos, UITheme.get_branch_color(t3_name).lerp(Color.WHITE, 0.1), MINI_CONN_W * 0.5)
				else:
					draw_line(t2pos, t3pos, CONN_DIM, 0.8)

func _draw_mini_node(center: Vector2, node_name: String) -> void:
	if not _node_positions.has(node_name):
		return
	var npos: Vector2 = center + _node_positions[node_name]
	var r: float = _node_radii.get(node_name, MINI_T1_R)
	var color: Color = UITheme.get_branch_color(node_name)
	var connected: bool = NodeSystem.is_connected_to_core(node_name)
	var fill_ratio: float = NodeSystem.get_fill_ratio(node_name)
	var is_ready: bool = NodeSystem.is_upgrade_ready(node_name)
	var is_hover: bool = (node_name == _hover_node)
	var node_col: Color = color if connected else color.darkened(0.65)

	if is_ready:
		# Flash bright green
		var pulse_val := (sin(_pulse * 1.8) + 1.0) * 0.5
		draw_circle(npos, r + 4.0 + pulse_val * 2.0, Color(0.1, 1.0, 0.3, 0.12 + pulse_val * 0.12))
		var green_col := UPGRADE_GREEN.lerp(Color(0.5, 1.0, 0.6), pulse_val)
		draw_circle(npos, r, green_col)
		draw_arc(npos, r + 1.0, 0.0, TAU, 20, Color(0.3, 1.0, 0.3, 0.6 + pulse_val * 0.4), 1.8)
	else:
		draw_circle(npos, r, Color(0.08, 0.08, 0.12))
		draw_circle(npos, r - 1.0, node_col.darkened(0.5))
		if fill_ratio > 0.0:
			var fill_col := color.lightened(0.15) if connected else color.darkened(0.4)
			_draw_circle_fill(npos, r - 1.0, fill_ratio, fill_col)
		draw_arc(npos, r, 0.0, TAU, 20, node_col.lightened(0.1), 1.2)

	if is_hover:
		draw_arc(npos, r + 2.0, 0.0, TAU, 20, Color(1.0, 1.0, 1.0, 0.5), 1.5)

	# Level centered large in node
	var level: int = NodeSystem.get_node_level(node_name)
	var level_fs: int = int(r * 0.90)
	var level_col: Color = Color(1.0, 1.0, 1.0, 0.90) if is_ready else TEXT_COLOR
	_draw_centered_text(npos, "%d" % level, level_col, level_fs)

func _draw_expand_icon() -> void:
	# Four-corner expand brackets at top-left to indicate clickability
	var cx := 12.0
	var cy := 12.0
	var arm := 5.0
	var col := Color(0.65, 0.65, 0.75, 0.75) if not is_full_tree_open else Color(0.4, 0.8, 1.0, 0.8)
	var w := 1.5
	draw_line(Vector2(cx - arm, cy - arm + 2), Vector2(cx - arm, cy - arm), col, w)
	draw_line(Vector2(cx - arm, cy - arm),     Vector2(cx - arm + 2, cy - arm), col, w)
	draw_line(Vector2(cx + arm - 2, cy - arm), Vector2(cx + arm, cy - arm), col, w)
	draw_line(Vector2(cx + arm, cy - arm),     Vector2(cx + arm, cy - arm + 2), col, w)
	draw_line(Vector2(cx - arm, cy + arm - 2), Vector2(cx - arm, cy + arm), col, w)
	draw_line(Vector2(cx - arm, cy + arm),     Vector2(cx - arm + 2, cy + arm), col, w)
	draw_line(Vector2(cx + arm - 2, cy + arm), Vector2(cx + arm, cy + arm), col, w)
	draw_line(Vector2(cx + arm, cy + arm),     Vector2(cx + arm, cy + arm - 2), col, w)

# =============================================================================
# Helpers
# =============================================================================

func _draw_centered_text(pos: Vector2, text: String, color: Color, font_size: int) -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(pos.x - text_size.x / 2.0, pos.y + text_size.y / 3.0),
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw_circle_fill(center_pos: Vector2, radius: float, fill_ratio: float, fill_color: Color) -> void:
	if fill_ratio <= 0.0:
		return
	if fill_ratio >= 1.0:
		draw_circle(center_pos, radius, fill_color)
		return
	var fill_y: float = center_pos.y + radius - (fill_ratio * 2.0 * radius)
	var dy: float = fill_y - center_pos.y
	if absf(dy) >= radius:
		if dy < 0.0:
			draw_circle(center_pos, radius, fill_color)
		return
	var dx: float = sqrt(radius * radius - dy * dy)
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2(center_pos.x - dx, fill_y))
	var angle_left: float = atan2(dy, -dx)
	var angle_right: float = atan2(dy, dx)
	var arc_end: float = angle_right
	if arc_end > angle_left:
		arc_end -= TAU
	for i in range(1, 12):
		var t: float = float(i) / 12.0
		var angle: float = angle_left + t * (arc_end - angle_left)
		points.append(center_pos + Vector2(cos(angle), sin(angle)) * radius)
	points.append(Vector2(center_pos.x + dx, fill_y))
	if points.size() >= 3:
		draw_colored_polygon(points, fill_color)
