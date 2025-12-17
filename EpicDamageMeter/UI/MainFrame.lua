--[[
    EpicDamageMeter - Main Frame (Rewritten)
    Multi-window support with proper bar management
]]

local ADDON_NAME, EDM = ...

EDM.UI = {}
local UI = EDM.UI
local Skins = EDM.Skins
local Widgets = EDM.Widgets
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
UI.barPoolIndex = 0

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

    -- Create the window frame
    self:CreateFrame(parent)

    return self
end

function Instance:CreateFrame(parent)
    local skin = Skins:Get()
    local db = EDM.db and EDM.db.profile or C.DEFAULT_SETTINGS.profile

    -- Calculate position offset for new windows
    local offsetX = (self.id - 1) * 20
    local offsetY = (self.id - 1) * -20

    -- Main frame
    self.frame = CreateFrame("Frame", "EDMInstance" .. self.id, parent or UIParent, "BackdropTemplate")
    self.frame:SetSize(db.window.width or 280, db.window.height or 200)
    self.frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(5 + self.id)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:SetClampedToScreen(true)
    self.frame:EnableMouse(true)
    self.frame.instance = self

    -- Apply backdrop
    Skins:ApplyBackground(self.frame)

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
    local skin = Skins:Get()
    local ts = skin and skin.titleBar or {}

    self.titleBar = CreateFrame("Frame", nil, self.frame)
    self.titleBar:SetHeight(ts.height or 22)
    self.titleBar:SetPoint("TOPLEFT", 0, 0)
    self.titleBar:SetPoint("TOPRIGHT", 0, 0)

    -- Background
    self.titleBar.bg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    self.titleBar.bg:SetAllPoints()
    self.titleBar.bg:SetColorTexture(
        ts.backgroundColor and ts.backgroundColor.r or 0.08,
        ts.backgroundColor and ts.backgroundColor.g or 0.08,
        ts.backgroundColor and ts.backgroundColor.b or 0.12,
        ts.backgroundColor and ts.backgroundColor.a or 0.98
    )

    -- Title text
    self.titleText = self.titleBar:CreateFontString(nil, "OVERLAY")
    self.titleText:SetPoint("LEFT", 8, 0)
    self.titleText:SetFont(ts.font or "Fonts\\FRIZQT__.TTF", ts.fontSize or 11, ts.fontFlags or "OUTLINE")
    self.titleText:SetTextColor(ts.fontColor and ts.fontColor.r or 1, ts.fontColor and ts.fontColor.g or 1, ts.fontColor and ts.fontColor.b or 1, 1)
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

    -- New window button (under settings)
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
            EDM.Config:Open()
        end
    end)

    -- Reset button
    self.resetBtn = CreateFrame("Button", nil, self.titleBar)
    self.resetBtn:SetSize(14, 14)
    self.resetBtn:SetPoint("RIGHT", self.settingsBtn, "LEFT", -3, 0)
    self.resetBtn:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    self.resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-RefreshButton")
    self.resetBtn:GetHighlightTexture():SetVertexColor(0.3, 1, 0.3, 0.8)
    self.resetBtn:SetScript("OnClick", function()
        if EDM.Core then
            EDM.Core:Reset()
        end
    end)

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

    -- Mode selector
    self.modeBtn = CreateFrame("Button", nil, self.toolbar, "BackdropTemplate")
    self.modeBtn:SetSize(90, 16)
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
            self:CycleMode(-1)
        end
    end)
    self.modeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.modeBtn:SetScript("OnEnter", function(btn)
        btn:SetBackdropColor(0.18, 0.18, 0.22, 1)
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:AddLine("Display Mode")
        GameTooltip:AddLine("Left-click: Next mode", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Previous mode", 0.7, 0.7, 0.7)
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
            self:ShowContextMenu()
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

    -- Combat time
    self.statusBar.time = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.time:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.time:SetPoint("LEFT", 4, 0)
    self.statusBar.time:SetTextColor(0.6, 0.6, 0.6, 1)
    self.statusBar.time:SetText("0:00")

    -- Total value
    self.statusBar.total = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.total:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.total:SetPoint("RIGHT", -4, 0)
    self.statusBar.total:SetTextColor(0.6, 0.6, 0.6, 1)
    self.statusBar.total:SetText("Total: 0")

    -- Instance number
    self.statusBar.instanceNum = self.statusBar:CreateFontString(nil, "OVERLAY")
    self.statusBar.instanceNum:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.statusBar.instanceNum:SetPoint("CENTER", 0, 0)
    self.statusBar.instanceNum:SetTextColor(0.4, 0.4, 0.4, 1)
    self.statusBar.instanceNum:SetText("#" .. self.id)
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
    self.titleText:SetText(modeName)
end

function Instance:CycleMode(direction)
    direction = direction or 1
    local modes = {
        C.DISPLAY_MODE.DAMAGE_DONE,
        C.DISPLAY_MODE.HEALING_DONE,
        C.DISPLAY_MODE.DPS,
        C.DISPLAY_MODE.HPS,
        C.DISPLAY_MODE.DAMAGE_TAKEN,
        C.DISPLAY_MODE.DEATHS,
        C.DISPLAY_MODE.INTERRUPTS,
        C.DISPLAY_MODE.DISPELS,
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

    self.mode = modes[currentIndex]
    self:UpdateTitle()
    self.modeBtn.text:SetText(C.DISPLAY_MODE_NAMES[self.mode] or "Damage")
    self:UpdateBars()
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
    local maxScroll = math.max(0, #self.bars - self:GetVisibleBarCount())
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
    -- Could save per-instance positions to savedvariables
end

--============================================================================
-- BAR MANAGEMENT (Fixed scroll bug)
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

    -- Calculate totals
    local total, topValue = self:CalculateTotals(actors, segment)

    -- Update bar count (don't clear, reuse)
    local maxBars = (EDM.db and EDM.db.profile.display.maxBars) or 25
    local barCount = math.min(#actors, maxBars)

    -- Update existing bars or create new ones
    for i = 1, barCount do
        local bar = self:GetBar(i)
        local actor = actors[i]
        self:SetBarData(bar, actor, i, topValue, duration)
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

    -- Update status bar
    self.statusBar.time:SetText(Utils.FormatTime(duration))
    self.statusBar.total:SetText("Total: " .. Utils.FormatNumber(total))

    self.isUpdating = false
end

function Instance:CalculateTotals(actors, segment)
    local total = 0
    local topValue = 0

    if self.mode == C.DISPLAY_MODE.DAMAGE_DONE or self.mode == C.DISPLAY_MODE.DPS then
        total = segment.totalDamage
        topValue = actors[1] and actors[1].damage or 1
    elseif self.mode == C.DISPLAY_MODE.HEALING_DONE or self.mode == C.DISPLAY_MODE.HPS then
        total = segment.totalHealing
        topValue = actors[1] and actors[1].healing or 1
    elseif self.mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        for _, actor in ipairs(actors) do
            total = total + (actor.damageTaken or 0)
        end
        topValue = actors[1] and actors[1].damageTaken or 1
    elseif self.mode == C.DISPLAY_MODE.DEATHS then
        for _, actor in ipairs(actors) do
            total = total + (actor.deaths or 0)
        end
        topValue = actors[1] and actors[1].deaths or 1
    elseif self.mode == C.DISPLAY_MODE.INTERRUPTS then
        for _, actor in ipairs(actors) do
            total = total + (actor.interrupts or 0)
        end
        topValue = actors[1] and actors[1].interrupts or 1
    elseif self.mode == C.DISPLAY_MODE.DISPELS then
        for _, actor in ipairs(actors) do
            total = total + (actor.dispels or 0)
        end
        topValue = actors[1] and actors[1].dispels or 1
    end

    if total == 0 then total = 1 end
    if topValue == 0 then topValue = 1 end

    return total, topValue
end

function Instance:SetBarData(bar, actor, rank, topValue, duration)
    bar.actorData = actor
    bar.rank = rank

    -- Get value based on mode
    local value = 0
    local perSecond = 0

    if self.mode == C.DISPLAY_MODE.DAMAGE_DONE or self.mode == C.DISPLAY_MODE.DPS then
        value = actor.damage or 0
        perSecond = duration > 0 and (value / duration) or 0
    elseif self.mode == C.DISPLAY_MODE.HEALING_DONE or self.mode == C.DISPLAY_MODE.HPS then
        value = actor.healing or 0
        perSecond = duration > 0 and (value / duration) or 0
    elseif self.mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        value = actor.damageTaken or 0
    elseif self.mode == C.DISPLAY_MODE.DEATHS then
        value = actor.deaths or 0
    elseif self.mode == C.DISPLAY_MODE.INTERRUPTS then
        value = actor.interrupts or 0
    elseif self.mode == C.DISPLAY_MODE.DISPELS then
        value = actor.dispels or 0
    end

    -- Set bar fill (relative to top player)
    local percent = topValue > 0 and (value / topValue) or 0
    bar.statusBar:SetValue(percent)

    -- Set color
    local r, g, b = Utils.GetClassColor(actor.class)
    bar.statusBar:SetStatusBarColor(r, g, b, 0.9)

    -- Set texts
    bar.rankText:SetText(rank)
    bar.nameText:SetText(Utils.ClassColorText(actor.name or "Unknown", actor.class))

    if self.mode == C.DISPLAY_MODE.DPS or self.mode == C.DISPLAY_MODE.HPS then
        bar.valueText:SetText(Utils.FormatNumber(perSecond))
    else
        bar.valueText:SetText(Utils.FormatNumber(value))
    end

    -- Icon
    local icon = actor.class and ("Interface\\Icons\\ClassIcon_" .. actor.class) or "Interface\\Icons\\INV_Misc_QuestionMark"
    bar.icon:SetTexture(icon)
end

function Instance:LayoutBars()
    local barHeight = (EDM.db and EDM.db.profile.bars.height) or 18
    local spacing = (EDM.db and EDM.db.profile.bars.spacing) or 1
    local contentWidth = self.content:GetWidth() or 280

    local yOffset = 0
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

function Instance:ShowContextMenu()
    local menu = CreateFrame("Frame", "EDMInstanceMenu" .. self.id, UIParent, "UIDropDownMenuTemplate")

    local menuList = {
        { text = "EpicDamageMeter #" .. self.id, isTitle = true, notCheckable = true },
        { text = "", notCheckable = true, disabled = true },
        { text = "Display Mode", notCheckable = true, hasArrow = true, menuList = {} },
        { text = "", notCheckable = true, disabled = true },
        { text = "New Window", notCheckable = true, func = function() UI:CreateNewInstance() end },
        { text = "Reset Data", notCheckable = true, func = function() if EDM.Core then EDM.Core:Reset() end end },
        { text = "", notCheckable = true, disabled = true },
        { text = "Settings", notCheckable = true, func = function() if EDM.Config then EDM.Config:Open() end end },
        { text = "Close Window", notCheckable = true, func = function()
            if #UI.instances > 1 then
                UI:DestroyInstance(self.id)
            else
                self.frame:Hide()
            end
        end },
    }

    -- Add display modes
    for modeId, modeName in pairs(C.DISPLAY_MODE_NAMES) do
        table.insert(menuList[3].menuList, {
            text = modeName,
            checked = self.mode == modeId,
            func = function()
                self.mode = modeId
                self:UpdateTitle()
                self.modeBtn.text:SetText(modeName)
                self:UpdateBars()
            end,
        })
    end

    EasyMenu(menuList, menu, "cursor", 0, 0, "MENU")
end

--============================================================================
-- UI MANAGER
--============================================================================

function UI:Initialize()
    if self.initialized then return end

    -- Create initial instance
    self:CreateNewInstance(C.DISPLAY_MODE.DAMAGE_DONE)

    self.initialized = true
    Utils.Debug("UI initialized with multi-window support")
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

    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.08, 0.08, 0.1, 0.7)

    -- Status bar
    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetAllPoints()
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetValue(0)

    local texture = LSM:Fetch("statusbar", db.texture) or "Interface\\TargetingFrame\\UI-StatusBar"
    bar.statusBar:SetStatusBarTexture(texture)

    -- Icon
    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(db.height - 2, db.height - 2)
    bar.icon:SetPoint("LEFT", 1, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Rank
    bar.rankText = bar:CreateFontString(nil, "OVERLAY")
    bar.rankText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", db.fontSize - 2 or 9, db.fontFlags or "OUTLINE")
    bar.rankText:SetPoint("LEFT", bar.icon, "RIGHT", 2, 0)
    bar.rankText:SetWidth(14)
    bar.rankText:SetJustifyH("CENTER")
    bar.rankText:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Name
    bar.nameText = bar:CreateFontString(nil, "OVERLAY")
    bar.nameText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", db.fontSize or 11, db.fontFlags or "OUTLINE")
    bar.nameText:SetPoint("LEFT", bar.rankText, "RIGHT", 2, 0)
    bar.nameText:SetPoint("RIGHT", bar, "RIGHT", -50, 0)
    bar.nameText:SetJustifyH("LEFT")
    bar.nameText:SetWordWrap(false)

    -- Value
    bar.valueText = bar:CreateFontString(nil, "OVERLAY")
    bar.valueText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", db.fontSize or 11, db.fontFlags or "OUTLINE")
    bar.valueText:SetPoint("RIGHT", -4, 0)
    bar.valueText:SetJustifyH("RIGHT")

    -- Highlight
    bar.highlight = bar:CreateTexture(nil, "HIGHLIGHT")
    bar.highlight:SetAllPoints()
    bar.highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Click handlers
    bar:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                -- Report to chat
                if self.actorData then
                    local text = string.format("%d. %s - %s",
                        self.rank or 1,
                        self.actorData.name or "Unknown",
                        self.valueText:GetText() or "0"
                    )
                    print(text)
                end
            elseif self.actorData and EDM.DetailWindow then
                EDM.DetailWindow:Show(self.actorData)
            end
        end
    end)

    bar:SetScript("OnEnter", function(self)
        if self.actorData and EDM.Tooltip then
            EDM.Tooltip:ShowActorTooltip(self, self.actorData)
        end
    end)

    bar:SetScript("OnLeave", function()
        if EDM.Tooltip then
            EDM.Tooltip:Hide()
        end
    end)

    return bar
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
    -- Update bar pool textures/fonts
    local db = EDM.db and EDM.db.profile.bars or {}
    local texture = LSM:Fetch("statusbar", db.texture) or "Interface\\TargetingFrame\\UI-StatusBar"

    for _, bar in ipairs(self.barPool) do
        bar.statusBar:SetStatusBarTexture(texture)
        bar:SetHeight(db.height or 18)
        bar.icon:SetSize(db.height - 2, db.height - 2)
        bar.rankText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", (db.fontSize or 11) - 2, db.fontFlags or "OUTLINE")
        bar.nameText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", db.fontSize or 11, db.fontFlags or "OUTLINE")
        bar.valueText:SetFont(db.font or "Fonts\\FRIZQT__.TTF", db.fontSize or 11, db.fontFlags or "OUTLINE")
    end

    -- Refresh layout
    for _, instance in pairs(self.instances) do
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
