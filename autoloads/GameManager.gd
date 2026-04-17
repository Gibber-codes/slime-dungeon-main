extends Node

# Game state manager - handles game flow, resets, and progression

enum GameState { PLAYING, PAUSED, GAME_OVER, VICTORY, RESETTING }

var game_state: GameState = GameState.PLAYING
var reset_multiplier: float = 1.0
var total_resets: int = 0
var current_room_index: int = 0
var current_run_xp: float = 0.0
var lifetime_xp: float = 0.0
var run_defenders_defeated: int = 0
var lifetime_defenders_defeated: int = 0
var run_objects_destroyed: int = 0
var lifetime_objects_destroyed: int = 0
var run_heroes_killed: int = 0
var lifetime_heroes_killed: int = 0

const SAVE_PATH: String = "user://save_data.json"

func _ready() -> void:
	SignalBus.slime_died.connect(_on_slime_died)
	SignalBus.all_rooms_cleared.connect(_on_all_rooms_cleared)
	SignalBus.entity_defeated.connect(_on_entity_defeated)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_fullscreen"):
		_toggle_fullscreen()
	elif event.is_action_pressed("ui_pause"):
		toggle_pause()
	elif event.is_action_pressed("ui_reset"):
		if (game_state == GameState.PLAYING or game_state == GameState.GAME_OVER) and can_prestige_reset():
			SignalBus.reset_confirmation_requested.emit()

func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_pause() -> void:
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		get_tree().paused = true
		SignalBus.game_paused.emit()
	elif game_state == GameState.PAUSED:
		game_state = GameState.PLAYING
		get_tree().paused = false
		SignalBus.game_resumed.emit()

func prestige_reset() -> void:
	game_state = GameState.RESETTING

	# Calculate run gain and add it to the lifetime multiplier
	var gain: float = get_prestige_gain(current_run_xp)
	reset_multiplier += gain
	total_resets += 1

	# Emit reset signal - all systems listen and reset themselves
	SignalBus.reset_triggered.emit()
	SignalBus.multiplier_changed.emit(reset_multiplier)

	# Reset room progression and run stats
	current_room_index = 0
	current_run_xp = 0.0
	run_defenders_defeated = 0
	run_objects_destroyed = 0
	run_heroes_killed = 0

	# Unpause if paused
	get_tree().paused = false
	game_state = GameState.PLAYING

	# Save after reset
	save_game()

func full_reset() -> void:
	# Complete wipe — resets everything including prestige multiplier and lifetime energy
	game_state = GameState.RESETTING
	reset_multiplier = 1.0
	total_resets = 0
	current_room_index = 0

	MonsterEnergy.current_energy = 0.0
	MonsterEnergy.current_run_energy = 0.0
	MonsterEnergy.lifetime_energy = 0.0
	current_run_xp = 0.0
	lifetime_xp = 0.0
	run_defenders_defeated = 0
	lifetime_defenders_defeated = 0
	run_objects_destroyed = 0
	lifetime_objects_destroyed = 0
	run_heroes_killed = 0
	lifetime_heroes_killed = 0

	# Emit reset signal so all systems reset (nodes, slime, etc.)
	SignalBus.reset_triggered.emit()
	SignalBus.multiplier_changed.emit(reset_multiplier)

	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	get_tree().paused = false
	game_state = GameState.PLAYING

func add_xp(amount: float) -> void:
	current_run_xp += amount
	lifetime_xp += amount

func get_prestige_gain(run_xp: float) -> float:
	return sqrt(run_xp) * 0.005

func can_prestige_reset() -> bool:
	if game_state == GameState.GAME_OVER:
		return true
	var gain: float = get_prestige_gain(current_run_xp)
	return gain >= 4.999

func _on_entity_defeated(category: EntityData.Category, _energy_reward: float, _xp_reward: float) -> void:
	match category:
		EntityData.Category.DEFENDER:
			run_defenders_defeated += 1
			lifetime_defenders_defeated += 1
		EntityData.Category.OBJECT:
			run_objects_destroyed += 1
			lifetime_objects_destroyed += 1
		EntityData.Category.HERO:
			run_heroes_killed += 1
			lifetime_heroes_killed += 1

func _on_slime_died() -> void:
	game_state = GameState.GAME_OVER
	SignalBus.game_over.emit()

func _on_all_rooms_cleared() -> void:
	game_state = GameState.VICTORY
	SignalBus.game_won.emit()

func advance_room() -> void:
	current_room_index += 1
	if current_room_index >= Globals.TOTAL_ROOMS:
		_on_all_rooms_cleared()

func save_game() -> void:
	var data: Dictionary = {
		"reset_multiplier": reset_multiplier,
		"total_resets": total_resets,
		"current_room_index": current_room_index,
		"energy": MonsterEnergy.get_save_data(),
		"nodes": NodeSystem.get_save_data(),
		"current_run_xp": current_run_xp,
		"lifetime_xp": lifetime_xp,
		"run_defenders_defeated": run_defenders_defeated,
		"lifetime_defenders_defeated": lifetime_defenders_defeated,
		"run_objects_destroyed": run_objects_destroyed,
		"lifetime_objects_destroyed": lifetime_objects_destroyed,
		"run_heroes_killed": run_heroes_killed,
		"lifetime_heroes_killed": lifetime_heroes_killed,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data
	reset_multiplier = data.get("reset_multiplier", 1.0)
	total_resets = data.get("total_resets", 0)
	current_room_index = data.get("current_room_index", 0)
	if data.has("energy"):
		MonsterEnergy.load_save_data(data["energy"])
	if data.has("nodes"):
		NodeSystem.load_save_data(data["nodes"])
	current_run_xp = data.get("current_run_xp", 0.0)
	lifetime_xp = data.get("lifetime_xp", 0.0)
	run_defenders_defeated = data.get("run_defenders_defeated", 0)
	lifetime_defenders_defeated = data.get("lifetime_defenders_defeated", 0)
	run_objects_destroyed = data.get("run_objects_destroyed", 0)
	lifetime_objects_destroyed = data.get("lifetime_objects_destroyed", 0)
	run_heroes_killed = data.get("run_heroes_killed", 0)
	lifetime_heroes_killed = data.get("lifetime_heroes_killed", 0)
