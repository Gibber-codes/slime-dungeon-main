extends CanvasLayer

# 3-panel HUD: Left (info/stats tabs) | Center (game view + node tree) | Right (status + nodes)
# Layout is baked into HUD.tscn — this script wires signals and pushes data into widgets.
# Status bars and stat rows are reusable widget scenes (scenes/ui/widgets/).

# --- @onready scene refs ---
@onready var _left_panel: PanelContainer = $Root/LeftPanel
@onready var _collapse_btn: Button = $Root/LeftPanel/VBox/CollapseBtn
@onready var _tab_container: TabContainer = $Root/LeftPanel/VBox/Tabs
@onready var _entity_info_box: VBoxContainer = $Root/LeftPanel/VBox/Tabs/Info/EntityInfoBox
@onready var _karma_box: VBoxContainer = $Root/LeftPanel/VBox/Tabs/Karma/KarmaBox
@onready var _settings_vbox: VBoxContainer = $Root/LeftPanel/VBox/Tabs/Settings/VBox

@onready var _center_area: Control = $Root/CenterArea
@onready var _node_tree_view: Control = $Root/CenterArea/NodeTreeView
@onready var _mini_node_tree: Control = $Root/RightPanel/Margin/VBox/MiniNodeTree

@onready var _room_label: Label = $Root/RightPanel/Margin/VBox/Header/RoomLabel
@onready var _mult_label: Label = $Root/RightPanel/Margin/VBox/Header/MultLabel
@onready var _me_label: Label = $Root/RightPanel/Margin/VBox/MELabel

@onready var _hp_bar: HBoxContainer = $Root/RightPanel/Margin/VBox/HpBar
@onready var _speed_bar: HBoxContainer = $Root/RightPanel/Margin/VBox/SpeedBar
@onready var _seek_bar: HBoxContainer = $Root/RightPanel/Margin/VBox/SeekBar
@onready var _mtm_bar: HBoxContainer = $Root/RightPanel/Margin/VBox/MtmBar

@onready var _focus_label: Label = $Root/RightPanel/Margin/VBox/StatsScroll/StatBox/FocusLabel
@onready var _stat_box: VBoxContainer = $Root/RightPanel/Margin/VBox/StatsScroll/StatBox

@onready var _tooltip_panel: PanelContainer = $Tooltip
@onready var _tooltip_label: Label = $Tooltip/Label

# --- State ---
var slime: CharacterBody2D = null
var selected_entity: Node = null
var selected_node_name: String = ""
var _left_collapsed := false

var _stats: Dictionary = {}           # key -> StatRow
var _stat_tooltips: Dictionary = {}   # key -> tooltip text
var _info_labels: Dictionary = {}     # entity-info field -> Label
var _karma_labels: Dictionary = {}    # key -> Label

# Upgrade slide panel (appears to the left of MiniNodeTree on hover)
var _upgrade_slide_panel: PanelContainer = null
var _upgrade_slide_list: VBoxContainer   = null
var _slide_panel_open: bool              = false
var _slide_tween: Tween                  = null
var _last_ready_nodes: Array             = []   # tracks which nodes were ready on last build

# Overlays — built programmatically (stateful dialogs)
var _confirm_panel: PanelContainer
var _confirm_msg: Label
var _gameover_panel: PanelContainer
var _gameover_label: Label
var _prestige_btn: Button

const LEFT_W := 280.0
const LEFT_W_COLLAPSED := 36.0
const UPGRADE_PANEL_W := 165.0

# =============================================================================
# Lifecycle
# =============================================================================

func _ready() -> void:
	slime = get_tree().get_first_node_in_group("slime")
	_collapse_btn.pressed.connect(_toggle_collapse)
	_tab_container.tab_changed.connect(_on_tab_changed)
	_mini_node_tree.open_full_tree.connect(_toggle_node_tree)

	_register_stat_rows()
	_show_entity_hint()
	_build_karma_tab(_karma_box)
	_build_settings_tab(_settings_vbox)
	_build_overlays()
	_build_upgrade_slide_panel()
	_connect_signals()

	_room_label.text = "Room: %d/%d" % [GameManager.current_room_index + 1, Globals.TOTAL_ROOMS]
	_mult_label.text = "x%.2f" % GameManager.reset_multiplier
	_me_label.text = "ME: %.0f" % MonsterEnergy.current_energy

func _process(_delta: float) -> void:
	_update_right_panel()
	_update_entity_info()
	_update_karma_tab()
	_update_upgrade_slide_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_upgrade_menu"):
		_toggle_node_tree()

func _connect_signals() -> void:
	SignalBus.energy_changed.connect(func(_c, _d): _update_me_display())
	SignalBus.room_loaded.connect(_on_room_loaded)
	SignalBus.multiplier_changed.connect(func(m): _mult_label.text = "x%.2f" % m)
	SignalBus.stats_changed.connect(_on_stats_changed)
	SignalBus.entity_selected.connect(_on_entity_selected)
	SignalBus.upgrade_node_selected.connect(_on_upgrade_node_selected)
	SignalBus.game_over.connect(_on_game_over)
	SignalBus.game_won.connect(_on_game_won)
	SignalBus.reset_triggered.connect(_on_reset)
	SignalBus.reset_confirmation_requested.connect(_show_confirm)

