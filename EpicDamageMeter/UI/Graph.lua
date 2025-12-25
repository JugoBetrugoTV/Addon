--[[
    EpicDamageMeter - Graph (Enhanced v2)
    Beautiful real-time graph visualization with animations and glow effects
]]

local ADDON_NAME, EDM = ...

EDM.Graph = {}
local Graph = EDM.Graph
local Skins = EDM.Skins
local Utils = EDM.Utils
local C = EDM.Constants
local Widgets = EDM.Widgets

-- Graph state
Graph.frame = nil
Graph.canvas = nil
Graph.dataPoints = {}
Graph.maxPoints = 600     -- More data points for smoother graph
Graph.updateInterval = 0.2 -- Faster updates for smoother animation (was 0.5)
Graph.lastUpdate = 0
Graph.peakDPS = 0
Graph.peakHPS = 0
Graph.animationProgress = 0
Graph.isAnimating = false
Graph.smoothingEnabled = true -- Enable curve smoothing
Graph.interpolationPoints = 3 -- Points to add between each data point for smoothness

-- Line data
Graph.lines = {
    damage = {},
    healing = {},
}

-- Color presets for beautiful gradients
Graph.colors = {
    damage = {
        primary = {1.0, 0.35, 0.25, 1.0},       -- Bright red-orange
        secondary = {1.0, 0.55, 0.35, 0.8},     -- Light orange
        glow = {1.0, 0.4, 0.2, 0.4},            -- Orange glow
        fill = {1.0, 0.3, 0.2, 0.15},           -- Fill under curve
    },
    healing = {
        primary = {0.3, 1.0, 0.5, 1.0},         -- Bright green
        secondary = {0.5, 1.0, 0.65, 0.8},      -- Light green
        glow = {0.3, 1.0, 0.4, 0.4},            -- Green glow
        fill = {0.2, 1.0, 0.4, 0.15},           -- Fill under curve
    },
}

