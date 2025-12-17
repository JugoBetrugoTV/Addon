--[[
    EpicDamageMeter - Main Frame
    Primary UI window
]]

local ADDON_NAME, EDM = ...

EDM.UI = {}
local UI = EDM.UI
local Skins = EDM.Skins
local Widgets = EDM.Widgets
local Bars = EDM.Bars
local Graph = EDM.Graph
local Utils = EDM.Utils
local C = EDM.Constants
local DB = EDM.Database

-- UI state
UI.mainFrame = nil
UI.titleBar = nil
UI.contentFrame = nil
UI.scrollFrame = nil
UI.bars = {}
UI.graphFrame = nil
UI.initialized = false

-- Initialize UI
function UI:Initialize()
    if self.initialized then return end

    -- Create main frame
    self:CreateMainFrame()

    -- Create graph frame
    self:CreateGraphFrame()

    -- Apply initial settings
    self:ApplySettings()

    self.initialized = true
    Utils.Debug("UI initialized")
end

-- Create main frame
function UI:CreateMainFrame()
    local skin = Skins:Get()

    -- Main frame
    self.mainFrame = CreateFrame("Frame", "EpicDamageMeterFrame", UIParent, "BackdropTemplate")
    self.mainFrame:SetSize(
        EDM.db.profile.window.width,
        EDM.db.profile.window.height
    )
    self.mainFrame:SetPoint(
        EDM.db.profile.window.point,
        UIParent,
        EDM.db.profile.window.point,
        EDM.db.profile.window.x,
        EDM.db.profile.window.y
    )
    self.mainFrame:SetFrameStrata("MEDIUM")
    self.mainFrame:SetFrameLevel(5)
    self.mainFrame:SetMovable(true)
    self.mainFrame:SetResizable(true)
    self.mainFrame:SetClampedToScreen(true)
    self.mainFrame:EnableMouse(true)

    -- Apply backdrop
    Skins:ApplyBackground(self.mainFrame)

    -- Title bar
    self.titleBar = self:CreateTitleBar()

    -- Button bar
    self.buttonBar = self:CreateButtonBar()

    -- Content area
    self.contentFrame = CreateFrame("Frame", nil, self.mainFrame)
    self.contentFrame:SetPoint("TOPLEFT", self.buttonBar, "BOTTOMLEFT", 4, -2)
    self.contentFrame:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", -4, 4)

    -- Scroll frame for bars
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.contentFrame)
    self.scrollFrame:SetAllPoints()

    self.scrollContent = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollContent:SetSize(self.contentFrame:GetWidth(), 1)
    self.scrollFrame:SetScrollChild(self.scrollContent)

    -- Enable scrolling
    self.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local current = self.scrollFrame:GetVerticalScroll()
        local max = self.scrollContent:GetHeight() - self.scrollFrame:GetHeight()
        if max < 0 then max = 0 end
        local new = current - (delta * 20)
        new = math.max(0, math.min(max, new))
        self.scrollFrame:SetVerticalScroll(new)
    end)

    -- Resize handle
    self.resizeHandle = Widgets:CreateResizeHandle(self.mainFrame, 150, 100, 600, 800)

    -- Status bar (footer)
    self.statusBar = self:CreateStatusBar()

    -- Make frame draggable
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function(f)
        if not EDM.db.profile.locked then
            f:StartMoving()
        end
    end)
    self.mainFrame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local point, _, _, x, y = f:GetPoint()
        EDM.db.profile.window.point = point
        EDM.db.profile.window.x = x
        EDM.db.profile.window.y = y
    end)

    -- Right-click menu
    self.mainFrame:SetScript("OnMouseDown", function(f, button)
        if button == "RightButton" then
            self:ShowContextMenu()
        end
    end)

    -- Show frame
    self.mainFrame:Show()
end

