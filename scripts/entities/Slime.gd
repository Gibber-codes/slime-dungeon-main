extends BaseEntity

## Tuning resource — assign in the Inspector (default: resources/entities/slime.tres).
## All base stats, momentum tuning, and bounce behavior come from this resource.
@export var slime_data: SlimeData = preload("res://resources/entities/slime.tres")

# Movement
var base_speed: float = 300.0
var current_speed: float = 300.0
var bounciness: float = 1.0
var momentum_damage_multiplier: float = 0.12

# Momentum (0.0 to 1.0)
var momentum: float = 0.0
var momentum_speed: float = 0.0  # actual speed including momentum bonus

# Auto-seek
var seek_timer: float = 0.0
var seeking: bool = false
var seek_target: Node2D = null

# Focus mode
var focus_active: bool = false

# State Machine
var state_machine

const EXIT_SEEK_STRENGTH := 0.15

# Hit freeze guard
var _freezing: bool = false

# Effects
var hit_effect_scene: PackedScene = preload("res://effects/HitEffect.tscn")
var bounce_effect_scene: PackedScene = preload("res://effects/BounceSplash.tscn")
var damage_number_scene: PackedScene = preload("res://effects/DamageNumber.tscn")

func _ready() -> void:
	super._ready()

	# Pull base tuning from SlimeData (set in Inspector)
	base_speed = slime_data.base_speed
	current_speed = base_speed
	momentum_damage_multiplier = slime_data.momentum_damage_multiplier
	bounciness = slime_data.bounciness
	max_health = slime_data.base_health
	current_health = max_health
	physical_damage = slime_data.base_damage
	physical_defense = slime_data.base_defense

	# Apply sprite from slime_data so the .tres controls the visual
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and slime_data.sprite_texture:
		sprite.texture = slime_data.sprite_texture
		sprite.scale = slime_data.sprite_scale
		sprite.position = slime_data.sprite_offset

	add_to_group("slime")
	# Slime lives under Main (sibling of Room), so Room's YSort can't reach it.
	# Use absolute z_index keyed to global Y so the slime draws above the Room floor
	# and interleaves correctly with YSorted defenders/breakables inside Room.
	z_as_relative = false
	_apply_node_stats()
	_initialize_random_velocity()

	SignalBus.stats_changed.connect(_apply_node_stats)
	SignalBus.reset_triggered.connect(_on_reset)
	SignalBus.room_transition_completed.connect(_on_room_loaded)
	SignalBus.room_exit_opened.connect(_on_exit_opened)
	SignalBus.room_cleared.connect(_on_room_cleared)

	# Initialize State Machine
	var StateMachineClass = preload("res://scripts/systems/state_machine/StateMachine.gd")
	state_machine = StateMachineClass.new()
	state_machine.name = "StateMachine"
	
	var state_entering = preload("res://scripts/entities/slime_states/SlimeEnteringState.gd").new()
	state_entering.name = "Entering"
	state_machine.add_child(state_entering)
	
	var state_combat = preload("res://scripts/entities/slime_states/SlimeCombatState.gd").new()
	state_combat.name = "Combat"
	state_machine.add_child(state_combat)
	
	var state_seek = preload("res://scripts/entities/slime_states/SlimeSeekExitState.gd").new()
	state_seek.name = "SeekExit"
	state_machine.add_child(state_seek)
	
	var state_exiting = preload("res://scripts/entities/slime_states/SlimeExitingState.gd").new()
	state_exiting.name = "Exiting"
	state_machine.add_child(state_exiting)
	
	state_machine.initial_state = ^"Entering"
	
	add_child(state_machine)

func _apply_node_stats() -> void:
	var b := NodeSystem.get_all_bonuses()

	# Damage: base * (1 + damage_mult)
	physical_damage = slime_data.base_damage * (1.0 + b.get("damage_mult", 0.0))
	momentum_damage_multiplier = slime_data.momentum_damage_multiplier * (1.0 + b.get("momentum_mult", 0.0))

	# Health: base + flat max_hp bonus
	var old_max: float = max_health
	max_health = slime_data.base_health + b.get("max_hp", 0.0)
	if old_max > 0:
		current_health = current_health * (max_health / old_max)
	health_changed.emit(current_health, max_health)

	# Regen: flat hp_regen (Stamina + Regeneration both contribute)
	health_regen = b.get("hp_regen", 0.0)

	# Speed: base * (1 + speed_mult)
	current_speed = base_speed * (1.0 + b.get("speed_mult", 0.0))

	# Defense: base + flat physical_defense (Mass contributes when implemented)
	physical_defense = slime_data.base_defense + b.get("physical_defense", 0.0)

