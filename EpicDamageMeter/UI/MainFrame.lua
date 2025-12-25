--[[
    EpicDamageMeter - Main Frame (Rewritten v2)
    Multi-window support with proper bar management, live updates, and per-character settings
]]

local ADDON_NAME, EDM = ...

EDM.UI = {}
local UI = EDM.UI
local Skins = EDM.Skins
local Utils = EDM.Utils
local C = EDM.Constants
local DB = EDM.Database
local LSM = LibStub("LibSharedMedia-3.0")

-- Instance management (multi-window support)
UI.instances = {}
UI.instanceCounter = 0
UI.initialized = false

-- Bar pool for efficient reuse
UI.barPool = {}

--============================================================================
-- INSTANCE CLASS (Each window is an instance)
--============================================================================

local Instance = {}
Instance.__index = Instance

function Instance:New(id, mode, parent)
    local self = setmetatable({}, Instance)

    self.id = id
    self.mode = mode or C.DISPLAY_MODE.DAMAGE_DONE
    self.segment = C.SEGMENT_TYPE.CURRENT
    self.bars = {}
    self.barCount = 0
    self.scrollOffset = 0
    self.lastUpdate = 0
    self.isUpdating = false
    self.selectedActor = nil

    -- Create the window frame
    self:CreateFrame(parent)

    return self
end

function Instance:CreateFrame(parent)
    local db = EDM.db and EDM.db.profile or C.DEFAULT_SETTINGS.profile

    -- Get per-character position if available
    local charKey = UnitName("player") .. "-" .. GetRealmName()
    local charSettings = EDM.db and EDM.db.char and EDM.db.char.windows and EDM.db.char.windows[self.id]

    -- Calculate position offset for new windows
    local offsetX = (self.id - 1) * 20
    local offsetY = (self.id - 1) * -20

    -- Main frame
    self.frame = CreateFrame("Frame", "EDMInstance" .. self.id, parent or UIParent, "BackdropTemplate")
    self.frame:SetSize(charSettings and charSettings.width or db.window.width or 300, charSettings and charSettings.height or db.window.height or 200)

    if charSettings and charSettings.point then
        self.frame:SetPoint(charSettings.point, UIParent, charSettings.relPoint or charSettings.point, charSettings.x or 0, charSettings.y or 0)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    end

    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(5 + self.id)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:SetClampedToScreen(true)
    self.frame:EnableMouse(true)
    self.frame.instance = self

    -- Apply backdrop
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    self.frame:SetBackdropColor(0.05, 0.05, 0.08, 0.92)
    self.frame:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)

    -- Create components
    self:CreateTitleBar()
    self:CreateToolbar()
    self:CreateContentArea()
    self:CreateStatusBar()
    self:CreateResizeHandle()

    -- Setup scripts
    self:SetupScripts()

    self.frame:Show()
end

function Instance:CreateTitleBar()
    self.titleBar = CreateFrame("Frame", nil, self.frame)
    self.titleBar:SetHeight(22)
    self.titleBar:SetPoint("TOPLEFT", 0, 0)
    self.titleBar:SetPoint("TOPRIGHT", 0, 0)

    -- Background
    self.titleBar.bg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    self.titleBar.bg:SetAllPoints()
    self.titleBar.bg:SetColorTexture(0.08, 0.08, 0.12, 0.98)

    -- Title text (shows mode)
    self.titleText = self.titleBar:CreateFontString(nil, "OVERLAY")
    self.titleText:SetPoint("LEFT", 8, 0)
    self.titleText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    self.titleText:SetTextColor(1, 1, 1, 1)
    self:UpdateTitle()

    -- Close button
    self.closeBtn = CreateFrame("Button", nil, self.titleBar)
    self.closeBtn:SetSize(14, 14)
    self.closeBtn:SetPoint("RIGHT", -4, 0)
    self.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    self.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
    self.closeBtn:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 0.8)
    self.closeBtn:SetScript("OnClick", function()
        if #UI.instances > 1 then
            UI:DestroyInstance(self.id)
        else
            self.frame:Hide()
        end
    end)

    -- New window button
    self.newWindowBtn = CreateFrame("Button", nil, self.titleBar)
    self.newWindowBtn:SetSize(14, 14)
    self.newWindowBtn:SetPoint("RIGHT", self.closeBtn, "LEFT", -3, 0)
    self.newWindowBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    self.newWindowBtn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
    self.newWindowBtn:SetScript("OnClick", function()
        UI:CreateNewInstance()
    end)
    self.newWindowBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Create New Window")
        GameTooltip:Show()
    end)
    self.newWindowBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Settings button
    self.settingsBtn = CreateFrame("Button", nil, self.titleBar)
    self.settingsBtn:SetSize(14, 14)
    self.settingsBtn:SetPoint("RIGHT", self.newWindowBtn, "LEFT", -3, 0)
    self.settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
    self.settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-OptionsButton")
    self.settingsBtn:GetHighlightTexture():SetVertexColor(0.3, 0.6, 1, 0.8)
    self.settingsBtn:SetScript("OnClick", function()
        if EDM.Config then
            if IsShiftKeyDown() then
                EDM.Config:Open() -- Full AceConfig panel
            else
                EDM.Config:ShowQuickPanel() -- Quick settings panel
            end
        end
    end)
    self.settingsBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Settings")
        GameTooltip:AddLine("Click: Quick settings", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Shift+Click: Advanced settings", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    self.settingsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Graph button
    self.graphBtn = CreateFrame("Button", nil, self.titleBar)
    self.graphBtn:SetSize(14, 14)
    self.graphBtn:SetPoint("RIGHT", self.settingsBtn, "LEFT", -3, 0)
    self.graphBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    self.graphBtn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    self.graphBtn:GetHighlightTexture():SetVertexColor(0.3, 1, 0.6, 0.8)
    self.graphBtn:SetScript("OnClick", function()
        if EDM.Graph then
            if not EDM.Graph.frame then
                EDM.Graph:Initialize(self.frame)
            end
            EDM.Graph:Toggle()
        end
    end)
    self.graphBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Toggle Graph")
        GameTooltip:Show()
    end)
    self.graphBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Reset button
    self.resetBtn = CreateFrame("Button", nil, self.titleBar)
    self.resetBtn:SetSize(14, 14)
    self.resetBtn:SetPoint("RIGHT", self.graphBtn, "LEFT", -3, 0)
    self.resetBtn:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    self.resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-RefreshButton")
    self.resetBtn:GetHighlightTexture():SetVertexColor(0.3, 1, 0.3, 0.8)
    self.resetBtn:SetScript("OnClick", function()
        if DB then
            DB:Reset()
            print("|cff00ff00EpicDamageMeter:|r Data reset!")
        end
    end)
    self.resetBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Reset Data")
        GameTooltip:Show()
    end)
    self.resetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Report button (chat)
    self.reportBtn = CreateFrame("Button", nil, self.titleBar)
    self.reportBtn:SetSize(14, 14)
    self.reportBtn:SetPoint("RIGHT", self.resetBtn, "LEFT", -3, 0)
    self.reportBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Up")
    self.reportBtn:SetHighlightTexture("Interface\\Buttons\\UI-GuildButton-OfficerNote-Up")
    self.reportBtn:GetHighlightTexture():SetVertexColor(1, 0.8, 0.3, 0.8)
    self.reportBtn:SetScript("OnClick", function(btn)
        if EDM.Core then
            EDM.Core:ShowReportMenu(btn)
        end
    end)
    self.reportBtn:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Report to Chat")
        GameTooltip:AddLine("Click to post data to chat", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    self.reportBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Draggable
    self.titleBar:EnableMouse(true)
    self.titleBar:RegisterForDrag("LeftButton")
    self.titleBar:SetScript("OnDragStart", function()
        if not (EDM.db and EDM.db.profile.locked) then
            self.frame:StartMoving()
        end
    end)
    self.titleBar:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        self:SavePosition()
    end)