func _on_stats_changed() -> void:
	if selected_node_name != "":
		_rebuild_entity_info()

# =============================================================================
# Stat row registration — discover all StatRow children automatically
# =============================================================================

func _register_stat_rows() -> void:
	# Discover StatRow children by duck-typing (has 'key' + 'hovered' signal).
	# Avoids hard dependency on the StatRow class_name being scanned first.
	for child in _stat_box.get_children():
		if not ("key" in child) or not child.has_signal("hovered"):
			continue
		if child.key == "":
			continue
		_stats[child.key] = child
		child.hovered.connect(_show_stat_tooltip)
		child.unhovered.connect(_hide_stat_tooltip)

# =============================================================================
# Overlays
# =============================================================================

func _build_overlays() -> void:
	# Confirm reset
	_confirm_panel = _make_overlay()
	_confirm_panel.custom_minimum_size = Vector2(380, 180)
	var cvbox := VBoxContainer.new()
	cvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cvbox.add_theme_constant_override("separation", 6)
	_confirm_panel.add_child(cvbox)
	_confirm_msg = Label.new()
	_confirm_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cvbox.add_child(_confirm_msg)
	var cbtn := HBoxContainer.new()
	cbtn.alignment = BoxContainer.ALIGNMENT_CENTER
	cbtn.add_theme_constant_override("separation", 8)
	var yes := Button.new()
	yes.text = "Prestige Reset"
	yes.pressed.connect(func(): _confirm_panel.visible = false; GameManager.prestige_reset())
	var full := Button.new()
	full.text = "Full Reset"
	full.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	full.pressed.connect(func(): _confirm_panel.visible = false; GameManager.full_reset())
	var no := Button.new()
	no.text = "Cancel"
	no.pressed.connect(func(): _confirm_panel.visible = false)
	cbtn.add_child(yes)
	cbtn.add_child(full)
	cbtn.add_child(no)
	cvbox.add_child(cbtn)

	# Game over
	_gameover_panel = _make_overlay()
	_gameover_panel.custom_minimum_size = Vector2(360, 200)
	var gvbox := VBoxContainer.new()
	gvbox.alignment = BoxContainer.ALIGNMENT_CENTER
	gvbox.add_theme_constant_override("separation", 8)
	_gameover_panel.add_child(gvbox)
	_gameover_label = Label.new()
	_gameover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gvbox.add_child(_gameover_label)
	gvbox.add_child(HSeparator.new())
	var prestige_btn := Button.new()
	prestige_btn.text = "Prestige Reset (R)"
	prestige_btn.custom_minimum_size.y = 32
	prestige_btn.pressed.connect(func(): GameManager.prestige_reset())
	gvbox.add_child(prestige_btn)
	var full_btn := Button.new()
	full_btn.text = "Full Reset (Testing)"
	full_btn.custom_minimum_size.y = 32
	full_btn.pressed.connect(func(): GameManager.full_reset())
	full_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	gvbox.add_child(full_btn)

# =============================================================================
# Upgrade slide panel — slides out from behind MiniNodeTree on hover
# =============================================================================

func _build_upgrade_slide_panel() -> void:
	_upgrade_slide_panel = PanelContainer.new()
	_upgrade_slide_panel.custom_minimum_size = Vector2(UPGRADE_PANEL_W, 0)
	_upgrade_slide_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_slide_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.11, 0.95)
	style.border_width_left   = 1
	style.border_width_right  = 0
	style.border_width_top    = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.30, 0.30, 0.48, 0.85)
	style.corner_radius_top_left    = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left   = 6
	style.content_margin_right  = 6
	style.content_margin_top    = 8
	style.content_margin_bottom = 8
	_upgrade_slide_panel.add_theme_stylebox_override("panel", style)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_upgrade_slide_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)
	_upgrade_slide_list = vbox

	add_child(_upgrade_slide_panel)
	# Render behind $Root (which contains MiniNodeTree) so panel slides under it
	move_child(_upgrade_slide_panel, 0)

func _update_upgrade_slide_visibility() -> void:
	if not _upgrade_slide_panel or not _mini_node_tree:
		return
	var mp := get_viewport().get_mouse_position()
	var mini_rect := _mini_node_tree.get_global_rect()
	var panel_rect := _upgrade_slide_panel.get_global_rect() if _upgrade_slide_panel.visible else Rect2()
	var in_region: bool = mini_rect.has_point(mp) or panel_rect.has_point(mp)
	if in_region and not _slide_panel_open:
		_open_upgrade_slide_panel()
	elif not in_region and _slide_panel_open:
		_close_upgrade_slide_panel()
	# Live update: compare current ready nodes to what's shown; rebuild if different
	if _slide_panel_open:
		var current_ready := _collect_ready_nodes()
		if current_ready != _last_ready_nodes:
			_refresh_upgrade_slide_panel()

