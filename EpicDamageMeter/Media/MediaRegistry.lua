--[[
    EpicDamageMeter - Media Registry
    Registers all custom textures, fonts, icons, and sounds with LibSharedMedia

    Author: JugoBetrugoTV
    Version: 1.1.0
]]

local ADDON_NAME, EDM = ...

-- Create media namespace
EDM.Media = {}
local Media = EDM.Media

-- Get LibSharedMedia
local LSM = LibStub("LibSharedMedia-3.0")

-- Media paths
local MEDIA_PATH = "Interface\\AddOns\\EpicDamageMeter\\Media\\"
local TEXTURE_PATH = MEDIA_PATH .. "Textures\\"
local ICON_PATH = MEDIA_PATH .. "Icons\\"
local FONT_PATH = MEDIA_PATH .. "Fonts\\"
local BACKDROP_PATH = MEDIA_PATH .. "Backdrops\\"
local STATUSBAR_PATH = MEDIA_PATH .. "Statusbars\\"
local BORDER_PATH = MEDIA_PATH .. "Borders\\"
local SOUND_PATH = MEDIA_PATH .. "Sounds\\"

-- Legacy texture path (for backward compatibility)
local LEGACY_TEXTURE_PATH = "Interface\\AddOns\\EpicDamageMeter\\Textures\\"

--============================================================================
-- STATUSBAR TEXTURES
--============================================================================

-- Register custom statusbar textures
LSM:Register("statusbar", "EDM Modern", STATUSBAR_PATH .. "statusbar_modern")
LSM:Register("statusbar", "EDM Smooth", STATUSBAR_PATH .. "statusbar_smooth")
LSM:Register("statusbar", "EDM Gradient", STATUSBAR_PATH .. "statusbar_gradient")
LSM:Register("statusbar", "EDM Glossy", STATUSBAR_PATH .. "statusbar_glossy")
LSM:Register("statusbar", "EDM Flat", STATUSBAR_PATH .. "statusbar_flat")
LSM:Register("statusbar", "EDM Minimalist", STATUSBAR_PATH .. "statusbar_minimalist")
LSM:Register("statusbar", "EDM Striped", STATUSBAR_PATH .. "statusbar_striped")
LSM:Register("statusbar", "EDM Gloss", STATUSBAR_PATH .. "statusbar_gloss")
LSM:Register("statusbar", "EDM Neon", STATUSBAR_PATH .. "statusbar_neon")
LSM:Register("statusbar", "EDM Fire", STATUSBAR_PATH .. "statusbar_fire")
LSM:Register("statusbar", "EDM Ice", STATUSBAR_PATH .. "statusbar_ice")
LSM:Register("statusbar", "EDM Arcane", STATUSBAR_PATH .. "statusbar_arcane")

-- Legacy paths (backward compatibility)
LSM:Register("statusbar", "EDM Modern Legacy", LEGACY_TEXTURE_PATH .. "statusbar_modern")
LSM:Register("statusbar", "EDM Smooth Legacy", LEGACY_TEXTURE_PATH .. "statusbar_smooth")
LSM:Register("statusbar", "EDM Gradient Legacy", LEGACY_TEXTURE_PATH .. "statusbar_gradient")
LSM:Register("statusbar", "EDM Glossy Legacy", LEGACY_TEXTURE_PATH .. "statusbar_glossy")
LSM:Register("statusbar", "EDM Flat Legacy", LEGACY_TEXTURE_PATH .. "statusbar_flat")

--============================================================================
-- BACKDROP TEXTURES
--============================================================================

-- Window backgrounds
Media.Backdrops = {
    solid = BACKDROP_PATH .. "backdrop_solid",
    gradient = BACKDROP_PATH .. "backdrop_gradient",
    subtle = BACKDROP_PATH .. "backdrop_subtle",
    dark = BACKDROP_PATH .. "backdrop_dark",
    light = BACKDROP_PATH .. "backdrop_light",
    glass = BACKDROP_PATH .. "backdrop_glass",
    neon = BACKDROP_PATH .. "backdrop_neon",
    fire = BACKDROP_PATH .. "backdrop_fire",
    ice = BACKDROP_PATH .. "backdrop_ice",
    arcane = BACKDROP_PATH .. "backdrop_arcane",
}