func _process(delta: float) -> void:
	super._process(delta)
	_update_momentum(delta)
	_update_visuals()
	# Dynamic z-index for 3/4 perspective — needed because Slime is not a child
	# of Room's YSort tree.
	z_index = int(global_position.y) + 1000

# physics_process logic moved to StateMachine states

# =============================================================================
# Momentum
# =============================================================================

func _clamp_momentum() -> void:
	var b := NodeSystem.get_all_bonuses()
	var max_mtm: float = 1.0 + b.get("momentum_cap", 0.0)
	var mtm_floor: float = max_mtm * b.get("focus_momentum_floor", 0.0) if focus_active else 0.0
	momentum = clampf(momentum, mtm_floor, max_mtm)

func _update_momentum(delta: float) -> void:
	# Momentum builds while moving, decays slowly
	var b := NodeSystem.get_all_bonuses()
	var speed_ratio: float = velocity.length() / max(current_speed, 1.0)
	if speed_ratio > 0.1:
		var gain_rate: float = slime_data.momentum_gain_rate * (1.0 + b.get("momentum_gain_rate", 0.0))
		momentum += gain_rate * delta
	else:
		momentum -= slime_data.momentum_decay_rate * delta
	_clamp_momentum()

func _on_entity_hit() -> void:
	# Entity hits: small gain, big decay — net loss early, net gain with agility upgrades
	var b := NodeSystem.get_all_bonuses()
	var decay_reduction: float = b.get("momentum_decay_reduction", 0.0)
	var retention: float = maxf(0.0, 1.0 - b.get("collision_momentum_retention", 0.0))
	var hit_decay: float = maxf(slime_data.entity_hit_decay - decay_reduction, 0.0) * retention
	momentum -= hit_decay
	momentum += slime_data.hit_boost
	_clamp_momentum()

func _decay_momentum_on_bounce(target_bounciness: float) -> void:
	var b := NodeSystem.get_all_bonuses()
	var decay_reduction: float = b.get("momentum_decay_reduction", 0.0)
	var base_bounce_decay: float = maxf(slime_data.bounce_decay - decay_reduction, 0.01)
	
	var retention: float = maxf(0.0, 1.0 - b.get("collision_momentum_retention", 0.0))
	var combined_bounciness: float = minf(1.0, maxf(0.0, bounciness * target_bounciness))
	var decay_amount: float = base_bounce_decay * (1.0 - combined_bounciness) * retention
	
	momentum -= decay_amount
	_clamp_momentum()

# =============================================================================
# Auto-seek
# =============================================================================

func _process_auto_seek(delta: float) -> void:
	var seek_time: float = NodeSystem.get_seek_time()
	var effective_delta := delta
	
	if focus_active:
		effective_delta *= 5.0

	seek_timer += effective_delta

	if seek_timer >= seek_time:
		seeking = true
		_find_seek_target()
		if seek_target and is_instance_valid(seek_target):
			var dir: Vector2 = (seek_target.global_position - global_position).normalized()
			velocity = dir * momentum_speed
			seek_timer = 0.0

