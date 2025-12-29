--[[
    EpicDamageMeter - Skins (Enhanced)
    Beautiful skin system with multiple themes
]]

local ADDON_NAME, EDM = ...

EDM.Skins = {}
local Skins = EDM.Skins
local LSM = LibStub("LibSharedMedia-3.0")

-- Skin definitions
Skins.list = {}
Skins.current = "Modern"

-- Default textures path
local TEXTURE_PATH = "Interface\\AddOns\\EpicDamageMeter\\Textures\\"

-- Register custom textures with LibSharedMedia
LSM:Register("statusbar", "EDM Modern", TEXTURE_PATH .. "statusbar_modern")
LSM:Register("statusbar", "EDM Smooth", TEXTURE_PATH .. "statusbar_smooth")
LSM:Register("statusbar", "EDM Gradient", TEXTURE_PATH .. "statusbar_gradient")
LSM:Register("statusbar", "EDM Glossy", TEXTURE_PATH .. "statusbar_glossy")
LSM:Register("statusbar", "EDM Flat", TEXTURE_PATH .. "statusbar_flat")

--============================================================================
-- MODERN SKIN - Clean, sleek look
--============================================================================
Skins.list["Modern"] = {
    name = "Modern",
    description = "Clean, modern look with soft gradients",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.92 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0.15, g = 0.15, b = 0.2, a = 1 },
        borderSize = 2,
        inset = 3,
        cornerRadius = 8,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.08, g = 0.08, b = 0.12, a = 0.98 },
        height = 22,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        gradientStart = { r = 0.12, g = 0.12, b = 0.18, a = 1 },
        gradientEnd = { r = 0.06, g = 0.06, b = 0.10, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = true,
        shadowColor = { r = 0, g = 0, b = 0, a = 0.5 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 1, g = 1, b = 1, a = 0.3 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.95 },
        borderColor = { r = 0.3, g = 0.3, b = 0.4, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.12, a = 0.8 },
        thumbColor = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
        thumbHoverColor = { r = 0.4, g = 0.4, b = 0.5, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.2, a = 1 },
        hoverColor = { r = 0.25, g = 0.25, b = 0.35, a = 1 },
        pressedColor = { r = 0.1, g = 0.1, b = 0.15, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.03, g = 0.03, b = 0.05, a = 0.95 },
        gridColor = { r = 0.15, g = 0.15, b = 0.2, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 0.9, g = 0.2, b = 0.2, a = 1 },
        healingColor = { r = 0.2, g = 0.9, b = 0.2, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- DARK SKIN - Sleek minimal dark theme
--============================================================================
Skins.list["Dark"] = {
    name = "Dark",
    description = "Sleek dark theme",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 },
        border = TEXTURE_PATH .. "border_simple",
        borderColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        borderSize = 1,
        inset = 2,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 1 },
        height = 20,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 16,
        spacing = 1,
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.7 },
        font = "Fonts\\ARIALN.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
        fontColor = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
        rankFont = "Fonts\\ARIALN.TTF",
        rankFontSize = 8,
        iconSize = 14,
        padding = 1,
        showShadow = false,
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.98 },
        borderColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 12,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\ARIALN.TTF",
        fontSize = 10,
        fontFlags = "",
        padding = 8,
    },

    scrollbar = {
        width = 6,
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 },
        thumbColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        thumbHoverColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        hoverColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        pressedColor = { r = 0.05, g = 0.05, b = 0.05, a = 1 },
        font = "Fonts\\ARIALN.TTF",
        fontSize = 10,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.98 },
        gridColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
        lineWidth = 2,
        damageColor = { r = 0.8, g = 0.1, b = 0.1, a = 1 },
        healingColor = { r = 0.1, g = 0.8, b = 0.1, a = 1 },
        legendFont = "Fonts\\ARIALN.TTF",
        legendFontSize = 9,
    },
}

