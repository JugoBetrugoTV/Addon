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
                            if val then EDM.Core:OnEnable() else EDM.Core:OnDisable() end
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
                            if EDM.UI then EDM.UI:SetLocked(val) end
                        end,
                    },
                },
            },
        },
    }
    return options
end

-- Register options
function Config:Register()
    -- Safety check - AceConfig might not be fully loaded if another addon's higher version takes over
    if not AceConfig or not AceConfig.RegisterOptionsTable then
        -- Retry after a short delay
        C_Timer.After(1, function()
            if AceConfig and AceConfig.RegisterOptionsTable then
                Config:Register()
            end
        end)
        return
    end

    local options = self:GetOptions()
    pcall(function()
        AceConfig:RegisterOptionsTable(ADDON_NAME, options)
    end)
    pcall(function()
        if AceConfigCmd and AceConfigCmd.CreateChatCommand then
            AceConfigCmd:CreateChatCommand("edm config", ADDON_NAME)
        end
    end)
    self.registered = true
end

-- Open config
function Config:Open()
    if not self.registered then self:Register() end
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
    panel:SetSize(520, 580)
    panel:SetPoint("CENTER", 0, 50)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(100)
    panel:SetMovable(true)
    panel:SetResizable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:SetResizeBounds(450, 450, 750, 850)

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
    panel.titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    panel.titleBar.bg:SetGradient("VERTICAL", CreateColor(0.15, 0.25, 0.4, 1), CreateColor(0.05, 0.08, 0.15, 1))

    -- Title bar bottom accent line
    panel.titleBar.accentLine = panel.titleBar:CreateTexture(nil, "OVERLAY")
    panel.titleBar.accentLine:SetHeight(2)
    panel.titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    panel.titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    panel.titleBar.accentLine:SetColorTexture(0.3, 0.6, 1, 0.8)

    -- Logo/Icon
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

    -- Title text
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

    -- Close button
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
    panel.closeBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.8, 0.2, 0.2, 0.9) end)
    panel.closeBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.6, 0.1, 0.1, 0.6) end)

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

    local tabNames = {"General", "Window", "Bars", "Display", "Credits"}
    local tabIcons = {
        "Interface\\Icons\\Spell_Holy_MagicalSentry",
        "Interface\\Icons\\INV_Misc_EngGizmos_30",
        "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
        "Interface\\Icons\\INV_Misc_Spyglass_03",
        "Interface\\Icons\\INV_Misc_Note_01"
    }
    panel.tabs = {}
    panel.selectedTab = 1

    local tabWidth = 95
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

        tab:SetScript("OnClick", function() Config:SelectTab(i) end)
        tab:SetScript("OnEnter", function(btn)
            if panel.selectedTab ~= i then btn:SetBackdropColor(0.12, 0.15, 0.22, 1) end
        end)
        tab:SetScript("OnLeave", function(btn)
            if panel.selectedTab ~= i then btn:SetBackdropColor(0.08, 0.1, 0.15, 1) end
        end)

        panel.tabs[i] = tab
    end

    -- Content area
    panel.contentFrame = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    panel.contentFrame:SetPoint("TOPLEFT", panel.tabFrame, "BOTTOMLEFT", 8, -8)
    panel.contentFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -8, 55)
    panel.contentFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    panel.contentFrame:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
    panel.contentFrame:SetBackdropBorderColor(0.15, 0.2, 0.3, 0.6)

    -- Scroll frame
    panel.scrollFrame = CreateFrame("ScrollFrame", nil, panel.contentFrame, "UIPanelScrollFrameTemplate")
    panel.scrollFrame:SetPoint("TOPLEFT", 4, -4)
    panel.scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)

    panel.scrollChild = CreateFrame("Frame", nil, panel.scrollFrame)
    panel.scrollChild:SetWidth(panel.scrollFrame:GetWidth() or 440)
    panel.scrollChild:SetHeight(600)
    panel.scrollFrame:SetScrollChild(panel.scrollChild)

    -- Bottom bar
    panel.bottomBar = CreateFrame("Frame", nil, panel)
    panel.bottomBar:SetHeight(45)
    panel.bottomBar:SetPoint("BOTTOMLEFT", 4, 4)
    panel.bottomBar:SetPoint("BOTTOMRIGHT", -4, 4)
    panel.bottomBar.bg = panel.bottomBar:CreateTexture(nil, "BACKGROUND")
    panel.bottomBar.bg:SetAllPoints()
    panel.bottomBar.bg:SetColorTexture(0.05, 0.07, 0.12, 0.95)

    panel.bottomBar.version = panel.bottomBar:CreateFontString(nil, "OVERLAY")
    panel.bottomBar.version:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    panel.bottomBar.version:SetPoint("LEFT", 10, 0)
    panel.bottomBar.version:SetTextColor(0.5, 0.5, 0.6, 1)
    panel.bottomBar.version:SetText("EpicDamageMeter v1.0.6 | Interface 110207")

    -- Save & Reload button
    panel.bottomBar.saveBtn = CreateFrame("Button", nil, panel.bottomBar, "BackdropTemplate")
    panel.bottomBar.saveBtn:SetSize(120, 28)
    panel.bottomBar.saveBtn:SetPoint("RIGHT", -10, 0)
    panel.bottomBar.saveBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    panel.bottomBar.saveBtn:SetBackdropColor(0.1, 0.5, 0.2, 0.8)
    panel.bottomBar.saveBtn:SetBackdropBorderColor(0.2, 0.7, 0.3, 0.9)
    panel.bottomBar.saveBtn.text = panel.bottomBar.saveBtn:CreateFontString(nil, "OVERLAY")
    panel.bottomBar.saveBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    panel.bottomBar.saveBtn.text:SetPoint("CENTER")
    panel.bottomBar.saveBtn.text:SetText("Save & Reload")
    panel.bottomBar.saveBtn.text:SetTextColor(0.9, 1, 0.9, 1)
    panel.bottomBar.saveBtn:SetScript("OnClick", function()
        panel:Hide()
        ReloadUI()
    end)
    panel.bottomBar.saveBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.15, 0.6, 0.3, 1)
    end)
    panel.bottomBar.saveBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.1, 0.5, 0.2, 0.8)
    end)

    -- Reset button
    panel.bottomBar.resetBtn = CreateFrame("Button", nil, panel.bottomBar, "BackdropTemplate")
    panel.bottomBar.resetBtn:SetSize(90, 28)
    panel.bottomBar.resetBtn:SetPoint("RIGHT", panel.bottomBar.saveBtn, "LEFT", -10, 0)
    panel.bottomBar.resetBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    panel.bottomBar.resetBtn:SetBackdropColor(0.5, 0.2, 0.1, 0.7)
    panel.bottomBar.resetBtn:SetBackdropBorderColor(0.7, 0.3, 0.2, 0.8)
    panel.bottomBar.resetBtn.text = panel.bottomBar.resetBtn:CreateFontString(nil, "OVERLAY")
    panel.bottomBar.resetBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    panel.bottomBar.resetBtn.text:SetPoint("CENTER")
    panel.bottomBar.resetBtn.text:SetText("Reset Data")
    panel.bottomBar.resetBtn.text:SetTextColor(1, 0.7, 0.6, 1)
    panel.bottomBar.resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("EDM_CONFIRM_RESET")
    end)
    panel.bottomBar.resetBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.7, 0.3, 0.2, 0.9) end)
    panel.bottomBar.resetBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.5, 0.2, 0.1, 0.7) end)

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
        panel.scrollChild:SetWidth(panel.scrollFrame:GetWidth() or 440)
    end)

    -- Static popup for reset
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

    -- Build all tab contents
    self:BuildAllTabs()
    self:SelectTab(1)
