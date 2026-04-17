extends StaticBody2D
class_name Obstacle

# Decorative non-destructible obstacles. Slime bounces off these.
# Visual size and color are inspector-tweakable. Collision shape lives in the scene
# (resize the CollisionShape2D's RectangleShape2D to match obstacle_size).

@export var obstacle_size: Vector2 = Vector2(24, 24) :
	set(value):
		obstacle_size = value
		_sync_collision_shape()
		queue_redraw()
@export var obstacle_color: Color = Color(0.45, 0.35, 0.25) :
	set(value):
		obstacle_color = value
		queue_redraw()

const BLOCK_HEIGHT := 8.0  # Visible front face height for 3/4 perspective

func _ready() -> void:
	_sync_collision_shape()
	queue_redraw()

## Keep the scene's CollisionShape2D in sync with obstacle_size at runtime.
func _sync_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or not (col.shape is RectangleShape2D):
		return
	# Duplicate so multiple instances don't share state
	col.shape = col.shape.duplicate()
	(col.shape as RectangleShape2D).size = obstacle_size

func _draw() -> void:
	var half := obstacle_size / 2.0
	var top_color := obstacle_color.lightened(0.15)
	var front_color := obstacle_color.darkened(0.2)
	var edge_color := obstacle_color.lightened(0.3)

	# Front face (visible vertical surface facing the viewer)
	draw_rect(Rect2(-half.x, half.y - BLOCK_HEIGHT, obstacle_size.x, BLOCK_HEIGHT), front_color)

	# Top face (the main visible surface from above)
	draw_rect(Rect2(-half.x, -half.y, obstacle_size.x, obstacle_size.y - BLOCK_HEIGHT), top_color)

	# Edge highlights
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), edge_color, 1.0)
	draw_line(Vector2(-half.x, half.y - BLOCK_HEIGHT), Vector2(half.x, half.y - BLOCK_HEIGHT), obstacle_color, 1.0)
	draw_rect(Rect2(-half.x, -half.y, obstacle_size.x, obstacle_size.y), edge_color, false, 1.0)