func _collect_ready_nodes() -> Array:
	var ready: Array = []
	for node_name in NodeSystem.get_node_names():
		if NodeSystem.is_upgrade_ready(node_name):
			ready.append(node_name)
	ready.sort_custom(func(a: String, b: String) -> bool:
		var ta: NodeStat = NodeSystem.get_node_stat(a)
		var tb: NodeStat = NodeSystem.get_node_stat(b)
		var tier_a: int = ta.tier if ta else 99
		var tier_b: int = tb.tier if tb else 99
		return tier_a != tier_b and tier_a < tier_b or (tier_a == tier_b and a < b)
	)
	return ready

func _open_upgrade_slide_panel() -> void:
	_slide_panel_open = true
	_refresh_upgrade_slide_panel()
	var mini_rect := _mini_node_tree.get_global_rect()
	_upgrade_slide_panel.custom_minimum_size.y = int(mini_rect.size.y)
	# Start at mini view's left edge (tucked behind it), slide LEFT to reveal
	var target_x: float = mini_rect.position.x - UPGRADE_PANEL_W
	_upgrade_slide_panel.position = Vector2(mini_rect.position.x, mini_rect.position.y)
	_upgrade_slide_panel.visible = true
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.tween_property(_upgrade_slide_panel, "position:x", target_x, 0.20) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _close_upgrade_slide_panel() -> void:
	_slide_panel_open = false
	_last_ready_nodes = []
	if _slide_tween:
		_slide_tween.kill()
	_slide_tween = create_tween()
	var mini_rect := _mini_node_tree.get_global_rect()
	# Slide RIGHT back under the mini view, then hide
	_slide_tween.tween_property(_upgrade_slide_panel, "position:x", mini_rect.position.x, 0.16) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_slide_tween.tween_callback(func(): _upgrade_slide_panel.visible = false)

func _refresh_upgrade_slide_panel() -> void:
	if not _upgrade_slide_list:
		return

	# Immediately free all old children so get_children() is clean before adding new ones
	for child in _upgrade_slide_list.get_children():
		child.free()

	var title := Label.new()
	title.text = "Quick Upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90))
	_upgrade_slide_list.add_child(title)
	_upgrade_slide_list.add_child(HSeparator.new())

	var ready_nodes: Array = _collect_ready_nodes()
	_last_ready_nodes = ready_nodes.duplicate()

	for node_name: String in ready_nodes:
		var stat: NodeStat = NodeSystem.get_node_stat(node_name)
		if not stat:
			continue
		var branch_col: Color = UITheme.get_branch_color(node_name)
		var level: int = NodeSystem.get_node_level(node_name)

		# Full-width clickable Button per upgrade item
		var btn := Button.new()
		btn.text = "%s  Lv.%d → %d" % [stat.display_name, level, level + 1]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.clip_text = false
		btn.add_theme_color_override("font_color", branch_col.lightened(0.25))
		btn.add_theme_font_size_override("font_size", 11)

		# Normal style — dark with left branch-color accent bar
		var sn := StyleBoxFlat.new()
		sn.bg_color = branch_col.darkened(0.72)
		sn.border_width_left = 4
		sn.border_color = branch_col
		sn.content_margin_left = 10
		sn.content_margin_right = 6
		sn.content_margin_top = 6
		sn.content_margin_bottom = 6
		sn.corner_radius_top_right = 3
		sn.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("normal", sn)

		# Hover style — slightly lighter
		var sh := sn.duplicate() as StyleBoxFlat
		sh.bg_color = branch_col.darkened(0.45)
		sh.border_color = branch_col.lightened(0.15)
		btn.add_theme_stylebox_override("hover", sh)

		# Pressed style — bright flash
		var sp := sn.duplicate() as StyleBoxFlat
		sp.bg_color = branch_col.darkened(0.2)
		sp.border_color = branch_col.lightened(0.35)
		btn.add_theme_stylebox_override("pressed", sp)

		# Focus style — same as hover to avoid ugly default dotted border
		btn.add_theme_stylebox_override("focus", sh.duplicate())

		var captured: String = node_name
		btn.pressed.connect(func() -> void: NodeSystem.upgrade_node(captured))
		_upgrade_slide_list.add_child(btn)

	if ready_nodes.is_empty():
		var empty := Label.new()
		empty.text = "No upgrades\nready yet."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 10)
		empty.add_theme_color_override("font_color", Color(0.45, 0.45, 0.50))
		_upgrade_slide_list.add_child(empty)

func _make_overlay() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 140)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	add_child(panel)
	return panel

# =============================================================================
# Left panel — collapse + tabs
# =============================================================================

func _toggle_collapse() -> void:
	_left_collapsed = not _left_collapsed
	if _left_collapsed:
		_tab_container.visible = false
	_collapse_btn.text = "\u25B6" if _left_collapsed else "\u25C0 Hide"
	var target := LEFT_W_COLLAPSED if _left_collapsed else LEFT_W
	var tween := create_tween()
	tween.tween_property(_left_panel, "custom_minimum_size:x", target, 0.15)
	if not _left_collapsed:
		tween.tween_callback(func(): _tab_container.visible = true)

