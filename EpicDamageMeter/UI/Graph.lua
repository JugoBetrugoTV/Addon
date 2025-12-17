--[[
    EpicDamageMeter - Graph
    Real-time graph visualization
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
Graph.maxPoints = 300
Graph.updateInterval = 1
Graph.lastUpdate = 0

-- Line data
Graph.lines = {
    damage = {},
    healing = {},
}

-- Initialize graph
function Graph:Initialize(parent)
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    -- Create graph frame
    self.frame = CreateFrame("Frame", "EDMGraphFrame", parent or UIParent, "BackdropTemplate")
    self.frame:SetSize(
        EDM.db and EDM.db.profile.graph.width or 400,
        EDM.db and EDM.db.profile.graph.height or 200
    )
    self.frame:SetPoint("TOPLEFT", parent or UIParent, "TOPRIGHT", 5, 0)
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(10)
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(true)

    -- Apply backdrop
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    self.frame:SetBackdropColor(
        graphSettings.backgroundColor and graphSettings.backgroundColor.r or 0.03,
        graphSettings.backgroundColor and graphSettings.backgroundColor.g or 0.03,
        graphSettings.backgroundColor and graphSettings.backgroundColor.b or 0.05,
        graphSettings.backgroundColor and graphSettings.backgroundColor.a or 0.95
    )
    self.frame:SetBackdropBorderColor(0.2, 0.2, 0.3, 1)

    -- Title bar
    self.titleBar = Widgets:CreateTitleBar(self.frame, "DPS/HPS Graph", 20)

    -- Close button
    self.closeButton = Widgets:CreateCloseButton(self.titleBar, 14)
    self.closeButton:SetPoint("RIGHT", self.titleBar, "RIGHT", -4, 0)

    -- Canvas for drawing
    self.canvas = CreateFrame("Frame", nil, self.frame)
    self.canvas:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 40, -25)
    self.canvas:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -10, 30)

    -- Create grid lines
    self:CreateGrid()

    -- Create axis labels
    self:CreateAxisLabels()

    -- Create legend
    self:CreateLegend()

    -- Line textures pool
    self.linePool = {}

    -- Make draggable
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)
    self.frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
    end)

    -- Initially hidden
    self.frame:Hide()

    return self.frame
end

