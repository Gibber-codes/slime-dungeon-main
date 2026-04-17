$dir = "c:\Users\zacka\Desktop\slime-dungeon-main\resources\nodes"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

$scriptPath = "res://scripts/systems/NodeStat.gd"

function Write-Node {
    param([string]$Id, [string]$Name, [string]$Desc, [int]$Tier, [string]$Parent,
          [string]$Branch, [bool]$Impl, [float]$Cost, [float]$Mult,
          [string]$BK1, [float]$V1, [string]$BK2, [float]$V2,
          [int[]]$Thresholds, [string]$ThresholdKey)

    $implStr = if ($Impl) {"true"} else {"false"}
    $threshArr = if ($Thresholds -and $Thresholds.Count -gt 0) {
        "Array[int]([$($Thresholds -join ', ')])"
    } else { "Array[int]([])" }

    $lines = @(
        '[gd_resource type="Resource" load_steps=2 format=3]',
        '',
        "[ext_resource type=""Script"" path=""$scriptPath"" id=""1""]",
        '',
        '[resource]',
        'script = ExtResource("1")',
        "id = ""$Id""",
        "display_name = ""$Name""",
        "description = ""$Desc""",
        "tier = $Tier",
        "parent_id = ""$Parent""",
        "branch = ""$Branch""",
        "is_implemented = $implStr",
        "base_cost = $Cost",
        "cost_multiplier = $Mult",
        "bonus_key = ""$BK1""",
        "value_per_level = $V1",
        "bonus_key_2 = ""$BK2""",
        "value_per_level_2 = $V2",
        "threshold_levels = $threshArr",
        "threshold_bonus_key = ""$ThresholdKey""",
        ''
    )
    $content = $lines -join "`n"
    [System.IO.File]::WriteAllText("$dir\$Id.tres", $content)
    Write-Host "Created $Id.tres"
}

