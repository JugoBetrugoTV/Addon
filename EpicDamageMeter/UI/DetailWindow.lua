--[[
    EpicDamageMeter - Detail Window
    Detailed breakdown view for individual actors
]]

local ADDON_NAME, EDM = ...

EDM.DetailWindow = {}
local DetailWindow = EDM.DetailWindow
local Skins = EDM.Skins
local Widgets = EDM.Widgets
local Utils = EDM.Utils
local C = EDM.Constants

-- State
DetailWindow.frame = nil
DetailWindow.currentActor = nil
DetailWindow.abilityBars = {}

-- Initialize detail window
function DetailWindow:Initialize()
    if self.frame then return end

    local skin = Skins:Get()

    -- Create frame
    self.frame = CreateFrame("Frame", "EDMDetailWindow", UIParent, "BackdropTemplate")
    self.frame:SetSize(350, 400)
    self.frame:SetPoint("CENTER")
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(20)
    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(true)

    -- Apply backdrop
    Skins:ApplyBackground(self.frame)

    -- Title bar
    self.titleBar = Widgets:CreateTitleBar(self.frame, "Player Details", 24)

    -- Close button
    self.closeBtn = Widgets:CreateCloseButton(self.titleBar, 16, function()
        self.frame:Hide()
    end)
    self.closeBtn:SetPoint("RIGHT", self.titleBar, "RIGHT", -4, 0)

    -- Player header
    self.header = CreateFrame("Frame", nil, self.frame)
    self.header:SetHeight(60)
    self.header:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", 0, 0)
    self.header:SetPoint("TOPRIGHT", self.titleBar, "BOTTOMRIGHT", 0, 0)

    self.header.bg = self.header:CreateTexture(nil, "BACKGROUND")
    self.header.bg:SetAllPoints()
    self.header.bg:SetColorTexture(0.05, 0.05, 0.08, 0.95)

    -- Player icon
    self.header.icon = self.header:CreateTexture(nil, "ARTWORK")
    self.header.icon:SetSize(40, 40)
    self.header.icon:SetPoint("LEFT", self.header, "LEFT", 10, 0)

    -- Player name
    self.header.name = self.header:CreateFontString(nil, "OVERLAY")
    self.header.name:SetPoint("TOPLEFT", self.header.icon, "TOPRIGHT", 8, -2)
    self.header.name:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- Player stats
    self.header.stats = self.header:CreateFontString(nil, "OVERLAY")
    self.header.stats:SetPoint("TOPLEFT", self.header.name, "BOTTOMLEFT", 0, -4)
    self.header.stats:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    self.header.stats:SetTextColor(0.8, 0.8, 0.8, 1)

    -- Tab buttons
    self.tabFrame = CreateFrame("Frame", nil, self.frame)
    self.tabFrame:SetHeight(24)
    self.tabFrame:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, 0)
    self.tabFrame:SetPoint("TOPRIGHT", self.header, "BOTTOMRIGHT", 0, 0)

    self.tabFrame.bg = self.tabFrame:CreateTexture(nil, "BACKGROUND")
    self.tabFrame.bg:SetAllPoints()
    self.tabFrame.bg:SetColorTexture(0.08, 0.08, 0.12, 0.95)

    self.tabs = {}
    local tabNames = { "Abilities", "Targets", "Deaths" }
    local tabWidth = 80

    for i, name in ipairs(tabNames) do
        local tab = Widgets:CreateTextButton(self.tabFrame, name, tabWidth, 20, function()
            self:SelectTab(i)
        end)
        tab:SetPoint("LEFT", self.tabFrame, "LEFT", (i - 1) * (tabWidth + 4) + 4, 0)
        self.tabs[i] = tab
    end

    self.selectedTab = 1

    -- Content area
    self.content = CreateFrame("Frame", nil, self.frame)
    self.content:SetPoint("TOPLEFT", self.tabFrame, "BOTTOMLEFT", 4, -4)
    self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 4)

    -- Scroll frame
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.content)
    self.scrollFrame:SetAllPoints()

    self.scrollContent = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollContent:SetSize(self.content:GetWidth() - 20, 1)
    self.scrollFrame:SetScrollChild(self.scrollContent)

    -- Scroll wheel
    self.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local current = self.scrollFrame:GetVerticalScroll()
        local max = self.scrollContent:GetHeight() - self.scrollFrame:GetHeight()
        if max < 0 then max = 0 end
        local new = current - (delta * 20)
        new = math.max(0, math.min(max, new))
        self.scrollFrame:SetVerticalScroll(new)
    end)

    -- Make draggable
    self.frame:RegisterForDrag("LeftButton")
    self.frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
    self.frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing() end)

    self.frame:Hide()
