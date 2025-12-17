--[[
    EpicDamageMeter - German (DE) Localization
]]

local ADDON_NAME = ...
local L = EpicDamageMeter_Locale or {}

if GetLocale() ~= "deDE" then return end

-- General
L["ADDON_NAME"] = "EpicDamageMeter"
L["ADDON_LOADED"] = "EpicDamageMeter geladen. Tippe /edm für Optionen."
L["VERSION"] = "Version"
L["ENABLED"] = "Aktiviert"
L["DISABLED"] = "Deaktiviert"
L["SHOW"] = "Anzeigen"
L["HIDE"] = "Verstecken"
L["RESET"] = "Zurücksetzen"
L["CLOSE"] = "Schließen"
L["OPTIONS"] = "Optionen"
L["SETTINGS"] = "Einstellungen"
L["GENERAL"] = "Allgemein"
L["APPEARANCE"] = "Aussehen"
L["PROFILES"] = "Profile"

-- Combat Tracking
L["DAMAGE"] = "Schaden"
L["HEALING"] = "Heilung"
L["DPS"] = "DPS"
L["HPS"] = "HPS"
L["TOTAL"] = "Gesamt"
L["OVERALL"] = "Insgesamt"
L["CURRENT"] = "Aktuell"
L["LAST_FIGHT"] = "Letzter Kampf"
L["SEGMENT"] = "Segment"
L["BOSS"] = "Boss"
L["TRASH"] = "Trash"
L["DUNGEON"] = "Dungeon"
L["RAID"] = "Schlachtzug"

-- Displays
L["DAMAGE_DONE"] = "Verursachter Schaden"
L["DAMAGE_TAKEN"] = "Erlittener Schaden"
L["HEALING_DONE"] = "Heilung verursacht"
L["HEALING_TAKEN"] = "Heilung erhalten"
L["OVERHEALING"] = "Überheilung"
L["ABSORBS"] = "Absorptionen"
L["EFFECTIVE_HEALING"] = "Effektive Heilung"
L["DEATHS"] = "Tode"
L["INTERRUPTS"] = "Unterbrechungen"
L["DISPELS"] = "Reinigungen"
L["THREAT"] = "Bedrohung"
L["ACTIVITY"] = "Aktivität"
L["UPTIME"] = "Laufzeit"

-- Abilities
L["ABILITIES"] = "Fähigkeiten"
L["SPELLS"] = "Zauber"
L["TOP_ABILITY"] = "Beste Fähigkeit"
L["CRITICAL"] = "Kritisch"
L["NORMAL"] = "Normal"
L["HIT"] = "Treffer"
L["CRIT"] = "Kritisch"
L["MISS"] = "Verfehlt"
L["DODGE"] = "Ausweichen"
L["PARRY"] = "Parieren"
L["BLOCK"] = "Blocken"
L["RESIST"] = "Widerstehen"
L["ABSORB"] = "Absorbieren"
L["IMMUNE"] = "Immun"
L["DEFLECT"] = "Ablenken"
L["EVADE"] = "Entkommen"
L["REFLECT"] = "Reflektieren"

-- Combat
L["IN_COMBAT"] = "Im Kampf"
L["OUT_OF_COMBAT"] = "Außerhalb des Kampfes"
L["COMBAT_TIME"] = "Kampfzeit"
L["COMBAT_START"] = "Kampf gestartet"
L["COMBAT_END"] = "Kampf beendet"
L["ENCOUNTER_START"] = "Begegnung gestartet"
L["ENCOUNTER_END"] = "Begegnung beendet"
L["WIPE"] = "Wipe"
L["KILL"] = "Kill"

-- Targets
L["TARGETS"] = "Ziele"
L["TARGET"] = "Ziel"
L["SOURCE"] = "Quelle"
L["PLAYER"] = "Spieler"
L["PET"] = "Begleiter"
L["NPC"] = "NPC"
L["UNKNOWN"] = "Unbekannt"

-- UI
L["MAIN_WINDOW"] = "Hauptfenster"
L["GRAPH_WINDOW"] = "Grafik-Fenster"
L["DETAIL_WINDOW"] = "Detail-Fenster"
L["TITLE_BAR"] = "Titelleiste"
L["STATUS_BAR"] = "Statusleiste"
L["SCROLL_BAR"] = "Scrollleiste"
L["MINIMAP_BUTTON"] = "Minimap-Button"
L["LOCK_WINDOW"] = "Fenster sperren"
L["UNLOCK_WINDOW"] = "Fenster entsperren"
L["RESIZE"] = "Größe ändern"
L["DRAG"] = "Ziehen zum Verschieben"