end

function Instance:CreateToolbar()
    self.toolbar = CreateFrame("Frame", nil, self.frame)
    self.toolbar:SetHeight(18)
    self.toolbar:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", 0, 0)
    self.toolbar:SetPoint("TOPRIGHT", self.titleBar, "BOTTOMRIGHT", 0, 0)

    self.toolbar.bg = self.toolbar:CreateTexture(nil, "BACKGROUND")
    self.toolbar.bg:SetAllPoints()
    self.toolbar.bg:SetColorTexture(0.04, 0.04, 0.06, 0.95)

    -- Mode selector (with right-click menu)
    self.modeBtn = CreateFrame("Button", nil, self.toolbar, "BackdropTemplate")
    self.modeBtn:SetSize(100, 16)
    self.modeBtn:SetPoint("LEFT", 4, 0)
    self.modeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.modeBtn:SetBackdropColor(0.12, 0.12, 0.15, 1)
    self.modeBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    self.modeBtn.text = self.modeBtn:CreateFontString(nil, "OVERLAY")
    self.modeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.modeBtn.text:SetPoint("CENTER")
    self.modeBtn.text:SetText(C.DISPLAY_MODE_NAMES[self.mode] or "Damage")

    self.modeBtn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            self:CycleMode(1)
        else
            self:ShowModeMenu()
        end
    end)
    self.modeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.modeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.18, 0.18, 0.22, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Display Mode")
        GameTooltip:AddLine("Left-click: Next mode", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Select mode", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    self.modeBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.12, 0.12, 0.15, 1)
        GameTooltip:Hide()
    end)

    -- Segment selector
    self.segmentBtn = CreateFrame("Button", nil, self.toolbar, "BackdropTemplate")
    self.segmentBtn:SetSize(60, 16)
    self.segmentBtn:SetPoint("LEFT", self.modeBtn, "RIGHT", 4, 0)
    self.segmentBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.segmentBtn:SetBackdropColor(0.12, 0.12, 0.15, 1)
    self.segmentBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    self.segmentBtn.text = self.segmentBtn:CreateFontString(nil, "OVERLAY")
    self.segmentBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.segmentBtn.text:SetPoint("CENTER")
    self.segmentBtn.text:SetText("Current")

    self.segmentBtn:SetScript("OnClick", function()
        self:CycleSegment()
    end)
    self.segmentBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.18, 0.18, 0.22, 1)
    end)
    self.segmentBtn:SetScript("OnLeave", function(btn)
        btn:SetBackdropColor(0.12, 0.12, 0.15, 1)
    end)
end

function Instance:CreateContentArea()
    -- Content frame (holds the bars)
    self.content = CreateFrame("Frame", nil, self.frame)
    self.content:SetPoint("TOPLEFT", self.toolbar, "BOTTOMLEFT", 2, -2)
    self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -2, 16)
    self.content:SetClipsChildren(true)

    -- Scroll child (bars go here)
    self.scrollChild = CreateFrame("Frame", nil, self.content)
    self.scrollChild:SetPoint("TOPLEFT", 0, 0)
    self.scrollChild:SetWidth(self.content:GetWidth() or 280)
    self.scrollChild:SetHeight(1)

    -- Mouse wheel scrolling
    self.content:EnableMouseWheel(true)
    self.content:SetScript("OnMouseWheel", function(_, delta)
        self:OnScroll(delta)
    end)

    -- Right click menu on content area
    self.content:EnableMouse(true)
    self.content:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            self:ShowModeMenu()
        end
    end)
end