-- Create title bar
function UI:CreateTitleBar()
    local skin = Skins:Get()
    local titleSettings = skin and skin.titleBar or {}

    local titleBar = CreateFrame("Frame", nil, self.mainFrame)
    titleBar:SetHeight(titleSettings.height or 22)
    titleBar:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", 0, 0)

    -- Background
    titleBar.bg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBar.bg:SetAllPoints()
    titleBar.bg:SetColorTexture(
        titleSettings.backgroundColor and titleSettings.backgroundColor.r or 0.08,
        titleSettings.backgroundColor and titleSettings.backgroundColor.g or 0.08,
        titleSettings.backgroundColor and titleSettings.backgroundColor.b or 0.12,
        titleSettings.backgroundColor and titleSettings.backgroundColor.a or 0.98
    )

    -- Gradient overlay
    if titleSettings.gradientStart then
        titleBar.gradient = titleBar:CreateTexture(nil, "ARTWORK")
        titleBar.gradient:SetAllPoints()
        titleBar.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleBar.gradient:SetGradient("VERTICAL",
            CreateColor(titleSettings.gradientEnd.r, titleSettings.gradientEnd.g, titleSettings.gradientEnd.b, titleSettings.gradientEnd.a or 1),
            CreateColor(titleSettings.gradientStart.r, titleSettings.gradientStart.g, titleSettings.gradientStart.b, titleSettings.gradientStart.a or 1)
        )
    end

    -- Icon
    titleBar.icon = titleBar:CreateTexture(nil, "ARTWORK")
    titleBar.icon:SetSize(16, 16)
    titleBar.icon:SetPoint("LEFT", titleBar, "LEFT", 4, 0)
    titleBar.icon:SetTexture("Interface\\AddOns\\EpicDamageMeter\\Textures\\icon")

    -- Title text
    titleBar.title = titleBar:CreateFontString(nil, "OVERLAY")
    titleBar.title:SetPoint("LEFT", titleBar.icon, "RIGHT", 4, 0)
    titleBar.title:SetFont(
        titleSettings.font or "Fonts\\FRIZQT__.TTF",
        titleSettings.fontSize or 12,
        titleSettings.fontFlags or "OUTLINE"
    )
    titleBar.title:SetTextColor(
        titleSettings.fontColor and titleSettings.fontColor.r or 1,
        titleSettings.fontColor and titleSettings.fontColor.g or 1,
        titleSettings.fontColor and titleSettings.fontColor.b or 1,
        titleSettings.fontColor and titleSettings.fontColor.a or 1
    )
    titleBar.title:SetText(EDM.Core and EDM.Core:GetDisplayModeName() or "Damage Done")

    -- Close button
    titleBar.closeBtn = Widgets:CreateCloseButton(titleBar, 14, function()
        self.mainFrame:Hide()
    end)
    titleBar.closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)

    -- Settings button
    titleBar.settingsBtn = Widgets:CreateSettingsButton(titleBar, 14, function()
        if EDM.Core then
            EDM.Core:OpenConfig()
        end
    end)
    titleBar.settingsBtn:SetPoint("RIGHT", titleBar.closeBtn, "LEFT", -4, 0)

    -- Reset button
    titleBar.resetBtn = Widgets:CreateResetButton(titleBar, 14, function()
        if EDM.Core then
            EDM.Core:Reset()
        end
    end)
    titleBar.resetBtn:SetPoint("RIGHT", titleBar.settingsBtn, "LEFT", -4, 0)

    -- Make draggable
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not EDM.db.profile.locked then
            self.mainFrame:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        self.mainFrame:StopMovingOrSizing()
        local point, _, _, x, y = self.mainFrame:GetPoint()
        EDM.db.profile.window.point = point
        EDM.db.profile.window.x = x
        EDM.db.profile.window.y = y
    end)

    return titleBar
end

-- Create button bar
function UI:CreateButtonBar()
    local buttonBar = CreateFrame("Frame", nil, self.mainFrame)
    buttonBar:SetHeight(18)
    buttonBar:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", 0, 0)
    buttonBar:SetPoint("TOPRIGHT", self.titleBar, "BOTTOMRIGHT", 0, 0)

    buttonBar.bg = buttonBar:CreateTexture(nil, "BACKGROUND")
    buttonBar.bg:SetAllPoints()
    buttonBar.bg:SetColorTexture(0.05, 0.05, 0.08, 0.9)

    -- Mode dropdown label
    buttonBar.modeLabel = buttonBar:CreateFontString(nil, "OVERLAY")
    buttonBar.modeLabel:SetPoint("LEFT", buttonBar, "LEFT", 4, 0)
    buttonBar.modeLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    buttonBar.modeLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    buttonBar.modeLabel:SetText("Mode:")

    -- Mode button
    buttonBar.modeBtn = Widgets:CreateTextButton(buttonBar, "Damage", 80, 16, function()
        if EDM.Core then
            EDM.Core:CycleDisplayMode()
            buttonBar.modeBtn.text:SetText(EDM.Core:GetDisplayModeName())
            self.titleBar.title:SetText(EDM.Core:GetDisplayModeName())
        end
    end)
    buttonBar.modeBtn:SetPoint("LEFT", buttonBar.modeLabel, "RIGHT", 4, 0)

    -- Segment dropdown label
    buttonBar.segmentLabel = buttonBar:CreateFontString(nil, "OVERLAY")
    buttonBar.segmentLabel:SetPoint("LEFT", buttonBar.modeBtn, "RIGHT", 8, 0)
    buttonBar.segmentLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    buttonBar.segmentLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    buttonBar.segmentLabel:SetText("Seg:")

    -- Segment button
    buttonBar.segmentBtn = Widgets:CreateTextButton(buttonBar, "Current", 60, 16, function()
        -- Toggle between current and overall
        if EDM.db.profile.display.segment == C.SEGMENT_TYPE.OVERALL then
            EDM.db.profile.display.segment = C.SEGMENT_TYPE.CURRENT
            buttonBar.segmentBtn.text:SetText("Current")
        else
            EDM.db.profile.display.segment = C.SEGMENT_TYPE.OVERALL
            buttonBar.segmentBtn.text:SetText("Overall")
        end
        self:Refresh()
    end)
    buttonBar.segmentBtn:SetPoint("LEFT", buttonBar.segmentLabel, "RIGHT", 4, 0)

    -- Graph toggle button
    buttonBar.graphBtn = Widgets:CreateTextButton(buttonBar, "Graph", 50, 16, function()
        if Graph.frame then
            Graph:Toggle()
        end
    end)
    buttonBar.graphBtn:SetPoint("RIGHT", buttonBar, "RIGHT", -4, 0)

    return buttonBar
