extends Node

# References
@onready var world = $SubViewportContainer/SubViewport/Dungeon/World
@onready var slime = $SubViewportContainer/SubViewport/Dungeon/Slime
@onready var dungeon_camera = $SubViewportContainer/SubViewport/DungeonCamera
@onready var dungeon_viewport = $SubViewportContainer/SubViewport
@onready var room_manager = $SubViewportContainer/SubViewport/Dungeon/World/RoomManager
@onready var ui = $UI
@onready var hud = $UI/Hud

var camera_target: Node2D
var is_panning := false
var last_mouse_pos := Vector2.ZERO
var base_scale := 2.0  # Start at 2x scale
var current_scale := 2.0
var min_scale := 2.0  # Can't zoom out past this
var max_scale := 8.0  # Maximum zoom in

func _ready():
		# Force SubViewport to correct size
	dungeon_viewport.size = Vector2i(640, 360)
	
	var viewport_container = $SubViewportContainer
	
	# Read the actual scale from the scene and use that as base
	base_scale = viewport_container.scale.x
	current_scale = base_scale
	min_scale = base_scale
	
	# Initialize position properly
	_clamp_container_position(viewport_container)
	camera_target = world.get_node_or_null("CameraTarget")
	setup_cameras()
	setup_hud()

func setup_cameras():
	# Enable the dungeon camera
	if dungeon_camera:
		dungeon_camera.enabled = true
	
func _process(_delta):
	pass

func setup_hud():
	# The world is already in the viewport, just make sure camera is enabled
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
		room_manager = new_world.get_node_or_null("RoomManager")
		camera_target = new_world.get_node_or_null("CameraTarget")
		
func _input(event):
	if not dungeon_camera:
		return
	
	var viewport_container = $SubViewportContainer
	var mouse_pos = get_viewport().get_mouse_position()
	var container_rect = viewport_container.get_global_rect()
	
	if not container_rect.has_point(mouse_pos):
		return
	
	# Start panning with left click
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_panning = true
				last_mouse_pos = event.position
				get_viewport().set_input_as_handled()
			else:
				is_panning = false
		
		# Zoom by scaling the viewport container (makes pixels bigger)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at_point(mouse_pos, 1.1, viewport_container)
			get_viewport().set_input_as_handled()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at_point(mouse_pos, 0.9, viewport_container)
			get_viewport().set_input_as_handled()
	
	# Pan while dragging
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - last_mouse_pos
		viewport_container.position += delta
		_clamp_container_position(viewport_container)
		last_mouse_pos = event.position
		get_viewport().set_input_as_handled()

func _zoom_at_point(mouse_pos: Vector2, zoom_factor: float, viewport_container: Control):
	var old_scale = current_scale
	var new_scale = clamp(current_scale * zoom_factor, min_scale, max_scale)
	
	# If already at min/max, don't do anything
	if new_scale == current_scale:
		return
	
	# Calculate mouse position relative to container before zoom
	var mouse_relative_to_container = mouse_pos - viewport_container.position
	
	# Apply new scale
	current_scale = new_scale
	viewport_container.scale = Vector2(current_scale, current_scale)
	
	# Adjust position to keep mouse point stationary
	var scale_ratio = current_scale / old_scale
	var new_mouse_relative = mouse_relative_to_container * scale_ratio
	viewport_container.position = mouse_pos - new_mouse_relative
	
	# Clamp position so edges never show
	_clamp_container_position(viewport_container)

func _clamp_container_position(viewport_container: Control):
	# Get the display area size (parent or viewport size)
	var display_size = get_viewport().get_visible_rect().size
	
	# Get the scaled container size
	var container_size = viewport_container.size * current_scale
	
	# Calculate bounds
	# The container can move from 0 (showing left/top edge) to negative (panning right/down)
	var min_x = display_size.x - container_size.x
	var min_y = display_size.y - container_size.y
	
	# Clamp position
	# If container is smaller than display, center it
	# If container is larger than display, prevent edges from showing
	if container_size.x <= display_size.x:
		# Center horizontally
		viewport_container.position.x = (display_size.x - container_size.x) / 2
	else:
		# Clamp so edges don't show
		viewport_container.position.x = clamp(viewport_container.position.x, min_x, 0)
	
	if container_size.y <= display_size.y:
		# Center vertically
		viewport_container.position.y = (display_size.y - container_size.y) / 2
	else:
		# Clamp so edges don't show
		viewport_container.position.y = clamp(viewport_container.position.y, min_y, 0)
