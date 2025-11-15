extends Control

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var energy_counter: Label = $EnergyCounter
@onready var room_counter: Label = $RoomCounter

func _ready():
    # Connect to game systems
    if MonsterEnergy:
        MonsterEnergy.energy_changed.connect(_on_energy_changed)
    
    if GameManager:
        GameManager.room_changed.connect(_on_room_changed)
    
    # Find slime and connect health signals
    var slime = get_tree().get_first_node_in_group("slime")
    if slime and slime.has_signal("health_changed"):
        slime.health_changed.connect(_on_health_changed)

func _on_health_changed(current: float, max_health: float):
    health_bar.value = (current / max_health) * 100.0

func _on_energy_changed(new_energy: float):
    energy_counter.text = "Energy: " + str(int(new_energy))

func _on_room_changed(current_room: int, total_rooms: int):
    room_counter.text = "Room: %d/%d" % [current_room, total_rooms]