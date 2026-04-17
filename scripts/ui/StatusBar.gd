extends HBoxContainer
class_name StatusBar

# Reusable status bar widget: [Label] [ProgressBar] [Value Label]
# Used for HP / Speed / Seek / Momentum on the right panel.
# Inspector-tweakable label, color, and dimensions via the scene's @export fields.

@export var label_text: String = "HP" :
	set(value):
		label_text = value
		if is_node_ready():
			$Label.text = value
@export var bar_color: Color = Color.WHITE :
	set(value):
		bar_color = value
		if is_node_ready():
			_apply_color()
@export var label_min_width: float = 45.0
@export var value_min_width: float = 80.0

@onready var label: Label = $Label
@onready var bar: ProgressBar = $ProgressBar
@onready var value_label: Label = $Value

func _ready() -> void:
	label.text = label_text
	label.custom_minimum_size.x = label_min_width
	value_label.custom_minimum_size.x = value_min_width
	_apply_color()
	bar.draw.connect(_on_bar_draw)

func _apply_color() -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = bar_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.15)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)

var _base_threshold: float = -1.0

## Update the bar value/max and the right-side text. Call from HUD's update tick.
func set_values(current: float, max_value: float, text: String = "", base_threshold: float = -1.0) -> void:
	bar.max_value = max_value if max_value > 0.0 else 1.0
	bar.value = current
	value_label.text = text if text != "" else "%.0f/%.0f" % [current, max_value]
	
	if _base_threshold != base_threshold:
		_base_threshold = base_threshold
		bar.queue_redraw()

func _on_bar_draw() -> void:
	if _base_threshold > 0.0 and bar.max_value > 0.0:
		var ratio := _base_threshold / bar.max_value
		var x_pos := bar.size.x * ratio
		
		# Draw the momentum fill chunk brighter overlay
		if bar.value > _base_threshold:
			var fill_ratio := bar.value / bar.max_value
			var fill_x := bar.size.x * fill_ratio
			var mom_color := bar_color.lightened(0.4)
			# Godot styleboxes might have margins, but bar.size ignores style margin. Draw inside bar bounds
			bar.draw_rect(Rect2(x_pos, 0, fill_x - x_pos, bar.size.y), mom_color)
			
		# Draw the divider line
		bar.draw_line(Vector2(x_pos, 0), Vector2(x_pos, bar.size.y), Color.WHITE, 2.0)