end

-- Show detail window for actor
function DetailWindow:Show(actor)
    if not actor then return end

    if not self.frame then
        self:Initialize()
    end

    self.currentActor = actor

    -- Update header
    self:UpdateHeader()

    -- Update content
    self:SelectTab(self.selectedTab)

    -- Show frame
    self.frame:Show()
end

-- Update header with actor info
function DetailWindow:UpdateHeader()
    local actor = self.currentActor
    if not actor then return end

    -- Set icon
    local icon = actor.class and ("Interface\\Icons\\ClassIcon_" .. actor.class) or "Interface\\Icons\\INV_Misc_QuestionMark"
    self.header.icon:SetTexture(icon)

    -- Set name with class color
    local coloredName = Utils.ClassColorText(actor.name, actor.class)
    self.header.name:SetText(coloredName)

    -- Get segment duration
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1

    -- Calculate stats
    local dps = duration > 0 and (actor.damage / duration) or 0
    local hps = duration > 0 and (actor.healing / duration) or 0

    local statsText = string.format(
        "Damage: %s (%s/s)  |  Healing: %s (%s/s)\nDeaths: %d  |  Interrupts: %d  |  Dispels: %d",
        Utils.FormatNumber(actor.damage),
        Utils.FormatNumber(dps),
        Utils.FormatNumber(actor.healing),
        Utils.FormatNumber(hps),
        actor.deaths,
        actor.interrupts,
        actor.dispels
    )
    self.header.stats:SetText(statsText)

    -- Update title
    self.titleBar.title:SetText(actor.name .. " - Details")
end

-- Select tab
function DetailWindow:SelectTab(index)
    self.selectedTab = index

    -- Update tab button appearance
    for i, tab in ipairs(self.tabs) do
        if i == index then
            tab:SetBackdropColor(0.25, 0.25, 0.35, 1)
        else
            tab:SetBackdropColor(0.15, 0.15, 0.2, 1)
        end
    end

    -- Clear content
    self:ClearContent()

    -- Populate based on tab
    if index == 1 then
        self:ShowAbilities()
    elseif index == 2 then
        self:ShowTargets()
    elseif index == 3 then
        self:ShowDeaths()
    end
end

-- Clear content
function DetailWindow:ClearContent()
    for _, bar in ipairs(self.abilityBars) do
        bar:Hide()
    end
    wipe(self.abilityBars)
end