--============================================================================
-- BORDER TEXTURES
--============================================================================

-- Window borders
Media.Borders = {
    simple = BORDER_PATH .. "border_simple",
    modern = BORDER_PATH .. "border_modern",
    rounded = BORDER_PATH .. "border_rounded",
    glow = BORDER_PATH .. "border_glow",
    neon = BORDER_PATH .. "border_neon",
    elegant = BORDER_PATH .. "border_elegant",
    thick = BORDER_PATH .. "border_thick",
    thin = BORDER_PATH .. "border_thin",
}

-- Register borders with LSM
LSM:Register("border", "EDM Simple", BORDER_PATH .. "border_simple")
LSM:Register("border", "EDM Modern", BORDER_PATH .. "border_modern")
LSM:Register("border", "EDM Rounded", BORDER_PATH .. "border_rounded")
LSM:Register("border", "EDM Glow", BORDER_PATH .. "border_glow")
LSM:Register("border", "EDM Neon", BORDER_PATH .. "border_neon")

-- Legacy borders
LSM:Register("border", "EDM Simple Legacy", LEGACY_TEXTURE_PATH .. "border_simple")
LSM:Register("border", "EDM Modern Legacy", LEGACY_TEXTURE_PATH .. "border_modern")

--============================================================================
-- ICON TEXTURES
--============================================================================

Media.Icons = {
    -- Main icons
    minimap = ICON_PATH .. "minimap_icon",
    logo = ICON_PATH .. "logo",
    logo_small = ICON_PATH .. "logo_small",

    -- Module icons
    damage = ICON_PATH .. "icon_damage",
    healing = ICON_PATH .. "icon_healing",
    absorbs = ICON_PATH .. "icon_absorbs",
    deaths = ICON_PATH .. "icon_deaths",
    interrupts = ICON_PATH .. "icon_interrupts",
    dispels = ICON_PATH .. "icon_dispels",
    threat = ICON_PATH .. "icon_threat",

    -- UI icons
    settings = ICON_PATH .. "icon_settings",
    graph = ICON_PATH .. "icon_graph",
    reset = ICON_PATH .. "icon_reset",
    close = ICON_PATH .. "icon_close",
    minimize = ICON_PATH .. "icon_minimize",
    maximize = ICON_PATH .. "icon_maximize",
    lock = ICON_PATH .. "icon_lock",
    unlock = ICON_PATH .. "icon_unlock",
    report = ICON_PATH .. "icon_report",

    -- Rank icons
    rank_gold = ICON_PATH .. "rank_gold",
    rank_silver = ICON_PATH .. "rank_silver",
    rank_bronze = ICON_PATH .. "rank_bronze",

    -- Class role icons
    role_tank = ICON_PATH .. "role_tank",
    role_healer = ICON_PATH .. "role_healer",
    role_dps = ICON_PATH .. "role_dps",
}

--============================================================================
-- FONTS
--============================================================================

-- Register custom fonts if available
-- Note: Fonts need to be in .ttf or .otf format

-- Check if custom fonts exist and register them
local customFonts = {
    {"EDM Modern", FONT_PATH .. "EDM_Modern.ttf"},
    {"EDM Clean", FONT_PATH .. "EDM_Clean.ttf"},
    {"EDM Bold", FONT_PATH .. "EDM_Bold.ttf"},
    {"EDM Condensed", FONT_PATH .. "EDM_Condensed.ttf"},
    {"EDM Display", FONT_PATH .. "EDM_Display.ttf"},
}

