extends Control

# Pause menu — shown when the game is paused.
# Layout lives in scenes/ui/PauseMenu.tscn; this script just wires signals.

@onready var _resume_btn: Button = $Center/Panel/VBox/ResumeBtn
@onready var _save_btn: Button = $Center/Panel/VBox/SaveBtn

func _ready() -> void:
	_resume_btn.pressed.connect(func(): GameManager.toggle_pause())
	_save_btn.pressed.connect(func(): GameManager.save_game())

	SignalBus.game_paused.connect(func(): visible = true)
	SignalBus.game_resumed.connect(func(): visible = false)
	SignalBus.reset_triggered.connect(func(): visible = false)
