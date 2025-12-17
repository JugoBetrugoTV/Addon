--[[
    EpicDamageMeter - English (US) Localization
]]

local ADDON_NAME = ...
local L = {}

-- General
L["ADDON_NAME"] = "EpicDamageMeter"
L["ADDON_LOADED"] = "EpicDamageMeter loaded. Type /edm for options."
L["VERSION"] = "Version"
L["ENABLED"] = "Enabled"
L["DISABLED"] = "Disabled"
L["SHOW"] = "Show"
L["HIDE"] = "Hide"
L["RESET"] = "Reset"
L["CLOSE"] = "Close"
L["OPTIONS"] = "Options"
L["SETTINGS"] = "Settings"
L["GENERAL"] = "General"
L["APPEARANCE"] = "Appearance"
L["PROFILES"] = "Profiles"

-- Combat Tracking
L["DAMAGE"] = "Damage"
L["HEALING"] = "Healing"
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["TOTAL"] = "Total"
L["OVERALL"] = "Overall"
L["CURRENT"] = "Current"
L["LAST_FIGHT"] = "Last Fight"
L["SEGMENT"] = "Segment"
L["BOSS"] = "Boss"
L["TRASH"] = "Trash"
L["DUNGEON"] = "Dungeon"
L["RAID"] = "Raid"

-- Displays
L["DAMAGE_DONE"] = "Damage Done"
L["DAMAGE_TAKEN"] = "Damage Taken"
L["HEALING_DONE"] = "Healing Done"
L["HEALING_TAKEN"] = "Healing Taken"
L["OVERHEALING"] = "Overhealing"
L["ABSORBS"] = "Absorbs"
L["EFFECTIVE_HEALING"] = "Effective Healing"
L["DEATHS"] = "Deaths"
L["INTERRUPTS"] = "Interrupts"
L["DISPELS"] = "Dispels"
L["THREAT"] = "Threat"
L["ACTIVITY"] = "Activity"
L["UPTIME"] = "Uptime"

-- Abilities
L["ABILITIES"] = "Abilities"
L["SPELLS"] = "Spells"
L["TOP_ABILITY"] = "Top Ability"
L["CRITICAL"] = "Critical"
L["NORMAL"] = "Normal"
L["HIT"] = "Hit"
L["CRIT"] = "Crit"
L["MISS"] = "Miss"
L["DODGE"] = "Dodge"
L["PARRY"] = "Parry"
L["BLOCK"] = "Block"
L["RESIST"] = "Resist"
L["ABSORB"] = "Absorb"
L["IMMUNE"] = "Immune"
L["DEFLECT"] = "Deflect"
L["EVADE"] = "Evade"
L["REFLECT"] = "Reflect"

-- Combat
L["IN_COMBAT"] = "In Combat"
L["OUT_OF_COMBAT"] = "Out of Combat"
L["COMBAT_TIME"] = "Combat Time"
L["COMBAT_START"] = "Combat Started"
L["COMBAT_END"] = "Combat Ended"
L["ENCOUNTER_START"] = "Encounter Started"
L["ENCOUNTER_END"] = "Encounter Ended"
L["WIPE"] = "Wipe"
L["KILL"] = "Kill"

-- Targets
L["TARGETS"] = "Targets"
L["TARGET"] = "Target"
L["SOURCE"] = "Source"
L["PLAYER"] = "Player"
L["PET"] = "Pet"
L["NPC"] = "NPC"
L["UNKNOWN"] = "Unknown"

-- UI
L["MAIN_WINDOW"] = "Main Window"
L["GRAPH_WINDOW"] = "Graph Window"
L["DETAIL_WINDOW"] = "Detail Window"
L["TITLE_BAR"] = "Title Bar"
L["STATUS_BAR"] = "Status Bar"
L["SCROLL_BAR"] = "Scroll Bar"
L["MINIMAP_BUTTON"] = "Minimap Button"
L["LOCK_WINDOW"] = "Lock Window"
L["UNLOCK_WINDOW"] = "Unlock Window"
L["RESIZE"] = "Resize"
L["DRAG"] = "Drag to move"

