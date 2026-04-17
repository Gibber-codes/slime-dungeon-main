extends BaseEntity

# Defender entity — attacks the slime when it enters range.
# Stats come from the assigned EntityData resource.
# Attack behavior (charge-up, cooldown, slash) lives here.

signal defeated()
signal attacked_player(damage: float)

var death_effect_scene: PackedScene = preload("res://effects/DeathPoof.tscn")
var damage_number_scene: PackedScene = preload("res://effects/DamageNumber.tscn")
var slash_effect_scene: PackedScene = preload("res://effects/SlashEffect.tscn")

var slime_in_range: Node2D = null
var attack_range_area: Area2D = null
var health_bar: ProgressBar = null
var cooldown_bar: ProgressBar = null

# ── Attack range (read from entity_data or fallback to export) ──────────────
## Local copy of attack range for runtime use (initialized from entity_data)
var _attack_range: float = 38.4
var _attack_speed: float = 0.2
var _attack_cooldown: float = 2.0

# ── Range indicator (Phase 1) ───────────────────────────────────────────────
# Grey dashed circle that fades in as the slime approaches.
# Visible from 2× attack_range, full alpha at the range boundary.
var range_indicator_alpha: float = 0.0
const RANGE_INDICATOR_FADE_DIST_MULT: float = 2.0  # starts fading in at this × attack_range
const RANGE_INDICATOR_MAX_ALPHA: float = 0.175

# ── Charge-up (Phase 2) ────────────────────────────────────────────────────
# Red circle that expands from center to attack_range over attack_speed.
var charge_radius: float = 0.0
var charge_active: bool = false
var charge_tween: Tween = null
var on_cooldown: bool = false  # True during the idle wait between attacks
var cooldown_progress: float = 0.0  # 0.0 → 1.0 during cooldown (for the arc indicator)
var cooldown_tween: Tween = null

func _ready() -> void:
	super._ready()

	# Read combat params and visuals from entity_data (falls back to defaults if not set)
	if entity_data:
		_attack_range = entity_data.attack_range
		_attack_speed = entity_data.attack_speed
		_attack_cooldown = entity_data.attack_cooldown
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite and entity_data.sprite_texture:
			sprite.texture = entity_data.sprite_texture
			sprite.scale = entity_data.sprite_scale
			sprite.position = entity_data.sprite_offset

	# Safety net: ensure room-clear tracking even if entity_data isn't assigned
	if not is_in_group("room_entities"):
		add_to_group("room_entities")
	if not is_in_group("defenders"):
		add_to_group("defenders")

	attack_range_area = get_node("AttackRange")
	health_bar = get_node("HealthBar")
	cooldown_bar = get_node_or_null("CooldownBar")

	# Sync the collision shape radius to the attack range so detection matches visuals
	var shape_node: CollisionShape2D = attack_range_area.get_node("CollisionShape2D")
	if shape_node and shape_node.shape is CircleShape2D:
		shape_node.shape = shape_node.shape.duplicate()
		shape_node.shape.radius = _attack_range

	attack_range_area.body_entered.connect(_on_attack_range_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_body_exited)

	health_changed.connect(_on_health_changed)
	_setup_health_bar()
	if cooldown_bar:
		cooldown_bar.value = 0.0
		cooldown_bar.visible = false
	_update_health_bar()

func _process(_delta: float) -> void:
	_update_range_indicator()
	_update_cooldown_bar()
	queue_redraw()

func _draw() -> void:
	# Ground shadow for 3/4 perspective
	var points: PackedVector2Array = []
	var segments: int = 20
	var rx: float = 12.0
	var ry: float = 5.0
	var center := Vector2(0, 4)
	for i in range(segments):
		var angle: float = (float(i) / segments) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.2))

	# ── Phase 1: Range indicator (dashed grey circle) ───────────────────
	if range_indicator_alpha > 0.01:
		_draw_dashed_circle(Vector2.ZERO, _attack_range, range_indicator_alpha)

	# ── Phase 2: Charge-up circle (expanding red) ──────────────────────
	if charge_active and charge_radius > 0.0:
		var charge_t: float = charge_radius / max(_attack_range, 1.0)
		# Semi-transparent red fill
		var fill_alpha: float = 0.08 + charge_t * 0.07
		draw_circle(Vector2.ZERO, charge_radius, Color(0.9, 0.15, 0.15, fill_alpha))
		# Bright edge ring
		var edge_alpha: float = 0.3 + charge_t * 0.4
		draw_arc(Vector2.ZERO, charge_radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, edge_alpha), 1.5)

# =============================================================================
# Difficulty — delegates to BaseEntity, then updates UI
# =============================================================================

func apply_difficulty(difficulty: float, room_index: int) -> void:
	super.apply_difficulty(difficulty, room_index)
	_update_health_bar()

# =============================================================================
# Phase 1 — Range indicator
# =============================================================================

func _update_range_indicator() -> void:
	var slime: Node2D = _find_nearest_slime()
	if not slime:
		range_indicator_alpha = move_toward(range_indicator_alpha, 0.0, 0.02)
		return

	var dist: float = global_position.distance_to(slime.global_position)
	var fade_start: float = _attack_range * RANGE_INDICATOR_FADE_DIST_MULT
	var fade_end: float = _attack_range

	if dist >= fade_start:
		range_indicator_alpha = move_toward(range_indicator_alpha, 0.0, 0.02)
	elif dist <= fade_end:
		range_indicator_alpha = move_toward(range_indicator_alpha, RANGE_INDICATOR_MAX_ALPHA, 0.04)
	else:
		# Linearly interpolate between fade_start and fade_end
		var t: float = 1.0 - (dist - fade_end) / (fade_start - fade_end)
		var target_alpha: float = t * RANGE_INDICATOR_MAX_ALPHA
		range_indicator_alpha = move_toward(range_indicator_alpha, target_alpha, 0.04)

