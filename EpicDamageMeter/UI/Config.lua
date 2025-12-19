--[[
    EpicDamageMeter - Config
    Configuration panel using AceConfig
]]

local ADDON_NAME, EDM = ...

EDM.Config = {}
local Config = EDM.Config
local AceConfig = LibStub("AceConfigRegistry-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigCmd = LibStub("AceConfigCmd-3.0")
local LSM = LibStub("LibSharedMedia-3.0")
local C = EDM.Constants
local Skins = EDM.Skins

-- Get options table
function Config:GetOptions()
    local options = {
        type = "group",
        name = "|cff00ff00Epic|r|cffff6600Damage|r|cffff0000Meter|r",
        handler = EDM.Core,
        args = {
            general = {
                type = "group",
                name = "General",
                order = 1,
                args = {
                    headerGeneral = {
                        type = "header",
                        name = "General Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Addon",
                        desc = "Enable or disable the addon",
                        order = 2,
                        get = function() return EDM.db.profile.enabled end,
                        set = function(_, val)
                            EDM.db.profile.enabled = val
                            if val then
                                EDM.Core:OnEnable()
                            else
                                EDM.Core:OnDisable()
                            end
                        end,
                    },
                    locked = {
                        type = "toggle",
                        name = "Lock Window",
                        desc = "Lock the window in place",
                        order = 3,
                        get = function() return EDM.db.profile.locked end,
                        set = function(_, val)
                            EDM.db.profile.locked = val
                            if EDM.UI then
                                EDM.UI:SetLocked(val)
                            end
                        end,
                    },
                    minimapIcon = {
                        type = "toggle",
                        name = "Show Minimap Icon",
                        desc = "Show or hide the minimap icon",
                        order = 4,
                        get = function() return not EDM.db.profile.minimap.hide end,
                        set = function(_, val)
                            EDM.db.profile.minimap.hide = not val
                            if EDM.Core then
                                EDM.Core:ToggleMinimap()
                            end
                        end,
                    },
                    headerSkin = {
                        type = "header",
                        name = "Skin / Theme",
                        order = 5,
                    },
                    skin = {
                        type = "select",
                        name = "Skin",
                        desc = "Choose a visual skin for the addon",
                        order = 6,
                        values = function()
                            if Skins then
                                return Skins:GetSkinNames()
                            end
                            return { Modern = "Modern" }
                        end,
                        get = function() return EDM.db.profile.skin or "Modern" end,
                        set = function(_, val)
                            EDM.db.profile.skin = val
                            if Skins then
                                Skins:Set(val)
                            end
                            if EDM.UI then
                                EDM.UI:ApplySettings()
                            end
                        end,
                    },
                    skinDesc = {
                        type = "description",
                        name = function()
                            local skinName = EDM.db.profile.skin or "Modern"
                            local skin = Skins and Skins:Get(skinName)
                            if skin and skin.description then
                                return "|cff888888" .. skin.description .. "|r"
                            end
                            return ""
                        end,
                        order = 7,
                    },
                    mergePets = {
                        type = "toggle",
                        name = "Merge Pet Damage",
                        desc = "Combine pet damage with the owner's damage",
                        order = 8,
                        get = function() return EDM.db.profile.general and EDM.db.profile.general.mergePets end,
                        set = function(_, val)
                            EDM.db.profile.general = EDM.db.profile.general or {}
                            EDM.db.profile.general.mergePets = val
                        end,
                    },
                    headerCombat = {
                        type = "header",
                        name = "Combat Settings",
                        order = 10,
                    },
                    autoReset = {
                        type = "toggle",
                        name = "Auto New Segment",
                        desc = "Automatically create new segment after combat ends",
                        order = 11,
                        get = function() return EDM.db.profile.combat.autoReset end,
                        set = function(_, val) EDM.db.profile.combat.autoReset = val end,
                    },
                    mergePlayerPets = {
                        type = "toggle",
                        name = "Merge Player Pets",
                        desc = "Combine pet damage with owner",
                        order = 12,
                        get = function() return EDM.db.profile.combat.mergePlayerPets end,
                        set = function(_, val) EDM.db.profile.combat.mergePlayerPets = val end,
                    },
                    maxSegments = {
                        type = "range",
                        name = "Max Segments",
                        desc = "Maximum number of segments to keep",
                        order = 13,
                        min = 5, max = 50, step = 1,
                        get = function() return EDM.db.profile.combat.maxSegments end,
                        set = function(_, val) EDM.db.profile.combat.maxSegments = val end,
                    },
                    minCombatTime = {
                        type = "range",
                        name = "Min Combat Time",
                        desc = "Minimum combat time to record (seconds)",
                        order = 14,
                        min = 1, max = 30, step = 1,
                        get = function() return EDM.db.profile.combat.minCombatTime end,
                        set = function(_, val) EDM.db.profile.combat.minCombatTime = val end,
                    },
                },
            },
            window = {
                type = "group",
                name = "Window",
                order = 2,
                args = {
                    headerWindow = {
                        type = "header",
                        name = "Window Settings",
                        order = 1,
                    },
                    width = {
                        type = "range",
                        name = "Width",
                        order = 2,
                        min = 150, max = 600, step = 1,
                        get = function() return EDM.db.profile.window.width end,
                        set = function(_, val)
                            EDM.db.profile.window.width = val
                            if EDM.UI and EDM.UI.mainFrame then
                                EDM.UI.mainFrame:SetWidth(val)
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Height",
                        order = 3,
                        min = 100, max = 800, step = 1,
                        get = function() return EDM.db.profile.window.height end,
                        set = function(_, val)
                            EDM.db.profile.window.height = val
                            if EDM.UI and EDM.UI.mainFrame then
                                EDM.UI.mainFrame:SetHeight(val)
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    scale = {
                        type = "range",
                        name = "Scale",
                        order = 4,
                        min = 0.5, max = 2.0, step = 0.05,
                        get = function() return EDM.db.profile.window.scale end,
                        set = function(_, val)
                            EDM.db.profile.window.scale = val
                            if EDM.UI and EDM.UI.mainFrame then
                                EDM.UI.mainFrame:SetScale(val)
                            end
                        end,
                    },
                    opacity = {
                        type = "range",
                        name = "Opacity",
                        order = 5,
                        min = 0.1, max = 1.0, step = 0.05,
                        get = function() return EDM.db.profile.window.opacity end,
                        set = function(_, val)
                            EDM.db.profile.window.opacity = val
                            if EDM.UI and EDM.UI.mainFrame then
                                EDM.UI.mainFrame:SetAlpha(val)
                            end
                        end,
                    },
                    showTitle = {
                        type = "toggle",
                        name = "Show Title Bar",
                        order = 6,
                        get = function() return EDM.db.profile.window.showTitle end,
                        set = function(_, val)
                            EDM.db.profile.window.showTitle = val
                            if EDM.UI then
                                EDM.UI:ApplySettings()
                            end
                        end,
                    },
                    showBackground = {
                        type = "toggle",
                        name = "Show Background",
                        order = 7,
                        get = function() return EDM.db.profile.window.showBackground end,
                        set = function(_, val)
                            EDM.db.profile.window.showBackground = val
                            if EDM.UI then
                                EDM.UI:ApplySettings()
                            end
                        end,
                    },
                    headerColors = {
                        type = "header",
                        name = "Colors",
                        order = 10,
                    },
                    backgroundColor = {
                        type = "color",
                        name = "Background Color",
                        order = 11,
                        hasAlpha = true,
                        get = function()
                            local c = EDM.db.profile.window.backgroundColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            EDM.db.profile.window.backgroundColor = { r = r, g = g, b = b, a = a }
                            if EDM.UI then
                                EDM.UI:ApplySettings()
                            end
                        end,
                    },
                    borderColor = {
                        type = "color",
                        name = "Border Color",
                        order = 12,
                        hasAlpha = true,
                        get = function()
                            local c = EDM.db.profile.window.borderColor
                            return c.r, c.g, c.b, c.a
                        end,
                        set = function(_, r, g, b, a)
                            EDM.db.profile.window.borderColor = { r = r, g = g, b = b, a = a }
                            if EDM.UI then
                                EDM.UI:ApplySettings()
                            end
                        end,
                    },
                },
            },
            bars = {
                type = "group",
                name = "Bars",
                order = 3,
                args = {
                    headerBars = {
                        type = "header",
                        name = "Bar Settings",
                        order = 1,
                    },
                    barHeight = {
                        type = "range",
                        name = "Bar Height",
                        order = 2,
                        min = 12, max = 32, step = 1,
                        get = function() return EDM.db.profile.bars.height end,
                        set = function(_, val)
                            EDM.db.profile.bars.height = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    barSpacing = {
                        type = "range",
                        name = "Bar Spacing",
                        order = 3,
                        min = 0, max = 5, step = 1,
                        get = function() return EDM.db.profile.bars.spacing end,
                        set = function(_, val)
                            EDM.db.profile.bars.spacing = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    barTexture = {
                        type = "select",
                        name = "Bar Texture",
                        order = 4,
                        dialogControl = "LSM30_Statusbar",
                        values = function() return LSM:HashTable("statusbar") end,
                        get = function() return EDM.db.profile.bars.texture end,
                        set = function(_, val)
                            EDM.db.profile.bars.texture = val
                            if EDM.Bars then
                                EDM.Bars:ApplySettings()
                            end
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    useClassColors = {
                        type = "toggle",
                        name = "Use Class Colors",
                        order = 5,
                        get = function() return EDM.db.profile.bars.useClassColors end,
                        set = function(_, val)
                            EDM.db.profile.bars.useClassColors = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    showRank = {
                        type = "toggle",
                        name = "Show Rank",
                        order = 6,
                        get = function() return EDM.db.profile.bars.showRank end,
                        set = function(_, val)
                            EDM.db.profile.bars.showRank = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    showPercent = {
                        type = "toggle",
                        name = "Show Percent",
                        order = 7,
                        get = function() return EDM.db.profile.bars.showPercent end,
                        set = function(_, val)
                            EDM.db.profile.bars.showPercent = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    showValue = {
                        type = "toggle",
                        name = "Show Value",
                        order = 8,
                        get = function() return EDM.db.profile.bars.showValue end,
                        set = function(_, val)
                            EDM.db.profile.bars.showValue = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    showIcon = {
                        type = "toggle",
                        name = "Show Icon",
                        order = 9,
                        get = function() return EDM.db.profile.bars.showIcon end,
                        set = function(_, val)
                            EDM.db.profile.bars.showIcon = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    headerFont = {
                        type = "header",
                        name = "Font Settings",
                        order = 20,
                    },
                    font = {
                        type = "select",
                        name = "Font",
                        order = 21,
                        dialogControl = "LSM30_Font",
                        values = function() return LSM:HashTable("font") end,
                        get = function() return EDM.db.profile.bars.font end,
                        set = function(_, val)
                            EDM.db.profile.bars.font = val
                            if EDM.Bars then
                                EDM.Bars:ApplySettings()
                            end
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        order = 22,
                        min = 8, max = 18, step = 1,
                        get = function() return EDM.db.profile.bars.fontSize end,
                        set = function(_, val)
                            EDM.db.profile.bars.fontSize = val
                            if EDM.Bars then
                                EDM.Bars:ApplySettings()
                            end
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    headerAnimation = {
                        type = "header",
                        name = "Animation",
                        order = 30,
                    },
                    animation = {
                        type = "toggle",
                        name = "Enable Animation",
                        order = 31,
                        get = function() return EDM.db.profile.bars.animation end,
                        set = function(_, val)
                            EDM.db.profile.bars.animation = val
                        end,
                    },
                    animationSpeed = {
                        type = "range",
                        name = "Animation Speed",
                        order = 32,
                        min = 0.1, max = 1.0, step = 0.05,
                        get = function() return EDM.db.profile.bars.animationSpeed end,
                        set = function(_, val)
                            EDM.db.profile.bars.animationSpeed = val
                        end,
                    },
                },
            },
            graph = {
                type = "group",
                name = "Graph",
                order = 4,
                args = {
                    headerGraph = {
                        type = "header",
                        name = "Graph Settings",
                        order = 1,
                    },
                    enabled = {
                        type = "toggle",
                        name = "Enable Graph",
                        order = 2,
                        get = function() return EDM.db.profile.graph.enabled end,
                        set = function(_, val)
                            EDM.db.profile.graph.enabled = val
                        end,
                    },
                    width = {
                        type = "range",
                        name = "Graph Width",
                        order = 3,
                        min = 200, max = 800, step = 10,
                        get = function() return EDM.db.profile.graph.width end,
                        set = function(_, val)
                            EDM.db.profile.graph.width = val
                            if EDM.Graph and EDM.Graph.frame then
                                EDM.Graph.frame:SetWidth(val)
                            end
                        end,
                    },
                    height = {
                        type = "range",
                        name = "Graph Height",
                        order = 4,
                        min = 100, max = 400, step = 10,
                        get = function() return EDM.db.profile.graph.height end,
                        set = function(_, val)
                            EDM.db.profile.graph.height = val
                            if EDM.Graph and EDM.Graph.frame then
                                EDM.Graph.frame:SetHeight(val)
                            end
                        end,
                    },
                    lineWidth = {
                        type = "range",
                        name = "Line Width",
                        order = 5,
                        min = 1, max = 5, step = 0.5,
                        get = function() return EDM.db.profile.graph.lineWidth end,
                        set = function(_, val)
                            EDM.db.profile.graph.lineWidth = val
                        end,
                    },
                    showLegend = {
                        type = "toggle",
                        name = "Show Legend",
                        order = 6,
                        get = function() return EDM.db.profile.graph.showLegend end,
                        set = function(_, val)
                            EDM.db.profile.graph.showLegend = val
                        end,
                    },
                    showGrid = {
                        type = "toggle",
                        name = "Show Grid",
                        order = 7,
                        get = function() return EDM.db.profile.graph.showGrid end,
                        set = function(_, val)
                            EDM.db.profile.graph.showGrid = val
                        end,
                    },
                },
            },
            sounds = {
                type = "group",
                name = "Sounds",
                order = 5,
                args = {
                    headerSounds = {
                        type = "header",
                        name = "Sound Settings",
                        order = 1,
                    },
                    combatStart = {
                        type = "toggle",
                        name = "Combat Start Sound",
                        order = 2,
                        get = function() return EDM.db.profile.sounds.combatStart end,
                        set = function(_, val)
                            EDM.db.profile.sounds.combatStart = val
                        end,
                    },
                    combatEnd = {
                        type = "toggle",
                        name = "Combat End Sound",
                        order = 3,
                        get = function() return EDM.db.profile.sounds.combatEnd end,
                        set = function(_, val)
                            EDM.db.profile.sounds.combatEnd = val
                        end,
                    },
                    newRecord = {
                        type = "toggle",
                        name = "New Record Sound",
                        order = 4,
                        get = function() return EDM.db.profile.sounds.newRecord end,
                        set = function(_, val)
                            EDM.db.profile.sounds.newRecord = val
                        end,
                    },
                    volume = {
                        type = "range",
                        name = "Volume",
                        order = 5,
                        min = 0, max = 1, step = 0.1,
                        get = function() return EDM.db.profile.sounds.volume end,
                        set = function(_, val)
                            EDM.db.profile.sounds.volume = val
                        end,
                    },
                },
            },
            display = {
                type = "group",
                name = "Display",
                order = 6,
                args = {
                    headerDisplay = {
                        type = "header",
                        name = "Display Settings",
                        order = 1,
                    },
                    numberFormat = {
                        type = "select",
                        name = "Number Format",
                        order = 2,
                        values = {
                            SHORT = "Short (1.2K, 3.4M)",
                            FULL = "Full (1234567)",
                            COMMA = "Comma (1,234,567)",
                        },
                        get = function() return EDM.db.profile.display.numberFormat end,
                        set = function(_, val)
                            EDM.db.profile.display.numberFormat = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                    refreshRate = {
                        type = "range",
                        name = "Refresh Rate",
                        desc = "How often to update the display (seconds)",
                        order = 3,
                        min = 0.1, max = 2.0, step = 0.1,
                        get = function() return EDM.db.profile.display.refreshRate end,
                        set = function(_, val)
                            EDM.db.profile.display.refreshRate = val
                            if EDM.Core then
                                EDM.Core:StartUpdateTimer()
                            end
                        end,
                    },
                    maxBars = {
                        type = "range",
                        name = "Max Bars",
                        order = 4,
                        min = 5, max = 50, step = 1,
                        get = function() return EDM.db.profile.display.maxBars end,
                        set = function(_, val)
                            EDM.db.profile.display.maxBars = val
                            if EDM.UI then
                                EDM.UI:Refresh()
                            end
                        end,
                    },
                },
            },
            advanced = {
                type = "group",
                name = "Advanced",
                order = 7,
                args = {
                    headerAdvanced = {
                        type = "header",
                        name = "Advanced Settings",
                        order = 1,
                    },
                    debugMode = {
                        type = "toggle",
                        name = "Debug Mode",
                        order = 2,
                        get = function() return EDM.db.profile.advanced.debugMode end,
                        set = function(_, val)
                            EDM.db.profile.advanced.debugMode = val
                        end,
                    },
                    recordTargets = {
                        type = "toggle",
                        name = "Record Targets",
                        desc = "Track damage/healing by target",
                        order = 3,
                        get = function() return EDM.db.profile.advanced.recordTargets end,
                        set = function(_, val)
                            EDM.db.profile.advanced.recordTargets = val
                        end,
                    },
                    recordAbilities = {
                        type = "toggle",
                        name = "Record Abilities",
                        desc = "Track detailed ability breakdown",
                        order = 4,
                        get = function() return EDM.db.profile.advanced.recordAbilities end,
                        set = function(_, val)
                            EDM.db.profile.advanced.recordAbilities = val
                        end,
                    },
                    recordTimeline = {
                        type = "toggle",
                        name = "Record Timeline",
                        desc = "Track DPS/HPS over time for graphs",
                        order = 5,
                        get = function() return EDM.db.profile.advanced.recordTimeline end,
                        set = function(_, val)
                            EDM.db.profile.advanced.recordTimeline = val
                        end,
                    },
                    headerReset = {
                        type = "header",
                        name = "Data Management",
                        order = 10,
                    },
                    resetData = {
                        type = "execute",
                        name = "Reset All Data",
                        order = 11,
                        confirm = true,
                        confirmText = "Are you sure you want to reset all data?",
                        func = function()
                            if EDM.Core then
                                EDM.Core:Reset()
                            end
                        end,
                    },
                },
            },
            profiles = {
                type = "group",
                name = "Profiles",
                order = 99,
                args = {
                    desc = {
                        type = "description",
                        name = "Profile management is available through the standard Blizzard interface options.",
                        order = 1,
                    },
                },
            },
        },
    }

    return options
end

-- Register options (only for chat command and standalone dialog, NOT Blizzard options)
function Config:Register()
    local options = self:GetOptions()
    AceConfig:RegisterOptionsTable(ADDON_NAME, options)

    -- Register chat command only (no Blizzard options to avoid duplicates)
    AceConfigCmd:CreateChatCommand("edm config", ADDON_NAME)

    self.registered = true
end

-- Open config (advanced AceConfig dialog)
function Config:Open()
    -- Register if not already done
    if not self.registered then
        self:Register()
    end

    -- Open the standalone window
    AceConfigDialog:Open(ADDON_NAME)
end

-- Close config
function Config:Close()
    AceConfigDialog:Close(ADDON_NAME)
end

--============================================================================
-- BEAUTIFUL SETTINGS PANEL (Fancy tabbed UI)
--============================================================================

function Config:CreateQuickPanel()
    if self.quickPanel then return end

    local panel = CreateFrame("Frame", "EDMQuickSettings", UIParent, "BackdropTemplate")
    panel:SetSize(500, 550)
    panel:SetPoint("CENTER", 0, 50)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(100)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetResizeBounds(400, 400, 700, 800)

    -- Main backdrop with gradient effect
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    panel:SetBackdropColor(0.03, 0.03, 0.05, 0.98)
    panel:SetBackdropBorderColor(0.4, 0.6, 1, 0.8)

    -- Inner glow effect
    panel.innerGlow = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.innerGlow:SetPoint("TOPLEFT", 3, -3)
    panel.innerGlow:SetPoint("BOTTOMRIGHT", -3, 3)
    panel.innerGlow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel.innerGlow:SetBackdropColor(0, 0, 0, 0)
    panel.innerGlow:SetBackdropBorderColor(0.2, 0.4, 0.8, 0.3)

    -- Fancy title bar with gradient
    panel.titleBar = CreateFrame("Frame", nil, panel)
    panel.titleBar:SetHeight(40)
    panel.titleBar:SetPoint("TOPLEFT", 4, -4)
    panel.titleBar:SetPoint("TOPRIGHT", -4, -4)

    panel.titleBar.bg = panel.titleBar:CreateTexture(nil, "BACKGROUND")
    panel.titleBar.bg:SetAllPoints()
    panel.titleBar.bg:SetColorTexture(0.08, 0.12, 0.2, 1)

    -- Gradient overlay on title bar
    panel.titleBar.gradient = panel.titleBar:CreateTexture(nil, "ARTWORK")
    panel.titleBar.gradient:SetPoint("TOPLEFT", 0, 0)
    panel.titleBar.gradient:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.titleBar.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    panel.titleBar.gradient:SetGradient("VERTICAL", CreateColor(0.15, 0.25, 0.4, 0.8), CreateColor(0.05, 0.08, 0.15, 0.8))

    -- Title bar bottom accent line
    panel.titleBar.accentLine = panel.titleBar:CreateTexture(nil, "OVERLAY")
    panel.titleBar.accentLine:SetHeight(2)
    panel.titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    panel.titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.titleBar.accentLine:SetColorTexture(0.3, 0.6, 1, 0.8)

    -- Logo/Icon with glow
    panel.titleBar.iconBg = panel.titleBar:CreateTexture(nil, "ARTWORK")
    panel.titleBar.iconBg:SetSize(36, 36)
    panel.titleBar.iconBg:SetPoint("LEFT", 10, 0)
    panel.titleBar.iconBg:SetTexture("Interface\\Buttons\\WHITE8X8")
    panel.titleBar.iconBg:SetVertexColor(0.1, 0.2, 0.4, 0.8)

    panel.titleBar.icon = panel.titleBar:CreateTexture(nil, "OVERLAY")
    panel.titleBar.icon:SetSize(28, 28)
    panel.titleBar.icon:SetPoint("CENTER", panel.titleBar.iconBg, "CENTER", 0, 0)
    panel.titleBar.icon:SetTexture("Interface\\Icons\\Ability_Warrior_BloodFrenzy")
    panel.titleBar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Title text with shadow
    panel.titleBar.title = panel.titleBar:CreateFontString(nil, "OVERLAY")
    panel.titleBar.title:SetPoint("LEFT", panel.titleBar.iconBg, "RIGHT", 12, 2)
    panel.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    panel.titleBar.title:SetText("|cff00ff00Epic|r|cffff6600Damage|r|cffff3333Meter|r")
    panel.titleBar.title:SetShadowOffset(2, -2)
    panel.titleBar.title:SetShadowColor(0, 0, 0, 0.8)

    panel.titleBar.subtitle = panel.titleBar:CreateFontString(nil, "OVERLAY")
    panel.titleBar.subtitle:SetPoint("TOPLEFT", panel.titleBar.title, "BOTTOMLEFT", 0, -2)
    panel.titleBar.subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    panel.titleBar.subtitle:SetTextColor(0.6, 0.7, 0.8, 1)
    panel.titleBar.subtitle:SetText("Settings & Configuration")

    -- Close button (fancy)
    panel.closeBtn = CreateFrame("Button", nil, panel.titleBar, "BackdropTemplate")
    panel.closeBtn:SetSize(28, 28)
    panel.closeBtn:SetPoint("RIGHT", -8, 0)
    panel.closeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    panel.closeBtn:SetBackdropColor(0.6, 0.1, 0.1, 0.6)
    panel.closeBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.8)
    panel.closeBtn.text = panel.closeBtn:CreateFontString(nil, "OVERLAY")
    panel.closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    panel.closeBtn.text:SetPoint("CENTER", 0, 1)
    panel.closeBtn.text:SetText("X")
    panel.closeBtn.text:SetTextColor(1, 0.8, 0.8, 1)
    panel.closeBtn:SetScript("OnClick", function() panel:Hide() end)
    panel.closeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.8, 0.2, 0.2, 0.9)
    end)
    panel.closeBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.6, 0.1, 0.1, 0.6)
    end)

    -- Advanced settings button
    panel.advancedBtn = CreateFrame("Button", nil, panel.titleBar, "BackdropTemplate")
    panel.advancedBtn:SetSize(28, 28)
    panel.advancedBtn:SetPoint("RIGHT", panel.closeBtn, "LEFT", -6, 0)
    panel.advancedBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    panel.advancedBtn:SetBackdropColor(0.1, 0.3, 0.5, 0.6)
    panel.advancedBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.8)
    panel.advancedBtn.text = panel.advancedBtn:CreateFontString(nil, "OVERLAY")
    panel.advancedBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    panel.advancedBtn.text:SetPoint("CENTER", 0, 0)
    panel.advancedBtn.text:SetText("+")
    panel.advancedBtn.text:SetTextColor(0.7, 0.9, 1, 1)
    panel.advancedBtn:SetScript("OnClick", function()
        panel:Hide()
        Config:Open()
    end)
    panel.advancedBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.2, 0.5, 0.7, 0.9)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Open Advanced Settings")
        GameTooltip:AddLine("Full AceConfig options panel", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    panel.advancedBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.1, 0.3, 0.5, 0.6)
        GameTooltip:Hide()
    end)

    -- Make draggable
    panel.titleBar:EnableMouse(true)
    panel.titleBar:RegisterForDrag("LeftButton")
    panel.titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel.titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)

    -- Tab system
    panel.tabFrame = CreateFrame("Frame", nil, panel)
    panel.tabFrame:SetHeight(36)
    panel.tabFrame:SetPoint("TOPLEFT", panel.titleBar, "BOTTOMLEFT", 0, 0)
    panel.tabFrame:SetPoint("TOPRIGHT", panel.titleBar, "BOTTOMRIGHT", 0, 0)

    panel.tabFrame.bg = panel.tabFrame:CreateTexture(nil, "BACKGROUND")
    panel.tabFrame.bg:SetAllPoints()
    panel.tabFrame.bg:SetColorTexture(0.04, 0.06, 0.1, 0.95)

    local tabNames = {"General", "Window", "Bars", "Display", "Advanced"}
    local tabIcons = {
        "Interface\\Icons\\Spell_Holy_MagicalSentry",
        "Interface\\Icons\\INV_Misc_EngGizmos_30",
        "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
        "Interface\\Icons\\INV_Misc_Spyglass_03",
        "Interface\\Icons\\Trade_Engineering"
    }
    panel.tabs = {}
    panel.tabContents = {}
    panel.selectedTab = 1

    local tabWidth = 90
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, panel.tabFrame, "BackdropTemplate")
        tab:SetSize(tabWidth, 32)
        tab:SetPoint("LEFT", panel.tabFrame, "LEFT", (i - 1) * (tabWidth + 2) + 6, 0)
        tab:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        tab:SetBackdropColor(0.08, 0.1, 0.15, 1)
        tab:SetBackdropBorderColor(0.2, 0.25, 0.35, 1)

        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetSize(18, 18)
        tab.icon:SetPoint("LEFT", 6, 0)
        tab.icon:SetTexture(tabIcons[i])
        tab.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 4, 0)
        tab.text:SetText(name)
        tab.text:SetTextColor(0.8, 0.8, 0.8, 1)

        tab.activeIndicator = tab:CreateTexture(nil, "OVERLAY")
        tab.activeIndicator:SetHeight(2)
        tab.activeIndicator:SetPoint("BOTTOMLEFT", 0, 0)
        tab.activeIndicator:SetPoint("BOTTOMRIGHT", 0, 0)
        tab.activeIndicator:SetColorTexture(0.3, 0.7, 1, 1)
        tab.activeIndicator:Hide()

        tab:SetScript("OnClick", function()
            Config:SelectTab(i)
        end)
        tab:SetScript("OnEnter", function(btn)
            if panel.selectedTab ~= i then
                btn:SetBackdropColor(0.12, 0.15, 0.22, 1)
            end
        end)
        tab:SetScript("OnLeave", function(btn)
            if panel.selectedTab ~= i then
                btn:SetBackdropColor(0.08, 0.1, 0.15, 1)
            end
        end)

        panel.tabs[i] = tab
    end

    -- Content area with scroll
    panel.content = CreateFrame("Frame", nil, panel)
    panel.content:SetPoint("TOPLEFT", panel.tabFrame, "BOTTOMLEFT", 8, -8)
    panel.content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 30)
    panel.content:SetClipsChildren(true)

    panel.scrollChild = CreateFrame("Frame", nil, panel.content)
    panel.scrollChild:SetPoint("TOPLEFT", 0, 0)
    panel.scrollChild:SetWidth(panel.content:GetWidth() or 460)
    panel.scrollChild:SetHeight(1)

    panel.scrollOffset = 0
    panel.content:EnableMouseWheel(true)
    panel.content:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = math.max(0, (panel.scrollChild:GetHeight() or 0) - (panel.content:GetHeight() or 400))
        panel.scrollOffset = panel.scrollOffset - (delta * 35)
        panel.scrollOffset = math.max(0, math.min(maxScroll, panel.scrollOffset))
        panel.scrollChild:SetPoint("TOPLEFT", 0, panel.scrollOffset)
    end)

    -- Bottom bar with version info
    panel.bottomBar = CreateFrame("Frame", nil, panel)
    panel.bottomBar:SetHeight(24)
    panel.bottomBar:SetPoint("BOTTOMLEFT", 4, 4)
    panel.bottomBar:SetPoint("BOTTOMRIGHT", -4, 4)
    panel.bottomBar.bg = panel.bottomBar:CreateTexture(nil, "BACKGROUND")
    panel.bottomBar.bg:SetAllPoints()
    panel.bottomBar.bg:SetColorTexture(0.05, 0.07, 0.12, 0.9)

    panel.bottomBar.version = panel.bottomBar:CreateFontString(nil, "OVERLAY")
    panel.bottomBar.version:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    panel.bottomBar.version:SetPoint("LEFT", 10, 0)
    panel.bottomBar.version:SetTextColor(0.5, 0.5, 0.6, 1)
    panel.bottomBar.version:SetText("EpicDamageMeter v1.0 | Interface 110207")

    panel.bottomBar.resetBtn = CreateFrame("Button", nil, panel.bottomBar, "BackdropTemplate")
    panel.bottomBar.resetBtn:SetSize(80, 18)
    panel.bottomBar.resetBtn:SetPoint("RIGHT", -8, 0)
    panel.bottomBar.resetBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    panel.bottomBar.resetBtn:SetBackdropColor(0.5, 0.2, 0.1, 0.7)
    panel.bottomBar.resetBtn:SetBackdropBorderColor(0.7, 0.3, 0.2, 0.8)
    panel.bottomBar.resetBtn.text = panel.bottomBar.resetBtn:CreateFontString(nil, "OVERLAY")
    panel.bottomBar.resetBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    panel.bottomBar.resetBtn.text:SetPoint("CENTER")
    panel.bottomBar.resetBtn.text:SetText("Reset Data")
    panel.bottomBar.resetBtn.text:SetTextColor(1, 0.7, 0.6, 1)
    panel.bottomBar.resetBtn:SetScript("OnClick", function()
        if EDM.Core then
            StaticPopup_Show("EDM_CONFIRM_RESET")
        end
    end)
    panel.bottomBar.resetBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.7, 0.3, 0.2, 0.9)
    end)
    panel.bottomBar.resetBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.5, 0.2, 0.1, 0.7)
    end)

    -- Resize handle
    panel.resizeHandle = CreateFrame("Frame", nil, panel)
    panel.resizeHandle:SetSize(16, 16)
    panel.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.resizeHandle:EnableMouse(true)
    panel.resizeHandle.tex = panel.resizeHandle:CreateTexture(nil, "OVERLAY")
    panel.resizeHandle.tex:SetAllPoints()
    panel.resizeHandle.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    panel.resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then panel:StartSizing("BOTTOMRIGHT") end
    end)
    panel.resizeHandle:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        Config:UpdatePanelLayout()
    end)

    panel:SetScript("OnSizeChanged", function()
        Config:UpdatePanelLayout()
    end)

    -- Static popup for reset confirmation
    StaticPopupDialogs["EDM_CONFIRM_RESET"] = {
        text = "Are you sure you want to reset all EpicDamageMeter data?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            if EDM.Core then EDM.Core:Reset() end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    panel:Hide()
    self.quickPanel = panel

    -- Build tab contents
    self:BuildTabContents()
    self:SelectTab(1)
end

-- Update panel layout when resized
function Config:UpdatePanelLayout()
    if not self.quickPanel then return end
    local panel = self.quickPanel
    if panel.scrollChild then
        panel.scrollChild:SetWidth(panel.content:GetWidth() or 460)
    end
    -- Refresh current tab content
    self:SelectTab(panel.selectedTab)
end

-- Select a tab
function Config:SelectTab(index)
    local panel = self.quickPanel
    if not panel then return end

    panel.selectedTab = index
    panel.scrollOffset = 0
    panel.scrollChild:SetPoint("TOPLEFT", 0, 0)

    -- Update tab appearance
    for i, tab in ipairs(panel.tabs) do
        if i == index then
            tab:SetBackdropColor(0.15, 0.2, 0.3, 1)
            tab:SetBackdropBorderColor(0.3, 0.6, 1, 1)
            tab.text:SetTextColor(1, 1, 1, 1)
            tab.activeIndicator:Show()
        else
            tab:SetBackdropColor(0.08, 0.1, 0.15, 1)
            tab:SetBackdropBorderColor(0.2, 0.25, 0.35, 1)
            tab.text:SetTextColor(0.7, 0.7, 0.7, 1)
            tab.activeIndicator:Hide()
        end
    end

    -- Show appropriate content
    for i, content in pairs(panel.tabContents) do
        if i == index then
            content:Show()
        else
            content:Hide()
        end
    end
end

-- Build all tab contents
function Config:BuildTabContents()
    local panel = self.quickPanel
    if not panel then return end

    -- Clear existing content frames
    for _, frame in pairs(panel.tabContents or {}) do
        frame:Hide()
        frame:SetParent(nil)
    end
    panel.tabContents = {}

    -- Helper functions
    local function CreateContentFrame(tabIndex)
        local content = CreateFrame("Frame", nil, panel.scrollChild)
        content:SetAllPoints(panel.scrollChild)
        content:Hide()
        content.widgets = {}
        content.yOffset = 0
        panel.tabContents[tabIndex] = content
        return content
    end

    local function CreateSectionHeader(content, text)
        local header = CreateFrame("Frame", nil, content)
        header:SetHeight(28)
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -content.yOffset)
        header:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -content.yOffset)

        header.bg = header:CreateTexture(nil, "BACKGROUND")
        header.bg:SetAllPoints()
        header.bg:SetColorTexture(0.1, 0.15, 0.25, 0.8)

        header.icon = header:CreateTexture(nil, "ARTWORK")
        header.icon:SetSize(16, 16)
        header.icon:SetPoint("LEFT", 8, 0)
        header.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")

        header.text = header:CreateFontString(nil, "OVERLAY")
        header.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        header.text:SetPoint("LEFT", header.icon, "RIGHT", 6, 0)
        header.text:SetText(text)
        header.text:SetTextColor(0.4, 0.8, 1, 1)

        header.line = header:CreateTexture(nil, "ARTWORK")
        header.line:SetHeight(1)
        header.line:SetPoint("BOTTOMLEFT", 0, 0)
        header.line:SetPoint("BOTTOMRIGHT", 0, 0)
        header.line:SetColorTexture(0.3, 0.5, 0.8, 0.5)

        content.yOffset = content.yOffset + 32
        table.insert(content.widgets, header)
        return header
    end

    local function CreateToggleRow(content, label, tooltip, dbKey, callback)
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(28)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -content.yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -content.yOffset)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        -- Custom toggle button
        row.toggle = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.toggle:SetSize(44, 22)
        row.toggle:SetPoint("RIGHT", -10, 0)
        row.toggle:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        row.toggle:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)

        row.toggle.indicator = row.toggle:CreateTexture(nil, "OVERLAY")
        row.toggle.indicator:SetSize(18, 18)
        row.toggle.indicator:SetPoint("LEFT", 2, 0)
        row.toggle.indicator:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function GetDbValue()
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db.profile
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val
        end

        local function SetDbValue(newVal)
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db.profile
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = newVal end
        end

        local function UpdateVisual()
            local enabled = GetDbValue()
            if enabled then
                row.toggle:SetBackdropColor(0.2, 0.6, 0.3, 0.9)
                row.toggle.indicator:SetPoint("LEFT", row.toggle, "LEFT", 22, 0)
                row.toggle.indicator:SetVertexColor(0.3, 1, 0.4, 1)
            else
                row.toggle:SetBackdropColor(0.4, 0.15, 0.15, 0.9)
                row.toggle.indicator:SetPoint("LEFT", row.toggle, "LEFT", 2, 0)
                row.toggle.indicator:SetVertexColor(0.7, 0.3, 0.3, 1)
            end
        end

        row.toggle:SetScript("OnClick", function()
            local current = GetDbValue()
            SetDbValue(not current)
            UpdateVisual()
            if callback then callback() end
            if EDM.UI then EDM.UI:ApplySettings() end
        end)

        UpdateVisual()

        if tooltip then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                row.bg:SetColorTexture(0.08, 0.1, 0.15, 0.8)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(label)
                GameTooltip:AddLine(tooltip, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)
                GameTooltip:Hide()
            end)
        end

        content.yOffset = content.yOffset + 30
        table.insert(content.widgets, row)
        return row
    end

    local function CreateSliderRow(content, label, tooltip, dbKey, minVal, maxVal, step, suffix, callback)
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(45)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -content.yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -content.yOffset)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("TOPLEFT", 10, -6)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        row.value = row:CreateFontString(nil, "OVERLAY")
        row.value:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        row.value:SetPoint("TOPRIGHT", -10, -6)
        row.value:SetTextColor(1, 0.85, 0.3, 1)

        -- Custom slider using proper WoW slider template
        row.slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        row.slider:SetHeight(16)
        row.slider:SetPoint("BOTTOMLEFT", 10, 6)
        row.slider:SetPoint("BOTTOMRIGHT", -10, 6)
        row.slider:SetOrientation("HORIZONTAL")
        row.slider:SetMinMaxValues(minVal, maxVal)
        row.slider:SetValueStep(step)
        row.slider:SetObeyStepOnDrag(true)
        row.slider.Low:SetText("")
        row.slider.High:SetText("")
        row.slider.Text:SetText("")

        -- Custom styling for the slider track
        row.slider:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = {left = 0, right = 0, top = 0, bottom = 0}
        })
        row.slider:SetBackdropColor(0.08, 0.1, 0.15, 1)
        row.slider:SetBackdropBorderColor(0.2, 0.3, 0.4, 0.8)

        local function GetDbValue()
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db.profile
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val or minVal
        end

        local function SetDbValue(newVal)
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db.profile
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = newVal end
        end

        local function UpdateValueText(val)
            local displayVal = step >= 1 and math.floor(val) or string.format("%.1f", val)
            row.value:SetText(displayVal .. (suffix or ""))
        end

        local currentVal = GetDbValue()
        row.slider:SetValue(currentVal)
        UpdateValueText(currentVal)

        row.slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / step + 0.5) * step
            SetDbValue(value)
            UpdateValueText(value)
            if callback then callback() end
            if EDM.UI then EDM.UI:ApplySettings() end
        end)

        if tooltip then
            row:EnableMouse(true)
            row:SetScript("OnEnter", function()
                row.bg:SetColorTexture(0.08, 0.1, 0.15, 0.8)
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetText(label)
                GameTooltip:AddLine(tooltip, 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)
                GameTooltip:Hide()
            end)
        end

        content.yOffset = content.yOffset + 48
        table.insert(content.widgets, row)
        return row
    end

    local function CreateDropdownRow(content, label, tooltip, dbKey, options, callback)
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(32)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -content.yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -content.yOffset)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        -- Custom dropdown button
        row.dropdown = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.dropdown:SetSize(140, 24)
        row.dropdown:SetPoint("RIGHT", -10, 0)
        row.dropdown:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        row.dropdown:SetBackdropColor(0.1, 0.12, 0.18, 1)
        row.dropdown:SetBackdropBorderColor(0.3, 0.35, 0.45, 1)

        row.dropdown.text = row.dropdown:CreateFontString(nil, "OVERLAY")
        row.dropdown.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        row.dropdown.text:SetPoint("LEFT", 8, 0)
        row.dropdown.text:SetTextColor(1, 1, 1, 1)

        row.dropdown.arrow = row.dropdown:CreateFontString(nil, "OVERLAY")
        row.dropdown.arrow:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        row.dropdown.arrow:SetPoint("RIGHT", -8, 0)
        row.dropdown.arrow:SetText("v")
        row.dropdown.arrow:SetTextColor(0.7, 0.7, 0.7, 1)

        local function GetDbValue()
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db.profile
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val
        end

        local function SetDbValue(newVal)
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db.profile
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = newVal end
        end

        local function UpdateText()
            local current = GetDbValue()
            row.dropdown.text:SetText(options[current] or current or "Select...")
        end

        UpdateText()

        -- Dropdown menu
        row.dropdown.menu = CreateFrame("Frame", nil, row.dropdown, "BackdropTemplate")
        row.dropdown.menu:SetPoint("TOPLEFT", row.dropdown, "BOTTOMLEFT", 0, -2)
        row.dropdown.menu:SetPoint("TOPRIGHT", row.dropdown, "BOTTOMRIGHT", 0, -2)
        row.dropdown.menu:SetFrameStrata("TOOLTIP")
        row.dropdown.menu:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        row.dropdown.menu:SetBackdropColor(0.08, 0.1, 0.15, 0.98)
        row.dropdown.menu:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
        row.dropdown.menu:Hide()

        local menuHeight = 0
        for key, displayText in pairs(options) do
            local btn = CreateFrame("Button", nil, row.dropdown.menu)
            btn:SetHeight(22)
            btn:SetPoint("TOPLEFT", 2, -menuHeight - 2)
            btn:SetPoint("TOPRIGHT", -2, -menuHeight - 2)

            btn.text = btn:CreateFontString(nil, "OVERLAY")
            btn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetText(displayText)
            btn.text:SetTextColor(0.9, 0.9, 0.9, 1)

            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetColorTexture(0.2, 0.4, 0.7, 0.5)

            btn:SetScript("OnClick", function()
                SetDbValue(key)
                UpdateText()
                row.dropdown.menu:Hide()
                if callback then callback() end
                if EDM.UI then EDM.UI:ApplySettings() end
            end)

            menuHeight = menuHeight + 22
        end
        row.dropdown.menu:SetHeight(menuHeight + 4)

        row.dropdown:SetScript("OnClick", function()
            if row.dropdown.menu:IsShown() then
                row.dropdown.menu:Hide()
            else
                row.dropdown.menu:Show()
            end
        end)

        row.dropdown:SetScript("OnEnter", function(btn)
            btn:SetBackdropColor(0.15, 0.18, 0.25, 1)
        end)
        row.dropdown:SetScript("OnLeave", function(btn)
            btn:SetBackdropColor(0.1, 0.12, 0.18, 1)
        end)

        content.yOffset = content.yOffset + 35
        table.insert(content.widgets, row)
        return row
    end

    local function CreateColorRow(content, label, tooltip, dbKey, callback)
        local row = CreateFrame("Frame", nil, content)
        row:SetHeight(28)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -content.yOffset)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, -content.yOffset)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("LEFT", 10, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        -- Color swatch
        row.swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
        row.swatch:SetSize(50, 20)
        row.swatch:SetPoint("RIGHT", -10, 0)
        row.swatch:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        row.swatch:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

        row.swatch.color = row.swatch:CreateTexture(nil, "BACKGROUND")
        row.swatch.color:SetPoint("TOPLEFT", 1, -1)
        row.swatch.color:SetPoint("BOTTOMRIGHT", -1, 1)
        row.swatch.color:SetTexture("Interface\\Buttons\\WHITE8X8")

        local function GetDbValue()
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db.profile
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val or {r = 1, g = 1, b = 1, a = 1}
        end

        local function SetDbValue(r, g, b, a)
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db.profile
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = {r = r, g = g, b = b, a = a or 1} end
        end

        local function UpdateSwatch()
            local c = GetDbValue()
            row.swatch.color:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
        end

        UpdateSwatch()

        row.swatch:SetScript("OnClick", function()
            local c = GetDbValue()
            ColorPickerFrame:SetupColorPickerAndShow({
                r = c.r or 1,
                g = c.g or 1,
                b = c.b or 1,
                opacity = c.a or 1,
                hasOpacity = true,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    local a = ColorPickerFrame:GetColorAlpha()
                    SetDbValue(r, g, b, a)
                    UpdateSwatch()
                    if callback then callback() end
                    if EDM.UI then EDM.UI:ApplySettings() end
                end,
                cancelFunc = function(prev)
                    SetDbValue(prev.r, prev.g, prev.b, prev.opacity)
                    UpdateSwatch()
                    if EDM.UI then EDM.UI:ApplySettings() end
                end,
            })
        end)

        content.yOffset = content.yOffset + 30
        table.insert(content.widgets, row)
        return row
    end

    -- ========== TAB 1: GENERAL ==========
    local tab1 = CreateContentFrame(1)
    CreateSectionHeader(tab1, "General Options")
    CreateToggleRow(tab1, "Enable Addon", "Enable or disable the damage meter", "enabled", function()
        if EDM.db.profile.enabled then
            EDM.Core:OnEnable()
        else
            EDM.Core:OnDisable()
        end
    end)
    CreateToggleRow(tab1, "Lock Window", "Prevent the window from being moved", "locked", function()
        if EDM.UI then EDM.UI:SetLocked(EDM.db.profile.locked) end
    end)
    CreateToggleRow(tab1, "Show Minimap Icon", "Show or hide the minimap button", "minimap.hide")
    CreateToggleRow(tab1, "Merge Pet Damage", "Combine pet damage with owner", "combat.mergePlayerPets")

    CreateSectionHeader(tab1, "Combat Settings")
    CreateToggleRow(tab1, "Auto New Segment", "Create new segment after combat ends", "combat.autoReset")
    CreateSliderRow(tab1, "Max Segments", "Maximum number of combat segments to keep", "combat.maxSegments", 5, 50, 1, "")
    CreateSliderRow(tab1, "Min Combat Time", "Minimum seconds to record a fight", "combat.minCombatTime", 1, 30, 1, "s")

    CreateSectionHeader(tab1, "Theme")
    local skinOptions = {}
    if EDM.Skins then
        for name, _ in pairs(EDM.Skins:GetSkinNames()) do
            skinOptions[name] = name
        end
    end
    if not next(skinOptions) then skinOptions = {Modern = "Modern", Classic = "Classic", Minimal = "Minimal"} end
    CreateDropdownRow(tab1, "Skin", "Choose a visual theme", "skin", skinOptions, function()
        if EDM.Skins then EDM.Skins:Set(EDM.db.profile.skin) end
    end)

    tab1.scrollChild = panel.scrollChild
    panel.scrollChild:SetHeight(tab1.yOffset + 20)

    -- ========== TAB 2: WINDOW ==========
    local tab2 = CreateContentFrame(2)
    CreateSectionHeader(tab2, "Window Size & Position")
    CreateSliderRow(tab2, "Width", "Window width in pixels", "window.width", 150, 600, 5, "px", function()
        if EDM.UI and EDM.UI.mainFrame then
            EDM.UI.mainFrame:SetWidth(EDM.db.profile.window.width)
            EDM.UI:Refresh()
        end
    end)
    CreateSliderRow(tab2, "Height", "Window height in pixels", "window.height", 100, 800, 5, "px", function()
        if EDM.UI and EDM.UI.mainFrame then
            EDM.UI.mainFrame:SetHeight(EDM.db.profile.window.height)
            EDM.UI:Refresh()
        end
    end)
    CreateSliderRow(tab2, "Scale", "Window scale multiplier", "window.scale", 0.5, 2.0, 0.05, "x", function()
        if EDM.UI and EDM.UI.mainFrame then
            EDM.UI.mainFrame:SetScale(EDM.db.profile.window.scale)
        end
    end)
    CreateSliderRow(tab2, "Opacity", "Window transparency", "window.opacity", 0.2, 1.0, 0.05, "", function()
        if EDM.UI and EDM.UI.mainFrame then
            EDM.UI.mainFrame:SetAlpha(EDM.db.profile.window.opacity)
        end
    end)

    CreateSectionHeader(tab2, "Appearance")
    CreateToggleRow(tab2, "Show Title Bar", "Display the title bar", "window.showTitle")
    CreateToggleRow(tab2, "Show Background", "Show window background", "window.showBackground")
    CreateColorRow(tab2, "Background Color", "Window background color", "window.backgroundColor")
    CreateColorRow(tab2, "Border Color", "Window border color", "window.borderColor")

    panel.scrollChild:SetHeight(math.max(tab1.yOffset, tab2.yOffset) + 20)

    -- ========== TAB 3: BARS ==========
    local tab3 = CreateContentFrame(3)
    CreateSectionHeader(tab3, "Bar Dimensions")
    CreateSliderRow(tab3, "Bar Height", "Height of each bar", "bars.height", 12, 32, 1, "px", function()
        if EDM.UI then EDM.UI:Refresh() end
    end)
    CreateSliderRow(tab3, "Bar Spacing", "Space between bars", "bars.spacing", 0, 5, 1, "px", function()
        if EDM.UI then EDM.UI:Refresh() end
    end)

    CreateSectionHeader(tab3, "Bar Display")
    CreateToggleRow(tab3, "Use Class Colors", "Color bars by player class", "bars.useClassColors")
    CreateToggleRow(tab3, "Show Rank", "Show ranking number on bars", "bars.showRank")
    CreateToggleRow(tab3, "Show Percent", "Show percentage on bars", "bars.showPercent")
    CreateToggleRow(tab3, "Show Value", "Show damage/healing value", "bars.showValue")
    CreateToggleRow(tab3, "Show Icon", "Show class/spec icon", "bars.showIcon")

    CreateSectionHeader(tab3, "Font Settings")
    CreateSliderRow(tab3, "Font Size", "Size of bar text", "bars.fontSize", 8, 18, 1, "pt", function()
        if EDM.Bars then EDM.Bars:ApplySettings() end
        if EDM.UI then EDM.UI:Refresh() end
    end)

    CreateSectionHeader(tab3, "Animation")
    CreateToggleRow(tab3, "Enable Animation", "Animate bar value changes", "bars.animation")
    CreateSliderRow(tab3, "Animation Speed", "How fast bars animate", "bars.animationSpeed", 0.1, 1.0, 0.05, "")

    panel.scrollChild:SetHeight(math.max(tab1.yOffset, tab2.yOffset, tab3.yOffset) + 20)

    -- ========== TAB 4: DISPLAY ==========
    local tab4 = CreateContentFrame(4)
    CreateSectionHeader(tab4, "Display Options")
    CreateDropdownRow(tab4, "Number Format", "How to display numbers", "display.numberFormat", {
        SHORT = "Short (1.2K)",
        FULL = "Full (1234567)",
        COMMA = "Comma (1,234,567)"
    })
    CreateSliderRow(tab4, "Refresh Rate", "How often to update display", "display.refreshRate", 0.1, 2.0, 0.1, "s", function()
        if EDM.Core then EDM.Core:StartUpdateTimer() end
    end)
    CreateSliderRow(tab4, "Max Bars", "Maximum bars to display", "display.maxBars", 5, 50, 1, "")

    CreateSectionHeader(tab4, "Graph Settings")
    CreateToggleRow(tab4, "Enable Graph", "Show DPS/HPS graph", "graph.enabled")
    CreateSliderRow(tab4, "Graph Width", "Width of the graph", "graph.width", 200, 800, 10, "px")
    CreateSliderRow(tab4, "Graph Height", "Height of the graph", "graph.height", 100, 400, 10, "px")
    CreateSliderRow(tab4, "Line Width", "Thickness of graph lines", "graph.lineWidth", 1, 5, 0.5, "px")
    CreateToggleRow(tab4, "Show Legend", "Display graph legend", "graph.showLegend")
    CreateToggleRow(tab4, "Show Grid", "Display graph grid lines", "graph.showGrid")

    panel.scrollChild:SetHeight(math.max(tab1.yOffset, tab2.yOffset, tab3.yOffset, tab4.yOffset) + 20)

    -- ========== TAB 5: ADVANCED ==========
    local tab5 = CreateContentFrame(5)
    CreateSectionHeader(tab5, "Advanced Options")
    CreateToggleRow(tab5, "Debug Mode", "Enable debug output", "advanced.debugMode")
    CreateToggleRow(tab5, "Record Targets", "Track damage by target", "advanced.recordTargets")
    CreateToggleRow(tab5, "Record Abilities", "Track detailed ability info", "advanced.recordAbilities")
    CreateToggleRow(tab5, "Record Timeline", "Track DPS over time for graphs", "advanced.recordTimeline")

    CreateSectionHeader(tab5, "Sound Settings")
    CreateToggleRow(tab5, "Combat Start Sound", "Play sound when combat starts", "sounds.combatStart")
    CreateToggleRow(tab5, "Combat End Sound", "Play sound when combat ends", "sounds.combatEnd")
    CreateToggleRow(tab5, "New Record Sound", "Play sound for new personal records", "sounds.newRecord")
    CreateSliderRow(tab5, "Sound Volume", "Volume of addon sounds", "sounds.volume", 0, 1, 0.1, "")

    panel.scrollChild:SetHeight(math.max(tab1.yOffset, tab2.yOffset, tab3.yOffset, tab4.yOffset, tab5.yOffset) + 20)
end

-- Show quick settings panel
function Config:ShowQuickPanel()
    if not self.quickPanel then
        self:CreateQuickPanel()
    end

    if self.quickPanel:IsShown() then
        self.quickPanel:Hide()
    else
        self.quickPanel:Show()
    end
end

-- Initialize on load
C_Timer.After(0, function()
    if EDM.db then
        Config:Register()
    end
end)
