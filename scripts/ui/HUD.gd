extends Control

@onready var speed_bar: TextureProgressBar = $menuRight/slimeBars/statsBars/slimeSpeedBar
@onready var frenzy_bar: TextureProgressBar = $menuRight/slimeBars/statsBars/slimeFrenzyBar
@onready var momentum_bar: TextureProgressBar = $menuRight/slimeBars/statsBars/slimeMomentumBar
@onready var auto_seek_bar: TextureProgressBar = $menuRight/slimeBars/statsBars/slimeAutoSeekBar
@onready var health_bar: TextureProgressBar = $menuRight/slimeBars/statsBars/slimeHealthBar
<<<<<<< Updated upstream
# @onready var monster_core_bar: TextureProgressBar = $SubViewportContainer/SubViewport/menuRight/slimeBars/monsterCoreBar

var energy_counter: Label = null
var room_counter: Label = null
var dungeon_viewport: SubViewport = null
var dungeon_camera: Camera2D = null
=======
@export var room_size := Vector2(640, 360)

var energy_counter: Label = null
var room_counter: Label = null
>>>>>>> Stashed changes
var slime: Node2D

@export var room_size := Vector2(640, 360)

func _ready():
<<<<<<< Updated upstream
	
=======
>>>>>>> Stashed changes
	# Optional HUD labels (may not exist in the scene)
	if has_node("EnergyCounter"):
		energy_counter = $EnergyCounter
	if has_node("RoomCounter"):
		room_counter = $RoomCounter

	# Connect to game systems
	if MonsterEnergy:
		MonsterEnergy.energy_changed.connect(_on_energy_changed)

	if GameManager:
		GameManager.room_changed.connect(_on_room_changed)

	# Find slime and connect health signals
	slime = get_tree().get_first_node_in_group("slime")
	if slime:
		if slime.has_signal("health_changed"):
			slime.health_changed.connect(_on_health_changed)
			# Initialize health bar
			_on_health_changed(slime.current_health, slime.max_health)
<<<<<<< Updated upstream
	
=======
			
>>>>>>> Stashed changes
func _process(_delta):
	if is_instance_valid(slime):
		# Update Speed Bar
		var current_speed = slime.velocity.length()
		speed_bar.value = (current_speed / 400.0) * 100.0
		
		# Update Momentum Bar
		momentum_bar.value = (slime.momentum / slime.max_momentum) * 100.0
		
		# Update Auto Seek Bar
		auto_seek_bar.value = (slime.current_seek_timer / slime.auto_seek_timer) * 100.0
		
		# Frenzy Bar (Not implemented yet)
		frenzy_bar.value = 0.0

func _on_health_changed(current: float, max_health: float):
	health_bar.value = (current / max_health) * 100.0

func _on_energy_changed(new_energy: float):
	if energy_counter:
		energy_counter.text = "Energy: " + str(int(new_energy))

func _on_room_changed(current_room: int, total_rooms: int):
	if room_counter:
		room_counter.text = "Room: %d/%d" % [current_room, total_rooms]
<<<<<<< Updated upstream
		
func set_viewport_references(viewport: SubViewport, camera: Camera2D):
	dungeon_viewport = viewport
	dungeon_camera = camera
	setup_dungeon_viewport()
func setup_dungeon_viewport():
	# Share the game world
	dungeon_viewport.world_2d = get_viewport().world_2d
	
	if dungeon_camera:
		dungeon_camera.enabled = true
		
		# Center camera on room (adjust if room is not at 0,0)
		dungeon_camera.global_position = Vector2(160, 160)
		
		# Calculate zoom to fill viewport
		var viewport_size = Vector2(dungeon_viewport.size)
		var zoom_x = viewport_size.x / room_size.x
		var zoom_y = viewport_size.y / room_size.y
		
		# Use smaller zoom to ensure entire room fits
		var zoom_level = min(zoom_x, zoom_y)
		
		dungeon_camera.zoom = Vector2(zoom_level, zoom_level)
		
		print("Dungeon camera zoom set to: ", zoom_level)

func get_dungeon_viewport() -> SubViewport:
	return dungeon_viewport

func get_dungeon_camera() -> Camera2D:
	return dungeon_camera
=======
>>>>>>> Stashed changes