func _toggle_node_tree() -> void:
	_node_tree_view.visible = not _node_tree_view.visible
	_center_area.mouse_filter = Control.MOUSE_FILTER_STOP if _node_tree_view.visible else Control.MOUSE_FILTER_IGNORE
	_mini_node_tree.is_full_tree_open = _node_tree_view.visible

func _on_tab_changed(_tab: int) -> void:
	pass

# =============================================================================
# Left panel — Entity Info (dynamic content)
# =============================================================================

func _show_entity_hint() -> void:
	for child in _entity_info_box.get_children():
		child.queue_free()
	_info_labels.clear()
	var hint := Label.new()
	hint.text = "Click an entity\nto inspect it."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_entity_info_box.add_child(hint)

func _on_entity_selected(entity: Node) -> void:
	selected_entity = entity
	selected_node_name = ""
	_rebuild_entity_info()
	if _left_collapsed:
		_toggle_collapse()
	_tab_container.current_tab = 0

func _on_upgrade_node_selected(node_name: String) -> void:
	selected_entity = null
	selected_node_name = node_name
	_rebuild_entity_info()
	if _left_collapsed:
		_toggle_collapse()
	_tab_container.current_tab = 0

func _rebuild_entity_info() -> void:
	for child in _entity_info_box.get_children():
		child.queue_free()
	_info_labels.clear()

	if selected_node_name != "":
		_build_node_info()
		return

	if not selected_entity or not is_instance_valid(selected_entity):
		_show_entity_hint()
		return

	var is_slime: bool = selected_entity.is_in_group("slime")
	var is_breakable: bool = selected_entity.is_in_group("breakables")

	var entity_name: String
	if is_slime:
		entity_name = "Slime"
	elif is_breakable:
		entity_name = selected_entity.object_type if "object_type" in selected_entity else "Breakable"
	else:
		entity_name = "Defender"

	var title := Label.new()
	title.text = "\u2014 %s \u2014" % entity_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entity_info_box.add_child(title)
	_entity_info_box.add_child(HSeparator.new())

	_info_labels["hp"] = _add_info_label("HP")
	if not is_breakable:
		_info_labels["atk"] = _add_info_label("ATK")
	_info_labels["def"] = _add_info_label("DEF")

	if is_slime:
		_info_labels["speed"] = _add_info_label("Speed")
		_info_labels["regen"] = _add_info_label("Regen")
		_info_labels["focus"] = _add_info_label("Focus")
	elif not is_breakable:
		if "attack_cooldown" in selected_entity:
			_info_labels["cooldown"] = _add_info_label("Atk CD")
		if "defender_type" in selected_entity:
			_info_labels["type"] = _add_info_label("Type")

func _add_info_label(prefix: String) -> Label:
	var lbl := Label.new()
	lbl.text = prefix + ": \u2014"
	_entity_info_box.add_child(lbl)
	return lbl