--============================================================================
-- NEON SKIN - Vibrant cyberpunk colors
--============================================================================
Skins.list["Neon"] = {
    name = "Neon",
    description = "Vibrant neon colors with glow effects",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.02, g = 0.02, b = 0.05, a = 0.9 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0, g = 0.8, b = 1, a = 0.8 },
        borderSize = 2,
        inset = 3,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.03, g = 0.03, b = 0.08, a = 0.98 },
        height = 24,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        fontColor = { r = 0, g = 1, b = 1, a = 1 },
        gradientStart = { r = 0, g = 0.3, b = 0.5, a = 0.3 },
        gradientEnd = { r = 0, g = 0.1, b = 0.2, a = 0.1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 20,
        spacing = 2,
        backgroundColor = { r = 0.02, g = 0.02, b = 0.05, a = 0.7 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 10,
        iconSize = 18,
        padding = 3,
        showShadow = true,
        shadowColor = { r = 0, g = 0.5, b = 0.5, a = 0.5 },
        shadowOffset = 2,
        glowOnHover = true,
        glowColor = { r = 0, g = 1, b = 1, a = 0.5 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.02, g = 0.02, b = 0.05, a = 0.98 },
        borderColor = { r = 0, g = 0.8, b = 1, a = 0.8 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 12,
    },

    scrollbar = {
        width = 10,
        backgroundColor = { r = 0.02, g = 0.02, b = 0.05, a = 0.9 },
        thumbColor = { r = 0, g = 0.5, b = 0.6, a = 0.9 },
        thumbHoverColor = { r = 0, g = 0.8, b = 1, a = 1 },
    },

    button = {
        backgroundColor = { r = 0, g = 0.2, b = 0.3, a = 1 },
        hoverColor = { r = 0, g = 0.4, b = 0.5, a = 1 },
        pressedColor = { r = 0, g = 0.1, b = 0.15, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.01, g = 0.01, b = 0.03, a = 0.98 },
        gridColor = { r = 0, g = 0.3, b = 0.4, a = 0.3 },
        lineWidth = 3,
        damageColor = { r = 1, g = 0.2, b = 0.5, a = 1 },
        healingColor = { r = 0, g = 1, b = 0.5, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- CLASSIC SKIN - WoW vanilla style
--============================================================================
Skins.list["Classic"] = {
    name = "Classic",
    description = "Classic WoW-style appearance",

    window = {
        background = "Interface\\DialogFrame\\UI-DialogBox-Background",
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        border = "Interface\\DialogFrame\\UI-DialogBox-Border",
        borderColor = { r = 1, g = 1, b = 1, a = 1 },
        borderSize = 16,
        inset = 8,
    },

    titleBar = {
        background = "Interface\\DialogFrame\\UI-DialogBox-Header",
        backgroundColor = { r = 0, g = 0, b = 0, a = 0 },
        height = 32,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 14,
        fontFlags = "",
        fontColor = { r = 1, g = 0.82, b = 0, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = false,
    },

    tooltip = {
        background = "Interface\\Tooltips\\UI-Tooltip-Background",
        backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
        borderColor = { r = 1, g = 1, b = 1, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 16,
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.3 },
        thumbColor = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
        thumbHoverColor = { r = 0.8, g = 0.8, b = 0.8, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        hoverColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
        pressedColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 },
        gridColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 1, g = 0.2, b = 0.2, a = 1 },
        healingColor = { r = 0.2, g = 1, b = 0.2, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- ELVUI SKIN - ElvUI-style minimalist
--============================================================================
Skins.list["ElvUI"] = {
    name = "ElvUI",
    description = "ElvUI-inspired minimalist design",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.85 },
        border = "Interface\\Buttons\\WHITE8X8",
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        borderSize = 1,
        inset = 1,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        height = 18,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 0.8, b = 0, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 17,
        spacing = 1,
        backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.8 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 8,
        iconSize = 15,
        padding = 1,
        showShadow = false,
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 12,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
        padding = 8,
    },

    scrollbar = {
        width = 5,
        backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1 },
        thumbColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        thumbHoverColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        hoverColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        pressedColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 },
        gridColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 0.9, g = 0.3, b = 0.3, a = 1 },
        healingColor = { r = 0.3, g = 0.9, b = 0.3, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 9,
    },
}

--============================================================================
-- GLASS SKIN - Transparent glass effect
--============================================================================
Skins.list["Glass"] = {
    name = "Glass",
    description = "Transparent glass-like appearance",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.15, a = 0.65 },
        border = "Interface\\Buttons\\WHITE8X8",
        borderColor = { r = 0.5, g = 0.5, b = 0.6, a = 0.5 },
        borderSize = 1,
        inset = 2,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.15, g = 0.15, b = 0.2, a = 0.75 },
        height = 22,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 0.95 },
        gradientStart = { r = 0.3, g = 0.3, b = 0.35, a = 0.4 },
        gradientEnd = { r = 0.1, g = 0.1, b = 0.15, a = 0.3 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0.08, g = 0.08, b = 0.1, a = 0.5 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = true,
        shadowColor = { r = 0, g = 0, b = 0, a = 0.3 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 1, g = 1, b = 1, a = 0.2 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.08, g = 0.08, b = 0.12, a = 0.9 },
        borderColor = { r = 0.4, g = 0.4, b = 0.5, a = 0.8 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.12, a = 0.5 },
        thumbColor = { r = 0.4, g = 0.4, b = 0.5, a = 0.7 },
        thumbHoverColor = { r = 0.5, g = 0.5, b = 0.6, a = 0.9 },
    },

    button = {
        backgroundColor = { r = 0.2, g = 0.2, b = 0.25, a = 0.7 },
        hoverColor = { r = 0.3, g = 0.3, b = 0.35, a = 0.8 },
        pressedColor = { r = 0.15, g = 0.15, b = 0.2, a = 0.6 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.7 },
        gridColor = { r = 0.2, g = 0.2, b = 0.25, a = 0.4 },
        lineWidth = 2,
        damageColor = { r = 1, g = 0.3, b = 0.3, a = 0.9 },
        healingColor = { r = 0.3, g = 1, b = 0.3, a = 0.9 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- MIDNIGHT SKIN - Deep blue/purple theme
--============================================================================
Skins.list["Midnight"] = {
    name = "Midnight",
    description = "Deep midnight blue theme",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.12, a = 0.92 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0.2, g = 0.2, b = 0.4, a = 1 },
        borderSize = 2,
        inset = 3,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.08, g = 0.08, b = 0.18, a = 0.98 },
        height = 22,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        fontColor = { r = 0.7, g = 0.7, b = 1, a = 1 },
        gradientStart = { r = 0.15, g = 0.15, b = 0.3, a = 1 },
        gradientEnd = { r = 0.05, g = 0.05, b = 0.12, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0.08, g = 0.08, b = 0.15, a = 0.7 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = true,
        shadowColor = { r = 0.1, g = 0.1, b = 0.3, a = 0.5 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 0.5, g = 0.5, b = 1, a = 0.3 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.12, a = 0.98 },
        borderColor = { r = 0.3, g = 0.3, b = 0.5, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.08, g = 0.08, b = 0.15, a = 0.8 },
        thumbColor = { r = 0.25, g = 0.25, b = 0.45, a = 0.9 },
        thumbHoverColor = { r = 0.35, g = 0.35, b = 0.6, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.12, g = 0.12, b = 0.25, a = 1 },
        hoverColor = { r = 0.2, g = 0.2, b = 0.4, a = 1 },
        pressedColor = { r = 0.08, g = 0.08, b = 0.18, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.03, g = 0.03, b = 0.08, a = 0.95 },
        gridColor = { r = 0.15, g = 0.15, b = 0.25, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 0.9, g = 0.3, b = 0.5, a = 1 },
        healingColor = { r = 0.3, g = 0.8, b = 0.9, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- EMBER SKIN - Warm fire/ember theme
--============================================================================
Skins.list["Ember"] = {
    name = "Ember",
    description = "Warm ember/fire themed",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.05, b = 0.03, a = 0.92 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0.4, g = 0.2, b = 0.1, a = 1 },
        borderSize = 2,
        inset = 3,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.15, g = 0.08, b = 0.05, a = 0.98 },
        height = 22,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 0.8, b = 0.5, a = 1 },
        gradientStart = { r = 0.25, g = 0.12, b = 0.08, a = 1 },
        gradientEnd = { r = 0.1, g = 0.05, b = 0.03, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0.12, g = 0.06, b = 0.04, a = 0.7 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = true,
        shadowColor = { r = 0.3, g = 0.1, b = 0, a = 0.5 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 1, g = 0.5, b = 0.2, a = 0.3 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.05, b = 0.03, a = 0.98 },
        borderColor = { r = 0.5, g = 0.25, b = 0.15, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.12, g = 0.06, b = 0.04, a = 0.8 },
        thumbColor = { r = 0.4, g = 0.2, b = 0.1, a = 0.9 },
        thumbHoverColor = { r = 0.6, g = 0.3, b = 0.15, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.2, g = 0.1, b = 0.06, a = 1 },
        hoverColor = { r = 0.3, g = 0.15, b = 0.08, a = 1 },
        pressedColor = { r = 0.12, g = 0.06, b = 0.04, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.08, g = 0.04, b = 0.02, a = 0.95 },
        gridColor = { r = 0.25, g = 0.12, b = 0.08, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 1, g = 0.4, b = 0.1, a = 1 },
        healingColor = { r = 0.4, g = 1, b = 0.5, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- DETAILS SKIN - Inspired by Details! Damage Meter
--============================================================================
Skins.list["Details"] = {
    name = "Details",
    description = "Inspired by Details! Damage Meter",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.85 },
        border = "Interface\\Buttons\\WHITE8X8",
        borderColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        borderSize = 1,
        inset = 1,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 1 },
        height = 20,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 0.82, b = 0, a = 1 },
        gradientStart = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        gradientEnd = { r = 0.08, g = 0.08, b = 0.08, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 16,
        spacing = 0,
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.9 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 14,
        padding = 0,
        showShadow = true,
        shadowColor = { r = 0, g = 0, b = 0, a = 0.7 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 1, g = 1, b = 1, a = 0.15 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.98 },
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 12,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
        padding = 8,
    },

    scrollbar = {
        width = 6,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
        thumbColor = { r = 0.35, g = 0.35, b = 0.35, a = 1 },
        thumbHoverColor = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        hoverColor = { r = 0.25, g = 0.25, b = 0.25, a = 1 },
        pressedColor = { r = 0.08, g = 0.08, b = 0.08, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 },
        gridColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 1, g = 0.3, b = 0.3, a = 1 },
        healingColor = { r = 0.3, g = 1, b = 0.4, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 9,
    },
}

--============================================================================
-- RECOUNT SKIN - Inspired by Recount
--============================================================================
Skins.list["Recount"] = {
    name = "Recount",
    description = "Inspired by Recount style",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
        border = "Interface\\Tooltips\\UI-Tooltip-Border",
        borderColor = { r = 0.6, g = 0.6, b = 0.6, a = 0.8 },
        borderSize = 12,
        inset = 4,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        height = 24,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "",
        fontColor = { r = 1, g = 0.9, b = 0.4, a = 1 },
        gradientStart = { r = 0.25, g = 0.25, b = 0.25, a = 1 },
        gradientEnd = { r = 0.12, g = 0.12, b = 0.12, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 18,
        spacing = 1,
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.85 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 16,
        padding = 2,
        showShadow = true,
        shadowColor = { r = 0, g = 0, b = 0, a = 0.6 },
        shadowOffset = 1,
        glowOnHover = true,
        glowColor = { r = 1, g = 1, b = 0.6, a = 0.25 },
    },

    tooltip = {
        background = "Interface\\Tooltips\\UI-Tooltip-Background",
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.95 },
        borderColor = { r = 0.6, g = 0.6, b = 0.6, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 12,
        headerFontFlags = "",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 10,
    },

    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.8 },
        thumbColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
        thumbHoverColor = { r = 0.55, g = 0.55, b = 0.55, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        hoverColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        pressedColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 },
        gridColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 0.9, g = 0.2, b = 0.2, a = 1 },
        healingColor = { r = 0.2, g = 0.9, b = 0.3, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- SKADA SKIN - Inspired by Skada
--============================================================================
Skins.list["Skada"] = {
    name = "Skada",
    description = "Inspired by Skada style",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.88 },
        border = "Interface\\Buttons\\WHITE8X8",
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
        borderSize = 1,
        inset = 2,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.18, g = 0.18, b = 0.18, a = 1 },
        height = 22,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 0.85, b = 0.1, a = 1 },
        gradientStart = { r = 0.25, g = 0.25, b = 0.25, a = 1 },
        gradientEnd = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 17,
        spacing = 0,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.85 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 9,
        iconSize = 15,
        padding = 1,
        showShadow = false,
        glowOnHover = true,
        glowColor = { r = 1, g = 1, b = 1, a = 0.12 },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.98 },
        borderColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 12,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
        padding = 8,
    },

    scrollbar = {
        width = 6,
        backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.9 },
        thumbColor = { r = 0.3, g = 0.3, b = 0.3, a = 1 },
        thumbHoverColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        hoverColor = { r = 0.22, g = 0.22, b = 0.22, a = 1 },
        pressedColor = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.05, g = 0.05, b = 0.05, a = 0.95 },
        gridColor = { r = 0.18, g = 0.18, b = 0.18, a = 0.5 },
        lineWidth = 2,
        damageColor = { r = 0.95, g = 0.25, b = 0.25, a = 1 },
        healingColor = { r = 0.25, g = 0.95, b = 0.35, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 9,
    },
}

