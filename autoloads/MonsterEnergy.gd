extends Node

# Monster Energy system - manages in-game currency

var current_energy: float = 0.0
var current_run_energy: float = 0.0
var lifetime_energy: float = 0.0

func _ready() -> void:
	SignalBus.entity_defeated.connect(_on_entity_defeated)
	SignalBus.reset_triggered.connect(_on_reset)

func _on_entity_defeated(_category: EntityData.Category, energy_reward: float, xp_reward: float) -> void:
	var wisdom_bonus: float = 1.0 + NodeSystem.get_all_bonuses().get("energy_mult", 0.0)
	var prestige_bonus: float = GameManager.reset_multiplier
	var total: float = energy_reward * wisdom_bonus * prestige_bonus * Globals.testing_multiplier
	add_energy(total)
	GameManager.add_xp(xp_reward * Globals.testing_multiplier)

func add_energy(amount: float) -> void:
	current_energy += amount
	current_run_energy += amount
	lifetime_energy += amount
	SignalBus.energy_changed.emit(current_energy, amount)

func spend_energy(cost: float) -> bool:
	if current_energy < cost:
		return false
	current_energy -= cost
	SignalBus.energy_spent.emit(cost, "")
	SignalBus.energy_changed.emit(current_energy, -cost)
	return true

func can_afford(cost: float) -> bool:
	return current_energy >= cost

func _on_reset() -> void:
	current_energy = 0.0
	current_run_energy = 0.0

func get_save_data() -> Dictionary:
	return {
		"current_energy": current_energy,
		"current_run_energy": current_run_energy,
		"lifetime_energy": lifetime_energy,
	}

func load_save_data(data: Dictionary) -> void:
	current_energy = data.get("current_energy", 0.0)
	current_run_energy = data.get("current_run_energy", 0.0)
	lifetime_energy = data.get("lifetime_energy", 0.0)