# ======================== TIER 1 ========================
Write-Node -Id "constitution" -Name "Constitution" `
    -Desc "Increases maximum health. Grants connection slots at key levels." `
    -Tier 1 -Parent "" -Branch "constitution" -Impl $true `
    -Cost 12.0 -Mult 1.15 `
    -BK1 "max_hp" -V1 20.0 -BK2 "" -V2 0.0 `
    -Thresholds @(1, 5, 10) -ThresholdKey "connection_slots"

Write-Node -Id "intelligence" -Name "Intelligence" `
    -Desc "Decreases auto-seek time. Enables focus mode at higher levels." `
    -Tier 1 -Parent "" -Branch "intelligence" -Impl $true `
    -Cost 20.0 -Mult 1.20 `
    -BK1 "seek_reduction" -V1 0.8 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "agility" -Name "Agility" `
    -Desc "Increases movement speed. Reduces momentum decay on hits and bounces." `
    -Tier 1 -Parent "" -Branch "agility" -Impl $true `
    -Cost 12.0 -Mult 1.15 `
    -BK1 "speed_mult" -V1 0.05 -BK2 "momentum_decay_reduction" -V2 0.03 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "strength" -Name "Strength" `
    -Desc "Increases base damage and momentum damage multiplier." `
    -Tier 1 -Parent "" -Branch "strength" -Impl $true `
    -Cost 15.0 -Mult 1.18 `
    -BK1 "damage_mult" -V1 0.08 -BK2 "momentum_mult" -V2 0.05 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "wisdom" -Name "Wisdom" `
    -Desc "Increases Monster Energy yield from all sources." `
    -Tier 1 -Parent "" -Branch "wisdom" -Impl $true `
    -Cost 10.0 -Mult 1.15 `
    -BK1 "energy_mult" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "stamina" -Name "Stamina" `
    -Desc "Increases passive health regeneration." `
    -Tier 1 -Parent "" -Branch "stamina" -Impl $true `
    -Cost 10.0 -Mult 1.12 `
    -BK1 "hp_regen" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ CONSTITUTION T2 ================
Write-Node -Id "mass" -Name "Mass" `
    -Desc "Increases base physical defense. Flat damage reduction." `
    -Tier 2 -Parent "constitution" -Branch "constitution" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "physical_defense" -V1 2.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "aegis" -Name "Aegis" `
    -Desc "Increases base elemental defense for all elements simultaneously." `
    -Tier 2 -Parent "constitution" -Branch "constitution" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "elemental_defense" -V1 1.5 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "balance" -Name "Balance" `
    -Desc "Increases the number of connection slots available in Slime Core." `
    -Tier 2 -Parent "constitution" -Branch "constitution" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "connection_slots" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ CONSTITUTION T3 ================
Write-Node -Id "defiance" -Name "Defiance" `
    -Desc "Resistance to movement impairments: slows, stuns, knockbacks, roots." `
    -Tier 3 -Parent "mass" -Branch "constitution" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "cc_resistance" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "tenacity" -Name "Tenacity" `
    -Desc "Reduces ALL low-health penalties: speed, damage, defense, initiative." `
    -Tier 3 -Parent "mass" -Branch "constitution" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "low_hp_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "resolve" -Name "Resolve" `
    -Desc "Elemental defense scales with your elemental progression levels." `
    -Tier 3 -Parent "aegis" -Branch "constitution" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "elemental_defense_scaling" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "channeling" -Name "Channeling" `
    -Desc "Greatly increased elemental defense for recently used ability elements." `
    -Tier 3 -Parent "aegis" -Branch "constitution" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "active_elemental_defense" -V1 0.15 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ INTELLIGENCE T2 ================
Write-Node -Id "knowledge" -Name "Knowledge" `
    -Desc "Unlocks UI information and stat displays. Reveals entity details." `
    -Tier 2 -Parent "intelligence" -Branch "intelligence" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "info_level" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "focus" -Name "Focus" `
    -Desc "Enables and improves focus mode when few entities remain." `
    -Tier 2 -Parent "intelligence" -Branch "intelligence" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "focus_damage_mult" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "thought" -Name "Thought" `
    -Desc "Increases Monster Energy transfer speed through all Slime Core connections." `
    -Tier 2 -Parent "intelligence" -Branch "intelligence" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "flow_speed_mult" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ INTELLIGENCE T3 ================
Write-Node -Id "analysis" -Name "Analysis" `
    -Desc "Click entities to see detailed information. Detail increases with level." `
    -Tier 3 -Parent "knowledge" -Branch "intelligence" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "analysis_level" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "memory" -Name "Memory" `
    -Desc "Permanently retains unlocked information across resets." `
    -Tier 3 -Parent "knowledge" -Branch "intelligence" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "memory_retention" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "focus_capacity" -Name "Capacity" `
    -Desc "Greatly decreases auto-seek time during focus mode." `
    -Tier 3 -Parent "focus" -Branch "intelligence" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "focus_seek_reduction" -V1 0.5 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "rigor" -Name "Rigor" `
    -Desc "Sets momentum floor during focus state. Retains percentage of max momentum." `
    -Tier 3 -Parent "focus" -Branch "intelligence" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "focus_momentum_floor" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ AGILITY T2 ================
Write-Node -Id "counter" -Name "Counter" `
    -Desc "Chance to reflect percentage of physical damage received." `
    -Tier 2 -Parent "agility" -Branch "agility" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "counter_chance" -V1 0.03 -BK2 "counter_reflect" -V2 0.1 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "dodge" -Name "Dodge" `
    -Desc "Unlocks and increases chance to completely negate incoming attacks." `
    -Tier 2 -Parent "agility" -Branch "agility" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "dodge_chance" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "opportunity" -Name "Opportunity" `
    -Desc "Increases critical strike damage when hitting enemy from behind." `
    -Tier 2 -Parent "agility" -Branch "agility" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "backstab_crit_damage" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ AGILITY T3 ================
Write-Node -Id "restitution" -Name "Restitution" `
    -Desc "Retain more momentum after collision impacts." `
    -Tier 3 -Parent "counter" -Branch "agility" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "collision_momentum_retention" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "multihit" -Name "Multihit" `
    -Desc "Chance to attack twice in one collision." `
    -Tier 3 -Parent "counter" -Branch "agility" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "multihit_chance" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "stealth" -Name "Stealth" `
    -Desc "Lowers sight range of enemies." `
    -Tier 3 -Parent "dodge" -Branch "agility" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "enemy_sight_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "penetration" -Name "Penetration" `
    -Desc "Ignore portion of enemy armor and defense." `
    -Tier 3 -Parent "dodge" -Branch "agility" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "armor_penetration" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ STRENGTH T2 ================
Write-Node -Id "precision" -Name "Precision" `
    -Desc "Increases critical hit chance." `
    -Tier 2 -Parent "strength" -Branch "strength" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "crit_chance" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "str_momentum" -Name "Momentum" `
    -Desc "Increases maximum momentum cap." `
    -Tier 2 -Parent "strength" -Branch "strength" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "momentum_cap" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "engulf" -Name "Engulf" `
    -Desc "Retain more momentum when engulfing entities." `
    -Tier 2 -Parent "strength" -Branch "strength" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "engulf_momentum_retention" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ STRENGTH T3 ================
Write-Node -Id "application" -Name "Application" `
    -Desc "Increases critical damage multiplier." `
    -Tier 3 -Parent "precision" -Branch "strength" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "crit_damage_mult" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "reaction" -Name "Reaction" `
    -Desc "Increased critical hit chance during failed initiative checks." `
    -Tier 3 -Parent "precision" -Branch "strength" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "reaction_crit_chance" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "drive" -Name "Drive" `
    -Desc "Increases momentum gain per second." `
    -Tier 3 -Parent "str_momentum" -Branch "strength" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "momentum_gain_rate" -V1 0.02 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "burst" -Name "Burst" `
    -Desc "Lowers momentum threshold required to trigger engulf." `
    -Tier 3 -Parent "str_momentum" -Branch "strength" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "engulf_threshold_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ WISDOM T2 ================
Write-Node -Id "power" -Name "Power" `
    -Desc "Unlocks Elemental Core system. Converts Monster Energy to Elemental Energy." `
    -Tier 2 -Parent "wisdom" -Branch "wisdom" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "elemental_unlock" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "intuition" -Name "Intuition" `
    -Desc "Sets maximum level cap for ALL elemental nodes." `
    -Tier 2 -Parent "wisdom" -Branch "wisdom" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "elemental_level_cap" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "peace" -Name "Peace" `
    -Desc "Increases Monster Energy yield from all entities." `
    -Tier 2 -Parent "wisdom" -Branch "wisdom" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "energy_mult" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ WISDOM T3 ================
Write-Node -Id "reflection" -Name "Reflection" `
    -Desc "Increases Elemental Energy transfer speed within Elemental Core." `
    -Tier 3 -Parent "power" -Branch "wisdom" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "elemental_flow_speed" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "harmony" -Name "Harmony" `
    -Desc "Increases elemental connection count for more simultaneous active elements." `
    -Tier 3 -Parent "power" -Branch "wisdom" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "elemental_connections" -V1 1.0 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "sympathy" -Name "Sympathy" `
    -Desc "Universal power boost to all active elemental effects." `
    -Tier 3 -Parent "intuition" -Branch "wisdom" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "elemental_power_mult" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "efficiency" -Name "Efficiency" `
    -Desc "Reduces Elemental Energy cost of all abilities." `
    -Tier 3 -Parent "intuition" -Branch "wisdom" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "elemental_cost_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ STAMINA T2 ================
Write-Node -Id "frenzy" -Name "Frenzy" `
    -Desc "Increases frenzy bar regeneration rate. Enables burst speed and momentum." `
    -Tier 2 -Parent "stamina" -Branch "stamina" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "frenzy_regen" -V1 0.1 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "regeneration" -Name "Regeneration" `
    -Desc "Increases passive health regeneration rate." `
    -Tier 2 -Parent "stamina" -Branch "stamina" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "hp_regen" -V1 0.5 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "digestion" -Name "Digestion" `
    -Desc "Yield more Monster Energy from engulfed entities." `
    -Tier 2 -Parent "stamina" -Branch "stamina" -Impl $false `
    -Cost 30.0 -Mult 1.15 `
    -BK1 "engulf_energy_mult" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

# ================ STAMINA T3 ================
Write-Node -Id "frenzy_burst" -Name "Frenzy Burst" `
    -Desc "Increases momentum gain while frenzy is active." `
    -Tier 3 -Parent "frenzy" -Branch "stamina" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "frenzy_momentum_gain" -V1 0.03 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "frenzy_speed" -Name "Frenzy Speed" `
    -Desc "Increases move speed while frenzy is active." `
    -Tier 3 -Parent "frenzy" -Branch "stamina" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "frenzy_speed_mult" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "resilience" -Name "Resilience" `
    -Desc "Decreases low-health penalty on move speed." `
    -Tier 3 -Parent "regeneration" -Branch "stamina" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "low_hp_speed_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Node -Id "toughness" -Name "Toughness" `
    -Desc "Decreases low-health penalty on damage output." `
    -Tier 3 -Parent "regeneration" -Branch "stamina" -Impl $false `
    -Cost 60.0 -Mult 1.18 `
    -BK1 "low_hp_damage_reduction" -V1 0.05 -BK2 "" -V2 0.0 `
    -Thresholds @() -ThresholdKey ""

Write-Host "`nDone! Created 48 .tres files in $dir"