for _, fontData in ipairs(customFonts) do
    local fontName, fontPath = fontData[1], fontData[2]
    -- Register font (will gracefully fail if file doesn't exist)
    LSM:Register("font", fontName, fontPath)
end

-- Store references to built-in WoW fonts for easy access
Media.Fonts = {
    -- WoW Built-in Fonts
    FrizQuadrata = "Fonts\\FRIZQT__.TTF",
    ArialNarrow = "Fonts\\ARIALN.TTF",
    Skurri = "Fonts\\SKURRI.TTF",
    Morpheus = "Fonts\\MORPHEUS.TTF",
    TwentyOTwo = "Fonts\\2002.TTF",
    TwentyOTwoBold = "Fonts\\2002B.TTF",

    -- Default addon fonts
    Default = "Fonts\\FRIZQT__.TTF",
    Header = "Fonts\\FRIZQT__.TTF",
    Numbers = "Fonts\\ARIALN.TTF",
}

--============================================================================
-- SOUNDS
--============================================================================

-- Register custom sounds
local customSounds = {
    {"EDM Combat Start", SOUND_PATH .. "combat_start.ogg"},
    {"EDM Combat End", SOUND_PATH .. "combat_end.ogg"},
    {"EDM New Record", SOUND_PATH .. "new_record.ogg"},
    {"EDM Death", SOUND_PATH .. "death.ogg"},
    {"EDM Warning", SOUND_PATH .. "warning.ogg"},
    {"EDM Achievement", SOUND_PATH .. "achievement.ogg"},
}

for _, soundData in ipairs(customSounds) do
    local soundName, soundPath = soundData[1], soundData[2]
    LSM:Register("sound", soundName, soundPath)
end

--============================================================================
-- BACKDROP TEMPLATES
--============================================================================

-- Pre-defined backdrop templates for easy use
Media.BackdropTemplates = {
    Modern = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },

    Classic = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    },

    Tooltip = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    },

    Flat = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false,
        tileSize = 0,
        edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    },

    Bordered = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    },

    Glass = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },

    Neon = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = BORDER_PATH .. "border_neon",
        tile = false,
        tileSize = 0,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    },
}

--============================================================================
-- GRADIENT COLORS
--============================================================================

Media.Gradients = {
    -- Window gradients
    TitleBar = {
        start = { r = 0.12, g = 0.12, b = 0.18, a = 1 },
        stop = { r = 0.06, g = 0.06, b = 0.10, a = 1 },
    },

    -- Bar gradients by class
    DamageBar = {
        start = { r = 1.0, g = 0.3, b = 0.2, a = 1 },
        stop = { r = 0.8, g = 0.2, b = 0.1, a = 1 },
    },

    HealingBar = {
        start = { r = 0.3, g = 1.0, b = 0.4, a = 1 },
        stop = { r = 0.2, g = 0.8, b = 0.3, a = 1 },
    },

    -- Neon effects
    NeonBlue = {
        start = { r = 0, g = 0.8, b = 1, a = 1 },
        stop = { r = 0, g = 0.4, b = 0.8, a = 1 },
    },

    NeonPurple = {
        start = { r = 0.8, g = 0.2, b = 1, a = 1 },
        stop = { r = 0.5, g = 0.1, b = 0.8, a = 1 },
    },

    NeonGreen = {
        start = { r = 0.2, g = 1, b = 0.4, a = 1 },
        stop = { r = 0.1, g = 0.8, b = 0.3, a = 1 },
    },
}

--============================================================================
-- COLOR PRESETS
--============================================================================