end

-- Select a tab
function Config:SelectTab(index)
    local panel = self.quickPanel
    if not panel then return end

    panel.selectedTab = index

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

    -- Clear scroll child
    for _, child in ipairs({panel.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Build the selected tab content
    if index == 1 then
        self:BuildGeneralTab()
    elseif index == 2 then
        self:BuildWindowTab()
    elseif index == 3 then
        self:BuildBarsTab()
    elseif index == 4 then
        self:BuildDisplayTab()
    elseif index == 5 then
        self:BuildCreditsTab()
    end

    -- Reset scroll
    panel.scrollFrame:SetVerticalScroll(0)
end

-- Build all tabs initially
function Config:BuildAllTabs()
    -- Just select tab 1 initially, content is built on demand
end

--============================================================================
-- HELPER FUNCTIONS FOR BUILDING UI
--============================================================================

function Config:CreateSectionHeader(yOffset, text)
    local panel = self.quickPanel
    local header = CreateFrame("Frame", nil, panel.scrollChild)
    header:SetHeight(28)
    header:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 0, -yOffset)
    header:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", 0, -yOffset)

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

    return 32
end

function Config:CreateToggleRow(yOffset, label, tooltip, getValue, setValue)
    local panel = self.quickPanel
    local row = CreateFrame("Frame", nil, panel.scrollChild)
    row:SetHeight(28)
    row:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -yOffset)
    row:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -yOffset)

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
    row.toggle.indicator:SetTexture("Interface\\Buttons\\WHITE8X8")

    local function UpdateVisual()
        local enabled = getValue()
        if enabled then
            row.toggle:SetBackdropColor(0.2, 0.6, 0.3, 0.9)
            row.toggle.indicator:ClearAllPoints()
            row.toggle.indicator:SetPoint("LEFT", row.toggle, "LEFT", 22, 0)
            row.toggle.indicator:SetVertexColor(0.3, 1, 0.4, 1)
        else
            row.toggle:SetBackdropColor(0.4, 0.15, 0.15, 0.9)
            row.toggle.indicator:ClearAllPoints()
            row.toggle.indicator:SetPoint("LEFT", row.toggle, "LEFT", 2, 0)
            row.toggle.indicator:SetVertexColor(0.7, 0.3, 0.3, 1)
        end
    end

    row.toggle:SetScript("OnClick", function()
        local current = getValue()
        setValue(not current)
        UpdateVisual()
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

    return 30
end

function Config:CreateSliderRow(yOffset, label, tooltip, getValue, setValue, minVal, maxVal, step, suffix)
    local panel = self.quickPanel
    local row = CreateFrame("Frame", nil, panel.scrollChild)
    row:SetHeight(45)
    row:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -yOffset)
    row:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -yOffset)

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

    -- Slider using proper WoW template
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

    local function UpdateValueText(val)
        local displayVal = step >= 1 and math.floor(val) or string.format("%.2f", val)
        row.value:SetText(displayVal .. (suffix or ""))
    end

    local currentVal = getValue() or minVal
    row.slider:SetValue(currentVal)
    UpdateValueText(currentVal)

    row.slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        setValue(value)
        UpdateValueText(value)
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

    return 48