--============================================================================
-- AURORA SKIN - Beautiful rainbow gradient accents
--============================================================================
Skins.list["Aurora"] = {
    name = "Aurora",
    description = "Beautiful aurora borealis inspired theme",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.03, g = 0.03, b = 0.06, a = 0.94 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0.4, g = 0.2, b = 0.6, a = 0.9 },
        borderSize = 2,
        inset = 3,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.04, b = 0.08, a = 0.98 },
        height = 24,
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 12,
        fontFlags = "OUTLINE",
        fontColor = { r = 0.8, g = 0.6, b = 1, a = 1 },
        gradientStart = { r = 0.3, g = 0.1, b = 0.4, a = 0.5 },
        gradientEnd = { r = 0.1, g = 0.2, b = 0.3, a = 0.3 },
    },

    bar = {
        texture = "Interface\\TargetingFrame\\UI-StatusBar",
        fallbackTexture = "Interface\\TargetingFrame\\UI-StatusBar",
        height = 20,
        spacing = 2,
        backgroundColor = { r = 0.04, g = 0.03, b = 0.06, a = 0.7 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "OUTLINE",
        fontColor = { r = 1, g = 1, b = 1, a = 1 },
        rankFont = "Fonts\\FRIZQT__.TTF",
        rankFontSize = 10,
        iconSize = 18,
        padding = 3,
        showShadow = true,
        shadowColor = { r = 0.2, g = 0.1, b = 0.3, a = 0.6 },
        shadowOffset = 2,
        glowOnHover = true,
        glowColor = { r = 0.6, g = 0.4, b = 1, a = 0.5 },
        useGradient = true,
        gradientColors = {
            top = { r = 0.3, g = 0.5, b = 0.9 },
            bottom = { r = 0.5, g = 0.2, b = 0.7 },
        },
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.03, g = 0.03, b = 0.06, a = 0.98 },
        borderColor = { r = 0.5, g = 0.3, b = 0.7, a = 0.9 },
        headerFont = "Fonts\\FRIZQT__.TTF",
        headerFontSize = 13,
        headerFontFlags = "OUTLINE",
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 11,
        fontFlags = "",
        padding = 12,
    },

    scrollbar = {
        width = 10,
        backgroundColor = { r = 0.04, g = 0.03, b = 0.06, a = 0.9 },
        thumbColor = { r = 0.4, g = 0.2, b = 0.6, a = 0.9 },
        thumbHoverColor = { r = 0.6, g = 0.4, b = 0.8, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.1, b = 0.25, a = 1 },
        hoverColor = { r = 0.25, g = 0.15, b = 0.4, a = 1 },
        pressedColor = { r = 0.1, g = 0.08, b = 0.18, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "OUTLINE",
    },

    graph = {
        backgroundColor = { r = 0.02, g = 0.02, b = 0.04, a = 0.98 },
        gridColor = { r = 0.15, g = 0.1, b = 0.25, a = 0.4 },
        lineWidth = 3,
        damageColor = { r = 1, g = 0.4, b = 0.6, a = 1 },
        healingColor = { r = 0.4, g = 1, b = 0.8, a = 1 },
        legendFont = "Fonts\\FRIZQT__.TTF",
        legendFontSize = 10,
    },
}