func _build_node_info() -> void:
	var node_name := selected_node_name
	var stat: NodeStat = NodeSystem.get_node_stat(node_name)
	if not stat:
		return

	var title := Label.new()
	title.text = "\u2014 %s \u2014" % stat.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entity_info_box.add_child(title)

	var tier_text := "Tier %d" % stat.tier
	if stat.parent_id != "":
		var parent: NodeStat = NodeSystem.get_node_stat(stat.parent_id)
		if parent:
			tier_text += " \u2022 %s" % parent.display_name
	var tier_lbl := Label.new()
	tier_lbl.text = tier_text
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.add_theme_color_override("font_color", UITheme.get_branch_color(node_name))
	_entity_info_box.add_child(tier_lbl)
	_entity_info_box.add_child(HSeparator.new())

	if not stat.is_implemented:
		var locked_lbl := Label.new()
		locked_lbl.text = "Not yet implemented"
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_color_override("font_color", UITheme.COLOR_LOCKED)
		_entity_info_box.add_child(locked_lbl)
		_entity_info_box.add_child(HSeparator.new())
		if stat.description != "":
			var desc := Label.new()
			desc.text = stat.description
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
			_entity_info_box.add_child(desc)
		return

	var level: int = NodeSystem.get_node_level(node_name)
	var cost: float = NodeSystem.get_upgrade_cost(node_name)
	var fill: float = NodeSystem.get_node_fill(node_name)
	var node_connected: bool = NodeSystem.is_connected_to_core(node_name)
	var is_ready: bool = NodeSystem.is_upgrade_ready(node_name)

	var lvl_lbl = _add_info_label("Level")
	lvl_lbl.text = "Level: %d" % level
	_entity_info_box.add_child(HSeparator.new())

	if stat.description != "":
		var desc := Label.new()
		desc.text = stat.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
		_entity_info_box.add_child(desc)
		_entity_info_box.add_child(HSeparator.new())

	var bonuses_header := Label.new()
	bonuses_header.text = "Bonuses:"
	bonuses_header.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	_entity_info_box.add_child(bonuses_header)

	var effects := NodeEffects.get_effect_descriptions(stat, level)
	for i in range(effects.size()):
		var eff_lbl := Label.new()
		eff_lbl.text = "  %s" % effects[i]
		eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if i == 0:
			eff_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		else:
			eff_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.75))
		_entity_info_box.add_child(eff_lbl)

	_entity_info_box.add_child(HSeparator.new())

	if is_ready:
		var lbl = _add_info_label("STATUS")
		lbl.text = "READY TO UPGRADE!"
		lbl.add_theme_color_override("font_color", UITheme.COLOR_UPGRADE_READY)
		var hnt = _add_info_label("HINT")
		hnt.text = "Click upgrade badge to level up"
	elif NodeSystem.is_level_capped(node_name) and fill >= cost * NodeSystem.upgrade_threshold:
		var lbl = _add_info_label("STATUS")
		lbl.text = "LEVEL CAPPED"
		lbl.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))
		var hnt = _add_info_label("HINT")
		hnt.text = "Upgrade parent node first"
		_info_labels["node_fill"] = _add_info_label("Fill")
		_info_labels["node_fill"].text = "Fill: %.0f / %.0f ME (Full)" % [fill, cost]
	elif node_connected:
		var stat_lbl = _add_info_label("Status")
		stat_lbl.text = "Status: Connected"
		_info_labels["node_fill"] = _add_info_label("Fill")
		_info_labels["node_fill"].text = "Fill: %.0f / %.0f ME" % [fill, cost]
	else:
		var status := "Disconnected"
		if NodeSystem.connections.size() >= NodeSystem.get_max_connections():
			status = "No slots available"
		var stat_lbl = _add_info_label("Status")
		stat_lbl.text = "Status: " + status
		var cost_lbl = _add_info_label("Cost")
		cost_lbl.text = "Cost: %.0f ME" % cost
		if fill > 0:
			_info_labels["node_fill"] = _add_info_label("Stored Fill")
			_info_labels["node_fill"].text = "Stored Fill: %.0f / %.0f ME" % [fill, cost]

func _update_entity_info() -> void:
	if selected_node_name != "":
		if _info_labels.has("node_fill"):
			var cost: float = NodeSystem.get_upgrade_cost(selected_node_name)
			var fill: float = NodeSystem.get_node_fill(selected_node_name)
			_info_labels["node_fill"].text = "Fill: %.0f / %.0f ME" % [fill, cost]
			if NodeSystem.is_upgrade_ready(selected_node_name) or (NodeSystem.is_level_capped(selected_node_name) and fill >= cost * NodeSystem.upgrade_threshold):
				_rebuild_entity_info()
		return

	if not selected_entity or not is_instance_valid(selected_entity):
		if _info_labels.size() > 0:
			_show_entity_hint()
			selected_entity = null
		return

	var e = selected_entity
	if _info_labels.has("hp"):
		_info_labels["hp"].text = "HP: %.0f / %.0f" % [e.current_health, e.max_health]
	if _info_labels.has("atk"):
		_info_labels["atk"].text = "ATK: %.1f" % e.physical_damage
	if _info_labels.has("def"):
		_info_labels["def"].text = "DEF: %.1f" % e.physical_defense
	if _info_labels.has("speed"):
		_info_labels["speed"].text = "Speed: %.0f" % e.current_speed
	if _info_labels.has("regen"):
		_info_labels["regen"].text = "Regen: %.1f/s" % e.health_regen
	if _info_labels.has("focus"):
		_info_labels["focus"].text = "Focus: %s" % ("ON" if e.focus_active else "OFF")
	if _info_labels.has("cooldown") and "attack_cooldown" in e:
		_info_labels["cooldown"].text = "Atk CD: %.2fs" % e.attack_cooldown
	if _info_labels.has("type") and "defender_type" in e:
		_info_labels["type"].text = "Type: %s" % e.defender_type

# =============================================================================
# Settings tab
# =============================================================================