end

function Config:CreateDropdownRow(yOffset, label, tooltip, getValue, setValue, options)
    local panel = self.quickPanel
    local row = CreateFrame("Frame", nil, panel.scrollChild)
    row:SetHeight(32)
    row:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -yOffset)
    row:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -yOffset)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

    row.label = row:CreateFontString(nil, "OVERLAY")
    row.label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    row.label:SetPoint("LEFT", 10, 0)
    row.label:SetTextColor(0.9, 0.9, 0.9, 1)
    row.label:SetText(label)

    -- Dropdown button
    row.dropdown = CreateFrame("Button", nil, row, "BackdropTemplate")
    row.dropdown:SetSize(150, 24)
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

    local function UpdateText()
        local current = getValue()
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
            setValue(key)
            UpdateText()
            row.dropdown.menu:Hide()
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

    return 35
end

function Config:CreateColorRow(yOffset, label, tooltip, getValue, setValue)
    local panel = self.quickPanel
    local row = CreateFrame("Frame", nil, panel.scrollChild)
    row:SetHeight(28)
    row:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -yOffset)
    row:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -yOffset)

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

    local function UpdateSwatch()
        local c = getValue() or {r = 1, g = 1, b = 1, a = 1}
        row.swatch.color:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
    end

    UpdateSwatch()

    row.swatch:SetScript("OnClick", function()
        local c = getValue() or {r = 1, g = 1, b = 1, a = 1}
        ColorPickerFrame:SetupColorPickerAndShow({
            r = c.r or 1,
            g = c.g or 1,
            b = c.b or 1,
            opacity = c.a or 1,
            hasOpacity = true,
            swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = ColorPickerFrame:GetColorAlpha()
                setValue({r = r, g = g, b = b, a = a})
                UpdateSwatch()
                if EDM.UI then EDM.UI:ApplySettings() end
            end,
            cancelFunc = function(prev)
                setValue({r = prev.r, g = prev.g, b = prev.b, a = prev.opacity})
                UpdateSwatch()
                if EDM.UI then EDM.UI:ApplySettings() end
            end,
        })
    end)

    return 30
end

--============================================================================
-- TAB CONTENT BUILDERS
--============================================================================

function Config:BuildGeneralTab()
    local y = 0

    -- Safety check - if db not ready, show error message
    if not EDM.db or not EDM.db.profile then
        y = y + self:CreateSectionHeader(y, "Error")
        local errorLabel = self.quickPanel.scrollChild:CreateFontString(nil, "OVERLAY")
        errorLabel:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        errorLabel:SetPoint("TOPLEFT", 10, -y - 10)
        errorLabel:SetTextColor(1, 0.3, 0.3, 1)
        errorLabel:SetText("Database not initialized. Please reload the UI (/reload).")
        self.quickPanel.scrollChild:SetHeight(y + 50)
        return
    end

    y = y + self:CreateSectionHeader(y, "General Options")
    y = y + self:CreateToggleRow(y, "Enable Addon", "Enable or disable the damage meter",
        function() return EDM.db and EDM.db.profile and EDM.db.profile.enabled or false end,
        function(v) EDM.db.profile.enabled = v; if v then EDM.Core:OnEnable() else EDM.Core:OnDisable() end end)
    y = y + self:CreateToggleRow(y, "Lock Window", "Prevent the window from being moved",
        function() return EDM.db.profile.locked end,
        function(v) EDM.db.profile.locked = v; if EDM.UI then EDM.UI:SetLocked(v) end end)
    y = y + self:CreateToggleRow(y, "Show Minimap Icon", "Show or hide the minimap button",
        function() return not EDM.db.profile.minimap.hide end,
        function(v) EDM.db.profile.minimap.hide = not v end)
    y = y + self:CreateToggleRow(y, "Merge Pet Damage", "Combine pet damage with owner",
        function() return EDM.db.profile.combat.mergePlayerPets end,
        function(v) EDM.db.profile.combat.mergePlayerPets = v end)

    y = y + self:CreateSectionHeader(y, "Combat Settings")
    y = y + self:CreateToggleRow(y, "Auto New Segment", "Create new segment after combat ends",
        function() return EDM.db.profile.combat.autoReset end,
        function(v) EDM.db.profile.combat.autoReset = v end)
    y = y + self:CreateSliderRow(y, "Max Segments", "Maximum combat segments to keep",
        function() return EDM.db.profile.combat.maxSegments end,
        function(v) EDM.db.profile.combat.maxSegments = v end, 5, 50, 1, "")
    y = y + self:CreateSliderRow(y, "Min Combat Time", "Minimum seconds to record",
        function() return EDM.db.profile.combat.minCombatTime end,
        function(v) EDM.db.profile.combat.minCombatTime = v end, 1, 30, 1, "s")

    y = y + self:CreateSectionHeader(y, "Data Persistence")
    y = y + self:CreateSliderRow(y, "Keep Data (minutes)", "How long to keep combat data before clearing",
        function() return EDM.db.profile.combat.keepDataMinutes or 30 end,
        function(v) EDM.db.profile.combat.keepDataMinutes = v end, 5, 120, 5, " min")
    y = y + self:CreateSliderRow(y, "Combat Timeout", "Seconds of no combat before segment ends",
        function() return EDM.db.profile.combat.combatTimeout or 3 end,
        function(v) EDM.db.profile.combat.combatTimeout = v end, 1, 10, 1, "s")

    y = y + self:CreateSectionHeader(y, "Theme / Skin")
    local skinOptions = {}
    if EDM.Skins then
        for name, _ in pairs(EDM.Skins:GetSkinNames()) do
            skinOptions[name] = name
        end
    end
    if not next(skinOptions) then skinOptions = {Modern = "Modern", Classic = "Classic", Minimal = "Minimal"} end
    y = y + self:CreateDropdownRow(y, "Skin", "Choose a visual theme",
        function() return EDM.db.profile.skin or "Modern" end,
        function(v) EDM.db.profile.skin = v; if EDM.Skins then EDM.Skins:Set(v) end end, skinOptions)

    y = y + self:CreateSectionHeader(y, "Advanced")
    y = y + self:CreateToggleRow(y, "Debug Mode", "Enable debug output",
        function() return EDM.db.profile.advanced and EDM.db.profile.advanced.debugMode end,
        function(v) EDM.db.profile.advanced = EDM.db.profile.advanced or {}; EDM.db.profile.advanced.debugMode = v end)
    y = y + self:CreateToggleRow(y, "Record Timeline", "Track DPS over time for graphs",
        function() return EDM.db.profile.advanced and EDM.db.profile.advanced.recordTimeline end,
        function(v) EDM.db.profile.advanced = EDM.db.profile.advanced or {}; EDM.db.profile.advanced.recordTimeline = v end)

    self.quickPanel.scrollChild:SetHeight(y + 30)
