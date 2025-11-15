extends Node2D

@onready var defenders_root: Node2D = get_node_or_null("Defenders")
@onready var exit_zone: Area2D = get_node_or_null("ExitZone")
@onready var slime_spawn: Marker2D = get_node_or_null("SlimeSpawn")

var _remaining_defenders: int = 0
var _room_cleared: bool = false

func _ready() -> void:
	call_deferred("_position_slime")
	if defenders_root:
		_setup_defenders()
	if exit_zone:
		_set_exit_enabled(false)
		exit_zone.body_entered.connect(_on_exit_zone_body_entered)

func _setup_defenders() -> void:
	_remaining_defenders = defenders_root.get_child_count()
	if _remaining_defenders <= 0:
		_on_all_defenders_defeated()
		return
	defenders_root.child_exiting_tree.connect(_on_defender_exiting_tree)

func _on_defender_exiting_tree(node: Node) -> void:
	if node.get_parent() != defenders_root:
		return
	_remaining_defenders -= 1
	if _remaining_defenders <= 0 and not _room_cleared:
		_on_all_defenders_defeated()

func _on_all_defenders_defeated() -> void:
	_room_cleared = true
	if exit_zone:
		_set_exit_enabled(true)

func _set_exit_enabled(enabled: bool) -> void:
	exit_zone.monitoring = enabled
	exit_zone.monitorable = enabled
	for child in exit_zone.get_children():
		if child is CollisionShape2D:
			child.disabled = not enabled

func _on_exit_zone_body_entered(body: Node) -> void:
	if not _room_cleared:
		return
	if body.name != "Slime":
		return
	# TODO: Notify RoomManager / GameManager that the room exit was reached.

func _position_slime() -> void:
	if not slime_spawn:
		return
	var slime: CharacterBody2D = get_tree().root.find_child("Slime", true, false)
	if slime:
		slime.global_position = slime_spawn.global_position