-- Initialize graph
function Graph:Initialize(parent)
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    -- Create graph frame
    self.frame = CreateFrame("Frame", "EDMGraphFrame", parent or UIParent, "BackdropTemplate")
    self.frame:SetSize(
        EDM.db and EDM.db.profile.graph.width or 450,
        EDM.db and EDM.db.profile.graph.height or 220
    )
    self.frame:SetPoint("TOPLEFT", parent or UIParent, "TOPRIGHT", 5, 0)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(10)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(true)
    self.frame:SetResizeBounds(350, 180, 900, 550)

    -- Apply beautiful backdrop with glow effect
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    self.frame:SetBackdropColor(0.02, 0.02, 0.04, 0.96)
    self.frame:SetBackdropBorderColor(0.35, 0.5, 0.8, 0.9)

    -- Inner glow effect
    self.innerGlow = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.innerGlow:SetPoint("TOPLEFT", 3, -3)
    self.innerGlow:SetPoint("BOTTOMRIGHT", -3, 3)
    self.innerGlow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.innerGlow:SetBackdropColor(0, 0, 0, 0)
    self.innerGlow:SetBackdropBorderColor(0.2, 0.35, 0.6, 0.4)

    -- Beautiful title bar with gradient
    self.titleBar = CreateFrame("Frame", nil, self.frame)
    self.titleBar:SetHeight(28)
    self.titleBar:SetPoint("TOPLEFT", 4, -4)
    self.titleBar:SetPoint("TOPRIGHT", -4, -4)

    self.titleBar.bg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    self.titleBar.bg:SetAllPoints()
    self.titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.titleBar.bg:SetGradient("VERTICAL", CreateColor(0.12, 0.18, 0.28, 1), CreateColor(0.06, 0.08, 0.14, 1))

    -- Accent line under title
    self.titleBar.accent = self.titleBar:CreateTexture(nil, "OVERLAY")
    self.titleBar.accent:SetHeight(2)
    self.titleBar.accent:SetPoint("BOTTOMLEFT", 0, 0)
    self.titleBar.accent:SetPoint("BOTTOMRIGHT", 0, 0)
    self.titleBar.accent:SetColorTexture(0.35, 0.6, 0.9, 0.8)

    -- Graph icon
    self.titleBar.icon = self.titleBar:CreateTexture(nil, "ARTWORK")
    self.titleBar.icon:SetSize(20, 20)
    self.titleBar.icon:SetPoint("LEFT", 6, 0)
    self.titleBar.icon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
    self.titleBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    self.titleBar.title = self.titleBar:CreateFontString(nil, "OVERLAY")
    self.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.titleBar.title:SetPoint("LEFT", self.titleBar.icon, "RIGHT", 8, 0)
    self.titleBar.title:SetText("|cffff6655DPS|r / |cff55ff88HPS|r |cff8899bbGraph|r")
    self.titleBar.title:SetShadowOffset(1, -1)
    self.titleBar.title:SetShadowColor(0, 0, 0, 0.8)

    -- Close button with fancy styling
    self.closeButton = CreateFrame("Button", nil, self.titleBar, "BackdropTemplate")
    self.closeButton:SetSize(22, 22)
    self.closeButton:SetPoint("RIGHT", -4, 0)
    self.closeButton:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.closeButton:SetBackdropColor(0.5, 0.1, 0.1, 0.5)
    self.closeButton:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.7)
    self.closeButton.text = self.closeButton:CreateFontString(nil, "OVERLAY")
    self.closeButton.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    self.closeButton.text:SetPoint("CENTER", 0, 1)
    self.closeButton.text:SetText("X")
    self.closeButton.text:SetTextColor(1, 0.7, 0.7, 1)
    self.closeButton:SetScript("OnClick", function() self.frame:Hide() end)
    self.closeButton:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.8, 0.2, 0.2, 0.8) end)
    self.closeButton:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.5, 0.1, 0.1, 0.5) end)

    -- Canvas for drawing with beautiful styling
    self.canvas = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.canvas:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 52, -38)
    self.canvas:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -12, 45)

    -- Canvas background with subtle gradient
    self.canvas:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    self.canvas:SetBackdropColor(0.015, 0.018, 0.025, 0.98)
    self.canvas:SetBackdropBorderColor(0.12, 0.15, 0.22, 0.8)

    -- Create gradient overlay on canvas for depth effect
    self.canvas.gradient = self.canvas:CreateTexture(nil, "BACKGROUND", nil, 1)
    self.canvas.gradient:SetAllPoints()
    self.canvas.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.canvas.gradient:SetGradient("VERTICAL", CreateColor(0.02, 0.025, 0.04, 0.6), CreateColor(0.01, 0.01, 0.015, 0.3))

    -- Create grid lines
    self:CreateGrid()

    -- Create axis labels
    self:CreateAxisLabels()

    -- Create enhanced legend
    self:CreateLegend()

    -- Line textures pool
    self.linePool = {}

    -- Fill textures pool for area under curves
    self.fillPool = {}

    -- Glow line pool for glow effects
    self.glowPool = {}

    -- Data point markers pool
    self.markerPool = {}

    -- Make draggable from titlebar
    self.titleBar:EnableMouse(true)
    self.titleBar:RegisterForDrag("LeftButton")
    self.titleBar:SetScript("OnDragStart", function() self.frame:StartMoving() end)
    self.titleBar:SetScript("OnDragStop", function() self.frame:StopMovingOrSizing() end)

    -- Resize handle with styling
    self.resizeHandle = CreateFrame("Frame", nil, self.frame)
    self.resizeHandle:SetSize(16, 16)
    self.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
    self.resizeHandle:EnableMouse(true)
    self.resizeHandle.tex = self.resizeHandle:CreateTexture(nil, "OVERLAY")
    self.resizeHandle.tex:SetAllPoints()
    self.resizeHandle.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    self.resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then self.frame:StartSizing("BOTTOMRIGHT") end
    end)
    self.resizeHandle:SetScript("OnMouseUp", function()
        self.frame:StopMovingOrSizing()
        self:Draw()
    end)

    -- No data label with nice styling
    self.noDataLabel = self.canvas:CreateFontString(nil, "OVERLAY")
    self.noDataLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    self.noDataLabel:SetPoint("CENTER")
    self.noDataLabel:SetTextColor(0.4, 0.45, 0.55, 1)
    self.noDataLabel:SetText("|cff667799Waiting for combat data...|r")
    self.noDataLabel:SetShadowOffset(1, -1)
    self.noDataLabel:SetShadowColor(0, 0, 0, 0.6)

    -- Initially hidden
    self.frame:Hide()

    return self.frame