func _find_seek_target() -> void:
	var targets: Array = get_tree().get_nodes_in_group("room_entities")
	if targets.is_empty():
		seek_target = null
		return

	var closest: Node2D = null
	var closest_dist: float = INF
	for d in targets:
		if not is_instance_valid(d):
			continue
		var dist: float = global_position.distance_to(d.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = d
	seek_target = closest

func _check_focus_mode() -> void:
	var threshold: int = NodeSystem.get_focus_threshold()
	if threshold <= 0:
		focus_active = false
		return

	var targets: Array = get_tree().get_nodes_in_group("room_entities")
	focus_active = targets.size() <= threshold and targets.size() > 0

# =============================================================================
# Collision
# =============================================================================

func _handle_collision_damage(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()

	if collider and collider.has_method("take_damage") and not collider.is_in_group("slime"):
		var total_damage: float = physical_damage * (1.0 + momentum * momentum_damage_multiplier)
		if Globals.testing_insta_kill:
			total_damage = 9999999.0

		var was_alive: bool = collider.current_health > 0
		collider.take_damage(total_damage)

		# Boost momentum on hit
		_on_entity_hit()

		# Damage number
		var dmg_num: Node2D = damage_number_scene.instantiate()
		dmg_num.global_position = collision.get_position()
		dmg_num.setup(total_damage, Color(1, 0.95, 0.6), focus_active)
		get_tree().current_scene.add_child(dmg_num)

		# Hit effect + camera shake
		_spawn_effect(hit_effect_scene, collision.get_position())
		var cam = get_viewport().get_camera_2d()
		if cam and cam.has_method("shake"):
			cam.shake(0.5)

		# Hit freeze on kill
		if was_alive and collider.current_health <= 0:
			if cam and cam.has_method("shake"):
				cam.shake(1.0)
			_hit_freeze()

		seek_timer = 0.0
		seeking = false

func _handle_bounce(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	var target_bounciness := 0.9 # Default wall bounciness
	
	if collider and "entity_data" in collider and collider.entity_data:
		target_bounciness = collider.entity_data.bounciness
		
	var combined_bounciness: float = minf(1.0, maxf(0.0, bounciness * target_bounciness))
	
	var normal: Vector2 = collision.get_normal()
	velocity = velocity.bounce(normal) * combined_bounciness
	velocity = velocity.rotated(randf_range(-0.1, 0.1))
	_decay_momentum_on_bounce(target_bounciness)
	_spawn_effect(bounce_effect_scene, collision.get_position())

func _spawn_effect(scene: PackedScene, pos: Vector2) -> void:
	var effect: Node2D = scene.instantiate()
	effect.global_position = pos
	get_tree().current_scene.add_child(effect)

# =============================================================================
# Hit Freeze
# =============================================================================

func _hit_freeze() -> void:
	# Locally freeze the slime for a few frames (kill-cam feel) without
	# stalling the HUD, defender tweens, or anything else time-scale would touch.
	if _freezing:
		return
	_freezing = true
	var was_physics: bool = is_physics_processing()
	var saved_velocity: Vector2 = velocity
	velocity = Vector2.ZERO
	set_physics_process(false)
	# ignore_time_scale = true so this timer finishes even if global time_scale changes.
	await get_tree().create_timer(0.04, true, false, true).timeout
	set_physics_process(was_physics)
	velocity = saved_velocity
	_freezing = false

# =============================================================================
# Visuals
# =============================================================================

func _update_visuals() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if not sprite:
		return

	# Scale sprite with momentum
	var scale_factor: float = 1.0 + momentum * 0.2
	sprite.scale = Vector2.ONE * 0.05 * scale_factor

	# 3/4 perspective: offset sprite upward so it "sits above" its shadow/collision
	sprite.position = Vector2(0, -8)

	# Red tint at low HP
	var hp_ratio: float = current_health / max(max_health, 1.0)
	if hp_ratio < 0.3:
		sprite.modulate = Color(1.0, 0.4, 0.4)
	elif hp_ratio < 0.6:
		sprite.modulate = Color(1.0, 0.7 + hp_ratio * 0.5, 0.7 + hp_ratio * 0.5)
	else:
		sprite.modulate = Color.WHITE

	queue_redraw()

func _draw() -> void:
	# Ground shadow (ellipse at the base, where collision is)
	var shadow_alpha: float = 0.22 + momentum * 0.08
	var shadow_rx: float = 10.0 + momentum * 2.0
	var shadow_ry: float = 5.0 + momentum * 1.0
	_draw_shadow_ellipse(Vector2(0, 2), shadow_rx, shadow_ry, Color(0.0, 0.0, 0.0, shadow_alpha))

	# Visual center is offset upward for 3/4 perspective
	var vc := Vector2(0, -8)

	# Focus aura — pulsing yellow-green glow
	if focus_active:
		var pulse: float = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.5
		var aura_alpha: float = 0.15 + pulse * 0.15
		draw_circle(vc, 18.0 + pulse * 4.0, Color(0.9, 1.0, 0.3, aura_alpha))

	# Momentum glow — orange ring that intensifies
	if momentum > 0.1:
		var glow_alpha: float = momentum * 0.4
		var glow_size: float = 14.0 + momentum * 6.0
		draw_arc(vc, glow_size, 0, TAU, 24, Color(1.0, 0.6, 0.2, glow_alpha), 2.0)

	# Speed lines at high momentum
	if momentum > 0.3:
		var alpha: float = momentum * 0.4
		var back: Vector2 = -velocity.normalized()
		var trail_c := Color(1, 0.8, 0.3, alpha)
		for i in range(3):
			var offset := Vector2(randf_range(-4, 4), randf_range(-4, 4))
			var start: Vector2 = vc + back * (10.0 + i * 4.0) + offset
			var end: Vector2 = vc + back * (18.0 + i * 6.0) + offset
			draw_line(start, end, trail_c, 1.5)

func _draw_shadow_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points: PackedVector2Array = []
	var segments: int = 20
	for i in range(segments):
		var angle: float = (float(i) / segments) * TAU
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)

# =============================================================================
# Exit Seeking
# =============================================================================

func _on_exit_opened(exit_pos: Vector2) -> void:
	var pre_exit = exit_pos + Vector2(0, 40) # Stand 40 pixels below the exit door
	state_machine.transition_to("SeekExit", {"target": pre_exit})

# =============================================================================
# Room Boundary Safety
# =============================================================================

func _clamp_to_room_bounds() -> void:
	# Don't clamp when the slime is not in combat
	if state_machine.current_state and state_machine.current_state.name != "Combat":
		return
	# Find the current room to get its bounds
	var rooms: Array = get_tree().get_nodes_in_group("rooms") if is_inside_tree() else []
	var room: Node2D = null
	if rooms.size() > 0:
		room = rooms[0]
	else:
		# Fallback: find room node by name
		room = get_tree().root.find_child("Room", true, false) if is_inside_tree() else null
	if not room:
		return

	# Read room bounds from the room itself (supports any grid_cols/grid_rows)
	const MARGIN: float = 6.0
	var half_w: float = 160.0
	var half_h: float = 160.0
	if "HALF_W" in room and "HALF_H" in room:
		half_w = room.HALF_W
		half_h = room.HALF_H

	var origin: Vector2 = room.global_position
	var min_x: float = origin.x - half_w + MARGIN
	var max_x: float = origin.x + half_w - MARGIN
	var min_y: float = origin.y - half_h + MARGIN
	var max_y: float = origin.y + half_h - MARGIN

	var clamped: bool = false
	if global_position.x < min_x:
		global_position.x = min_x
		velocity.x = absf(velocity.x)
		clamped = true
	elif global_position.x > max_x:
		global_position.x = max_x
		velocity.x = -absf(velocity.x)
		clamped = true
	if global_position.y < min_y:
		global_position.y = min_y
		velocity.y = absf(velocity.y)
		clamped = true
	elif global_position.y > max_y:
		global_position.y = max_y
		velocity.y = -absf(velocity.y)
		clamped = true

# =============================================================================
# Lifecycle
# =============================================================================

func _initialize_random_velocity() -> void:
	var random_angle: float = randf() * TAU
	velocity = Vector2(cos(random_angle), sin(random_angle)) * current_speed

var _dead := false

func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	modulate = Color(1.0, 0.3, 0.3, 0.6)
	super.die()
	SignalBus.slime_died.emit()

func _on_reset() -> void:
	_dead = false
	visible = true
	set_physics_process(true)
	set_process(true)
	modulate = Color.WHITE
	_apply_node_stats()
	current_health = max_health
	health_changed.emit(current_health, max_health)
	seek_timer = 0.0
	seeking = false
	focus_active = false
	momentum = 0.0
	_initialize_random_velocity()
	call_deferred("_start_entering")

func _on_room_cleared(_room_index: int) -> void:
	visible = false
	velocity = Vector2.ZERO
	seeking = false
	momentum = 0.0
	set_physics_process(false)

func _on_room_loaded() -> void:
	visible = true
	set_physics_process(true)
	seek_timer = 0.0
	seeking = false
	momentum = 0.0

	_find_seek_target()
	
	call_deferred("_start_entering")

func _start_entering() -> void:
	if state_machine:
		state_machine.transition_to("Entering", {"target": global_position + Vector2.UP * 100})
