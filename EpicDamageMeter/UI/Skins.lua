--[[
    EpicDamageMeter - Skins
    Custom skin system for beautiful UI
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

-- Register built-in skins
Skins.list["Modern"] = {
    name = "Modern",
    description = "Clean, modern look with soft gradients",

    -- Window
    window = {
        background = "Interface\\Buttons\\WHITE8X8",
        backgroundColor = { r = 0.05, g = 0.05, b = 0.08, a = 0.92 },
        border = TEXTURE_PATH .. "border_modern",
        borderColor = { r = 0.15, g = 0.15, b = 0.2, a = 1 },
        borderSize = 2,
        inset = 3,
        cornerRadius = 8,
    },

    -- Title bar
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

    -- Bars
    bar = {
        texture = TEXTURE_PATH .. "statusbar_modern",
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

    -- Tooltip
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

    -- Scrollbar
    scrollbar = {
        width = 8,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.12, a = 0.8 },
        thumbColor = { r = 0.3, g = 0.3, b = 0.4, a = 0.9 },
        thumbHoverColor = { r = 0.4, g = 0.4, b = 0.5, a = 1 },
    },

    -- Buttons
    button = {
        backgroundColor = { r = 0.15, g = 0.15, b = 0.2, a = 1 },
        hoverColor = { r = 0.25, g = 0.25, b = 0.35, a = 1 },
        pressedColor = { r = 0.1, g = 0.1, b = 0.15, a = 1 },
        font = "Fonts\\FRIZQT__.TTF",
        fontSize = 10,
        fontFlags = "",
    },

    -- Graph
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
        texture = TEXTURE_PATH .. "statusbar_flat",
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
        texture = TEXTURE_PATH .. "statusbar_glossy",
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

-- Get skin
function Skins:Get(skinName)
    return self.list[skinName or self.current] or self.list["Modern"]
end

-- Set current skin
function Skins:Set(skinName)
    if self.list[skinName] then
        self.current = skinName
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
    return list
end

-- Apply skin element
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

    -- Set status bar texture
    local texture = LSM:Fetch("statusbar", b.texture) or b.texture
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
