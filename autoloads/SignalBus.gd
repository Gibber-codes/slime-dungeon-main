extends Node

# Central signal bus for decoupled communication between systems

# --- Room Signals ---
signal room_cleared(room_index: int)
signal room_loaded(room_index: int)
signal all_rooms_cleared()
signal room_transition_started()
signal room_transition_completed()
signal room_exit_opened(exit_position: Vector2)

# --- Combat Signals ---
signal entity_defeated(category: EntityData.Category, energy_reward: float, xp_reward: float)
signal slime_died()
signal slime_took_damage(amount: float)

# --- Energy Signals ---
signal energy_changed(current: float, delta_amount: float)
signal energy_spent(amount: float, item: String)

# --- Node/Upgrade Signals ---
signal node_upgraded(node_name: String, new_level: int)
signal upgrade_node_selected(node_name: String)
signal stats_changed()

# --- Game State Signals ---
signal reset_triggered()
signal game_over()
signal game_won()
signal multiplier_changed(new_multiplier: float)
signal game_paused()
signal game_resumed()

# --- UI Signals ---
signal upgrade_menu_toggled(visible: bool)
signal reset_confirmation_requested()
signal entity_selected(entity: Node)