function Instance:CreateStatusBar()
    self.statusBar = CreateFrame("Frame", nil, self.frame)
    self.statusBar:SetHeight(14)
    self.statusBar:SetPoint("BOTTOMLEFT", 0, 0)
    self.statusBar:SetPoint("BOTTOMRIGHT", 0, 0)

    self.statusBar.bg = self.statusBar:CreateTexture(nil, "BACKGROUND")
    self.statusBar.bg:SetAllPoints()
    self.statusBar.bg:SetColorTexture(0.04, 0.04, 0.06, 0.95)

    -- Player info (name-server with class icon)
    self.statusBar.playerInfo = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.playerInfo:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.playerInfo:SetPoint("LEFT", 4, 0)
    self.statusBar.playerInfo:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Update player info
    local playerName = UnitName("player")
    local playerRealm = GetRealmName()
    local _, playerClass = UnitClass("player")
    local r, g, b = Utils.GetClassColor(playerClass)
    self.statusBar.playerInfo:SetText(string.format("|cff%02x%02x%02x%s|r-%s", r*255, g*255, b*255, playerName, playerRealm))

    -- Combat time
    self.statusBar.time = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.time:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.time:SetPoint("CENTER", 0, 0)
    self.statusBar.time:SetTextColor(0.6, 0.6, 0.6, 1)
    self.statusBar.time:SetText("0:00")

    -- Total value
    self.statusBar.total = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.total:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.total:SetPoint("RIGHT", -4, 0)
    self.statusBar.total:SetTextColor(0.6, 0.6, 0.6, 1)
    self.statusBar.total:SetText("Total: 0")
end

function Instance:CreateResizeHandle()
    self.resizeHandle = CreateFrame("Frame", nil, self.frame)
    self.resizeHandle:SetSize(16, 16)
    self.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
    self.resizeHandle:EnableMouse(true)

    self.resizeHandle.tex = self.resizeHandle:CreateTexture(nil, "OVERLAY")
    self.resizeHandle.tex:SetAllPoints()
    self.resizeHandle.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    self.frame:SetResizeBounds(180, 80, 600, 800)

    self.resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not (EDM.db and EDM.db.profile.locked) then
            self.frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    self.resizeHandle:SetScript("OnMouseUp", function()
        self.frame:StopMovingOrSizing()
        self:SavePosition()
        self:UpdateLayout()
    end)
end

function Instance:SetupScripts()
    -- Frame dragging from anywhere when unlocked
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function()
        if not (EDM.db and EDM.db.profile.locked) then
            self.frame:StartMoving()
        end
    end)
    self.frame:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        self:SavePosition()
    end)

    -- Size changed
    self.frame:SetScript("OnSizeChanged", function()
        self:UpdateLayout()
    end)
end

function Instance:UpdateTitle()
    local modeName = C.DISPLAY_MODE_NAMES[self.mode] or "Damage"
    self.titleText:SetText("|cff00ff00Epic|r|cffff6600DM|r - " .. modeName)
end

function Instance:ShowModeMenu()
    -- Create custom menu frame instead of UIDropDownMenu (more reliable click handling)
    if not self.customMenu then
        self.customMenu = self:CreateCustomMenu()
    end

    -- Position at cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self.customMenu:ClearAllPoints()
    self.customMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    self.customMenu:Show()
    self.customMenu:Raise()
end

function Instance:CreateCustomMenu()
    local menu = CreateFrame("Frame", "EDMCustomMenu" .. self.id, UIParent, "BackdropTemplate")
    menu:SetSize(160, 360)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(200)
    menu:EnableMouse(true)
    menu:SetClampedToScreen(true)

    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    menu:SetBackdropColor(0.08, 0.08, 0.12, 0.98)
    menu:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)

    local self_ref = self
    local yOffset = -4

    local function CreateHeader(text, color)
        local header = menu:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        header:SetPoint("TOPLEFT", 8, yOffset)
        header:SetText(color .. text .. "|r")
        yOffset = yOffset - 16
    end

    local function CreateMenuItem(text, mode)
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(144, 18)
        btn:SetPoint("TOPLEFT", 8, yOffset)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.15, 0.15, 0.2, 0)

        btn.check = btn:CreateTexture(nil, "ARTWORK")
        btn.check:SetSize(12, 12)
        btn.check:SetPoint("LEFT", 2, 0)
        btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        btn.check:SetShown(self_ref.mode == mode)

        btn.text = btn:CreateFontString(nil, "OVERLAY")
        btn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        btn.text:SetPoint("LEFT", 18, 0)
        btn.text:SetText(text)
        btn.text:SetTextColor(0.9, 0.9, 0.9, 1)

        btn:SetScript("OnEnter", function()
            btn.bg:SetColorTexture(0.25, 0.25, 0.35, 1)
        end)
        btn:SetScript("OnLeave", function()
            btn.bg:SetColorTexture(0.15, 0.15, 0.2, 0)
        end)
        btn:SetScript("OnClick", function()
            self_ref:SetMode(mode)
            menu:Hide()
        end)

        btn.mode = mode
        yOffset = yOffset - 20

        return btn
    end

    -- Build menu
    CreateHeader("Damage", "|cffff6666")
    menu.damageDone = CreateMenuItem("Damage Done", C.DISPLAY_MODE.DAMAGE_DONE)
    menu.dps = CreateMenuItem("DPS", C.DISPLAY_MODE.DPS)
    menu.damageTaken = CreateMenuItem("Damage Taken", C.DISPLAY_MODE.DAMAGE_TAKEN)

    yOffset = yOffset - 6
    CreateHeader("Healing", "|cff66ff66")
    menu.healingDone = CreateMenuItem("Healing Done", C.DISPLAY_MODE.HEALING_DONE)
    menu.hps = CreateMenuItem("HPS", C.DISPLAY_MODE.HPS)
    menu.healingTaken = CreateMenuItem("Healing Received", C.DISPLAY_MODE.HEALING_TAKEN)
    menu.overhealing = CreateMenuItem("Overhealing", C.DISPLAY_MODE.OVERHEALING)
    menu.absorbs = CreateMenuItem("Absorbs", C.DISPLAY_MODE.ABSORBS)

    yOffset = yOffset - 6
    CreateHeader("Utility", "|cff6699ff")
    menu.interrupts = CreateMenuItem("Interrupts", C.DISPLAY_MODE.INTERRUPTS)
    menu.dispels = CreateMenuItem("Dispels", C.DISPLAY_MODE.DISPELS)
    menu.deaths = CreateMenuItem("Deaths", C.DISPLAY_MODE.DEATHS)

    -- Adjust menu height
    menu:SetHeight(-yOffset + 8)

    -- Close when clicking outside
    menu:SetScript("OnShow", function()
        menu:SetPropagateKeyboardInput(true)
    end)

    menu:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then
            menu:Hide()
            menu:SetPropagateKeyboardInput(false)
        end
    end)

    -- Close on world click
    menu:SetScript("OnUpdate", function()
        if not menu:IsMouseOver() and IsMouseButtonDown("LeftButton") then
            C_Timer.After(0.1, function()
                if menu:IsShown() and not menu:IsMouseOver() then
                    menu:Hide()
                end
            end)
        end
    end)

    -- Update checks when shown
    menu:SetScript("OnShow", function()
        for _, child in pairs({menu:GetChildren()}) do
            if child.mode and child.check then
                child.check:SetShown(self_ref.mode == child.mode)
            end
        end
    end)

    menu:Hide()
    return menu