func _build_settings_tab(parent: VBoxContainer) -> void:
	for child in parent.get_children():
		child.queue_free()
		
	if not Globals.enable_testing_cheats:
		var lbl := Label.new()
		lbl.text = "Settings coming soon."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		parent.add_child(lbl)
		return

	_add_section_header(parent, "Testing & Cheats")
	var tlbl := Label.new()
	tlbl.text = "These override global flow."
	tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tlbl.add_theme_color_override("font_color", UITheme.COLOR_LOCKED)
	parent.add_child(tlbl)
	parent.add_child(HSeparator.new())

	# Multiplier Slider
	var mult_row = VBoxContainer.new()
	var mult_lbl = Label.new()
	mult_lbl.text = "Testing Multiplier: %.1fx" % Globals.testing_multiplier
	mult_row.add_child(mult_lbl)
	var mult_slider = HSlider.new()
	mult_slider.min_value = 1.0
	mult_slider.max_value = 200.0
	mult_slider.step = 1.0
	mult_slider.value = Globals.testing_multiplier
	mult_slider.value_changed.connect(func(v): 
		Globals.testing_multiplier = v
		mult_lbl.text = "Testing Multiplier: %.1fx" % v
	)
	mult_row.add_child(mult_slider)
	parent.add_child(mult_row)
	parent.add_child(HSeparator.new())

	# Game Speed
	var spd_row = VBoxContainer.new()
	var spd_lbl = Label.new()
	spd_lbl.text = "Game Speed: %.1fx" % Engine.time_scale
	spd_row.add_child(spd_lbl)
	var spd_slider = HSlider.new()
	spd_slider.min_value = 1.0
	spd_slider.max_value = 5.0
	spd_slider.step = 1.0
	spd_slider.value = Engine.time_scale
	spd_slider.value_changed.connect(func(v): 
		Engine.time_scale = v
		spd_lbl.text = "Game Speed: %.1fx" % v
	)
	spd_row.add_child(spd_slider)
	parent.add_child(spd_row)
	parent.add_child(HSeparator.new())

	# God Mode
	var god_chk = CheckButton.new()
	god_chk.text = "Slime God Mode"
	god_chk.button_pressed = Globals.testing_god_mode
	god_chk.toggled.connect(func(v): Globals.testing_god_mode = v)
	parent.add_child(god_chk)

	# Insta Kill
	var kill_chk = CheckButton.new()
	kill_chk.text = "Slime Insta-Kill"
	kill_chk.button_pressed = Globals.testing_insta_kill
	kill_chk.toggled.connect(func(v): Globals.testing_insta_kill = v)
	parent.add_child(kill_chk)
	parent.add_child(HSeparator.new())

	# Unlock All Nodes
	var unl_btn = Button.new()
	unl_btn.text = "Unlock All Nodes"
	unl_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 1.0))
	unl_btn.pressed.connect(func(): NodeSystem.unlock_all_for_testing())
	parent.add_child(unl_btn)

# =============================================================================
# Karma tab
# =============================================================================

func _build_karma_tab(parent: VBoxContainer) -> void:
	_add_section_header(parent, "Prestige")
	_karma_labels["current_mult"] = _add_karma_row(parent, "Current Multiplier")
	_karma_labels["next_mult"] = _add_karma_row(parent, "If Reset Now")
	parent.add_child(HSeparator.new())

	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 6)
	parent.add_child(btn_box)

	_prestige_btn = Button.new()
	_prestige_btn.text = "\u2728 Prestige Reset"
	_prestige_btn.custom_minimum_size.y = 30
	_prestige_btn.pressed.connect(func(): if GameManager.can_prestige_reset(): SignalBus.reset_confirmation_requested.emit())
	btn_box.add_child(_prestige_btn)

	parent.add_child(HSeparator.new())
	_add_section_header(parent, "Current Run")
	_karma_labels["floors"] = _add_karma_row(parent, "Floors Cleared")
	_karma_labels["run_xp"] = _add_karma_row(parent, "Run XP")
	_karma_labels["run_me"] = _add_karma_row(parent, "Run Energy")
	_karma_labels["run_defenders"] = _add_karma_row(parent, "Defenders Defeated")
	_karma_labels["run_objects"] = _add_karma_row(parent, "Objects Destroyed")
	_karma_labels["run_heroes"] = _add_karma_row(parent, "Heroes Killed")

	parent.add_child(HSeparator.new())
	_add_section_header(parent, "Lifetime")
	_karma_labels["resets"] = _add_karma_row(parent, "Total Resets")
	_karma_labels["lifetime_xp"] = _add_karma_row(parent, "Lifetime XP")
	_karma_labels["lifetime_me"] = _add_karma_row(parent, "Lifetime Energy")
	_karma_labels["lifetime_defenders"] = _add_karma_row(parent, "Defenders Defeated")
	_karma_labels["lifetime_objects"] = _add_karma_row(parent, "Objects Destroyed")
	_karma_labels["lifetime_heroes"] = _add_karma_row(parent, "Heroes Killed")

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = "\u2014 %s \u2014" % text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(lbl)

func _add_karma_row(parent: VBoxContainer, label_text: String) -> Label:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var val := Label.new()
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	parent.add_child(row)
	return val