--============================================================================
-- MINIMAL SKIN - Ultra clean, distraction-free
--============================================================================
Skins.list["Minimal"] = {
    name = "Minimal",
    description = "Ultra minimal, distraction-free design",

    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.08, g = 0.08, b = 0.08, a = 0.88 },
        border = "Interface\\Buttons\\WHITE8X8",
        borderColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.6 },
        borderSize = 1,
        inset = 1,
    },

    titleBar = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.12, g = 0.12, b = 0.12, a = 0.95 },
        height = 18,
        font = "Fonts\\ARIALN.TTF",
        fontSize = 10,
        fontFlags = "",
        fontColor = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
    },

    bar = {
        texture = "Interface\\Buttons\\WHITE8X8",
        fallbackTexture = "Interface\\Buttons\\WHITE8X8",
        height = 14,
        spacing = 1,
        backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.5 },
        font = "Fonts\\ARIALN.TTF",
        fontSize = 9,
        fontFlags = "",
        fontColor = { r = 0.95, g = 0.95, b = 0.95, a = 1 },
        rankFont = "Fonts\\ARIALN.TTF",
        rankFontSize = 8,
        iconSize = 12,
        padding = 1,
        showShadow = false,
        glowOnHover = false,
    },

    tooltip = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.95 },
        borderColor = { r = 0.25, g = 0.25, b = 0.25, a = 1 },
        headerFont = "Fonts\\ARIALN.TTF",
        headerFontSize = 11,
        headerFontFlags = "",
        font = "Fonts\\ARIALN.TTF",
        fontSize = 9,
        fontFlags = "",
        padding = 6,
    },

    scrollbar = {
        width = 4,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
        thumbColor = { r = 0.3, g = 0.3, b = 0.3, a = 0.8 },
        thumbHoverColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
    },

    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.15, a = 1 },
        hoverColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 },
        pressedColor = { r = 0.1, b = 0.1, b = 0.1, a = 1 },
        font = "Fonts\\ARIALN.TTF",
        fontSize = 9,
        fontFlags = "",
    },

    graph = {
        backgroundColor = { r = 0.06, g = 0.06, b = 0.06, a = 0.9 },
        gridColor = { r = 0.15, g = 0.15, b = 0.15, a = 0.4 },
        lineWidth = 1,
        damageColor = { r = 0.9, g = 0.35, b = 0.35, a = 1 },
        healingColor = { r = 0.35, g = 0.9, b = 0.35, a = 1 },
        legendFont = "Fonts\\ARIALN.TTF",
        legendFontSize = 8,
    },
}

