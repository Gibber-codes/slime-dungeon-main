extends RefCounted
class_name NodeEffects

# Bonus aggregator — reads NodeStat .tres data and computes bonuses.
# Most nodes are simple (level * value_per_level).
# Complex nodes (Intelligence focus, Constitution thresholds) have explicit handlers.

# =========================================================================
# Per-Node Bonus
# =========================================================================

static func get_bonus(stat: NodeStat, level: int) -> Dictionary:
	if level <= 0:
		return {}

	var bonuses := {}

	# Primary effect
	if stat.bonus_key != "":
		bonuses[stat.bonus_key] = level * stat.value_per_level

	# Secondary effect
	if stat.bonus_key_2 != "":
		bonuses[stat.bonus_key_2] = level * stat.value_per_level_2

	# Threshold effect (e.g. Constitution grants slots at specific levels)
	if stat.threshold_bonus_key != "" and stat.threshold_levels.size() > 0:
		var count := 0
		for threshold in stat.threshold_levels:
			if level >= threshold:
				count += 1
		if count > 0:
			bonuses[stat.threshold_bonus_key] = bonuses.get(stat.threshold_bonus_key, 0.0) + count

	return bonuses

# =========================================================================
# Aggregated Bonuses — call NodeSystem.get_all_bonuses() instead
# (Moved to NodeSystem since static functions can't access autoloads)
# =========================================================================

# =========================================================================
# Description Generator — auto-generates effect text from .tres data
# =========================================================================

static func get_effect_descriptions(stat: NodeStat, level: int) -> Array[String]:
	var effects: Array[String] = []
	if level <= 0 and not stat.is_implemented:
		return effects

	# Try special descriptions first (complex nodes)
	var special := _get_special_description(stat, level)
	if special.size() > 0:
		return special

	# Generic: auto-generate from bonus keys
	if stat.bonus_key != "":
		var total: float = level * stat.value_per_level
		var label: String = _humanize_key(stat.bonus_key)
		var fmt: String = _format_bonus(stat.bonus_key, total, stat.value_per_level)
		effects.append(fmt)

	if stat.bonus_key_2 != "":
		var total2: float = level * stat.value_per_level_2
		var fmt2: String = _format_bonus(stat.bonus_key_2, total2, stat.value_per_level_2)
		effects.append(fmt2)

	if stat.threshold_bonus_key != "" and stat.threshold_levels.size() > 0:
		var count := 0
		for t in stat.threshold_levels:
			if level >= t:
				count += 1
		var thresholds_str := []
		for t in stat.threshold_levels:
			thresholds_str.append(str(t))
		var label: String = _humanize_key(stat.threshold_bonus_key)
		effects.append("%s: +%d (at Lv.%s)" % [label, count, ", ".join(thresholds_str)])

	return effects

# =========================================================================
# Special Descriptions — override for complex T1 nodes
# =========================================================================

static func _get_special_description(stat: NodeStat, level: int) -> Array[String]:
	var effects: Array[String] = []
	match stat.id:
		"intelligence":
			var seek_base: float = 9.0
			var seek_time: float = 3.0 + 6.0 * pow(0.90, level)
			effects.append("Seek: %.1fs (base %.1f, asymptotic curve)" % [seek_time, seek_base])
		"focus":
			var threshold: int = int(floor((-1.0 + sqrt(1.0 + 8.0 * float(level))) / 2.0))
			var next_threshold: int = threshold + 1
			var next_level: int = (next_threshold * (next_threshold + 1)) / 2
			effects.append("Activates safely at <= %d enemies" % threshold)
			effects.append("(+1 enemy tolerance at Lv.%d)" % next_level)
		"constitution":
			effects.append("+%.0f HP (+%.0f/lv)" % [level * stat.value_per_level, stat.value_per_level])
			var slots := 0
			for t in stat.threshold_levels:
				if level >= t:
					slots += 1
			var thresholds := []
			for t in stat.threshold_levels:
				thresholds.append(str(t))
			effects.append("Slots: +%d (at Lv.%s)" % [slots, ", ".join(thresholds)])
	return effects

# =========================================================================
# Formatting Helpers
# =========================================================================

## Convert bonus_key to human-readable label
static func _humanize_key(key: String) -> String:
	var labels := {
		"max_hp": "Max HP",
		"damage_mult": "Damage",
		"speed_mult": "Speed",
		"energy_mult": "Energy Yield",
		"hp_regen": "HP Regen",
		"seek_reduction": "Seek Reduction",
		"momentum_decay_reduction": "Momentum Decay Reduction",
		"momentum_mult": "Momentum Damage",
		"connection_slots": "Connection Slots",
		"physical_defense": "Physical Defense",
		"elemental_defense": "Elemental Defense",
		"flow_speed_mult": "Flow Speed",
		"crit_chance": "Crit Chance",
		"dodge_chance": "Dodge Chance",
		"counter_chance": "Counter Chance",
		"counter_reflect": "Counter Reflect",
		"momentum_cap": "Momentum Cap",
		"frenzy_regen": "Frenzy Regen",
		"engulf_energy_mult": "Engulf Energy",
		"backstab_crit_damage": "Backstab Crit",
		"focus_damage_mult": "Focus Damage",
		"info_level": "Info Level",
		"cc_resistance": "CC Resistance",
		"low_hp_reduction": "Low-HP Penalty Reduction",
		"armor_penetration": "Armor Penetration",
	}
	if labels.has(key):
		return labels[key]
	return key.replace("_", " ").capitalize()

## Format a bonus value depending on whether it's a multiplier, flat, or percentage
static func _format_bonus(key: String, total: float, per_level: float) -> String:
	# Multiplier keys (displayed as percentage)
	var mult_keys := ["damage_mult", "speed_mult", "energy_mult", "momentum_mult",
		"momentum_decay_reduction", "crit_chance", "dodge_chance", "counter_chance",
		"counter_reflect", "momentum_cap", "frenzy_regen", "engulf_energy_mult",
		"backstab_crit_damage", "focus_damage_mult", "cc_resistance",
		"low_hp_reduction", "armor_penetration", "flow_speed_mult",
		"elemental_defense_scaling", "active_elemental_defense",
		"focus_seek_reduction", "focus_momentum_floor",
		"engulf_momentum_retention", "collision_momentum_retention",
		"multihit_chance", "enemy_sight_reduction",
		"crit_damage_mult", "reaction_crit_chance",
		"momentum_gain_rate", "engulf_threshold_reduction",
		"elemental_power_mult", "elemental_cost_reduction",
		"frenzy_momentum_gain", "frenzy_speed_mult",
		"low_hp_speed_reduction", "low_hp_damage_reduction"]
	# Flat keys (displayed as raw numbers)
	var flat_keys := ["max_hp", "hp_regen", "physical_defense", "elemental_defense",
		"connection_slots", "seek_reduction", "info_level", "analysis_level",
		"memory_retention", "elemental_unlock", "elemental_level_cap",
		"elemental_connections", "elemental_flow_speed"]

	var label := _humanize_key(key)

	if key in mult_keys:
		return "+%.0f%% %s (+%.0f%%/lv)" % [total * 100.0, label, per_level * 100.0]
	elif key in flat_keys:
		if absf(total) >= 10.0:
			return "+%.0f %s (+%.0f/lv)" % [total, label, per_level]
		else:
			return "+%.1f %s (+%.1f/lv)" % [total, label, per_level]
	else:
		# Default: treat as percentage
		return "+%.0f%% %s (+%.0f%%/lv)" % [total * 100.0, label, per_level * 100.0]