-- Configuration
L["GENERAL_SETTINGS"] = "Allgemeine Einstellungen"
L["WINDOW_SETTINGS"] = "Fenster-Einstellungen"
L["BAR_SETTINGS"] = "Balken-Einstellungen"
L["FONT_SETTINGS"] = "Schrift-Einstellungen"
L["COLOR_SETTINGS"] = "Farb-Einstellungen"
L["SOUND_SETTINGS"] = "Sound-Einstellungen"

L["BACKGROUND_COLOR"] = "Hintergrundfarbe"
L["BORDER_COLOR"] = "Rahmenfarbe"
L["BAR_TEXTURE"] = "Balken-Textur"
L["BAR_HEIGHT"] = "Balkenhöhe"
L["BAR_SPACING"] = "Balkenabstand"
L["FONT"] = "Schriftart"
L["FONT_SIZE"] = "Schriftgröße"
L["FONT_FLAGS"] = "Schrift-Flags"
L["SCALE"] = "Skalierung"
L["OPACITY"] = "Transparenz"
L["WIDTH"] = "Breite"
L["HEIGHT"] = "Höhe"

-- Actions
L["TOGGLE_WINDOW"] = "Fenster umschalten"
L["SHOW_WINDOW"] = "Fenster anzeigen"
L["HIDE_WINDOW"] = "Fenster verstecken"
L["RESET_DATA"] = "Daten zurücksetzen"
L["RESET_SEGMENT"] = "Segment zurücksetzen"
L["CLEAR_ALL"] = "Alles löschen"
L["REPORT"] = "Melden"
L["REPORT_TO_CHAT"] = "Im Chat melden"
L["COPY_TO_CLIPBOARD"] = "In Zwischenablage kopieren"

-- Tooltips
L["TOOLTIP_DPS"] = "Schaden pro Sekunde"
L["TOOLTIP_HPS"] = "Heilung pro Sekunde"
L["TOOLTIP_CLICK_DETAILS"] = "Klicken für Details"
L["TOOLTIP_RIGHT_CLICK_OPTIONS"] = "Rechtsklick für Optionen"
L["TOOLTIP_DRAG_MOVE"] = "Ziehen zum Verschieben"
L["TOOLTIP_SHIFT_CLICK_REPORT"] = "Shift-Klick zum Melden"

-- Graph
L["GRAPH_DPS_OVER_TIME"] = "DPS über Zeit"
L["GRAPH_HPS_OVER_TIME"] = "HPS über Zeit"
L["GRAPH_DAMAGE_TIMELINE"] = "Schadens-Zeitverlauf"
L["GRAPH_HEALING_TIMELINE"] = "Heilungs-Zeitverlauf"
L["TIME_AXIS"] = "Zeit"
L["VALUE_AXIS"] = "Wert"

-- Death Log
L["DEATH_LOG"] = "Todes-Log"
L["TIME_OF_DEATH"] = "Todeszeitpunkt"
L["KILLING_BLOW"] = "Tödlicher Schlag"
L["LAST_HITS"] = "Letzte Treffer"
L["HEALTH_BEFORE_DEATH"] = "Gesundheit vor dem Tod"

-- Segments
L["CURRENT_SEGMENT"] = "Aktuell"
L["PREVIOUS_SEGMENT"] = "Vorherig"
L["OVERALL_DATA"] = "Insgesamt"
L["SELECT_SEGMENT"] = "Segment auswählen"
L["DELETE_SEGMENT"] = "Segment löschen"
L["MAX_SEGMENTS"] = "Max. Segmente"

-- Classes (for coloring)
L["WARRIOR"] = "Krieger"
L["PALADIN"] = "Paladin"
L["HUNTER"] = "Jäger"
L["ROGUE"] = "Schurke"
L["PRIEST"] = "Priester"
L["DEATHKNIGHT"] = "Todesritter"
L["SHAMAN"] = "Schamane"
L["MAGE"] = "Magier"
L["WARLOCK"] = "Hexenmeister"
L["MONK"] = "Mönch"
L["DRUID"] = "Druide"
L["DEMONHUNTER"] = "Dämonenjäger"
L["EVOKER"] = "Rufer"

-- Errors
L["ERROR_NO_DATA"] = "Keine Daten verfügbar"
L["ERROR_INVALID_SEGMENT"] = "Ungültiges Segment"
L["ERROR_COMBAT_REQUIRED"] = "Muss im Kampf sein"

-- Slash Commands
L["SLASH_SHOW"] = "show - Hauptfenster anzeigen"
L["SLASH_HIDE"] = "hide - Hauptfenster verstecken"
L["SLASH_TOGGLE"] = "toggle - Hauptfenster umschalten"
L["SLASH_RESET"] = "reset - Alle Daten zurücksetzen"
L["SLASH_CONFIG"] = "config - Konfiguration öffnen"
L["SLASH_HELP"] = "help - Diese Hilfe anzeigen"