end

-- Create beautiful grid lines
function Graph:CreateGrid()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    self.gridLines = {}

    -- Horizontal lines (5 lines) - main grid
    for i = 0, 4 do
        local line = self.canvas:CreateTexture(nil, "BACKGROUND", nil, 2)
        line:SetColorTexture(0.12, 0.15, 0.22, 0.5)
        line:SetHeight(1)
        self.gridLines[#self.gridLines + 1] = line
    end

    -- Vertical lines (10 lines) - subtle grid
    for i = 0, 9 do
        local line = self.canvas:CreateTexture(nil, "BACKGROUND", nil, 2)
        line:SetColorTexture(0.1, 0.12, 0.18, 0.3)
        line:SetWidth(1)
        self.gridLines[#self.gridLines + 1] = line
    end

    -- Zero line (more prominent)
    self.zeroLine = self.canvas:CreateTexture(nil, "BACKGROUND", nil, 3)
    self.zeroLine:SetHeight(1)
    self.zeroLine:SetColorTexture(0.2, 0.25, 0.35, 0.7)
end

-- Position grid lines
function Graph:LayoutGrid()
    local width = self.canvas:GetWidth()
    local height = self.canvas:GetHeight()

    local lineIndex = 1

    -- Horizontal lines
    for i = 0, 4 do
        local y = (i / 4) * height
        local line = self.gridLines[lineIndex]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", self.canvas, "BOTTOMLEFT", 0, y)
        line:SetPoint("TOPRIGHT", self.canvas, "BOTTOMRIGHT", 0, y)
        lineIndex = lineIndex + 1
    end

    -- Vertical lines
    for i = 0, 9 do
        local x = (i / 9) * width
        local line = self.gridLines[lineIndex]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", self.canvas, "TOPLEFT", x, 0)
        line:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x, 0)
        lineIndex = lineIndex + 1
    end

    -- Position zero line
    if self.zeroLine then
        self.zeroLine:ClearAllPoints()
        self.zeroLine:SetPoint("TOPLEFT", self.canvas, "BOTTOMLEFT", 0, 0)
        self.zeroLine:SetPoint("TOPRIGHT", self.canvas, "BOTTOMRIGHT", 0, 0)
    end
end

-- Create axis labels with nice styling
function Graph:CreateAxisLabels()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    -- Y-axis labels (values) - positioned on left side with fixed width
    self.yLabels = {}
    for i = 0, 4 do
        local label = self.frame:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        label:SetTextColor(0.65, 0.7, 0.8, 1)
        label:SetJustifyH("RIGHT")
        label:SetWidth(44)
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 0.8)
        self.yLabels[i] = label
    end

    -- X-axis labels (time) - positioned below canvas
    self.xLabels = {}
    for i = 0, 5 do
        local label = self.frame:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        label:SetTextColor(0.65, 0.7, 0.8, 1)
        label:SetJustifyH("CENTER")
        label:SetShadowOffset(1, -1)
        label:SetShadowColor(0, 0, 0, 0.8)
        self.xLabels[i] = label
    end
end

-- Position axis labels
function Graph:LayoutAxisLabels(maxValue, duration)
    local width = self.canvas:GetWidth() or 350
    local height = self.canvas:GetHeight() or 150

    -- Y-axis labels (positioned from bottom to top along left edge)
    for i = 0, 4 do
        local label = self.yLabels[i]
        local yOffset = (i / 4) * height
        label:ClearAllPoints()
        label:SetPoint("BOTTOMRIGHT", self.canvas, "BOTTOMLEFT", -4, yOffset - 6)
        local value = (i / 4) * maxValue
        if value >= 1000000 then
            label:SetText(string.format("|cffaabbcc%.1fM|r", value / 1000000))
        elseif value >= 1000 then
            label:SetText(string.format("|cffaabbcc%.1fK|r", value / 1000))
        else
            label:SetText(string.format("|cffaabbcc%.0f|r", value))
        end
    end

    -- X-axis labels (positioned left to right below canvas)
    for i = 0, 5 do
        local label = self.xLabels[i]
        local xOffset = (i / 5) * width
        label:ClearAllPoints()
        label:SetPoint("TOP", self.canvas, "BOTTOMLEFT", xOffset, -6)
        local time = (i / 5) * duration
        if time >= 60 then
            label:SetText(string.format("|cff8899aa%d:%02d|r", math.floor(time / 60), math.floor(time % 60)))
        else
            label:SetText(string.format("|cff8899aa:%02d|r", math.floor(time)))
        end
    end