--============================================================================
-- SKIN FUNCTIONS
--============================================================================

-- Get skin
function Skins:Get(skinName)
    return self.list[skinName or self.current] or self.list["Modern"]
end

-- Set current skin
function Skins:Set(skinName)
    if self.list[skinName] then
        self.current = skinName
        if EDM.db and EDM.db.profile then
            EDM.db.profile.skin = skinName
        end
        -- Trigger skin update for all UI elements
        if EDM.UI then
            EDM.UI:ApplySettings()
        end
        return true
    end
    return false
end

-- Get skin list
function Skins:GetList()
    local list = {}
    for name, skin in pairs(self.list) do
        table.insert(list, { name = name, description = skin.description })
    end
    -- Sort alphabetically
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Get skin names for dropdown
function Skins:GetSkinNames()
    local names = {}
    for name in pairs(self.list) do
        names[name] = name
    end
    return names
end

-- Apply skin element to frame background
function Skins:ApplyBackground(frame, skinName)
    local skin = self:Get(skinName)
    if not skin or not skin.window then return end

    local w = skin.window

    -- Set backdrop
    if frame.SetBackdrop then
        local backdrop = {
            bgFile = w.background,
            edgeFile = w.border,
            tile = true,
            tileSize = 16,
            edgeSize = w.borderSize or 16,
            insets = {
                left = w.inset or 4,
                right = w.inset or 4,
                top = w.inset or 4,
                bottom = w.inset or 4
            }
        }
        frame:SetBackdrop(backdrop)
        frame:SetBackdropColor(w.backgroundColor.r, w.backgroundColor.g, w.backgroundColor.b, w.backgroundColor.a)
        frame:SetBackdropBorderColor(w.borderColor.r, w.borderColor.g, w.borderColor.b, w.borderColor.a)
    end
