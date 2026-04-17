extends HBoxContainer
class_name StatRow

# Reusable stat row widget: [color dot] [stat_name] [value]
# Used for the Primary/Secondary stats list on the right panel.
# Hovering shows a tooltip via the parent HUD.

signal hovered(key: String, row: Control)
signal unhovered()

@export var key: String = ""
@export var stat_name: String = "Stat" :
	set(value):
		stat_name = value
		if is_node_ready():
			$Name.text = "  " + value
@export var dot_color: Color = Color.WHITE :
	set(value):
		dot_color = value
		if is_node_ready():
			$Dot.color = value
@export var value_min_width: float = 130.0

@onready var dot: ColorRect = $Dot
@onready var name_label: Label = $Name
@onready var value_label: Label = $Value

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): hovered.emit(key, self))
	mouse_exited.connect(func(): unhovered.emit())
	dot.color = dot_color
	name_label.text = "  " + stat_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.custom_minimum_size.x = value_min_width

func set_value_text(text: String) -> void:
	if value_label:
		value_label.text = text