end

-- Create enhanced legend with beautiful styling
function Graph:CreateLegend()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    self.legend = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.legend:SetSize(320, 28)
    self.legend:SetPoint("TOPRIGHT", self.titleBar, "TOPRIGHT", -35, 0)

    -- Damage section with glow box
    self.legend.damageFrame = CreateFrame("Frame", nil, self.legend, "BackdropTemplate")
    self.legend.damageFrame:SetSize(140, 22)
    self.legend.damageFrame:SetPoint("LEFT", 0, 0)
    self.legend.damageFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.legend.damageFrame:SetBackdropColor(0.3, 0.1, 0.1, 0.4)
    self.legend.damageFrame:SetBackdropBorderColor(0.5, 0.2, 0.2, 0.5)

    self.legend.damageBox = self.legend.damageFrame:CreateTexture(nil, "ARTWORK")
    self.legend.damageBox:SetSize(14, 14)
    self.legend.damageBox:SetPoint("LEFT", 6, 0)
    self.legend.damageBox:SetColorTexture(1.0, 0.35, 0.25, 1)

    self.legend.damageLabel = self.legend.damageFrame:CreateFontString(nil, "OVERLAY")
    self.legend.damageLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    self.legend.damageLabel:SetPoint("LEFT", self.legend.damageBox, "RIGHT", 4, 0)
    self.legend.damageLabel:SetText("|cffff8866DPS:|r")
    self.legend.damageLabel:SetShadowOffset(1, -1)

    -- Current DPS value
    self.legend.dpsValue = self.legend.damageFrame:CreateFontString(nil, "OVERLAY")
    self.legend.dpsValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    self.legend.dpsValue:SetPoint("LEFT", self.legend.damageLabel, "RIGHT", 4, 0)
    self.legend.dpsValue:SetTextColor(1, 0.6, 0.4, 1)
    self.legend.dpsValue:SetText("0")
    self.legend.dpsValue:SetShadowOffset(1, -1)

    -- Healing section with glow box
    self.legend.healingFrame = CreateFrame("Frame", nil, self.legend, "BackdropTemplate")
    self.legend.healingFrame:SetSize(140, 22)
    self.legend.healingFrame:SetPoint("LEFT", self.legend.damageFrame, "RIGHT", 6, 0)
    self.legend.healingFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.legend.healingFrame:SetBackdropColor(0.1, 0.25, 0.1, 0.4)
    self.legend.healingFrame:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.5)

    self.legend.healingBox = self.legend.healingFrame:CreateTexture(nil, "ARTWORK")
    self.legend.healingBox:SetSize(14, 14)
    self.legend.healingBox:SetPoint("LEFT", 6, 0)
    self.legend.healingBox:SetColorTexture(0.3, 1.0, 0.5, 1)

    self.legend.healingLabel = self.legend.healingFrame:CreateFontString(nil, "OVERLAY")
    self.legend.healingLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    self.legend.healingLabel:SetPoint("LEFT", self.legend.healingBox, "RIGHT", 4, 0)
    self.legend.healingLabel:SetText("|cff66ff88HPS:|r")
    self.legend.healingLabel:SetShadowOffset(1, -1)

    -- Current HPS value
    self.legend.hpsValue = self.legend.healingFrame:CreateFontString(nil, "OVERLAY")
    self.legend.hpsValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    self.legend.hpsValue:SetPoint("LEFT", self.legend.healingLabel, "RIGHT", 4, 0)
    self.legend.hpsValue:SetTextColor(0.4, 1, 0.6, 1)
    self.legend.hpsValue:SetText("0")
    self.legend.hpsValue:SetShadowOffset(1, -1)

    -- Peak values display (beautiful styling at bottom)
    self.peakFrame = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.peakFrame:SetSize(380, 22)
    self.peakFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 55, 10)
    self.peakFrame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.peakFrame:SetBackdropColor(0.05, 0.06, 0.08, 0.8)
    self.peakFrame:SetBackdropBorderColor(0.15, 0.18, 0.25, 0.6)

    self.peakLabel = self.peakFrame:CreateFontString(nil, "OVERLAY")
    self.peakLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.peakLabel:SetPoint("CENTER", 0, 0)
    self.peakLabel:SetTextColor(0.75, 0.78, 0.85, 1)
    self.peakLabel:SetText("|cff889999Peak:|r |cffff7755DPS: 0|r  |cff556677/|r  |cff55ff77HPS: 0|r")
    self.peakLabel:SetShadowOffset(1, -1)
    self.peakLabel:SetShadowColor(0, 0, 0, 0.8)