Media.Colors = {
    -- UI Colors
    Background = { r = 0.05, g = 0.05, b = 0.08, a = 0.92 },
    BackgroundDark = { r = 0.02, g = 0.02, b = 0.04, a = 0.95 },
    BackgroundLight = { r = 0.1, g = 0.1, b = 0.15, a = 0.9 },

    Border = { r = 0.15, g = 0.15, b = 0.2, a = 1 },
    BorderHighlight = { r = 0.3, g = 0.5, b = 0.8, a = 1 },
    BorderAccent = { r = 0.4, g = 0.6, b = 1.0, a = 0.8 },

    Text = { r = 1, g = 1, b = 1, a = 1 },
    TextDim = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
    TextMuted = { r = 0.5, g = 0.5, b = 0.5, a = 1 },

    -- Accent Colors
    AccentBlue = { r = 0.3, g = 0.6, b = 1.0, a = 1 },
    AccentGreen = { r = 0.3, g = 1.0, b = 0.4, a = 1 },
    AccentRed = { r = 1.0, g = 0.3, b = 0.3, a = 1 },
    AccentOrange = { r = 1.0, g = 0.6, b = 0.2, a = 1 },
    AccentPurple = { r = 0.7, g = 0.3, b = 1.0, a = 1 },
    AccentCyan = { r = 0.0, g = 0.9, b = 1.0, a = 1 },

    -- Ranking Colors
    RankGold = { r = 1.0, g = 0.84, b = 0.0, a = 1 },
    RankSilver = { r = 0.75, g = 0.75, b = 0.75, a = 1 },
    RankBronze = { r = 0.80, g = 0.50, b = 0.20, a = 1 },

    -- Status Colors
    Success = { r = 0.2, g = 0.8, b = 0.3, a = 1 },
    Warning = { r = 1.0, g = 0.8, b = 0.0, a = 1 },
    Error = { r = 1.0, g = 0.2, b = 0.2, a = 1 },
    Info = { r = 0.3, g = 0.7, b = 1.0, a = 1 },
}

--============================================================================
-- HELPER FUNCTIONS
--============================================================================

-- Get a statusbar texture path
function Media:GetStatusBar(name)
    local texture = LSM:Fetch("statusbar", name)
    if texture then
        return texture
    end
    return "Interface\\TargetingFrame\\UI-StatusBar"
end

-- Get a border texture path
function Media:GetBorder(name)
    local border = LSM:Fetch("border", name)
    if border then
        return border
    end
    return "Interface\\Buttons\\WHITE8X8"
end

-- Get a font path
function Media:GetFont(name)
    local font = LSM:Fetch("font", name)
    if font then
        return font
    end
    return self.Fonts.Default
end

-- Get a sound path
function Media:GetSound(name)
    local sound = LSM:Fetch("sound", name)
    if sound then
        return sound
    end
    return nil
end

-- Get icon path
function Media:GetIcon(name)
    if self.Icons[name] then
        return self.Icons[name]
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Get backdrop template
function Media:GetBackdropTemplate(name)
    if self.BackdropTemplates[name] then
        return self.BackdropTemplates[name]
    end
    return self.BackdropTemplates.Modern
end

-- Create a gradient texture
function Media:CreateGradient(parent, startColor, endColor, orientation)
    local tex = parent:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")

    if orientation == "HORIZONTAL" then
        tex:SetGradient("HORIZONTAL",
            CreateColor(startColor.r, startColor.g, startColor.b, startColor.a or 1),
            CreateColor(endColor.r, endColor.g, endColor.b, endColor.a or 1)
        )
    else
        tex:SetGradient("VERTICAL",
            CreateColor(startColor.r, startColor.g, startColor.b, startColor.a or 1),
            CreateColor(endColor.r, endColor.g, endColor.b, endColor.a or 1)
        )
    end

    return tex
end

-- Apply color to frame backdrop
function Media:ApplyBackdropColor(frame, bgColor, borderColor)
    if frame.SetBackdropColor and bgColor then
        frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 1)
    end
    if frame.SetBackdropBorderColor and borderColor then
        frame:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    end
end

-- Debug: Print all registered media
function Media:PrintDebug()
    print("|cff00ff00EpicDamageMeter Media Registry:|r")
    print("  Statusbars:", #LSM:List("statusbar"))
    print("  Borders:", #LSM:List("border"))
    print("  Fonts:", #LSM:List("font"))
    print("  Sounds:", #LSM:List("sound"))
end