-- Configuration
L["GENERAL_SETTINGS"] = "General Settings"
L["WINDOW_SETTINGS"] = "Window Settings"
L["BAR_SETTINGS"] = "Bar Settings"
L["FONT_SETTINGS"] = "Font Settings"
L["COLOR_SETTINGS"] = "Color Settings"
L["SOUND_SETTINGS"] = "Sound Settings"

L["BACKGROUND_COLOR"] = "Background Color"
L["BORDER_COLOR"] = "Border Color"
L["BAR_TEXTURE"] = "Bar Texture"
L["BAR_HEIGHT"] = "Bar Height"
L["BAR_SPACING"] = "Bar Spacing"
L["FONT"] = "Font"
L["FONT_SIZE"] = "Font Size"
L["FONT_FLAGS"] = "Font Flags"
L["SCALE"] = "Scale"
L["OPACITY"] = "Opacity"
L["WIDTH"] = "Width"
L["HEIGHT"] = "Height"

-- Actions
L["TOGGLE_WINDOW"] = "Toggle Window"
L["SHOW_WINDOW"] = "Show Window"
L["HIDE_WINDOW"] = "Hide Window"
L["RESET_DATA"] = "Reset Data"
L["RESET_SEGMENT"] = "Reset Segment"
L["CLEAR_ALL"] = "Clear All"
L["REPORT"] = "Report"
L["REPORT_TO_CHAT"] = "Report to Chat"
L["COPY_TO_CLIPBOARD"] = "Copy to Clipboard"

-- Tooltips
L["TOOLTIP_DPS"] = "Damage per Second"
L["TOOLTIP_HPS"] = "Healing per Second"
L["TOOLTIP_CLICK_DETAILS"] = "Click for details"
L["TOOLTIP_RIGHT_CLICK_OPTIONS"] = "Right-click for options"
L["TOOLTIP_DRAG_MOVE"] = "Drag to move"
L["TOOLTIP_SHIFT_CLICK_REPORT"] = "Shift-click to report"

-- Graph
L["GRAPH_DPS_OVER_TIME"] = "DPS Over Time"
L["GRAPH_HPS_OVER_TIME"] = "HPS Over Time"
L["GRAPH_DAMAGE_TIMELINE"] = "Damage Timeline"
L["GRAPH_HEALING_TIMELINE"] = "Healing Timeline"
L["TIME_AXIS"] = "Time"
L["VALUE_AXIS"] = "Value"

-- Death Log
L["DEATH_LOG"] = "Death Log"
L["TIME_OF_DEATH"] = "Time of Death"
L["KILLING_BLOW"] = "Killing Blow"
L["LAST_HITS"] = "Last Hits"
L["HEALTH_BEFORE_DEATH"] = "Health Before Death"

-- Segments
L["CURRENT_SEGMENT"] = "Current"
L["PREVIOUS_SEGMENT"] = "Previous"
L["OVERALL_DATA"] = "Overall"
L["SELECT_SEGMENT"] = "Select Segment"
L["DELETE_SEGMENT"] = "Delete Segment"
L["MAX_SEGMENTS"] = "Max Segments"

-- Classes (for coloring)
L["WARRIOR"] = "Warrior"
L["PALADIN"] = "Paladin"
L["HUNTER"] = "Hunter"
L["ROGUE"] = "Rogue"
L["PRIEST"] = "Priest"
L["DEATHKNIGHT"] = "Death Knight"
L["SHAMAN"] = "Shaman"
L["MAGE"] = "Mage"
L["WARLOCK"] = "Warlock"
L["MONK"] = "Monk"
L["DRUID"] = "Druid"
L["DEMONHUNTER"] = "Demon Hunter"
L["EVOKER"] = "Evoker"

-- Errors
L["ERROR_NO_DATA"] = "No data available"
L["ERROR_INVALID_SEGMENT"] = "Invalid segment"
L["ERROR_COMBAT_REQUIRED"] = "Must be in combat"

-- Slash Commands
L["SLASH_SHOW"] = "show - Show the main window"
L["SLASH_HIDE"] = "hide - Hide the main window"
L["SLASH_TOGGLE"] = "toggle - Toggle the main window"
L["SLASH_RESET"] = "reset - Reset all data"
L["SLASH_CONFIG"] = "config - Open configuration"
L["SLASH_HELP"] = "help - Show this help"

-- Make L available globally
EpicDamageMeter_Locale = L