end

-- Update legend values with animation potential
function Graph:UpdateLegendValues(currentDPS, currentHPS)
    if self.legend then
        if self.legend.dpsValue then
            self.legend.dpsValue:SetText(Utils.FormatNumber(currentDPS))
        end
        if self.legend.hpsValue then
            self.legend.hpsValue:SetText(Utils.FormatNumber(currentHPS))
        end
    end
    -- Update peak values
    if currentDPS > self.peakDPS then self.peakDPS = currentDPS end
    if currentHPS > self.peakHPS then self.peakHPS = currentHPS end
    if self.peakLabel then
        self.peakLabel:SetText(string.format(
            "|cff889999Peak:|r |cffff7755DPS: %s|r  |cff556677/|r  |cff55ff77HPS: %s|r",
            Utils.FormatNumber(self.peakDPS),
            Utils.FormatNumber(self.peakHPS)))
    end
end

-- Get line texture from pool
function Graph:GetLineTexture()
    for _, line in ipairs(self.linePool) do
        if not line.inUse then
            line.inUse = true
            line:Show()
            return line
        end
    end

    -- Create new line using CreateLine API
    local line = self.canvas:CreateLine(nil, "ARTWORK", nil, 5)
    line:SetThickness(2.5)
    line.inUse = true
    table.insert(self.linePool, line)
    return line
end

-- Get glow line from pool (for glow effect under main line)
function Graph:GetGlowLine()
    for _, line in ipairs(self.glowPool) do
        if not line.inUse then
            line.inUse = true
            line:Show()
            return line
        end
    end

    -- Create new glow line
    local line = self.canvas:CreateLine(nil, "ARTWORK", nil, 4)
    line:SetThickness(6)
    line.inUse = true
    table.insert(self.glowPool, line)
    return line
end

-- Get fill texture from pool (for area under curve)
function Graph:GetFillTexture()
    for _, tex in ipairs(self.fillPool) do
        if not tex.inUse then
            tex.inUse = true
            tex:Show()
            return tex
        end
    end

    -- Create new fill texture
    local tex = self.canvas:CreateTexture(nil, "ARTWORK", nil, 2)
    tex.inUse = true
    table.insert(self.fillPool, tex)
    return tex
end

-- Release all line textures
function Graph:ReleaseLines()
    for _, line in ipairs(self.linePool) do
        line.inUse = false
        line:Hide()
    end
    for _, line in ipairs(self.glowPool) do
        line.inUse = false
        line:Hide()
    end
    for _, tex in ipairs(self.fillPool) do
        tex.inUse = false
        tex:Hide()
    end
end

-- Add data point
function Graph:AddDataPoint(timestamp, dps, hps)
    table.insert(self.dataPoints, {
        time = timestamp,
        dps = dps,
        hps = hps,
    })

    -- Trim old points
    while #self.dataPoints > self.maxPoints do
        table.remove(self.dataPoints, 1)
    end
end