end

-- Create status bar
function UI:CreateStatusBar()
    local statusBar = CreateFrame("Frame", nil, self.mainFrame)
    statusBar:SetHeight(14)
    statusBar:SetPoint("BOTTOMLEFT", self.mainFrame, "BOTTOMLEFT", 0, 0)
    statusBar:SetPoint("BOTTOMRIGHT", self.mainFrame, "BOTTOMRIGHT", 0, 0)

    statusBar.bg = statusBar:CreateTexture(nil, "BACKGROUND")
    statusBar.bg:SetAllPoints()
    statusBar.bg:SetColorTexture(0.05, 0.05, 0.08, 0.9)

    -- Time text
    statusBar.timeText = statusBar:CreateFontString(nil, "OVERLAY")
    statusBar.timeText:SetPoint("LEFT", statusBar, "LEFT", 4, 0)
    statusBar.timeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    statusBar.timeText:SetTextColor(0.7, 0.7, 0.7, 1)
    statusBar.timeText:SetText("0:00")

    -- Total text
    statusBar.totalText = statusBar:CreateFontString(nil, "OVERLAY")
    statusBar.totalText:SetPoint("RIGHT", statusBar, "RIGHT", -4, 0)
    statusBar.totalText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    statusBar.totalText:SetTextColor(0.7, 0.7, 0.7, 1)
    statusBar.totalText:SetText("Total: 0")

    return statusBar
end

-- Create graph frame
function UI:CreateGraphFrame()
    self.graphFrame = Graph:Initialize(self.mainFrame)
end