-- Create ability bar
function DetailWindow:CreateAbilityBar(index)
    local bar = CreateFrame("Frame", nil, self.scrollContent, "BackdropTemplate")
    bar:SetHeight(24)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.1, 0.1, 0.12, 0.8)

    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetAllPoints()
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.statusBar:SetStatusBarColor(0.3, 0.3, 0.7, 0.7)

    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(20, 20)
    bar.icon:SetPoint("LEFT", 2, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetPoint("LEFT", bar.icon, "RIGHT", 4, 0)
    bar.name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    bar.name:SetTextColor(1, 1, 1, 1)
    bar.name:SetJustifyH("LEFT")

    bar.value = bar:CreateFontString(nil, "OVERLAY")
    bar.value:SetPoint("RIGHT", -4, 0)
    bar.value:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    bar.value:SetTextColor(1, 1, 1, 1)

    bar.percent = bar:CreateFontString(nil, "OVERLAY")
    bar.percent:SetPoint("RIGHT", bar.value, "LEFT", -8, 0)
    bar.percent:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    bar.percent:SetTextColor(0.7, 0.7, 0.7, 1)

    bar.name:SetPoint("RIGHT", bar.percent, "LEFT", -4, 0)

    return bar
end

-- Get ability bar
function DetailWindow:GetAbilityBar(index)
    if self.abilityBars[index] then
        self.abilityBars[index]:Show()
        return self.abilityBars[index]
    end

    local bar = self:CreateAbilityBar(index)
    self.abilityBars[index] = bar
    return bar
end

-- Show abilities tab
function DetailWindow:ShowAbilities()
    local actor = self.currentActor
    if not actor or not actor.abilities then return end

    -- Sort abilities by damage
    local sorted = {}
    for spellId, ability in pairs(actor.abilities) do
        table.insert(sorted, ability)
    end
    table.sort(sorted, function(a, b) return a.damage > b.damage end)

    -- Get total
    local total = actor.damage
    if total == 0 then total = 1 end

    -- Find max
    local maxValue = sorted[1] and sorted[1].damage or 1

    -- Create bars
    local yOffset = 0
    for i, ability in ipairs(sorted) do
        if i > 30 then break end -- Limit to 30 abilities

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, -yOffset)
        bar:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -yOffset)

        -- Set icon
        local spellInfo = Utils.GetSpellInfo(ability.spellId)
        bar.icon:SetTexture(spellInfo and spellInfo.icon or ability.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Set name
        bar.name:SetText(ability.name)

        -- Set value
        bar.value:SetText(Utils.FormatNumber(ability.damage))

        -- Set percent
        bar.percent:SetText(Utils.FormatPercent(ability.damage, total))

        -- Set bar fill
        bar.statusBar:SetValue(ability.damage / maxValue)

        -- Set color based on damage vs healing
        if ability.healing > ability.damage then
            bar.statusBar:SetStatusBarColor(0.2, 0.8, 0.2, 0.7)
        else
            bar.statusBar:SetStatusBarColor(0.8, 0.2, 0.2, 0.7)
        end

        yOffset = yOffset + 26
    end

    self.scrollContent:SetHeight(yOffset)
end

-- Show targets tab
function DetailWindow:ShowTargets()
    local actor = self.currentActor
    if not actor or not actor.targets then return end

    -- Sort targets by damage
    local sorted = {}
    for guid, target in pairs(actor.targets) do
        table.insert(sorted, target)
    end
    table.sort(sorted, function(a, b) return a.damage > b.damage end)

    -- Get total
    local total = actor.damage
    if total == 0 then total = 1 end

    -- Find max
    local maxValue = sorted[1] and sorted[1].damage or 1

    -- Create bars
    local yOffset = 0
    for i, target in ipairs(sorted) do
        if i > 20 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, -yOffset)
        bar:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -yOffset)

        -- Set icon
        bar.icon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")

        -- Set name
        bar.name:SetText(target.name or "Unknown")

        -- Set value
        bar.value:SetText(Utils.FormatNumber(target.damage))

        -- Set percent
        bar.percent:SetText(Utils.FormatPercent(target.damage, total))

        -- Set bar fill
        bar.statusBar:SetValue(target.damage / maxValue)
        bar.statusBar:SetStatusBarColor(0.8, 0.5, 0.2, 0.7)

        yOffset = yOffset + 26
    end

    self.scrollContent:SetHeight(yOffset)
end

-- Show deaths tab
function DetailWindow:ShowDeaths()
    local actor = self.currentActor
    if not actor or not actor.deathLog then return end

    local yOffset = 0

    if #actor.deathLog == 0 then
        local noDeaths = self.scrollContent:CreateFontString(nil, "OVERLAY")
        noDeaths:SetPoint("TOPLEFT", 10, -10)
        noDeaths:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noDeaths:SetTextColor(0.7, 0.7, 0.7, 1)
        noDeaths:SetText("No deaths recorded")
        return
    end

    for i, death in ipairs(actor.deathLog) do
        if i > 10 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollContent, "TOPLEFT", 0, -yOffset)
        bar:SetPoint("TOPRIGHT", self.scrollContent, "TOPRIGHT", 0, -yOffset)

        -- Set icon (skull)
        bar.icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")

        -- Set name (time and source)
        local timeStr = date("%H:%M:%S", death.timestamp)
        bar.name:SetText(string.format("%s - %s", timeStr, death.spellName or "Unknown"))

        -- Set value (damage)
        bar.value:SetText(Utils.FormatNumber(death.damage or 0))

        -- Set percent (overkill)
        if death.overkill and death.overkill > 0 then
            bar.percent:SetText("Overkill: " .. Utils.FormatNumber(death.overkill))
        else
            bar.percent:SetText("")
        end

        -- Red color for deaths
        bar.statusBar:SetValue(1)
        bar.statusBar:SetStatusBarColor(0.8, 0.1, 0.1, 0.8)

        yOffset = yOffset + 26
    end

    self.scrollContent:SetHeight(yOffset)
end

-- Hide
function DetailWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