-- Draw the graph with beautiful effects
function Graph:Draw()
    if not self.frame or not self.frame:IsShown() then return end

    self:ReleaseLines()
    self:LayoutGrid()

    -- Show/hide no data label
    if #self.dataPoints < 2 then
        if self.noDataLabel then self.noDataLabel:Show() end
        self:LayoutAxisLabels(100, 60) -- Default values for empty graph
        return
    end
    if self.noDataLabel then self.noDataLabel:Hide() end

    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    local width = self.canvas:GetWidth() or 350
    local height = self.canvas:GetHeight() or 150

    -- Find max values
    local maxDPS = 0
    local maxHPS = 0
    local startTime = self.dataPoints[1].time
    local endTime = self.dataPoints[#self.dataPoints].time
    local duration = math.max(endTime - startTime, 1)

    for _, point in ipairs(self.dataPoints) do
        if point.dps > maxDPS then maxDPS = point.dps end
        if point.hps > maxHPS then maxHPS = point.hps end
    end

    local maxValue = math.max(maxDPS, maxHPS)
    if maxValue == 0 then maxValue = 100 end

    -- Round up max value for cleaner labels
    local magnitude = 10 ^ math.floor(math.log10(maxValue))
    maxValue = math.ceil(maxValue / magnitude) * magnitude

    -- Update axis labels
    self:LayoutAxisLabels(maxValue, duration)

    -- Get line width from settings
    local lineWidth = EDM.db and EDM.db.profile.graph.lineWidth or graphSettings.lineWidth or 2.5

    -- Draw fill areas first (under the lines)
    self:DrawFillArea(self.dataPoints, startTime, duration, width, height, maxValue, "dps", self.colors.damage.fill)
    self:DrawFillArea(self.dataPoints, startTime, duration, width, height, maxValue, "hps", self.colors.healing.fill)

    -- Draw glow lines (behind main lines for glow effect)
    self:DrawLine(self.dataPoints, startTime, duration, width, height, maxValue, "dps", self.colors.damage.glow, lineWidth + 4, true)
    self:DrawLine(self.dataPoints, startTime, duration, width, height, maxValue, "hps", self.colors.healing.glow, lineWidth + 4, true)

    -- Draw main lines
    self:DrawLine(self.dataPoints, startTime, duration, width, height, maxValue, "dps", self.colors.damage.primary, lineWidth, false)
    self:DrawLine(self.dataPoints, startTime, duration, width, height, maxValue, "hps", self.colors.healing.primary, lineWidth, false)
end

-- Catmull-Rom spline interpolation for smooth curves
function Graph:CatmullRom(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t

    return 0.5 * (
        (2 * p1) +
        (-p0 + p2) * t +
        (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
        (-p0 + 3 * p1 - 3 * p2 + p3) * t3
    )
end

-- Generate interpolated points for smoother curves
function Graph:InterpolatePoints(points, key, startTime, duration, width, height, maxValue)
    if #points < 2 then return {} end

    local interpolated = {}
    local numPoints = self.interpolationPoints

    for i = 1, #points do
        local point = points[i]
        local value = point[key] or 0
        local x = ((point.time - startTime) / duration) * width
        local y = math.max(1, (value / maxValue) * height)

        -- Add the original point
        table.insert(interpolated, {x = x, y = y})

        -- Add interpolated points between this and next point (for smooth curves)
        if self.smoothingEnabled and i < #points then
            -- Get control points for Catmull-Rom spline
            local p0 = points[math.max(1, i - 1)]
            local p1 = points[i]
            local p2 = points[i + 1]
            local p3 = points[math.min(#points, i + 2)]

            local v0 = (p0[key] or 0) / maxValue * height
            local v1 = (p1[key] or 0) / maxValue * height
            local v2 = (p2[key] or 0) / maxValue * height
            local v3 = (p3[key] or 0) / maxValue * height

            local x1 = ((p1.time - startTime) / duration) * width
            local x2 = ((p2.time - startTime) / duration) * width

            -- Generate intermediate points
            for j = 1, numPoints do
                local t = j / (numPoints + 1)
                local interpY = math.max(1, self:CatmullRom(v0, v1, v2, v3, t))
                local interpX = x1 + (x2 - x1) * t

                table.insert(interpolated, {x = interpX, y = interpY})
            end
        end
    end

    return interpolated
end

-- Draw a single data line with smooth curves
function Graph:DrawLine(dataPoints, startTime, duration, width, height, maxValue, key, color, lineWidth, isGlow)
    -- Get interpolated points for smooth curves
    local points = self:InterpolatePoints(dataPoints, key, startTime, duration, width, height, maxValue)

    local lastX, lastY

    for i, point in ipairs(points) do
        local x = point.x
        local y = point.y

        if lastX and lastY then
            local line
            if isGlow then
                line = self:GetGlowLine()
            else
                line = self:GetLineTexture()
            end
            line:SetVertexColor(color[1], color[2], color[3], color[4])
            line:SetThickness(lineWidth)
            line:ClearAllPoints()
            line:SetStartPoint("BOTTOMLEFT", self.canvas, lastX, lastY)
            line:SetEndPoint("BOTTOMLEFT", self.canvas, x, y)
        end

        lastX, lastY = x, y
    end
end

-- Draw fill area under a curve with smooth gradient
function Graph:DrawFillArea(dataPoints, startTime, duration, width, height, maxValue, key, color)
    -- Use interpolated points for smoother fill
    local points = self:InterpolatePoints(dataPoints, key, startTime, duration, width, height, maxValue)

    -- Create smooth fill segments using the interpolated points
    for i = 2, #points do
        local prevPoint = points[i - 1]
        local currPoint = points[i]

        local x1 = prevPoint.x
        local y1 = prevPoint.y
        local x2 = currPoint.x
        local y2 = currPoint.y

        -- Skip if segment is too small
        if math.abs(x2 - x1) < 0.3 then
            -- Skip very small segments
        else
            -- Create a smooth fill texture for this segment
            local fill = self:GetFillTexture()
            fill:SetTexture("Interface\\Buttons\\WHITE8X8")

            -- Apply gradient alpha based on height for better visual effect
            local avgHeight = (y1 + y2) / 2
            local heightRatio = math.min(1, avgHeight / height)
            local alpha = color[4] * (0.5 + 0.5 * heightRatio) -- More visible at peaks

            fill:SetVertexColor(color[1], color[2], color[3], alpha)

            -- Position with smooth height interpolation
            fill:ClearAllPoints()
            fill:SetPoint("BOTTOMLEFT", self.canvas, "BOTTOMLEFT", x1, 0)
            fill:SetSize(math.max(1, x2 - x1 + 0.5), math.max(1, avgHeight))
        end
    end
end

-- Update graph with current data (called from timer, records data even when hidden)
function Graph:Update()
    local now = GetTime()
    if now - self.lastUpdate < self.updateInterval then return end
    self.lastUpdate = now

    -- Get current segment data
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    if not segment then return end

    local duration = DB:GetSegmentDuration(segment)
    if duration < 0.5 then return end -- Skip very short durations

    -- Calculate total DPS/HPS
    local totalDPS = segment.totalDamage / duration
    local totalHPS = segment.totalHealing / duration

    -- Add data point (always record, even if not visible)
    self:AddDataPoint(now, totalDPS, totalHPS)

    -- Update legend with current values
    self:UpdateLegendValues(totalDPS, totalHPS)

    -- Redraw only if visible
    if self.frame and self.frame:IsShown() then
        self:Draw()
    end
end

-- Clear graph data
function Graph:Clear()
    wipe(self.dataPoints)
    self:ReleaseLines()
    -- Reset peak values
    self.peakDPS = 0
    self.peakHPS = 0
    if self.peakLabel then
        self.peakLabel:SetText("|cff889999Peak:|r |cffff7755DPS: 0|r  |cff556677/|r  |cff55ff77HPS: 0|r")
    end
    self:UpdateLegendValues(0, 0)
end

-- Toggle visibility
function Graph:Toggle()
    if self.frame then
        if self.frame:IsShown() then
            self.frame:Hide()
        else
            self.frame:Show()
            self:Draw()
        end
    end
end

-- Show
function Graph:Show()
    if self.frame then
        self.frame:Show()
        self:Draw()
    end
end

-- Hide
function Graph:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