end

function Config:BuildWindowTab()
    local y = 0

    -- Helper function to apply to all window instances
    local function ApplyToAllWindows(func)
        if EDM.UI and EDM.UI.instances then
            for _, instance in pairs(EDM.UI.instances) do
                if instance.frame then
                    func(instance)
                end
            end
        end
    end

    y = y + self:CreateSectionHeader(y, "Window Size & Position")
    y = y + self:CreateSliderRow(y, "Width", "Window width in pixels",
        function() return EDM.db.profile.window.width end,
        function(v)
            EDM.db.profile.window.width = v
            ApplyToAllWindows(function(inst)
                inst.frame:SetWidth(v)
                inst:UpdateLayout()
            end)
        end,
        150, 600, 5, "px")
    y = y + self:CreateSliderRow(y, "Height", "Window height in pixels",
        function() return EDM.db.profile.window.height end,
        function(v)
            EDM.db.profile.window.height = v
            ApplyToAllWindows(function(inst)
                inst.frame:SetHeight(v)
                inst:UpdateLayout()
            end)
        end,
        100, 800, 5, "px")
    y = y + self:CreateSliderRow(y, "Scale", "Window scale multiplier",
        function() return EDM.db.profile.window.scale end,
        function(v)
            EDM.db.profile.window.scale = v
            ApplyToAllWindows(function(inst)
                inst.frame:SetScale(v)
            end)
        end,
        0.5, 2.0, 0.05, "x")
    y = y + self:CreateSliderRow(y, "Opacity", "Window transparency",
        function() return EDM.db.profile.window.opacity end,
        function(v)
            EDM.db.profile.window.opacity = v
            ApplyToAllWindows(function(inst)
                inst.frame:SetAlpha(v)
            end)
        end,
        0.2, 1.0, 0.05, "")

    y = y + self:CreateSectionHeader(y, "Appearance")
    y = y + self:CreateToggleRow(y, "Show Title Bar", "Display the title bar",
        function() return EDM.db.profile.window.showTitle end,
        function(v)
            EDM.db.profile.window.showTitle = v
            ApplyToAllWindows(function(inst)
                if inst.titleBar then inst.titleBar:SetShown(v) end
            end)
        end)
    y = y + self:CreateToggleRow(y, "Show Background", "Show window background",
        function() return EDM.db.profile.window.showBackground end,
        function(v)
            EDM.db.profile.window.showBackground = v
            ApplyToAllWindows(function(inst)
                local bgColor = EDM.db.profile.window.backgroundColor
                if v then
                    inst.frame:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.9)
                else
                    inst.frame:SetBackdropColor(0, 0, 0, 0)
                end
            end)
        end)
    y = y + self:CreateColorRow(y, "Background Color", "Window background color",
        function() return EDM.db.profile.window.backgroundColor end,
        function(v)
            EDM.db.profile.window.backgroundColor = v
            ApplyToAllWindows(function(inst)
                if EDM.db.profile.window.showBackground then
                    inst.frame:SetBackdropColor(v.r, v.g, v.b, v.a or 0.9)
                end
            end)
        end)
    y = y + self:CreateColorRow(y, "Border Color", "Window border color",
        function() return EDM.db.profile.window.borderColor end,
        function(v)
            EDM.db.profile.window.borderColor = v
            ApplyToAllWindows(function(inst)
                inst.frame:SetBackdropBorderColor(v.r, v.g, v.b, v.a or 1)
            end)
        end)

    self.quickPanel.scrollChild:SetHeight(y + 30)