-- Create grid lines
function Graph:CreateGrid()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}
    local gridColor = graphSettings.gridColor or { r = 0.15, g = 0.15, b = 0.2, a = 0.5 }

    self.gridLines = {}

    -- Horizontal lines (5 lines)
    for i = 0, 4 do
        local line = self.canvas:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(gridColor.r, gridColor.g, gridColor.b, gridColor.a)
        line:SetHeight(1)
        self.gridLines[#self.gridLines + 1] = line
    end

    -- Vertical lines (10 lines)
    for i = 0, 9 do
        local line = self.canvas:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(gridColor.r, gridColor.g, gridColor.b, gridColor.a * 0.5)
        line:SetWidth(1)
        self.gridLines[#self.gridLines + 1] = line
    end
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
end

-- Create axis labels
function Graph:CreateAxisLabels()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    -- Y-axis labels (values)
    self.yLabels = {}
    for i = 0, 4 do
        local label = self.frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", graphSettings.legendFontSize or 10, "")
        label:SetTextColor(0.7, 0.7, 0.7, 1)
        label:SetJustifyH("RIGHT")
        self.yLabels[i] = label
    end

    -- X-axis labels (time)
    self.xLabels = {}
    for i = 0, 5 do
        local label = self.frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", graphSettings.legendFontSize or 10, "")
        label:SetTextColor(0.7, 0.7, 0.7, 1)
        label:SetJustifyH("CENTER")
        self.xLabels[i] = label
    end

    -- Y-axis title
    self.yTitle = self.frame:CreateFontString(nil, "OVERLAY")
    self.yTitle:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", graphSettings.legendFontSize or 10, "")
    self.yTitle:SetTextColor(0.8, 0.8, 0.8, 1)
    self.yTitle:SetText("Value")
    self.yTitle:SetPoint("LEFT", self.frame, "LEFT", 5, 0)

    -- X-axis title
    self.xTitle = self.frame:CreateFontString(nil, "OVERLAY")
    self.xTitle:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", graphSettings.legendFontSize or 10, "")
    self.xTitle:SetTextColor(0.8, 0.8, 0.8, 1)
    self.xTitle:SetText("Time")
    self.xTitle:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 5)
end

-- Position axis labels
function Graph:LayoutAxisLabels(maxValue, duration)
    local width = self.canvas:GetWidth()
    local height = self.canvas:GetHeight()

    -- Y-axis labels
    for i = 0, 4 do
        local label = self.yLabels[i]
        local y = (i / 4) * height
        label:ClearAllPoints()
        label:SetPoint("RIGHT", self.canvas, "LEFT", -4, y - height/2)
        label:SetText(Utils.FormatNumber((i / 4) * maxValue))
    end

    -- X-axis labels
    for i = 0, 5 do
        local label = self.xLabels[i]
        local x = (i / 5) * width
        label:ClearAllPoints()
        label:SetPoint("TOP", self.canvas, "BOTTOMLEFT", x, -4)
        local time = (i / 5) * duration
        label:SetText(Utils.FormatTime(time))
    end
end

-- Create legend
function Graph:CreateLegend()
    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    self.legend = CreateFrame("Frame", nil, self.frame)
    self.legend:SetSize(150, 40)
    self.legend:SetPoint("TOPRIGHT", self.titleBar, "TOPRIGHT", -30, 0)

    -- Damage legend
    self.legend.damageBox = self.legend:CreateTexture(nil, "ARTWORK")
    self.legend.damageBox:SetSize(12, 12)
    self.legend.damageBox:SetPoint("TOPLEFT", 0, -4)
    self.legend.damageBox:SetColorTexture(
        graphSettings.damageColor and graphSettings.damageColor.r or 0.9,
        graphSettings.damageColor and graphSettings.damageColor.g or 0.2,
        graphSettings.damageColor and graphSettings.damageColor.b or 0.2,
        1
    )

    self.legend.damageLabel = self.legend:CreateFontString(nil, "OVERLAY")
    self.legend.damageLabel:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", 9, "")
    self.legend.damageLabel:SetPoint("LEFT", self.legend.damageBox, "RIGHT", 4, 0)
    self.legend.damageLabel:SetText("DPS")
    self.legend.damageLabel:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Healing legend
    self.legend.healingBox = self.legend:CreateTexture(nil, "ARTWORK")
    self.legend.healingBox:SetSize(12, 12)
    self.legend.healingBox:SetPoint("TOPLEFT", 70, -4)
    self.legend.healingBox:SetColorTexture(
        graphSettings.healingColor and graphSettings.healingColor.r or 0.2,
        graphSettings.healingColor and graphSettings.healingColor.g or 0.9,
        graphSettings.healingColor and graphSettings.healingColor.b or 0.2,
        1
    )

    self.legend.healingLabel = self.legend:CreateFontString(nil, "OVERLAY")
    self.legend.healingLabel:SetFont(graphSettings.legendFont or "Fonts\\FRIZQT__.TTF", 9, "")
    self.legend.healingLabel:SetPoint("LEFT", self.legend.healingBox, "RIGHT", 4, 0)
    self.legend.healingLabel:SetText("HPS")
    self.legend.healingLabel:SetTextColor(0.9, 0.9, 0.9, 1)
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

    -- Create new line
    local line = self.canvas:CreateLine(nil, "ARTWORK")
    line:SetThickness(2)
    line.inUse = true
    table.insert(self.linePool, line)
    return line
end

-- Release all line textures
function Graph:ReleaseLines()
    for _, line in ipairs(self.linePool) do
        line.inUse = false
        line:Hide()
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

-- Draw the graph
function Graph:Draw()
    if not self.frame or not self.frame:IsShown() then return end
    if #self.dataPoints < 2 then return end

    self:ReleaseLines()
    self:LayoutGrid()

    local skin = Skins:Get()
    local graphSettings = skin and skin.graph or {}

    local width = self.canvas:GetWidth()
    local height = self.canvas:GetHeight()

    -- Find max values
    local maxDPS = 0
    local maxHPS = 0
    local startTime = self.dataPoints[1].time
    local endTime = self.dataPoints[#self.dataPoints].time
    local duration = endTime - startTime

    for _, point in ipairs(self.dataPoints) do
        if point.dps > maxDPS then maxDPS = point.dps end
        if point.hps > maxHPS then maxHPS = point.hps end
    end

    local maxValue = math.max(maxDPS, maxHPS)
    if maxValue == 0 then maxValue = 1 end

    -- Update axis labels
    self:LayoutAxisLabels(maxValue, duration)

    -- Draw DPS line
    local lastX, lastY
    for i, point in ipairs(self.dataPoints) do
        local x = ((point.time - startTime) / duration) * width
        local y = (point.dps / maxValue) * height

        if lastX and lastY then
            local line = self:GetLineTexture()
            line:SetColorTexture(
                graphSettings.damageColor and graphSettings.damageColor.r or 0.9,
                graphSettings.damageColor and graphSettings.damageColor.g or 0.2,
                graphSettings.damageColor and graphSettings.damageColor.b or 0.2,
                1
            )
            line:SetThickness(graphSettings.lineWidth or 2)
            line:SetStartPoint("BOTTOMLEFT", self.canvas, lastX, lastY)
            line:SetEndPoint("BOTTOMLEFT", self.canvas, x, y)
        end

        lastX, lastY = x, y
    end

    -- Draw HPS line
    lastX, lastY = nil, nil
    for i, point in ipairs(self.dataPoints) do
        local x = ((point.time - startTime) / duration) * width
        local y = (point.hps / maxValue) * height

        if lastX and lastY then
            local line = self:GetLineTexture()
            line:SetColorTexture(
                graphSettings.healingColor and graphSettings.healingColor.r or 0.2,
                graphSettings.healingColor and graphSettings.healingColor.g or 0.9,
                graphSettings.healingColor and graphSettings.healingColor.b or 0.2,
                1
            )
            line:SetThickness(graphSettings.lineWidth or 2)
            line:SetStartPoint("BOTTOMLEFT", self.canvas, lastX, lastY)
            line:SetEndPoint("BOTTOMLEFT", self.canvas, x, y)
        end

        lastX, lastY = x, y
    end
end

-- Update graph with current data
function Graph:Update()
    if not self.frame or not self.frame:IsShown() then return end

    local now = GetTime()
    if now - self.lastUpdate < self.updateInterval then return end
    self.lastUpdate = now

    -- Get current segment data
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    if not segment then return end

    local duration = DB:GetSegmentDuration(segment)
    if duration == 0 then return end

    -- Calculate total DPS/HPS
    local totalDPS = segment.totalDamage / duration
    local totalHPS = segment.totalHealing / duration

    -- Add data point
    self:AddDataPoint(now, totalDPS, totalHPS)

    -- Redraw
    self:Draw()
end

-- Clear graph data
function Graph:Clear()
    wipe(self.dataPoints)
    self:ReleaseLines()
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