end

-- Apply title bar skin
function Skins:ApplyTitleBar(frame, fontString, skinName)
    local skin = self:Get(skinName)
    if not skin or not skin.titleBar then return end

    local tb = skin.titleBar

    -- Set background
    if frame.texture then
        frame.texture:SetColorTexture(tb.backgroundColor.r, tb.backgroundColor.g, tb.backgroundColor.b, tb.backgroundColor.a)
    end

    -- Set font
    if fontString then
        fontString:SetFont(tb.font, tb.fontSize, tb.fontFlags)
        fontString:SetTextColor(tb.fontColor.r, tb.fontColor.g, tb.fontColor.b, tb.fontColor.a)
    end
end

-- Apply bar skin
function Skins:ApplyBar(statusBar, nameText, valueText, skinName)
    local skin = self:Get(skinName)
    if not skin or not skin.bar then return end

    local b = skin.bar

    -- Set status bar texture - try custom texture first, fall back to default
    local texture = LSM:Fetch("statusbar", b.texture)
    if not texture then
        texture = b.fallbackTexture or "Interface\\TargetingFrame\\UI-StatusBar"
    end
    statusBar:SetStatusBarTexture(texture)

    -- Set fonts
    if nameText then
        nameText:SetFont(b.font, b.fontSize, b.fontFlags)
        nameText:SetTextColor(b.fontColor.r, b.fontColor.g, b.fontColor.b, b.fontColor.a)
    end

    if valueText then
        valueText:SetFont(b.font, b.fontSize, b.fontFlags)
        valueText:SetTextColor(b.fontColor.r, b.fontColor.g, b.fontColor.b, b.fontColor.a)
    end