func _update_karma_tab() -> void:
	if _karma_labels.has("current_mult"):
		_karma_labels["current_mult"].text = "x%.2f" % GameManager.reset_multiplier
	if _karma_labels.has("next_mult"):
		var gain: float = GameManager.get_prestige_gain(GameManager.current_run_xp)
		var potential: float = GameManager.reset_multiplier + gain
		if gain > 0.001:
			_karma_labels["next_mult"].text = "x%.2f (+%.2f)" % [potential, gain]
			_karma_labels["next_mult"].add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
		else:
			_karma_labels["next_mult"].text = "x%.2f (+0.00)" % potential
			_karma_labels["next_mult"].add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if _karma_labels.has("floors"):
		_karma_labels["floors"].text = str(GameManager.current_room_index)
	if _karma_labels.has("resets"):
		_karma_labels["resets"].text = str(GameManager.total_resets)

	if _karma_labels.has("run_xp"):
		_karma_labels["run_xp"].text = "%.0f" % GameManager.current_run_xp
	if _karma_labels.has("lifetime_xp"):
		_karma_labels["lifetime_xp"].text = "%.0f" % GameManager.lifetime_xp

	if _karma_labels.has("run_me"):
		_karma_labels["run_me"].text = "%.0f" % MonsterEnergy.current_run_energy
	if _karma_labels.has("lifetime_me"):
		_karma_labels["lifetime_me"].text = "%.0f" % MonsterEnergy.lifetime_energy

	if _karma_labels.has("run_defenders"):
		_karma_labels["run_defenders"].text = str(GameManager.run_defenders_defeated)
	if _karma_labels.has("lifetime_defenders"):
		_karma_labels["lifetime_defenders"].text = str(GameManager.lifetime_defenders_defeated)

	if _karma_labels.has("run_objects"):
		_karma_labels["run_objects"].text = str(GameManager.run_objects_destroyed)
	if _karma_labels.has("lifetime_objects"):
		_karma_labels["lifetime_objects"].text = str(GameManager.lifetime_objects_destroyed)

	if _karma_labels.has("run_heroes"):
		_karma_labels["run_heroes"].text = str(GameManager.run_heroes_killed)
	if _karma_labels.has("lifetime_heroes"):
		_karma_labels["lifetime_heroes"].text = str(GameManager.lifetime_heroes_killed)

	if _prestige_btn:
		var can_reset = GameManager.can_prestige_reset()
		_prestige_btn.disabled = not can_reset
		if can_reset:
			_prestige_btn.text = "\u2728 Prestige Reset"
		else:
			_prestige_btn.text = "\u2728 Requires +5.0 Gain or Death"

# =============================================================================
# Right panel — live updates
# =============================================================================

func _update_right_panel() -> void:
	if not slime or not is_instance_valid(slime):
		return

	# --- Stat breakdowns using NodeEffects ---
	var b := NodeSystem.get_all_bonuses()
	var int_lvl := NodeSystem.get_node_level("intelligence")
	var sd = slime.slime_data

	var max_momentum: float = 1.0 + b.get("momentum_cap", 0.0)

	_hp_bar.set_values(slime.current_health, slime.max_health)
	
	var max_potential_speed: float = slime.current_speed * (1.0 + slime.slime_data.max_speed_bonus * max_momentum)
	_speed_bar.set_values(slime.velocity.length(), max_potential_speed,
		"%.0f/%.0f" % [slime.velocity.length(), max_potential_speed],
		slime.current_speed)

	var seek_max: float = NodeSystem.get_seek_time()
	_seek_bar.set_values(slime.seek_timer, seek_max, "%.1f/%.1fs" % [slime.seek_timer, seek_max])

	_mtm_bar.set_values(slime.momentum, max_momentum, "%.0f%%" % (slime.momentum * 100.0))

	# Max HP: base + flat bonus
	var hp_base: float = sd.base_health
	var hp_bonus: float = b.get("max_hp", 0.0)
	_set_stat_bkdn("max_hp", slime.max_health, hp_base, hp_bonus, "%.0f",
		"Max HP Breakdown:\n  Base: %.0f\n  Nodes: +%.0f" % [hp_base, hp_bonus])

	# HP Regen
	var regen_bonus: float = b.get("hp_regen", 0.0)
	_set_stat_bkdn("hp_regen", slime.health_regen, 0.0, regen_bonus, "%.1f",
		"HP Regen Breakdown:\n  Base: 0.0\n  Nodes: +%.1f" % [regen_bonus])

	# Defense
	var def_bonus: float = b.get("physical_defense", 0.0)
	_set_stat_bkdn("defense", slime.physical_defense, sd.base_defense, def_bonus, "%.1f",
		"Defense Breakdown:\n  Base: %.1f\n  Nodes: +%.1f" % [sd.base_defense, def_bonus])

	# Phys DMG
	var dmg_base: float = sd.base_damage
	var dmg_mult: float = b.get("damage_mult", 0.0)
	var dmg_bonus := dmg_base * dmg_mult
	_set_stat_bkdn("phys_dmg", slime.physical_damage, dmg_base, dmg_bonus, "%.1f",
		"Phys DMG Breakdown:\n  Base: %.1f\n  Nodes: +%.1f (x%.2f)" % [dmg_base, dmg_bonus, 1.0 + dmg_mult])

	# Max Speed
	var spd_base: float = sd.base_speed
	var spd_mult: float = b.get("speed_mult", 0.0)
	var spd_bonus := spd_base * spd_mult
	_set_stat_bkdn("max_speed", slime.current_speed, spd_base, spd_bonus, "%.0f",
		"Max Speed Breakdown:\n  Base: %.0f\n  Nodes: +%.0f (x%.2f)" % [spd_base, spd_bonus, 1.0 + spd_mult])

	# Momentum dmg multiplier
	var mom_base: float = sd.momentum_damage_multiplier
	var mom_mult: float = b.get("momentum_mult", 0.0)
	var mom_bonus := mom_base * mom_mult
	_set_stat_bkdn("mom_dmg", slime.momentum_damage_multiplier, mom_base, mom_bonus, "x%.3f",
		"Momentum DMG Multiplier:\n  Base: x%.3f\n  Nodes: +%.3f" % [mom_base, mom_bonus])

	# Momentum speed bonus
	var mom_spd_max: float = sd.max_speed_bonus * 100.0 * max_momentum
	var mom_spd_cur: float = float(slime.momentum) * sd.max_speed_bonus * 100.0
	_set_stat_text("mom_spd", "+%.0f%% spd (%.0f%% max)" % [mom_spd_cur, mom_spd_max],
		"Momentum Speed Bonus:\n  Current: +%.0f%% speed\n  Max at %.0f%% momentum: +%.0f%% speed" % [mom_spd_cur, max_momentum * 100.0, mom_spd_max])

	# Seek Time
	var seek_base := 9.0
	var seek_red := seek_base - seek_max
	_set_stat_bkdn("seek_time", seek_max, seek_base, -seek_red, "%.1f",
		"Seek Timer Breakdown:\n  Base: %.1fs\n  Intelligence: -%.1fs (Asymptotic)\n  Min curve: 3.0s" % [seek_base, seek_red])

	# Focus
	var focus_lvl := NodeSystem.get_node_level("focus")
	var focus_threshold := NodeSystem.get_focus_threshold()
	var focus_text := "ON" if slime.focus_active else "OFF"
	if focus_lvl < 1:
		focus_text = "LOCKED"
		
	var focus_tt := "Focus Mode:\n  Requires Focus Node\n"
	if focus_lvl >= 1:
		focus_tt += "  Activates at <= %d enemies\n  5x Auto-Seek frequency when active" % focus_threshold
	_set_stat_text("focus", focus_text, focus_tt)

	if focus_lvl >= 1:
		_focus_label.text = "Focus at <= %d enemies (Lv.%d)" % [focus_threshold, focus_lvl]
		_focus_label.add_theme_color_override("font_color", UITheme.COLOR_INTELLIGENCE.darkened(0.3))
	else:
		_focus_label.text = "Focus unlocks via Node"
		_focus_label.add_theme_color_override("font_color", UITheme.COLOR_LOCKED)

	_me_label.text = "ME: %.0f" % MonsterEnergy.current_energy

