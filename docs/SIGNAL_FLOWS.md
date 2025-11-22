# Signal Flow Reference

## Combat Signal Chain
```
Slime.body_entered(defender) 
    ↓
CombatManager.calculate_damage(slime_stats, defender_stats)
    ↓
Defender.take_damage(amount)
    ↓
Defender.health_changed(new_health)
    ↓
if health <= 0:
    Defender.defeated
        ↓
    MonsterEnergy.add_energy(reward_amount)
        ↓
    MonsterEnergy.energy_changed(new_total)
        ↓
    UI.update_energy_display(new_total)
        ↓
    Room.check_all_defenders_defeated()
        ↓
    if all defeated:
        Room.room_cleared
            ↓
        RoomManager.load_next_room()
```

## Upgrade Signal Chain
```
UI.upgrade_button_pressed(node_name)
    ↓
NodeSystem.can_upgrade(node_name) → bool
    ↓
if true:
    MonsterEnergy.spend_energy(cost)
        ↓
    NodeSystem.upgrade_node(node_name)
        ↓
    NodeSystem.node_upgraded(node_name, new_level)
        ↓
    Slime.update_stats()
        ↓
    UI.refresh_upgrade_menu()
```

## Reset Signal Chain
```
UI.reset_button_pressed()
    ↓
GameManager.calculate_prestige_bonus()
    ↓
GameManager.prestige_reset_started
    ↓
NodeSystem.reset_nodes()
    ↓
MonsterEnergy.reset_energy()
    ↓
RoomManager.reset_to_room_1()
    ↓
GameManager.apply_prestige_multipliers()
    ↓
GameManager.prestige_reset_completed
    ↓
UI.show_reset_results()
```