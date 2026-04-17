extends Node2D

# Floating damage number that rises and fades

var text: String = "0"
var color: Color = Color.WHITE
var alpha: float = 1.0
var font_size: int = 14
var drift: Vector2 = Vector2.ZERO

func setup(damage: float, col: Color, is_crit: bool = false) -> void:
	text = str(int(damage))
	color = col
	font_size = 20 if is_crit else 14
	drift = Vector2(randf_range(-15, 15), 0)

func _ready() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", position + Vector2(drift.x, -35), 0.7)
	tween.parallel().tween_property(self, "alpha", 0.0, 0.7).set_delay(0.2)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := color
	c.a = alpha
	var font := ThemeDB.fallback_font
	# Outline for readability
	var outline_c := Color(0, 0, 0, alpha * 0.7)
	for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		draw_string(font, Vector2(-24, 0) + offset, text, HORIZONTAL_ALIGNMENT_CENTER, 48, font_size, outline_c)
	draw_string(font, Vector2(-24, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 48, font_size, c)
