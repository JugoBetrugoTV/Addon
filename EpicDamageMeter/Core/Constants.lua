--[[
    EpicDamageMeter - Constants
    Global constants and configuration values
]]

local ADDON_NAME, EDM = ...

-- Create namespace
EDM.Constants = {}
local C = EDM.Constants

-- Addon Info
C.ADDON_NAME = "EpicDamageMeter"
C.ADDON_SHORT = "EDM"
C.VERSION = "1.0.9"
C.INTERFACE_VERSION = 110207

-- Display Modes
C.DISPLAY_MODE = {
    -- Damage
    DAMAGE_DONE = 1,
    DPS = 2,
    DAMAGE_TAKEN = 3,
    FRIENDLY_FIRE = 4,
    -- Healing
    HEALING_DONE = 5,
    HPS = 6,
    OVERHEALING = 7,
    HEALING_TAKEN = 8,
    ABSORBS = 9,
    ABSORBS_DONE = 10,
    -- Utility
    DEATHS = 11,
    INTERRUPTS = 12,
    DISPELS = 13,
    CC_BREAKS = 14,
    RESURRECTS = 15,
    -- Misc
    THREAT = 16,
    ACTIVITY = 17,
}

C.DISPLAY_MODE_NAMES = {
    [C.DISPLAY_MODE.DAMAGE_DONE] = "Damage Done",
    [C.DISPLAY_MODE.DPS] = "DPS",
    [C.DISPLAY_MODE.DAMAGE_TAKEN] = "Damage Taken",
    [C.DISPLAY_MODE.FRIENDLY_FIRE] = "Friendly Fire",
    [C.DISPLAY_MODE.HEALING_DONE] = "Healing Done",
    [C.DISPLAY_MODE.HPS] = "HPS",
    [C.DISPLAY_MODE.OVERHEALING] = "Overhealing",
    [C.DISPLAY_MODE.HEALING_TAKEN] = "Healing Received",
    [C.DISPLAY_MODE.ABSORBS] = "Absorbs Done",
    [C.DISPLAY_MODE.ABSORBS_DONE] = "Absorbs Received",
    [C.DISPLAY_MODE.DEATHS] = "Deaths",
    [C.DISPLAY_MODE.INTERRUPTS] = "Interrupts",
    [C.DISPLAY_MODE.DISPELS] = "Dispels",
    [C.DISPLAY_MODE.CC_BREAKS] = "CC Breaks",
    [C.DISPLAY_MODE.RESURRECTS] = "Resurrects",
    [C.DISPLAY_MODE.THREAT] = "Threat",
    [C.DISPLAY_MODE.ACTIVITY] = "Activity",
}

-- Segment Types
C.SEGMENT_TYPE = {
    CURRENT = 1,
    OVERALL = 2,
    BOSS = 3,
    TRASH = 4,
}

-- Combat Events
C.DAMAGE_EVENTS = {
    ["SWING_DAMAGE"] = true,
    ["RANGE_DAMAGE"] = true,
    ["SPELL_DAMAGE"] = true,
    ["SPELL_PERIODIC_DAMAGE"] = true,
    ["DAMAGE_SHIELD"] = true,
    ["DAMAGE_SPLIT"] = true,
    ["ENVIRONMENTAL_DAMAGE"] = true,
}

C.HEAL_EVENTS = {
    ["SPELL_HEAL"] = true,
    ["SPELL_PERIODIC_HEAL"] = true,
}

C.ABSORB_EVENTS = {
    ["SPELL_ABSORBED"] = true,
}

C.MISS_EVENTS = {
    ["SWING_MISSED"] = true,
    ["RANGE_MISSED"] = true,
    ["SPELL_MISSED"] = true,
    ["SPELL_PERIODIC_MISSED"] = true,
    ["DAMAGE_SHIELD_MISSED"] = true,
}

C.DEATH_EVENTS = {
    ["UNIT_DIED"] = true,
    ["UNIT_DESTROYED"] = true,
    ["UNIT_DISSIPATES"] = true,
}

C.INTERRUPT_EVENTS = {
    ["SPELL_INTERRUPT"] = true,
}