end

function Instance:SetMode(mode)
    self.mode = mode
    self:UpdateTitle()
    self.modeBtn.text:SetText(C.DISPLAY_MODE_NAMES[self.mode] or "Damage")
    self:UpdateBars()
end

function Instance:CycleMode(direction)
    direction = direction or 1
    local modes = {
        C.DISPLAY_MODE.DAMAGE_DONE,
        C.DISPLAY_MODE.DPS,
        C.DISPLAY_MODE.HEALING_DONE,
        C.DISPLAY_MODE.HPS,
        C.DISPLAY_MODE.DAMAGE_TAKEN,
        C.DISPLAY_MODE.DEATHS,
        C.DISPLAY_MODE.INTERRUPTS,
        C.DISPLAY_MODE.DISPELS,
        C.DISPLAY_MODE.ABSORBS,
        C.DISPLAY_MODE.OVERHEALING,
    }

    local currentIndex = 1
    for i, m in ipairs(modes) do
        if m == self.mode then
            currentIndex = i
            break
        end
    end

    currentIndex = currentIndex + direction
    if currentIndex > #modes then currentIndex = 1 end
    if currentIndex < 1 then currentIndex = #modes end

    self:SetMode(modes[currentIndex])
end

function Instance:CycleSegment()
    if self.segment == C.SEGMENT_TYPE.CURRENT then
        self.segment = C.SEGMENT_TYPE.OVERALL
        self.segmentBtn.text:SetText("Overall")
    else
        self.segment = C.SEGMENT_TYPE.CURRENT
        self.segmentBtn.text:SetText("Current")
    end
    self:UpdateBars()
end

function Instance:OnScroll(delta)
    local maxScroll = math.max(0, self.barCount - self:GetVisibleBarCount())
    self.scrollOffset = self.scrollOffset - delta
    self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset))
    self:LayoutBars()
end

function Instance:GetVisibleBarCount()
    local contentHeight = self.content:GetHeight() or 150
    local barHeight = (EDM.db and EDM.db.profile.bars.height) or 18
    local spacing = (EDM.db and EDM.db.profile.bars.spacing) or 1
    return math.floor(contentHeight / (barHeight + spacing))
end

function Instance:UpdateLayout()
    if self.scrollChild then
        self.scrollChild:SetWidth(self.content:GetWidth() or 280)
    end
    self:LayoutBars()
end

function Instance:SavePosition()
    if not EDM.db then return end

    -- Initialize char table if needed
    EDM.db.char = EDM.db.char or {}
    EDM.db.char.windows = EDM.db.char.windows or {}

    local point, _, relPoint, x, y = self.frame:GetPoint()
    local width, height = self.frame:GetSize()

    EDM.db.char.windows[self.id] = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
        width = width,
        height = height,
        mode = self.mode,
    }
end

--============================================================================
-- BAR MANAGEMENT
--============================================================================

function Instance:GetBar(index)
    if self.bars[index] then
        return self.bars[index]
    end

    local bar = UI:GetBarFromPool()
    bar:SetParent(self.scrollChild)
    bar.instance = self
    self.bars[index] = bar
    return bar
end

function Instance:ClearBars()
    for i, bar in ipairs(self.bars) do
        bar:Hide()
        UI:ReturnBarToPool(bar)
    end
    wipe(self.bars)
    self.barCount = 0
end

