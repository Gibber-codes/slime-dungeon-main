extends BaseEntity

# Breakable objects: vases, pots, bones, sticks, etc.
# Stats and visuals come from the assigned EntityData resource.
# Sprite-based rendering is the standard path; a plain circle is the fallback.

var death_effect_scene: PackedScene = preload("res://effects/DeathPoof.tscn")

var _color: Color = Color(0.6, 0.4, 0.25)
var _sprite: Sprite2D = null

func _ready() -> void:
	super._ready()

	if not is_in_group("room_entities"):
		add_to_group("room_entities")
	if not is_in_group("breakables"):
		add_to_group("breakables")

	if entity_data:
		_color = entity_data.draw_color
		if entity_data.sprite_texture:
			_sprite = Sprite2D.new()
			_sprite.texture = entity_data.sprite_texture
			_sprite.scale = entity_data.sprite_scale
			_sprite.position = entity_data.sprite_offset
			add_child(_sprite)
	else:
		push_warning("BreakableObject spawned without entity_data — using defaults")

func _process(_delta: float) -> void:
	super._process(_delta)
	if _sprite:
		var hp_ratio: float = current_health / max(max_health, 1.0)
		_sprite.modulate = Color(1.0, lerpf(0.4, 1.0, hp_ratio), lerpf(0.4, 1.0, hp_ratio))
	queue_redraw()

func _draw() -> void:
	if _sprite:
		return
	# Fallback: plain filled circle using draw_color
	draw_circle(Vector2.ZERO, 12.0, _color)
	draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 16, _color.darkened(0.3), 1.5)

func die() -> void:
	var effect: Node2D = death_effect_scene.instantiate()
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)
	super.die()
	queue_free()
