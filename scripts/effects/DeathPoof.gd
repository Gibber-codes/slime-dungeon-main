extends Node2D

# Burst of particles expanding outward on death — bigger and juicier

var particles: Array = []
var ring_radius: float = 0.0
var ring_alpha: float = 0.8

func _ready() -> void:
	# More particles, wider spread
	for i in range(10):
		var angle: float = (TAU / 10.0) * i + randf_range(-0.3, 0.3)
		var speed: float = randf_range(50.0, 120.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"radius": randf_range(2.0, 7.0),
			"alpha": 1.0,
		})

	# Expanding ring
	var tween := create_tween()
	tween.tween_property(self, "ring_radius", 30.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "ring_alpha", 0.0, 0.4)
	tween.tween_interval(0.3)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.96  # Decelerate
		p["alpha"] = max(0.0, p["alpha"] - delta * 1.8)
	queue_redraw()

func _draw() -> void:
	# Expanding ring
	if ring_alpha > 0.01:
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(1.0, 0.4, 0.2, ring_alpha), 2.0)
	# Particles
	for p in particles:
		var c := Color(0.9, 0.2, 0.1, p["alpha"])
		draw_circle(p["pos"], p["radius"], c)
