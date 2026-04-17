extends Node2D

# Floating "+X ME" text on energy gain

var text: String = ""
var alpha: float = 1.0

func setup(amount: float) -> void:
	text = "+%.0f ME" % amount

func _ready() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:y", position.y - 28, 0.9)
	tween.parallel().tween_property(self, "alpha", 0.0, 0.9).set_delay(0.3)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := Color(UITheme.COLOR_ME.r, UITheme.COLOR_ME.g, UITheme.COLOR_ME.b, alpha)
	var font := ThemeDB.fallback_font
	var outline := Color(0, 0, 0, alpha * 0.6)
	for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		draw_string(font, Vector2(-30, -8) + offset, text, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, outline)
	draw_string(font, Vector2(-30, -8), text, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, c)