end

function Config:BuildBarsTab()
    local y = 0

    -- Helper function to apply bar settings
    local function ApplyBarSettings()
        -- Get font path from selection
        local fontName = EDM.db.profile.bars.font or "Friz Quadrata TT"
        local fontPaths = {
            ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
            ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
            ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
            ["Skurri"] = "Fonts\\SKURRI.TTF",
            ["2002"] = "Fonts\\2002.TTF",
            ["2002 Bold"] = "Fonts\\2002B.TTF",
        }
        local fontPath = fontPaths[fontName] or "Fonts\\FRIZQT__.TTF"
        local fontSize = EDM.db.profile.bars.fontSize or 11
        local barHeight = EDM.db.profile.bars.height or 18
        local fontFlags = EDM.db.profile.bars.fontFlags or "OUTLINE"

        -- Apply to Bars pool
        if EDM.Bars and EDM.Bars.pool then
            for _, bar in pairs(EDM.Bars.pool) do
                bar:SetHeight(barHeight)
                if bar.icon then
                    bar.icon:SetSize(barHeight - 2, barHeight - 2)
                    bar.icon:SetShown(EDM.db.profile.bars.showIcon ~= false)
                end
                if bar.name then
                    bar.name:SetFont(fontPath, fontSize, fontFlags)
                end
                if bar.value then
                    bar.value:SetFont(fontPath, fontSize - 1, fontFlags)
                    bar.value:SetShown(EDM.db.profile.bars.showValue ~= false)
                end
                if bar.rank then
                    bar.rank:SetFont(fontPath, fontSize - 2, fontFlags)
                    bar.rank:SetShown(EDM.db.profile.bars.showRank ~= false)
                end
                if bar.percent then
                    bar.percent:SetShown(EDM.db.profile.bars.showPercent ~= false)
                end
            end
        end
        -- Refresh all instances
        if EDM.UI then EDM.UI:Refresh() end
    end

    y = y + self:CreateSectionHeader(y, "Bar Dimensions")
    y = y + self:CreateSliderRow(y, "Bar Height", "Height of each bar",
        function() return EDM.db.profile.bars.height end,
        function(v) EDM.db.profile.bars.height = v; ApplyBarSettings() end, 12, 32, 1, "px")
    y = y + self:CreateSliderRow(y, "Bar Spacing", "Space between bars",
        function() return EDM.db.profile.bars.spacing end,
        function(v) EDM.db.profile.bars.spacing = v; ApplyBarSettings() end, 0, 5, 1, "px")

    y = y + self:CreateSectionHeader(y, "Bar Display")
    y = y + self:CreateToggleRow(y, "Use Class Colors", "Color bars by player class",
        function() return EDM.db.profile.bars.useClassColors end,
        function(v) EDM.db.profile.bars.useClassColors = v; ApplyBarSettings() end)
    y = y + self:CreateToggleRow(y, "Show Rank", "Show ranking number on bars",
        function() return EDM.db.profile.bars.showRank end,
        function(v) EDM.db.profile.bars.showRank = v; ApplyBarSettings() end)
    y = y + self:CreateToggleRow(y, "Show Percent", "Show percentage on bars",
        function() return EDM.db.profile.bars.showPercent end,
        function(v) EDM.db.profile.bars.showPercent = v; ApplyBarSettings() end)
    y = y + self:CreateToggleRow(y, "Show Value", "Show damage/healing value",
        function() return EDM.db.profile.bars.showValue end,
        function(v) EDM.db.profile.bars.showValue = v; ApplyBarSettings() end)
    y = y + self:CreateToggleRow(y, "Show Icon", "Show class/spec icon",
        function() return EDM.db.profile.bars.showIcon end,
        function(v) EDM.db.profile.bars.showIcon = v; ApplyBarSettings() end)

    y = y + self:CreateSectionHeader(y, "Font Settings")
    y = y + self:CreateDropdownRow(y, "Font", "Choose bar text font",
        function() return EDM.db.profile.bars.font or "Friz Quadrata TT" end,
        function(v)
            EDM.db.profile.bars.font = v
            ApplyBarSettings()
        end, {
            ["Friz Quadrata TT"] = "Friz Quadrata",
            ["Arial Narrow"] = "Arial Narrow",
            ["Morpheus"] = "Morpheus",
            ["Skurri"] = "Skurri",
            ["2002"] = "2002",
            ["2002 Bold"] = "2002 Bold",
        })
    y = y + self:CreateSliderRow(y, "Font Size", "Size of bar text",
        function() return EDM.db.profile.bars.fontSize end,
        function(v) EDM.db.profile.bars.fontSize = v; ApplyBarSettings() end, 8, 18, 1, "pt")

    y = y + self:CreateSectionHeader(y, "Animation")
    y = y + self:CreateToggleRow(y, "Enable Animation", "Animate bar value changes",
        function() return EDM.db.profile.bars.animation end,
        function(v) EDM.db.profile.bars.animation = v end)
    y = y + self:CreateSliderRow(y, "Animation Speed", "How fast bars animate",
        function() return EDM.db.profile.bars.animationSpeed end,
        function(v) EDM.db.profile.bars.animationSpeed = v end, 0.1, 1.0, 0.05, "")

    self.quickPanel.scrollChild:SetHeight(y + 30)