function Instance:UpdateBars()
    if not self.frame or not self.frame:IsShown() then return end
    if self.isUpdating then return end
    self.isUpdating = true

    -- Get segment
    local segment
    if self.segment == C.SEGMENT_TYPE.OVERALL then
        segment = DB.Data.overallSegment
    else
        segment = DB.Data.currentSegment
    end

    if not segment then
        self.isUpdating = false
        return
    end

    -- Get sorted actors
    local actors = DB:GetSortedActors(segment, self.mode)
    local duration = DB:GetSegmentDuration(segment)
    if duration == 0 then duration = 1 end

    -- Calculate totals
    local total, topValue = self:CalculateTotals(actors, segment, duration)

    -- Update bar count (don't clear, reuse)
    local maxBars = (EDM.db and EDM.db.profile.display.maxBars) or 25
    local barCount = math.min(#actors, maxBars)

    -- Update existing bars or create new ones
    for i = 1, barCount do
        local bar = self:GetBar(i)
        local actor = actors[i]
        self:SetBarData(bar, actor, i, topValue, duration, total)
        bar:Show()
    end

    -- Hide unused bars
    for i = barCount + 1, #self.bars do
        if self.bars[i] then
            self.bars[i]:Hide()
        end
    end

    self.barCount = barCount

    -- Layout without resetting scroll
    self:LayoutBars()

    -- Get display settings
    local displayDb = EDM.db and EDM.db.profile.display or {}
    local showDuration = displayDb.showDuration ~= false
    local showCurrentDPS = displayDb.showCurrentDPS ~= false

    -- Update status bar
    if showDuration then
        self.statusBar.time:SetText(Utils.FormatTime(duration))
        self.statusBar.time:Show()
    else
        self.statusBar.time:Hide()
    end

    -- Show total with DPS if enabled
    local totalStr = "Total: " .. Utils.FormatNumber(total)
    if showCurrentDPS and duration > 0 then
        local totalPS = total / duration
        totalStr = totalStr .. " (" .. Utils.FormatNumber(totalPS) .. "/s)"
    end
    self.statusBar.total:SetText(totalStr)

    self.isUpdating = false
end

function Instance:CalculateTotals(actors, segment, duration)
    local total = 0
    local topValue = 0

    if self.mode == C.DISPLAY_MODE.DAMAGE_DONE or self.mode == C.DISPLAY_MODE.DPS then
        total = segment.totalDamage or 0
        for _, actor in ipairs(actors) do
            local val = self.mode == C.DISPLAY_MODE.DPS and (actor.damage / duration) or actor.damage
            if val > topValue then topValue = val end
        end
    elseif self.mode == C.DISPLAY_MODE.HEALING_DONE or self.mode == C.DISPLAY_MODE.HPS then
        total = segment.totalHealing or 0
        for _, actor in ipairs(actors) do
            local val = self.mode == C.DISPLAY_MODE.HPS and (actor.healing / duration) or actor.healing
            if val > topValue then topValue = val end
        end
    elseif self.mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        for _, actor in ipairs(actors) do
            total = total + (actor.damageTaken or 0)
            if (actor.damageTaken or 0) > topValue then topValue = actor.damageTaken end
        end
    elseif self.mode == C.DISPLAY_MODE.HEALING_TAKEN then
        for _, actor in ipairs(actors) do
            total = total + (actor.healingTaken or 0)
            if (actor.healingTaken or 0) > topValue then topValue = actor.healingTaken end
        end
    elseif self.mode == C.DISPLAY_MODE.CC_BREAKS then
        for _, actor in ipairs(actors) do
            total = total + (actor.ccBreaks or 0)
            if (actor.ccBreaks or 0) > topValue then topValue = actor.ccBreaks end
        end
    elseif self.mode == C.DISPLAY_MODE.DEATHS then
        for _, actor in ipairs(actors) do
            total = total + (actor.deaths or 0)
            if (actor.deaths or 0) > topValue then topValue = actor.deaths end
        end
    elseif self.mode == C.DISPLAY_MODE.INTERRUPTS then
        for _, actor in ipairs(actors) do
            total = total + (actor.interrupts or 0)
            if (actor.interrupts or 0) > topValue then topValue = actor.interrupts end
        end
    elseif self.mode == C.DISPLAY_MODE.DISPELS then
        for _, actor in ipairs(actors) do
            total = total + (actor.dispels or 0)
            if (actor.dispels or 0) > topValue then topValue = actor.dispels end
        end
    elseif self.mode == C.DISPLAY_MODE.ABSORBS then
        for _, actor in ipairs(actors) do
            total = total + (actor.absorbs or 0)
            if (actor.absorbs or 0) > topValue then topValue = actor.absorbs end
        end
    elseif self.mode == C.DISPLAY_MODE.OVERHEALING then
        for _, actor in ipairs(actors) do
            total = total + (actor.overhealing or 0)
            if (actor.overhealing or 0) > topValue then topValue = actor.overhealing end
        end
    end

    if total == 0 then total = 1 end
    if topValue == 0 then topValue = 1 end

    return total, topValue
end

function Instance:SetBarData(bar, actor, rank, topValue, duration, total)
    bar.actorData = actor
    bar.rank = rank

    -- Get settings
    local db = EDM.db and EDM.db.profile or {}
    local barsDb = db.bars or {}
    local displayDb = db.display or {}
    local showIcon = barsDb.showIcon ~= false
    local showValue = barsDb.showValue ~= false
    local showRank = barsDb.showRank ~= false
    local showPercent = barsDb.showPercent ~= false
    local useClassColors = barsDb.useClassColors ~= false
    local numberFormat = displayDb.numberFormat or "SHORT"
    local highlightSelf = displayDb.highlightSelf

    -- Get value based on mode
    local value = 0
    local perSecond = 0

    if self.mode == C.DISPLAY_MODE.DAMAGE_DONE then
        value = actor.damage or 0
        perSecond = value / duration
    elseif self.mode == C.DISPLAY_MODE.DPS then
        value = (actor.damage or 0) / duration
        perSecond = value
    elseif self.mode == C.DISPLAY_MODE.HEALING_DONE then
        value = actor.healing or 0
        perSecond = value / duration
    elseif self.mode == C.DISPLAY_MODE.HPS then
        value = (actor.healing or 0) / duration
        perSecond = value
    elseif self.mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        value = actor.damageTaken or 0
    elseif self.mode == C.DISPLAY_MODE.HEALING_TAKEN then
        value = actor.healingTaken or 0
    elseif self.mode == C.DISPLAY_MODE.CC_BREAKS then
        value = actor.ccBreaks or 0
    elseif self.mode == C.DISPLAY_MODE.DEATHS then
        value = actor.deaths or 0
    elseif self.mode == C.DISPLAY_MODE.INTERRUPTS then
        value = actor.interrupts or 0
    elseif self.mode == C.DISPLAY_MODE.DISPELS then
        value = actor.dispels or 0
    elseif self.mode == C.DISPLAY_MODE.ABSORBS then
        value = actor.absorbs or 0
    elseif self.mode == C.DISPLAY_MODE.OVERHEALING then
        value = actor.overhealing or 0
    end

    -- Calculate percentage relative to top player (for bar width)
    local percent = topValue > 0 and (value / topValue) or 0
    bar.statusBar:SetValue(percent)

    -- Calculate percentage of total (for display)
    local percentOfTotal = total > 0 and ((value / total) * 100) or 0

    -- Set color based on class colors setting
    local r, g, b = Utils.GetClassColor(actor.class)
    if useClassColors then
        bar.statusBar:SetStatusBarColor(r, g, b, 0.9)
    else
        -- Use rank-based colors
        if rank == 1 then
            bar.statusBar:SetStatusBarColor(1, 0.84, 0, 0.9) -- Gold
        elseif rank == 2 then
            bar.statusBar:SetStatusBarColor(0.75, 0.75, 0.75, 0.9) -- Silver
        elseif rank == 3 then
            bar.statusBar:SetStatusBarColor(0.80, 0.50, 0.20, 0.9) -- Bronze
        else
            bar.statusBar:SetStatusBarColor(0.4, 0.4, 0.5, 0.9) -- Grey
        end
    end

    -- Highlight self
    if highlightSelf and actor.name == UnitName("player") then
        bar.bg:SetColorTexture(0.15, 0.25, 0.35, 0.9)
    else
        bar.bg:SetColorTexture(0.02, 0.02, 0.02, 0.85)
    end

    -- Set rank text (respect showRank setting)
    if showRank then
        bar.rankText:SetText(rank)
        bar.rankText:Show()
    else
        bar.rankText:SetText("")
        bar.rankText:Hide()
    end

    -- Name with class color
    local nameColor = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    bar.nameText:SetText(nameColor .. (actor.name or "Unknown") .. "|r")

    -- Value text (respect showValue and showPercent settings)
    local displayValue = (self.mode == C.DISPLAY_MODE.DPS or self.mode == C.DISPLAY_MODE.HPS) and perSecond or value
    local valueStr = ""
    if showValue then
        if self.mode == C.DISPLAY_MODE.DEATHS or self.mode == C.DISPLAY_MODE.INTERRUPTS or
           self.mode == C.DISPLAY_MODE.DISPELS or self.mode == C.DISPLAY_MODE.CC_BREAKS then
            valueStr = string.format("%d", value)
        else
            valueStr = Utils.FormatNumber(displayValue, numberFormat)
        end
    end
    if showPercent then
        if valueStr ~= "" then
            valueStr = valueStr .. string.format(" (%.1f%%)", percentOfTotal)
        else
            valueStr = string.format("%.1f%%", percentOfTotal)
        end
    end
    bar.valueText:SetText(valueStr)
    bar.valueText:SetShown(showValue or showPercent)

    -- Icon - use class icon (respect showIcon setting)
    local icon = actor.class and ("Interface\\Icons\\ClassIcon_" .. actor.class) or "Interface\\Icons\\INV_Misc_QuestionMark"
    bar.icon:SetTexture(icon)
    bar.icon:SetShown(showIcon)
end

function Instance:LayoutBars()
    local barHeight = (EDM.db and EDM.db.profile.bars.height) or 18
    local spacing = (EDM.db and EDM.db.profile.bars.spacing) or 1
    local contentWidth = self.content:GetWidth() or 280

    local startIndex = math.floor(self.scrollOffset) + 1
    local visibleCount = self:GetVisibleBarCount() + 1

    for i = 1, self.barCount do
        local bar = self.bars[i]
        if bar then
            if i >= startIndex and i < startIndex + visibleCount then
                local displayIndex = i - startIndex
                bar:ClearAllPoints()
                bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -displayIndex * (barHeight + spacing))
                bar:SetSize(contentWidth, barHeight)
                bar:Show()
            else
                bar:Hide()
            end
        end
    end

    -- Update scroll child height
    self.scrollChild:SetHeight(self.barCount * (barHeight + spacing))
end

--============================================================================
-- UI MANAGER
--============================================================================

function UI:Initialize()
    if self.initialized then return end

    -- Try to restore saved windows from character data
    local savedWindows = EDM.db and EDM.db.char and EDM.db.char.windows
    local windowsCreated = 0

    if savedWindows then
        -- Sort by ID to restore in order
        local sortedIds = {}
        for id in pairs(savedWindows) do
            table.insert(sortedIds, id)
        end
        table.sort(sortedIds)

        for _, id in ipairs(sortedIds) do
            local winData = savedWindows[id]
            if winData then
                self.instanceCounter = self.instanceCounter + 1
                local instance = Instance:New(self.instanceCounter, winData.mode or C.DISPLAY_MODE.DAMAGE_DONE)
                self.instances[self.instanceCounter] = instance
                windowsCreated = windowsCreated + 1
            end
        end
    end

    -- Create at least one window if none were restored
    if windowsCreated == 0 then
        self:CreateNewInstance(C.DISPLAY_MODE.DAMAGE_DONE)
    end

    self.initialized = true
    Utils.Debug("UI initialized with", windowsCreated > 0 and windowsCreated or 1, "window(s)")
end

function UI:CreateNewInstance(mode)
    self.instanceCounter = self.instanceCounter + 1
    local instance = Instance:New(self.instanceCounter, mode)
    self.instances[self.instanceCounter] = instance
    return instance
end

function UI:DestroyInstance(id)
    local instance = self.instances[id]
    if instance then
        -- Return bars to pool
        instance:ClearBars()
        -- Hide and destroy frame
        if instance.frame then
            instance.frame:Hide()
            instance.frame:SetParent(nil)
        end
        self.instances[id] = nil
    end
end

function UI:GetBarFromPool()
    -- Check pool for available bar
    for i, bar in ipairs(self.barPool) do
        if not bar.inUse then
            bar.inUse = true
            bar:Show()
            return bar
        end
    end

    -- Create new bar
    local bar = self:CreateBar()
    bar.inUse = true
    table.insert(self.barPool, bar)
    return bar
end

function UI:ReturnBarToPool(bar)
    bar.inUse = false
    bar:Hide()
    bar:ClearAllPoints()
end

function UI:CreateBar()
    local db = EDM.db and EDM.db.profile.bars or C.DEFAULT_SETTINGS.profile.bars

    local bar = CreateFrame("Button", nil, UIParent, "BackdropTemplate")
    bar:SetHeight(db.height or 18)
    bar:EnableMouse(true)
    bar:RegisterForClicks("AnyUp")

    -- Background (darker for contrast)
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.02, 0.02, 0.02, 0.85)

    -- Status bar (percentage fill) - with reduced alpha for text visibility
    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetAllPoints()
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetValue(0)
    bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.statusBar:SetAlpha(0.7) -- Reduced alpha so text is readable
    bar.statusBar:EnableMouse(false) -- Pass clicks through to parent button

    -- Dark overlay on top of status bar for better text contrast
    bar.overlay = bar:CreateTexture(nil, "ARTWORK", nil, 1)
    bar.overlay:SetAllPoints()
    bar.overlay:SetColorTexture(0, 0, 0, 0.3)

    -- Icon
    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(db.height - 2, db.height - 2)
    bar.icon:SetPoint("LEFT", 1, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Rank with shadow
    bar.rankText = bar:CreateFontString(nil, "OVERLAY")
    bar.rankText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    bar.rankText:SetPoint("LEFT", bar.icon, "RIGHT", 2, 0)
    bar.rankText:SetWidth(14)
    bar.rankText:SetJustifyH("CENTER")
    bar.rankText:SetTextColor(1, 1, 1, 1)
    bar.rankText:SetShadowOffset(1, -1)
    bar.rankText:SetShadowColor(0, 0, 0, 1)

    -- Name with strong shadow for readability
    bar.nameText = bar:CreateFontString(nil, "OVERLAY")
    bar.nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bar.nameText:SetPoint("LEFT", bar.rankText, "RIGHT", 2, 0)
    bar.nameText:SetPoint("RIGHT", bar, "RIGHT", -70, 0)
    bar.nameText:SetJustifyH("LEFT")
    bar.nameText:SetWordWrap(false)
    bar.nameText:SetShadowOffset(1, -1)
    bar.nameText:SetShadowColor(0, 0, 0, 1)

    -- Value with shadow
    bar.valueText = bar:CreateFontString(nil, "OVERLAY")
    bar.valueText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    bar.valueText:SetPoint("RIGHT", -4, 0)
    bar.valueText:SetJustifyH("RIGHT")
    bar.valueText:SetShadowOffset(1, -1)
    bar.valueText:SetShadowColor(0, 0, 0, 1)

    -- Highlight
    bar.highlight = bar:CreateTexture(nil, "HIGHLIGHT")
    bar.highlight:SetAllPoints()
    bar.highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Click handlers
    bar:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if self.actorData and EDM.DetailWindow then
                EDM.DetailWindow:Show(self.actorData, self.instance)
            end
        elseif button == "RightButton" then
            if self.instance then
                self.instance:ShowModeMenu()
            end
        end
    end)

    bar:SetScript("OnEnter", function(self)
        if self.actorData then
            UI:ShowBarTooltip(self, self.actorData, self.instance)
        end
    end)

    bar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return bar