-- Update bars with data
function UI:UpdateBars()
    if not self.mainFrame or not self.mainFrame:IsShown() then return end

    local mode = EDM.db.profile.display.mode
    local segmentType = EDM.db.profile.display.segment

    -- Get segment
    local segment
    if segmentType == C.SEGMENT_TYPE.OVERALL then
        segment = DB.Data.overallSegment
    else
        segment = DB.Data.currentSegment
    end

    if not segment then return end

    -- Get sorted actors
    local actors = DB:GetSortedActors(segment, mode)
    local duration = DB:GetSegmentDuration(segment)

    -- Get max value for percentage calculations
    local total = 0
    if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
        total = segment.totalDamage
    elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
        total = segment.totalHealing
    else
        for _, actor in ipairs(actors) do
            local value = 0
            if mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
                value = actor.damageTaken
            elseif mode == C.DISPLAY_MODE.DEATHS then
                value = actor.deaths
            elseif mode == C.DISPLAY_MODE.INTERRUPTS then
                value = actor.interrupts
            elseif mode == C.DISPLAY_MODE.DISPELS then
                value = actor.dispels
            end
            total = total + value
        end
    end

    if total == 0 then total = 1 end -- Prevent division by zero

    -- Get top actor's value for relative bar sizing
    local topValue = 0
    if #actors > 0 then
        local topActor = actors[1]
        if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
            topValue = topActor.damage
        elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
            topValue = topActor.healing
        elseif mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
            topValue = topActor.damageTaken
        elseif mode == C.DISPLAY_MODE.DEATHS then
            topValue = topActor.deaths
        elseif mode == C.DISPLAY_MODE.INTERRUPTS then
            topValue = topActor.interrupts
        elseif mode == C.DISPLAY_MODE.DISPELS then
            topValue = topActor.dispels
        end
    end
    if topValue == 0 then topValue = 1 end

    -- Update or create bars
    local maxBars = EDM.db.profile.display.maxBars or 20
    local barCount = math.min(#actors, maxBars)

    for i = 1, barCount do
        local actor = actors[i]
        local bar = Bars:GetBar(self.scrollContent, i)

        Bars:SetBarData(bar, actor, i, topValue, duration, mode)
        Bars:AnimateBar(bar)

        table.insert(self.bars, bar)
    end

    -- Hide extra bars
    for i = barCount + 1, #Bars.pool do
        if Bars.pool[i] then
            Bars:ReleaseBar(Bars.pool[i])
        end
    end

    -- Layout bars
    local contentHeight = Bars:LayoutBars(self.scrollContent, self.bars)
    self.scrollContent:SetHeight(contentHeight)

    -- Update status bar
    self.statusBar.timeText:SetText(Utils.FormatTime(duration))
    self.statusBar.totalText:SetText("Total: " .. Utils.FormatNumber(total))

    -- Update graph
    Graph:Update()
end

-- Refresh UI
function UI:Refresh()
    -- Clear existing bars
    for _, bar in ipairs(self.bars) do
        Bars:ReleaseBar(bar)
    end
    wipe(self.bars)

    -- Update bars
    self:UpdateBars()

    -- Update title
    if self.titleBar and self.titleBar.title and EDM.Core then
        self.titleBar.title:SetText(EDM.Core:GetDisplayModeName())
    end

    -- Update mode button
    if self.buttonBar and self.buttonBar.modeBtn and EDM.Core then
        self.buttonBar.modeBtn.text:SetText(EDM.Core:GetDisplayModeName())
    end
end

-- Apply settings
function UI:ApplySettings()
    if not self.mainFrame then return end

    -- Update size
    self.mainFrame:SetSize(
        EDM.db.profile.window.width,
        EDM.db.profile.window.height
    )

    -- Update scale
    self.mainFrame:SetScale(EDM.db.profile.window.scale or 1)

    -- Update opacity
    local opacity = EDM.db.profile.window.opacity or 0.9
    self.mainFrame:SetAlpha(opacity)

    -- Apply skin
    Skins:ApplyBackground(self.mainFrame)

    -- Update bars appearance
    Bars:ApplySettings()

    -- Lock/unlock
    self:SetLocked(EDM.db.profile.locked)

    -- Refresh
    self:Refresh()
end

-- Set locked state
function UI:SetLocked(locked)
    if not self.mainFrame then return end

    if locked then
        self.mainFrame:SetMovable(false)
        self.mainFrame:SetResizable(false)
        if self.resizeHandle then
            self.resizeHandle:Hide()
        end
    else
        self.mainFrame:SetMovable(true)
        self.mainFrame:SetResizable(true)
        if self.resizeHandle then
            self.resizeHandle:Show()
        end
    end
end

-- Show context menu
function UI:ShowContextMenu()
    local menu = CreateFrame("Frame", "EDMContextMenu", UIParent, "UIDropDownMenuTemplate")

    local menuList = {
        { text = "EpicDamageMeter", isTitle = true, notCheckable = true },
        { text = "", notCheckable = true, disabled = true },
        { text = "Display Mode", notCheckable = true, hasArrow = true, menuList = {
            { text = "Damage Done", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.DAMAGE_DONE) end },
            { text = "Healing Done", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.HEALING_DONE) end },
            { text = "DPS", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.DPS) end },
            { text = "HPS", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.HPS) end },
            { text = "Damage Taken", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.DAMAGE_TAKEN) end },
            { text = "Deaths", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.DEATHS) end },
            { text = "Interrupts", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.INTERRUPTS) end },
            { text = "Dispels", func = function() EDM.Core:SetDisplayMode(C.DISPLAY_MODE.DISPELS) end },
        }},
        { text = "", notCheckable = true, disabled = true },
        { text = "Toggle Graph", notCheckable = true, func = function() Graph:Toggle() end },
        { text = "Reset Data", notCheckable = true, func = function() EDM.Core:Reset() end },
        { text = "", notCheckable = true, disabled = true },
        { text = EDM.db.profile.locked and "Unlock Window" or "Lock Window", notCheckable = true, func = function()
            EDM.Core:ToggleLock()
        end },
        { text = "Settings", notCheckable = true, func = function() EDM.Core:OpenConfig() end },
        { text = "", notCheckable = true, disabled = true },
        { text = "Close", notCheckable = true, func = function() self.mainFrame:Hide() end },
    }

    EasyMenu(menuList, menu, "cursor", 0, 0, "MENU")
end

-- Toggle window
function UI:Toggle()
    if self.mainFrame then
        if self.mainFrame:IsShown() then
            self.mainFrame:Hide()
        else
            self.mainFrame:Show()
            self:Refresh()
        end
    end
end