end

function Config:BuildDisplayTab()
    local y = 0

    y = y + self:CreateSectionHeader(y, "Display Options")
    y = y + self:CreateDropdownRow(y, "Number Format", "How to display numbers",
        function() return EDM.db.profile.display.numberFormat end,
        function(v) EDM.db.profile.display.numberFormat = v end, {
            SHORT = "Short (1.2K)",
            FULL = "Full (1234567)",
            COMMA = "Comma (1,234,567)"
        })
    y = y + self:CreateSliderRow(y, "Refresh Rate", "How often to update display",
        function() return EDM.db.profile.display.refreshRate end,
        function(v) EDM.db.profile.display.refreshRate = v; if EDM.Core then EDM.Core:StartUpdateTimer() end end,
        0.1, 2.0, 0.1, "s")
    y = y + self:CreateSliderRow(y, "Max Bars", "Maximum bars to display",
        function() return EDM.db.profile.display.maxBars end,
        function(v) EDM.db.profile.display.maxBars = v end, 5, 50, 1, "")

    y = y + self:CreateSectionHeader(y, "Graph Settings")
    y = y + self:CreateToggleRow(y, "Enable Graph", "Show DPS/HPS graph",
        function() return EDM.db.profile.graph.enabled end,
        function(v) EDM.db.profile.graph.enabled = v end)
    y = y + self:CreateSliderRow(y, "Graph Width", "Width of the graph",
        function() return EDM.db.profile.graph.width end,
        function(v) EDM.db.profile.graph.width = v; if EDM.Graph and EDM.Graph.frame then EDM.Graph.frame:SetWidth(v) end end, 200, 800, 10, "px")
    y = y + self:CreateSliderRow(y, "Graph Height", "Height of the graph",
        function() return EDM.db.profile.graph.height end,
        function(v) EDM.db.profile.graph.height = v; if EDM.Graph and EDM.Graph.frame then EDM.Graph.frame:SetHeight(v) end end, 100, 400, 10, "px")
    y = y + self:CreateSliderRow(y, "Line Width", "Thickness of graph lines",
        function() return EDM.db.profile.graph.lineWidth end,
        function(v) EDM.db.profile.graph.lineWidth = v end, 1, 5, 0.5, "px")

    y = y + self:CreateSectionHeader(y, "Quick Actions")

    -- Quick action buttons
    local actionsRow = CreateFrame("Frame", nil, self.quickPanel.scrollChild)
    actionsRow:SetHeight(40)
    actionsRow:SetPoint("TOPLEFT", self.quickPanel.scrollChild, "TOPLEFT", 8, -y)
    actionsRow:SetPoint("TOPRIGHT", self.quickPanel.scrollChild, "TOPRIGHT", -8, -y)

    actionsRow.bg = actionsRow:CreateTexture(nil, "BACKGROUND")
    actionsRow.bg:SetAllPoints()
    actionsRow.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

    -- Toggle Graph button
    local graphBtn = CreateFrame("Button", nil, actionsRow, "BackdropTemplate")
    graphBtn:SetSize(100, 28)
    graphBtn:SetPoint("LEFT", 10, 0)
    graphBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    graphBtn:SetBackdropColor(0.2, 0.4, 0.6, 0.8)
    graphBtn:SetBackdropBorderColor(0.3, 0.5, 0.8, 1)
    graphBtn.text = graphBtn:CreateFontString(nil, "OVERLAY")
    graphBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    graphBtn.text:SetPoint("CENTER")
    graphBtn.text:SetText("Toggle Graph")
    graphBtn.text:SetTextColor(1, 1, 1, 1)
    graphBtn:SetScript("OnClick", function()
        if EDM.Core then EDM.Core:ToggleGraph() end
    end)
    graphBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.3, 0.5, 0.7, 1) end)
    graphBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.2, 0.4, 0.6, 0.8) end)

    -- Report button
    local reportBtn = CreateFrame("Button", nil, actionsRow, "BackdropTemplate")
    reportBtn:SetSize(100, 28)
    reportBtn:SetPoint("LEFT", graphBtn, "RIGHT", 10, 0)
    reportBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    reportBtn:SetBackdropColor(0.5, 0.4, 0.2, 0.8)
    reportBtn:SetBackdropBorderColor(0.7, 0.6, 0.3, 1)
    reportBtn.text = reportBtn:CreateFontString(nil, "OVERLAY")
    reportBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    reportBtn.text:SetPoint("CENTER")
    reportBtn.text:SetText("Report Menu")
    reportBtn.text:SetTextColor(1, 1, 1, 1)
    reportBtn:SetScript("OnClick", function()
        if EDM.Core then EDM.Core:ShowReportMenu(reportBtn) end
    end)
    reportBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.6, 0.5, 0.3, 1) end)
    reportBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.5, 0.4, 0.2, 0.8) end)

    -- New Window button
    local newWinBtn = CreateFrame("Button", nil, actionsRow, "BackdropTemplate")
    newWinBtn:SetSize(100, 28)
    newWinBtn:SetPoint("LEFT", reportBtn, "RIGHT", 10, 0)
    newWinBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    newWinBtn:SetBackdropColor(0.3, 0.5, 0.3, 0.8)
    newWinBtn:SetBackdropBorderColor(0.4, 0.7, 0.4, 1)
    newWinBtn.text = newWinBtn:CreateFontString(nil, "OVERLAY")
    newWinBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    newWinBtn.text:SetPoint("CENTER")
    newWinBtn.text:SetText("New Window")
    newWinBtn.text:SetTextColor(1, 1, 1, 1)
    newWinBtn:SetScript("OnClick", function()
        if EDM.Core then EDM.Core:CreateNewWindow() end
    end)
    newWinBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.4, 0.6, 0.4, 1) end)
    newWinBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.3, 0.5, 0.3, 0.8) end)

    y = y + 45

    y = y + self:CreateSectionHeader(y, "Performance Overlay")
    y = y + self:CreateToggleRow(y, "Show Current DPS", "Display live DPS in title bar",
        function() return EDM.db.profile.display.showCurrentDPS ~= false end,
        function(v) EDM.db.profile.display.showCurrentDPS = v end)
    y = y + self:CreateToggleRow(y, "Show Fight Duration", "Display combat time in title bar",
        function() return EDM.db.profile.display.showDuration ~= false end,
        function(v) EDM.db.profile.display.showDuration = v end)
    y = y + self:CreateToggleRow(y, "Highlight Self", "Highlight your own bar",
        function() return EDM.db.profile.display.highlightSelf end,
        function(v) EDM.db.profile.display.highlightSelf = v end)

    self.quickPanel.scrollChild:SetHeight(y + 30)