end

-- Enhanced tooltip with abilities
function UI:ShowBarTooltip(bar, actor, instance)
    if not actor then return end

    GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")

    -- Header with class color
    local r, g, b = Utils.GetClassColor(actor.class)
    GameTooltip:AddLine(actor.name or "Unknown", r, g, b)
    GameTooltip:AddLine(" ")

    local segment = instance.segment == C.SEGMENT_TYPE.OVERALL and DB.Data.overallSegment or DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1
    if duration == 0 then duration = 1 end

    -- Main stats
    if actor.damage > 0 then
        local dps = actor.damage / duration
        GameTooltip:AddDoubleLine("Damage:", string.format("%s (%s/s)", Utils.FormatNumber(actor.damage), Utils.FormatNumber(dps)), 1, 0.5, 0.5, 1, 1, 1)
    end
    if actor.healing > 0 then
        local hps = actor.healing / duration
        GameTooltip:AddDoubleLine("Healing:", string.format("%s (%s/s)", Utils.FormatNumber(actor.healing), Utils.FormatNumber(hps)), 0.5, 1, 0.5, 1, 1, 1)
    end
    if actor.absorbs > 0 then
        GameTooltip:AddDoubleLine("Absorbs:", Utils.FormatNumber(actor.absorbs), 0.9, 0.9, 0.5, 1, 1, 1)
    end
    if actor.overhealing > 0 then
        GameTooltip:AddDoubleLine("Overhealing:", Utils.FormatNumber(actor.overhealing), 0.7, 0.7, 0.7, 1, 1, 1)
    end
    if actor.damageTaken > 0 then
        GameTooltip:AddDoubleLine("Damage Taken:", Utils.FormatNumber(actor.damageTaken), 1, 0.3, 0.3, 1, 1, 1)
    end

    -- Activity stats
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Deaths:", actor.deaths or 0, 0.8, 0.8, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine("Interrupts:", actor.interrupts or 0, 0.8, 0.8, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine("Dispels:", actor.dispels or 0, 0.8, 0.8, 0.8, 1, 1, 1)

    -- Top abilities (if available)
    if actor.abilities and next(actor.abilities) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Top Abilities:", 1, 0.8, 0)

        -- Sort abilities by damage/healing
        local sortedAbilities = {}
        for spellId, ability in pairs(actor.abilities) do
            table.insert(sortedAbilities, ability)
        end

        local sortKey = (instance.mode == C.DISPLAY_MODE.HEALING_DONE or instance.mode == C.DISPLAY_MODE.HPS) and "healing" or "damage"
        table.sort(sortedAbilities, function(a, b) return (a[sortKey] or 0) > (b[sortKey] or 0) end)

        local totalForPercent = sortKey == "healing" and actor.healing or actor.damage
        if totalForPercent == 0 then totalForPercent = 1 end

        for i = 1, math.min(5, #sortedAbilities) do
            local ability = sortedAbilities[i]
            local abilityValue = ability[sortKey] or 0
            if abilityValue > 0 then
                local percent = (abilityValue / totalForPercent) * 100
                GameTooltip:AddDoubleLine(
                    ability.name or "Unknown",
                    string.format("%s (%.1f%%)", Utils.FormatNumber(abilityValue), percent),
                    0.7, 0.7, 1, 1, 1, 1
                )
            end
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click for details | Right-click for menu", 0.5, 0.5, 0.5)

    GameTooltip:Show()
end

-- Update all instances
function UI:UpdateAll()
    for _, instance in pairs(self.instances) do
        if instance.frame and instance.frame:IsShown() then
            instance:UpdateBars()
        end
    end
end

-- Refresh all (force full redraw)
function UI:Refresh()
    self:UpdateAll()
end

-- Apply settings to all instances
function UI:ApplySettings()
    -- Initialize skins if needed
    if Skins and Skins.Initialize then
        Skins:Initialize()
    end

    -- Get profile settings
    local profile = EDM.db and EDM.db.profile or {}
    local windowDb = profile.window or {}
    local barsDb = profile.bars or {}

    -- Get skin settings
    local skin = Skins and Skins:Get() or nil
    local barSettings = skin and skin.bar or {}

    -- Get bar texture from skin
    local barTexture = "Interface\\TargetingFrame\\UI-StatusBar"
    if barSettings.texture then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            local tex = LSM:Fetch("statusbar", barSettings.texture)
            if tex then barTexture = tex end
        end
    end

    -- Get font settings
    local fontName = barsDb.font or "Friz Quadrata TT"
    local fontPaths = {
        ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
        ["Skurri"] = "Fonts\\SKURRI.TTF",
        ["2002"] = "Fonts\\2002.TTF",
        ["2002 Bold"] = "Fonts\\2002B.TTF",
    }
    local fontPath = fontPaths[fontName] or "Fonts\\FRIZQT__.TTF"
    local fontSize = barsDb.fontSize or 11
    local fontFlags = barsDb.fontFlags or "OUTLINE"
    local barHeight = barsDb.height or 18

    -- Update bar pool with settings
    for _, bar in ipairs(self.barPool) do
        bar.statusBar:SetStatusBarTexture(barTexture)
        bar:SetHeight(barHeight)
        bar.icon:SetSize(barHeight - 2, barHeight - 2)
        bar.icon:SetShown(barsDb.showIcon ~= false)

        -- Apply font settings
        bar.nameText:SetFont(fontPath, fontSize, fontFlags)
        bar.valueText:SetFont(fontPath, fontSize - 1, fontFlags)
        bar.rankText:SetFont(fontPath, fontSize - 2, fontFlags)
        bar.rankText:SetShown(barsDb.showRank ~= false)
    end

    -- Apply settings to all instances
    for _, instance in pairs(self.instances) do
        -- Apply window background color from profile
        local bgColor = windowDb.backgroundColor or {r = 0.05, g = 0.05, b = 0.08, a = 0.92}
        local borderColor = windowDb.borderColor or {r = 0.15, g = 0.15, b = 0.2, a = 1}
        local showBackground = windowDb.showBackground ~= false

        if showBackground then
            instance.frame:SetBackdropColor(bgColor.r or 0.05, bgColor.g or 0.05, bgColor.b or 0.08, bgColor.a or 0.92)
        else
            instance.frame:SetBackdropColor(0, 0, 0, 0)
        end
        instance.frame:SetBackdropBorderColor(borderColor.r or 0.15, borderColor.g or 0.15, borderColor.b or 0.2, borderColor.a or 1)

        -- Apply window size settings
        if windowDb.width and windowDb.height then
            instance.frame:SetSize(windowDb.width, windowDb.height)
        end
        if windowDb.scale then
            instance.frame:SetScale(windowDb.scale)
        end
        if windowDb.opacity then
            instance.frame:SetAlpha(windowDb.opacity)
        end

        -- Apply title bar visibility
        if instance.titleBar then
            instance.titleBar:SetShown(windowDb.showTitle ~= false)
        end

        -- Apply skin overrides if available
        if skin and skin.window then
            local w = skin.window
            if showBackground then
                instance.frame:SetBackdropColor(w.backgroundColor.r, w.backgroundColor.g, w.backgroundColor.b, w.backgroundColor.a)
            end
            instance.frame:SetBackdropBorderColor(w.borderColor.r, w.borderColor.g, w.borderColor.b, w.borderColor.a)
        end
        if skin and skin.titleBar then
            local tb = skin.titleBar
            instance.titleBar.bg:SetColorTexture(tb.backgroundColor.r, tb.backgroundColor.g, tb.backgroundColor.b, tb.backgroundColor.a)
            instance.titleText:SetFont(tb.font or fontPath, tb.fontSize or 11, tb.fontFlags or fontFlags)
        end

        instance:UpdateLayout()
    end
end

-- Set locked state for all instances
function UI:SetLocked(locked)
    for _, instance in pairs(self.instances) do
        if locked then
            instance.frame:SetMovable(false)
            if instance.resizeHandle then
                instance.resizeHandle:Hide()
            end
        else
            instance.frame:SetMovable(true)
            if instance.resizeHandle then
                instance.resizeHandle:Show()
            end
        end
    end
end

-- Toggle visibility
function UI:Toggle()
    for _, instance in pairs(self.instances) do
        if instance.frame:IsShown() then
            instance.frame:Hide()
        else
            instance.frame:Show()
            instance:UpdateBars()
        end
    end
end

-- Legacy compatibility
function UI:UpdateBars()
    self:UpdateAll()
end
