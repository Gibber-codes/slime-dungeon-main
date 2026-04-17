extends Node

# Main scene script — initializes the game and adds HUD + pause menu overlays.

var hud_scene: PackedScene = preload("res://scenes/ui/HUD.tscn")
var pause_menu_scene: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")

func _ready() -> void:
	add_to_group("main")
	GameManager.load_game()

	# HUD overlay
	add_child(hud_scene.instantiate())

	# Pause menu on its own CanvasLayer so it sits above everything
	var pause_layer := CanvasLayer.new()
	pause_layer.layer = 10
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.add_child(pause_menu_scene.instantiate())
	add_child(pause_layer)
