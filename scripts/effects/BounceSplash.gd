extends Node2D

# Impact flash at bounce point with expanding ring

var alpha: float = 0.8
var ring_radius: float = 4.0

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "alpha", 0.0, 0.15)
	tween.parallel().tween_property(self, "ring_radius", 14.0, 0.15)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var c := Color(0.6, 0.8, 1.0, alpha)
	draw_circle(Vector2.ZERO, 6.0, c)
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 16, Color(0.7, 0.9, 1.0, alpha * 0.5), 1.5)