func _find_nearest_slime() -> Node2D:
	if not is_inside_tree():
		return null
	var slimes: Array = get_tree().get_nodes_in_group("slime")
	var closest: Node2D = null
	var closest_dist: float = INF
	for s in slimes:
		if not is_instance_valid(s):
			continue
		var d: float = global_position.distance_to(s.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = s
	return closest

func _draw_dashed_circle(pos: Vector2, radius: float, alpha: float) -> void:
	var total_segments: int = 24
	var dash_count: int = total_segments / 2  # half dash, half gap
	var color := Color(0.7, 0.7, 0.7, alpha)
	for i in range(dash_count):
		var start_angle: float = (float(i * 2) / total_segments) * TAU
		var end_angle: float = (float(i * 2 + 1) / total_segments) * TAU
		draw_arc(pos, radius, start_angle, end_angle, 6, color, 1.5)

# =============================================================================
# Phase 2 — Charge-up attack
# =============================================================================

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("slime"):
		slime_in_range = body
		_start_charge()

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("slime") and body == slime_in_range:
		slime_in_range = null
		_cancel_charge()

func _start_charge() -> void:
	if on_cooldown:
		return
	_cancel_charge()
	charge_active = true
	charge_radius = 0.0

	charge_tween = create_tween()
	charge_tween.set_ease(Tween.EASE_IN)
	charge_tween.set_trans(Tween.TRANS_QUAD)
	charge_tween.tween_property(self, "charge_radius", _attack_range, _attack_speed)
	charge_tween.tween_callback(_on_charge_complete)

func _cancel_charge() -> void:
	if charge_tween and charge_tween.is_valid():
		charge_tween.kill()
	charge_tween = null
	charge_active = false
	charge_radius = 0.0

func _on_charge_complete() -> void:
	_attack_player()
	_cancel_charge()
	# Start cooldown before the next attack
	on_cooldown = true
	cooldown_progress = 0.0
	if cooldown_tween and cooldown_tween.is_valid():
		cooldown_tween.kill()
	if cooldown_bar:
		cooldown_bar.visible = true
	cooldown_tween = create_tween()
	cooldown_tween.tween_property(self, "cooldown_progress", 1.0, _attack_cooldown)
	cooldown_tween.tween_callback(_on_cooldown_finished)

func _on_cooldown_finished() -> void:
	on_cooldown = false
	cooldown_progress = 0.0
	if cooldown_bar:
		cooldown_bar.visible = false
	# If slime is still in range, start the next charge
	if slime_in_range and is_instance_valid(slime_in_range):
		_start_charge()

# =============================================================================
# Phase 3 — Attack + slash effect
# =============================================================================

func _attack_player() -> void:
	if not slime_in_range or not is_instance_valid(slime_in_range):
		return
	if not slime_in_range.has_method("take_damage"):
		return
	slime_in_range.take_damage(physical_damage)
	attacked_player.emit(physical_damage)

	# Red damage number on slime
	var dmg_num: Node2D = damage_number_scene.instantiate()
	dmg_num.global_position = slime_in_range.global_position + Vector2(randf_range(-8, 8), -8)
	dmg_num.setup(physical_damage, UITheme.COLOR_DEBUFF)
	get_tree().current_scene.add_child(dmg_num)

	# Slash effect — clamped within attack range
	var slash: Node2D = slash_effect_scene.instantiate()
	var to_slime: Vector2 = slime_in_range.global_position - global_position
	var clamped_dist: float = min(to_slime.length(), _attack_range * 0.85)
	var slash_pos: Vector2 = global_position + to_slime.normalized() * clamped_dist
	slash.global_position = slash_pos
	slash.setup(to_slime.normalized())
	get_tree().current_scene.add_child(slash)

# =============================================================================
# Health UI
# =============================================================================

func _on_health_changed(_current: float, _max_hp: float) -> void:
	_update_health_bar()

func _setup_health_bar() -> void:
	if not health_bar:
		return
	# Make the health bar thinner (3px tall) and red
	health_bar.offset_top = -20.0
	health_bar.offset_bottom = -17.0
	health_bar.offset_left = -16.0
	health_bar.offset_right = 16.0
	# Style overrides for red fill
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.15, 0.15)
	fill_style.corner_radius_top_left = 1
	fill_style.corner_radius_top_right = 1
	fill_style.corner_radius_bottom_left = 1
	fill_style.corner_radius_bottom_right = 1
	health_bar.add_theme_stylebox_override("fill", fill_style)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	bg_style.corner_radius_top_left = 1
	bg_style.corner_radius_top_right = 1
	bg_style.corner_radius_bottom_left = 1
	bg_style.corner_radius_bottom_right = 1
	health_bar.add_theme_stylebox_override("background", bg_style)

func _update_cooldown_bar() -> void:
	if cooldown_bar:
		cooldown_bar.value = cooldown_progress

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func die() -> void:
	_cancel_charge()
	defeated.emit()
	var effect: Node2D = death_effect_scene.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(1.0)
	super.die()
	queue_free()