C.DISPEL_EVENTS = {
    ["SPELL_DISPEL"] = true,
    ["SPELL_STOLEN"] = true,
    ["SPELL_DISPEL_FAILED"] = true,
}

C.AURA_EVENTS = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REMOVED"] = true,
    ["SPELL_AURA_APPLIED_DOSE"] = true,
    ["SPELL_AURA_REMOVED_DOSE"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_AURA_BROKEN"] = true,
    ["SPELL_AURA_BROKEN_SPELL"] = true,
}

C.CAST_EVENTS = {
    ["SPELL_CAST_START"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_CAST_FAILED"] = true,
}

-- Miss Types
C.MISS_TYPES = {
    ABSORB = "ABSORB",
    BLOCK = "BLOCK",
    DEFLECT = "DEFLECT",
    DODGE = "DODGE",
    EVADE = "EVADE",
    IMMUNE = "IMMUNE",
    MISS = "MISS",
    PARRY = "PARRY",
    REFLECT = "REFLECT",
    RESIST = "RESIST",
}

-- Unit Flags
C.UNIT_FLAGS = {
    AFFILIATION_MINE = 0x00000001,
    AFFILIATION_PARTY = 0x00000002,
    AFFILIATION_RAID = 0x00000004,
    AFFILIATION_OUTSIDER = 0x00000008,
    REACTION_FRIENDLY = 0x00000010,
    REACTION_NEUTRAL = 0x00000020,
    REACTION_HOSTILE = 0x00000040,
    CONTROL_PLAYER = 0x00000100,
    CONTROL_NPC = 0x00000200,
    TYPE_PLAYER = 0x00000400,
    TYPE_NPC = 0x00000800,
    TYPE_PET = 0x00001000,
    TYPE_GUARDIAN = 0x00002000,
    TYPE_OBJECT = 0x00004000,
}

-- Class Colors (Blizzard standard)
C.CLASS_COLORS = {
    WARRIOR = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE = { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK = { r = 0.53, g = 0.53, b = 0.93 },
    MONK = { r = 0.00, g = 1.00, b = 0.60 },
    DRUID = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER = { r = 0.20, g = 0.58, b = 0.50 },
    -- Default
    UNKNOWN = { r = 0.6, g = 0.6, b = 0.6 },
    PET = { r = 0.3, g = 0.65, b = 0.3 },
    NPC = { r = 0.8, g = 0.2, b = 0.2 },
}

-- School Colors
C.SCHOOL_COLORS = {
    [1] = { r = 1.0, g = 1.0, b = 0.0 }, -- Physical
    [2] = { r = 1.0, g = 0.9, b = 0.5 }, -- Holy
    [4] = { r = 1.0, g = 0.5, b = 0.0 }, -- Fire
    [8] = { r = 0.3, g = 1.0, b = 0.3 }, -- Nature
    [16] = { r = 0.5, g = 0.5, b = 1.0 }, -- Frost
    [32] = { r = 0.5, g = 0.0, b = 0.5 }, -- Shadow
    [64] = { r = 1.0, g = 0.5, b = 1.0 }, -- Arcane
}

-- Bar Colors based on ranking
C.BAR_COLORS = {
    { r = 1.0, g = 0.84, b = 0.0 },  -- Gold for #1
    { r = 0.75, g = 0.75, b = 0.75 }, -- Silver for #2
    { r = 0.80, g = 0.50, b = 0.20 }, -- Bronze for #3
    -- Rest will use class colors or default
}

-- Default Profile Settings
C.DEFAULT_SETTINGS = {
    profile = {
        -- General
        enabled = true,
        minimap = {
            hide = false,
            minimapPos = 225,
            radius = 80,
        },
        locked = false,

        -- Window
        window = {
            width = 300,
            height = 200,
            scale = 1.0,
            opacity = 0.9,
            point = "CENTER",
            x = 0,
            y = 0,
            titleHeight = 20,
            showTitle = true,
            showScrollbar = true,
            showBackground = true,
            backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.85 },
            borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        },

        -- Bars
        bars = {
            height = 18,
            spacing = 1,
            texture = "Modern",
            font = "Friz Quadrata TT",
            fontSize = 11,
            fontFlags = "OUTLINE",
            showRank = true,
            showPercent = true,
            showValue = true,
            showIcon = true,
            useClassColors = true,
            barColor = { r = 0.3, g = 0.3, b = 0.7, a = 1 },
            textColor = { r = 1, g = 1, b = 1, a = 1 },
            animation = true,
            animationSpeed = 0.3,
            -- Advanced options
            showSpecIcon = true,           -- Show specialization icon instead of class
            showRPS = false,               -- Show R-PS (resource per second)
            showTotalAndPS = false,        -- Show both total and per-second value
            clickToDetails = true,         -- Click bar to open details window
            rightClickMenu = true,         -- Right-click for context menu
            flashOnCrit = false,           -- Flash bar on critical hit
            myBarFirst = false,            -- Always show player's bar at top
        },

        -- Death Log
        deathLog = {
            enabled = true,
            maxEntries = 20,               -- Max entries per death
            trackTime = 10,                -- Seconds before death to track
            showAbsorbs = true,            -- Show absorb amounts
            showOverkill = true,           -- Show overkill damage
        },

        -- Aura Tracking (not yet implemented)
        auras = {
            trackBuffs = true,             -- Track buff uptimes
            trackDebuffs = true,           -- Track debuff applications
            onlyMine = true,               -- Only track player's auras
            showUptime = true,             -- Show uptime percentages
        },

        -- Graph
        graph = {
            enabled = true,
            width = 400,
            height = 200,
            lineWidth = 2,
            showLegend = true,
            showGrid = true,
            gridColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 },
            updateInterval = 1,
            maxDataPoints = 300,
        },

        -- Combat
        combat = {
            autoReset = false,             -- Don't auto-reset on combat end
            resetOnCombat = true,          -- Reset current segment when new combat starts
            maxSegments = 10,
            mergePlayerPets = true,
            showOnlyBosses = false,
            minCombatTime = 3,
            combatTimeout = 3,             -- Seconds of no combat before segment ends
            keepDataMinutes = 30,          -- Keep data for 30 minutes
        },

        -- Display
        display = {
            mode = C.DISPLAY_MODE.DAMAGE_DONE,
            segment = C.SEGMENT_TYPE.CURRENT,
            numberFormat = "SHORT", -- SHORT, FULL, COMMA
            refreshRate = 0.5,
            maxBars = 20,
            showCurrentDPS = true,         -- Show current DPS in status bar
            showDuration = true,           -- Show fight duration
            highlightSelf = true,          -- Highlight player's own bar
            colorBySchool = false,         -- Color bars by spell school instead of class
            realTimeMode = true,           -- Real-time updates vs segment-only
        },

        -- Visibility
        visibility = {
            autoHide = false,              -- Auto-hide when leaving combat
            autoShow = false,              -- Auto-show when entering combat
            showOnlyInGroup = false,       -- Only show when in party/raid
            showOnlyInInstance = false,    -- Only show in dungeons/raids
            hideInPvP = false,             -- Hide in battlegrounds/arenas
            fadeOutOfCombat = false,       -- Fade window when out of combat
            fadeOpacity = 0.5,             -- Opacity when faded
        },

        -- Sounds
        sounds = {
            combatStart = true,
            combatEnd = true,
            newRecord = true,
            volume = 0.5,
        },

        -- Advanced
        advanced = {
            debugMode = false,
            recordTargets = true,
            recordAbilities = true,
            recordTimeline = true,
        },
    },
}

-- Number Abbreviations
C.NUMBER_ABBREVIATIONS = {
    { threshold = 1e12, suffix = "T" },
    { threshold = 1e9, suffix = "B" },
    { threshold = 1e6, suffix = "M" },
    { threshold = 1e3, suffix = "K" },
}

-- Update Intervals
C.UPDATE_INTERVAL = 0.1 -- 10 updates per second for real-time feel
C.GRAPH_UPDATE_INTERVAL = 1.0 -- Graph updates once per second

-- Max Values
C.MAX_SEGMENTS = 30
C.MAX_BARS = 50
C.MAX_GRAPH_POINTS = 600
C.MAX_DEATH_LOG_ENTRIES = 20
C.MAX_ABILITY_ENTRIES = 100

-- Make constants available
_G.EDM = EDM
