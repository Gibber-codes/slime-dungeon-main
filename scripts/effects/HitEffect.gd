extends Node2D

# Expanding impact circle with bright core and ring

var radius: float = 5.0
var max_radius: float = 20.0
var alpha: float = 1.0
var color: Color = Color(1, 0.3, 0.3)

func _ready() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "radius", max_radius, 0.2)
	tween.parallel().tween_property(self, "alpha", 0.0, 0.25)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := color
	c.a = alpha
	draw_circle(Vector2.ZERO, radius, c)
	# Bright inner core
	draw_circle(Vector2.ZERO, radius * 0.35, Color(1, 1, 1, alpha * 0.8))
	# Expanding ring
	draw_arc(Vector2.ZERO, radius * 1.3, 0, TAU, 24, Color(c.r, c.g, c.b, alpha * 0.4), 2.0)
