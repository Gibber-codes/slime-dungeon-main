extends Node

# Centralized color definitions — all UI elements reference these, never hardcode colors

# Branch colors
const COLOR_CONSTITUTION := Color(0.85, 0.15, 0.15)
const COLOR_STAMINA := Color(0.20, 0.75, 0.20)
const COLOR_AGILITY := Color(0.95, 0.55, 0.10)
const COLOR_STRENGTH := Color(0.60, 0.15, 0.85)
const COLOR_WISDOM := Color(0.20, 0.45, 0.90)
const COLOR_INTELLIGENCE := Color(0.95, 0.85, 0.10)

# Resource colors
const COLOR_ME := Color(0.75, 0.75, 0.75)

# General UI
const COLOR_BUFF := Color(0.2, 0.8, 0.2)
const COLOR_DEBUFF := Color(0.8, 0.2, 0.2)
const COLOR_LOCKED := Color(0.5, 0.5, 0.5)
const COLOR_UPGRADE_READY := Color(0.3, 1.0, 0.3)
const COLOR_UNIMPLEMENTED := Color(0.3, 0.3, 0.35)

const BRANCH_COLORS := {
	"constitution": COLOR_CONSTITUTION,
	"stamina": COLOR_STAMINA,
	"agility": COLOR_AGILITY,
	"strength": COLOR_STRENGTH,
	"wisdom": COLOR_WISDOM,
	"intelligence": COLOR_INTELLIGENCE,
}

func get_branch_color(node_name: String) -> Color:
	# Direct match for T1 nodes
	var key := node_name.to_lower()
	if BRANCH_COLORS.has(key):
		return BRANCH_COLORS[key]
	# T2/T3: resolve via branch root stored in NodeStat
	var stat = NodeSystem.get_node_stat(key)
	if stat and stat.branch != "" and BRANCH_COLORS.has(stat.branch):
		return BRANCH_COLORS[stat.branch]
	return Color.WHITE
