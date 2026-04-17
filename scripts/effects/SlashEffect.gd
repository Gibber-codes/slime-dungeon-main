extends Node2D

# Animated slash arcs that fan out and fade — spawned at slime on defender attack

var direction: float = 0.0  # Angle toward the target (radians)
var slash_progress: float = 0.0
var slash_alpha: float = 1.0
var slash_scale: float = 1.0

func setup(dir: Vector2) -> void:
	direction = dir.angle()

func _ready() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "slash_progress", 1.0, 0.15)
	tween.parallel().tween_property(self, "slash_scale", 1.3, 0.25)
	tween.tween_property(self, "slash_alpha", 0.0, 0.25)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if slash_alpha <= 0.01:
		return

	var base_radius: float = 4.0 + slash_progress * 3.0

	# Three arc slashes at slightly different angles — like claw marks
	var arc_data: Array = [
		{"offset": -0.35, "width": 2.5, "r_mult": 1.0},
		{"offset":  0.0,  "width": 3.0, "r_mult": 1.15},
		{"offset":  0.35, "width": 2.5, "r_mult": 1.0},
	]

	for arc in arc_data:
		var r: float = base_radius * arc["r_mult"] * slash_scale
		var center_angle: float = direction + arc["offset"]
		var sweep: float = 0.6 + slash_progress * 0.4  # arc length in radians
		var start_angle: float = center_angle - sweep * 0.5
		var end_angle: float = center_angle + sweep * 0.5

		# Main slash line — bright white/yellow
		var color := Color(1.0, 0.95, 0.85, slash_alpha)
		draw_arc(Vector2.ZERO, r, start_angle, end_angle, 12, color, arc["width"])

		# Inner glow — slightly smaller, brighter
		var inner_color := Color(1.0, 1.0, 1.0, slash_alpha * 0.6)
		draw_arc(Vector2.ZERO, r * 0.7, start_angle + 0.1, end_angle - 0.1, 8, inner_color, arc["width"] * 0.5)