func _set_stat_bkdn(key: String, total: float, base_val: float, bonus: float, fmt: String, tooltip: String) -> void:
	if not _stats.has(key):
		return
	var text: String
	if absf(bonus) > 0.001:
		var sign_str := "+" if bonus >= 0 else ""
		text = (fmt % total) + " (" + (fmt % base_val) + sign_str + (fmt % bonus) + ")"
	else:
		text = fmt % total
	_stats[key].set_value_text(text)
	_stat_tooltips[key] = tooltip

func _set_stat_text(key: String, text: String, tooltip: String) -> void:
	if not _stats.has(key):
		return
	_stats[key].set_value_text(text)
	_stat_tooltips[key] = tooltip

# =============================================================================
# Tooltip
# =============================================================================

func _show_stat_tooltip(key: String, row: Control) -> void:
	if not _stat_tooltips.has(key):
		return
	_tooltip_label.text = _stat_tooltips[key]
	_tooltip_panel.visible = true
	var row_rect := row.get_global_rect()
	_tooltip_panel.reset_size()
	await get_tree().process_frame
	var tip_size := _tooltip_panel.size
	_tooltip_panel.global_position = Vector2(
		row_rect.position.x - tip_size.x - 8,
		row_rect.position.y
	)

func _hide_stat_tooltip() -> void:
	_tooltip_panel.visible = false

func _update_me_display() -> void:
	_me_label.text = "ME: %.0f" % MonsterEnergy.current_energy

# =============================================================================
# Signal handlers
# =============================================================================

func _on_room_loaded(room_index: int) -> void:
	_room_label.text = "Room: %d/%d" % [room_index + 1, Globals.TOTAL_ROOMS]
	selected_entity = null
	_show_entity_hint()

func _show_confirm() -> void:
	var potential: float = GameManager.reset_multiplier + GameManager.get_prestige_gain(GameManager.current_run_xp)
	_confirm_msg.text = "Prestige Reset?\nCurrent: x%.2f  \u2192  New: x%.2f\nAll node levels will reset." % [
		GameManager.reset_multiplier, potential]
	_confirm_panel.visible = true

func _on_game_over() -> void:
	_gameover_label.text = "Game Over!"
	_gameover_panel.visible = true

func _on_game_won() -> void:
	_gameover_label.text = "Victory!\nAll 40 rooms cleared!\nPress R to Reset"
	_gameover_panel.visible = true

func _on_reset() -> void:
	_gameover_panel.visible = false
	_confirm_panel.visible = false
	await get_tree().create_timer(0.2).timeout
	slime = get_tree().get_first_node_in_group("slime")
	selected_entity = null
	_show_entity_hint()
	_update_me_display()
