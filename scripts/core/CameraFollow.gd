extends Camera2D

# Static room-centered camera with screen shake

var shake_amount: float = 0.0
var shake_decay: float = 5.0

func _ready() -> void:
	global_position = Vector2.ZERO

func _process(delta: float) -> void:
	var target_pos := Vector2.ZERO

	if shake_amount > 0.01:
		target_pos += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		shake_amount = 0.0

	global_position = target_pos

func shake(amount: float) -> void:
	shake_amount = max(shake_amount, amount)
