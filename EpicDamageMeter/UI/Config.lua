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

-- Register options
function Config:Register()
    local options = self:GetOptions()
    AceConfig:RegisterOptionsTable(ADDON_NAME, options)

    -- Add to Blizzard options
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(ADDON_NAME, "EpicDamageMeter")

    -- Create sub-categories
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Window", "EpicDamageMeter", "window")
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Bars", "EpicDamageMeter", "bars")
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Graph", "EpicDamageMeter", "graph")
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Sounds", "EpicDamageMeter", "sounds")
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Display", "EpicDamageMeter", "display")
    AceConfigDialog:AddToBlizOptions(ADDON_NAME, "Advanced", "EpicDamageMeter", "advanced")

    -- Register chat command
    AceConfigCmd:CreateChatCommand("edm config", ADDON_NAME)
end

-- Open config
function Config:Open()
    -- Register if not already done
    if not self.optionsFrame then
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
-- QUICK SETTINGS PANEL (Nice inline UI)
--============================================================================

function Config:CreateQuickPanel()
    if self.quickPanel then return end

    local panel = CreateFrame("Frame", "EDMQuickSettings", UIParent, "BackdropTemplate")
    panel:SetSize(320, 400)
    panel:SetPoint("CENTER", 0, 50)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(100)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)

    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    panel:SetBackdropColor(0.05, 0.05, 0.08, 0.98)
    panel:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)

    -- Title bar with gradient
    panel.titleBar = CreateFrame("Frame", nil, panel)
    panel.titleBar:SetHeight(32)
    panel.titleBar:SetPoint("TOPLEFT", 2, -2)
    panel.titleBar:SetPoint("TOPRIGHT", -2, -2)

    panel.titleBar.bg = panel.titleBar:CreateTexture(nil, "BACKGROUND")
    panel.titleBar.bg:SetAllPoints()
    panel.titleBar.bg:SetColorTexture(0.1, 0.15, 0.25, 1)

    panel.titleBar.icon = panel.titleBar:CreateTexture(nil, "ARTWORK")
    panel.titleBar.icon:SetSize(24, 24)
    panel.titleBar.icon:SetPoint("LEFT", 8, 0)
    panel.titleBar.icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")

    panel.titleBar.title = panel.titleBar:CreateFontString(nil, "OVERLAY")
    panel.titleBar.title:SetPoint("LEFT", panel.titleBar.icon, "RIGHT", 8, 0)
    panel.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    panel.titleBar.title:SetText("|cff00ff00Epic|r|cffff6600DM|r Settings")

    -- Close button
    panel.closeBtn = CreateFrame("Button", nil, panel.titleBar)
    panel.closeBtn:SetSize(20, 20)
    panel.closeBtn:SetPoint("RIGHT", -6, 0)
    panel.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    panel.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
    panel.closeBtn:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 0.8)
    panel.closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- Advanced settings button
    panel.advancedBtn = CreateFrame("Button", nil, panel.titleBar)
    panel.advancedBtn:SetSize(20, 20)
    panel.advancedBtn:SetPoint("RIGHT", panel.closeBtn, "LEFT", -4, 0)
    panel.advancedBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Up")
    panel.advancedBtn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Up")
    panel.advancedBtn:GetHighlightTexture():SetVertexColor(0.3, 0.8, 1, 0.8)
    panel.advancedBtn:SetScript("OnClick", function()
        panel:Hide()
        Config:Open()
    end)
    panel.advancedBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Advanced Settings")
        GameTooltip:Show()
    end)
    panel.advancedBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Make draggable
    panel.titleBar:EnableMouse(true)
    panel.titleBar:RegisterForDrag("LeftButton")
    panel.titleBar:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel.titleBar:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)

    -- Content area
    panel.content = CreateFrame("Frame", nil, panel)
    panel.content:SetPoint("TOPLEFT", panel.titleBar, "BOTTOMLEFT", 10, -10)
    panel.content:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -10, 10)

    local yOffset = 0

    -- Helper function to create a setting row
    local function CreateToggle(label, dbKey, dbPath)
        local row = CreateFrame("Frame", nil, panel.content)
        row:SetSize(280, 28)
        row:SetPoint("TOPLEFT", 0, -yOffset)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        row.checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.checkbox:SetSize(24, 24)
        row.checkbox:SetPoint("RIGHT", 0, 0)

        local function GetValue()
            local path = dbPath or "profile"
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db[path]
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val
        end

        local function SetValue(newVal)
            local path = dbPath or "profile"
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db[path]
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = newVal end
        end

        row.checkbox:SetChecked(GetValue())
        row.checkbox:SetScript("OnClick", function(self)
            SetValue(self:GetChecked())
            if EDM.UI then EDM.UI:ApplySettings() end
        end)

        yOffset = yOffset + 30
        return row
    end

    local function CreateSlider(label, dbKey, minVal, maxVal, step, dbPath)
        local row = CreateFrame("Frame", nil, panel.content)
        row:SetSize(280, 40)
        row:SetPoint("TOPLEFT", 0, -yOffset)

        row.label = row:CreateFontString(nil, "OVERLAY")
        row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row.label:SetPoint("TOPLEFT", 0, 0)
        row.label:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label:SetText(label)

        row.slider = CreateFrame("Slider", nil, row, "OptionsSliderTemplate")
        row.slider:SetSize(160, 16)
        row.slider:SetPoint("BOTTOMRIGHT", 0, 0)
        row.slider:SetMinMaxValues(minVal, maxVal)
        row.slider:SetValueStep(step)
        row.slider:SetObeyStepOnDrag(true)
        row.slider.Low:SetText(minVal)
        row.slider.High:SetText(maxVal)

        row.value = row:CreateFontString(nil, "OVERLAY")
        row.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        row.value:SetPoint("TOPRIGHT", 0, 0)
        row.value:SetTextColor(1, 0.8, 0.2, 1)

        local function GetValue()
            local path = dbPath or "profile"
            local keys = {strsplit(".", dbKey)}
            local val = EDM.db[path]
            for _, key in ipairs(keys) do
                if val then val = val[key] end
            end
            return val or minVal
        end

        local function SetValue(newVal)
            local path = dbPath or "profile"
            local keys = {strsplit(".", dbKey)}
            local tbl = EDM.db[path]
            for i = 1, #keys - 1 do
                if tbl then tbl = tbl[keys[i]] end
            end
            if tbl then tbl[keys[#keys]] = newVal end
        end

        local currentVal = GetValue()
        row.slider:SetValue(currentVal)
        row.value:SetText(currentVal)
        row.slider:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / step + 0.5) * step
            SetValue(value)
            row.value:SetText(value)
            if EDM.UI then EDM.UI:ApplySettings() end
        end)

        yOffset = yOffset + 45
        return row
    end

    local function CreateHeader(text)
        local header = panel.content:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        header:SetPoint("TOPLEFT", 0, -yOffset)
        header:SetTextColor(0.4, 0.7, 1, 1)
        header:SetText(text)

        local line = panel.content:CreateTexture(nil, "ARTWORK")
        line:SetSize(280, 1)
        line:SetPoint("TOPLEFT", 0, -yOffset - 16)
        line:SetColorTexture(0.3, 0.5, 0.8, 0.5)

        yOffset = yOffset + 25
    end

    -- Create settings
    CreateHeader("General")
    CreateToggle("Lock Window Position", "locked")
    CreateToggle("Show Minimap Icon", "minimap.hide")

    CreateHeader("Window")
    CreateSlider("Window Scale", "window.scale", 0.5, 2.0, 0.1)
    CreateSlider("Window Opacity", "window.opacity", 0.2, 1.0, 0.1)

    CreateHeader("Bars")
    CreateSlider("Bar Height", "bars.height", 12, 32, 1)
    CreateSlider("Bar Spacing", "bars.spacing", 0, 5, 1)
    CreateToggle("Use Class Colors", "bars.useClassColors")
    CreateToggle("Show Rank Numbers", "bars.showRank")

    CreateHeader("Display")
    CreateSlider("Max Bars Shown", "display.maxBars", 5, 50, 1)
    CreateSlider("Refresh Rate (s)", "display.refreshRate", 0.1, 2.0, 0.1)

    CreateHeader("Sounds")
    CreateToggle("Combat Start Sound", "sounds.combatStart")
    CreateToggle("Combat End Sound", "sounds.combatEnd")

    panel:Hide()
    self.quickPanel = panel
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
