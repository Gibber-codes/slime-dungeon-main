extends Node

# References
@onready var world = $World
@onready var slime = $World/Slime
@onready var game_camera = $World/GameCamera
@onready var room_manager = $World/RoomManager
@onready var ui = $UI
@onready var hud = $UI/Hud

var dungeon_camera: Camera2D
var dungeon_viewport: SubViewport
var camera_target: Node2D

func _ready():
	camera_target = world.get_node_or_null("CameraTarget")
	setup_cameras()
	setup_hud()

func setup_cameras():
	# Main gameplay camera follows slime
	game_camera.enabled = true
	
func _process(_delta):
	pass

func setup_hud():
	# Setup dungeon viewport to show the game world
	dungeon_viewport = hud.get_dungeon_viewport()

	if dungeon_viewport:
		# Move world into the viewport so it's only rendered there
		world.get_parent().remove_child(world)
		dungeon_viewport.add_child(world)

	# Cache dungeon camera reference
	dungeon_camera = hud.get_dungeon_camera()
	if dungeon_camera:
		dungeon_camera.enabled = true

func get_current_room() -> Node2D:
	return room_manager.get_node_or_null("Room")

func reset_game():
	# Easy to reset by just reloading world
	world.queue_free()
	var new_world = preload("res://scenes/core/World.tscn").instantiate()
	if dungeon_viewport:
		dungeon_viewport.add_child(new_world)
		world = new_world
		# Update references that depend on world
		slime = new_world.get_node_or_null("Slime")
		game_camera = new_world.get_node_or_null("GameCamera")
		room_manager = new_world.get_node_or_null("RoomManager")
		camera_target = new_world.get_node_or_null("CameraTarget")
	else:
		add_child(new_world)
		move_child(new_world, 0)  # Keep world below UI
		world = new_world
		camera_target = new_world.get_node_or_null("CameraTarget")