end

function Config:BuildCreditsTab()
    local panel = self.quickPanel
    local y = 0

    -- Developer section
    y = y + self:CreateSectionHeader(y, "Developer")

    local devRow = CreateFrame("Frame", nil, panel.scrollChild)
    devRow:SetHeight(60)
    devRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    devRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    devRow.bg = devRow:CreateTexture(nil, "BACKGROUND")
    devRow.bg:SetAllPoints()
    devRow.bg:SetColorTexture(0.08, 0.1, 0.15, 0.8)

    devRow.icon = devRow:CreateTexture(nil, "ARTWORK")
    devRow.icon:SetSize(48, 48)
    devRow.icon:SetPoint("LEFT", 10, 0)
    devRow.icon:SetTexture("Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend")
    devRow.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    devRow.name = devRow:CreateFontString(nil, "OVERLAY")
    devRow.name:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    devRow.name:SetPoint("TOPLEFT", devRow.icon, "TOPRIGHT", 12, -6)
    devRow.name:SetText("|cff9966ffJugoBetrugoTV|r")

    devRow.role = devRow:CreateFontString(nil, "OVERLAY")
    devRow.role:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    devRow.role:SetPoint("TOPLEFT", devRow.name, "BOTTOMLEFT", 0, -4)
    devRow.role:SetTextColor(0.7, 0.7, 0.8, 1)
    devRow.role:SetText("Creator & Lead Developer")

    y = y + 65

    -- Links section
    y = y + self:CreateSectionHeader(y, "Links & Community")

    -- Twitch
    local twitchRow = CreateFrame("Frame", nil, panel.scrollChild)
    twitchRow:SetHeight(36)
    twitchRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    twitchRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    twitchRow.bg = twitchRow:CreateTexture(nil, "BACKGROUND")
    twitchRow.bg:SetAllPoints()
    twitchRow.bg:SetColorTexture(0.3, 0.15, 0.5, 0.6)

    twitchRow.icon = twitchRow:CreateTexture(nil, "ARTWORK")
    twitchRow.icon:SetSize(24, 24)
    twitchRow.icon:SetPoint("LEFT", 10, 0)
    twitchRow.icon:SetTexture("Interface\\Icons\\INV_Misc_Film_01")
    twitchRow.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    twitchRow.label = twitchRow:CreateFontString(nil, "OVERLAY")
    twitchRow.label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    twitchRow.label:SetPoint("LEFT", twitchRow.icon, "RIGHT", 10, 0)
    twitchRow.label:SetText("|cff9146ffTwitch:|r  twitch.tv/novi_live")

    y = y + 40

    -- Discord
    local discordRow = CreateFrame("Frame", nil, panel.scrollChild)
    discordRow:SetHeight(36)
    discordRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    discordRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    discordRow.bg = discordRow:CreateTexture(nil, "BACKGROUND")
    discordRow.bg:SetAllPoints()
    discordRow.bg:SetColorTexture(0.2, 0.25, 0.5, 0.6)

    discordRow.icon = discordRow:CreateTexture(nil, "ARTWORK")
    discordRow.icon:SetSize(24, 24)
    discordRow.icon:SetPoint("LEFT", 10, 0)
    discordRow.icon:SetTexture("Interface\\Icons\\INV_Letter_01")
    discordRow.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    discordRow.label = discordRow:CreateFontString(nil, "OVERLAY")
    discordRow.label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    discordRow.label:SetPoint("LEFT", discordRow.icon, "RIGHT", 10, 0)
    discordRow.label:SetText("|cff5865f2Discord:|r  discord.gg/rv2BsbE")

    y = y + 45

    -- Beta notice section
    y = y + self:CreateSectionHeader(y, "Beta Notice")

    local betaRow = CreateFrame("Frame", nil, panel.scrollChild)
    betaRow:SetHeight(80)
    betaRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    betaRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    betaRow.bg = betaRow:CreateTexture(nil, "BACKGROUND")
    betaRow.bg:SetAllPoints()
    betaRow.bg:SetColorTexture(0.4, 0.3, 0.1, 0.5)

    betaRow.icon = betaRow:CreateTexture(nil, "ARTWORK")
    betaRow.icon:SetSize(32, 32)
    betaRow.icon:SetPoint("TOPLEFT", 10, -10)
    betaRow.icon:SetTexture("Interface\\Icons\\INV_Misc_EngGizmos_20")
    betaRow.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    betaRow.title = betaRow:CreateFontString(nil, "OVERLAY")
    betaRow.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    betaRow.title:SetPoint("TOPLEFT", betaRow.icon, "TOPRIGHT", 10, -2)
    betaRow.title:SetText("|cffffcc00This addon is currently in BETA!|r")

    betaRow.text = betaRow:CreateFontString(nil, "OVERLAY")
    betaRow.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    betaRow.text:SetPoint("TOPLEFT", betaRow.title, "BOTTOMLEFT", 0, -6)
    betaRow.text:SetPoint("RIGHT", betaRow, "RIGHT", -10, 0)
    betaRow.text:SetTextColor(0.85, 0.8, 0.7, 1)
    betaRow.text:SetJustifyH("LEFT")
    betaRow.text:SetText("If you find any bugs or have suggestions, please report them on our Discord server! Your feedback helps make this addon better.")

    y = y + 90

    -- Changelog section
    y = y + self:CreateSectionHeader(y, "Changelog")

    local changelogRow = CreateFrame("Frame", nil, panel.scrollChild)
    changelogRow:SetHeight(200)
    changelogRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    changelogRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    changelogRow.bg = changelogRow:CreateTexture(nil, "BACKGROUND")
    changelogRow.bg:SetAllPoints()
    changelogRow.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

    changelogRow.text = changelogRow:CreateFontString(nil, "OVERLAY")
    changelogRow.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    changelogRow.text:SetPoint("TOPLEFT", 10, -10)
    changelogRow.text:SetPoint("RIGHT", changelogRow, "RIGHT", -10, 0)
    changelogRow.text:SetTextColor(0.8, 0.8, 0.85, 1)
    changelogRow.text:SetJustifyH("LEFT")
    changelogRow.text:SetText(
        "|cff00ff00v1.0.6 - Latest|r\n" ..
        "  - Simplified tracking (group/raid only like Recount)\n" ..
        "  - Fixed data persistence (no more quick resets)\n" ..
        "  - Fixed all bar settings (class colors, percent, value)\n" ..
        "  - Added font selection dropdown\n" ..
        "  - Fixed number format options\n" ..
        "  - Added Quick Actions in Display tab\n" ..
        "  - Removed sound settings\n\n" ..
        "|cffccccccv1.0.5|r\n" ..
        "  - Fixed settings panel tabs\n" ..
        "  - Fixed font size slider\n" ..
        "  - Fixed window size/opacity settings\n" ..
        "  - New minimap icon\n\n" ..
        "|cffccccccv1.0.4|r\n" ..
        "  - Major settings rewrite with tabs\n" ..
        "  - Added 11 custom skins"
    )

    y = y + 210

    -- Version info
    y = y + self:CreateSectionHeader(y, "Version Info")

    local versionRow = CreateFrame("Frame", nil, panel.scrollChild)
    versionRow:SetHeight(60)
    versionRow:SetPoint("TOPLEFT", panel.scrollChild, "TOPLEFT", 8, -y)
    versionRow:SetPoint("TOPRIGHT", panel.scrollChild, "TOPRIGHT", -8, -y)

    versionRow.bg = versionRow:CreateTexture(nil, "BACKGROUND")
    versionRow.bg:SetAllPoints()
    versionRow.bg:SetColorTexture(0.05, 0.07, 0.1, 0.6)

    versionRow.text = versionRow:CreateFontString(nil, "OVERLAY")
    versionRow.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    versionRow.text:SetPoint("LEFT", 10, 0)
    versionRow.text:SetTextColor(0.6, 0.6, 0.7, 1)
    versionRow.text:SetText("|cff00ff00EpicDamageMeter|r v1.0.6 BETA\nInterface Version: 110207\nBuilt with |cffff0000<3|r for the WoW community by JugoBetrugoTV")

    y = y + 70

    panel.scrollChild:SetHeight(y + 30)
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

-- Initialize on load - delay to ensure libraries are fully loaded
C_Timer.After(2, function()
    if EDM.db then
        pcall(function()
            Config:Register()
        end)
    end
end)