end

-- Get bar settings from current skin
function Skins:GetBarSettings(skinName)
    local skin = self:Get(skinName)
    if skin and skin.bar then
        return skin.bar
    end
    return self.list["Modern"].bar
end

-- Get tooltip settings from current skin
function Skins:GetTooltipSettings(skinName)
    local skin = self:Get(skinName)
    if skin and skin.tooltip then
        return skin.tooltip
    end
    return self.list["Modern"].tooltip
end

-- Get graph settings from current skin
function Skins:GetGraphSettings(skinName)
    local skin = self:Get(skinName)
    if skin and skin.graph then
        return skin.graph
    end
    return self.list["Modern"].graph
end

-- Create gradient texture
function Skins:CreateGradient(frame, startColor, endColor, orientation)
    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetGradient(
        orientation or "VERTICAL",
        CreateColor(startColor.r, startColor.g, startColor.b, startColor.a or 1),
        CreateColor(endColor.r, endColor.g, endColor.b, endColor.a or 1)
    )
    return tex
end

-- Apply highlight effect
function Skins:ApplyHighlight(frame, color)
    if not frame.highlight then
        frame.highlight = frame:CreateTexture(nil, "HIGHLIGHT")
        frame.highlight:SetAllPoints()
        frame.highlight:SetColorTexture(color.r, color.g, color.b, color.a or 0.1)
    else
        frame.highlight:SetColorTexture(color.r, color.g, color.b, color.a or 0.1)
    end
end

-- Initialize skin from saved settings
function Skins:Initialize()
    if EDM.db and EDM.db.profile and EDM.db.profile.skin then
        self.current = EDM.db.profile.skin
    end
end
