--[[
    EpicDamageMeter - Detail Window (Enhanced)
    Detailed breakdown view with resize, scroll, and spell details
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
DetailWindow.currentInstance = nil
DetailWindow.abilityBars = {}
DetailWindow.selectedSpell = nil

-- Initialize detail window
function DetailWindow:Initialize()
    if self.frame then return end

    -- Create frame
    self.frame = CreateFrame("Frame", "EDMDetailWindow", UIParent, "BackdropTemplate")
    self.frame:SetSize(400, 450)
    self.frame:SetPoint("CENTER", 200, 0)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(20)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(true)
    self.frame:SetResizeBounds(300, 250, 700, 800)

    -- Apply backdrop
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    self.frame:SetBackdropColor(0.03, 0.03, 0.05, 0.95)
    self.frame:SetBackdropBorderColor(0.2, 0.2, 0.3, 1)

    -- Title bar
    self.titleBar = CreateFrame("Frame", nil, self.frame)
    self.titleBar:SetHeight(24)
    self.titleBar:SetPoint("TOPLEFT", 0, 0)
    self.titleBar:SetPoint("TOPRIGHT", 0, 0)

    self.titleBar.bg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    self.titleBar.bg:SetAllPoints()
    self.titleBar.bg:SetColorTexture(0.08, 0.08, 0.12, 0.98)

    self.titleBar.title = self.titleBar:CreateFontString(nil, "OVERLAY")
    self.titleBar.title:SetPoint("LEFT", 8, 0)
    self.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.titleBar.title:SetTextColor(1, 1, 1, 1)
    self.titleBar.title:SetText("Player Details")

    -- Close button
    self.closeBtn = CreateFrame("Button", nil, self.titleBar)
    self.closeBtn:SetSize(16, 16)
    self.closeBtn:SetPoint("RIGHT", -4, 0)
    self.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
    self.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
    self.closeBtn:GetHighlightTexture():SetVertexColor(1, 0.3, 0.3, 0.8)
    self.closeBtn:SetScript("OnClick", function()
        self.frame:Hide()
    end)

    -- Player header
    self.header = CreateFrame("Frame", nil, self.frame)
    self.header:SetHeight(70)
    self.header:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", 0, 0)
    self.header:SetPoint("TOPRIGHT", self.titleBar, "BOTTOMRIGHT", 0, 0)

    self.header.bg = self.header:CreateTexture(nil, "BACKGROUND")
    self.header.bg:SetAllPoints()
    self.header.bg:SetColorTexture(0.04, 0.04, 0.06, 0.95)

    -- Player icon
    self.header.icon = self.header:CreateTexture(nil, "ARTWORK")
    self.header.icon:SetSize(50, 50)
    self.header.icon:SetPoint("LEFT", 10, 0)
    self.header.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Player name
    self.header.name = self.header:CreateFontString(nil, "OVERLAY")
    self.header.name:SetPoint("TOPLEFT", self.header.icon, "TOPRIGHT", 10, -2)
    self.header.name:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    -- Player stats line 1 (Damage/Healing)
    self.header.stats1 = self.header:CreateFontString(nil, "OVERLAY")
    self.header.stats1:SetPoint("TOPLEFT", self.header.name, "BOTTOMLEFT", 0, -4)
    self.header.stats1:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    self.header.stats1:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Player stats line 2 (Deaths/Interrupts/Dispels)
    self.header.stats2 = self.header:CreateFontString(nil, "OVERLAY")
    self.header.stats2:SetPoint("TOPLEFT", self.header.stats1, "BOTTOMLEFT", 0, -2)
    self.header.stats2:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    self.header.stats2:SetTextColor(0.7, 0.7, 0.7, 1)

    -- Tab buttons
    self.tabFrame = CreateFrame("Frame", nil, self.frame)
    self.tabFrame:SetHeight(26)
    self.tabFrame:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, 0)
    self.tabFrame:SetPoint("TOPRIGHT", self.header, "BOTTOMRIGHT", 0, 0)

    self.tabFrame.bg = self.tabFrame:CreateTexture(nil, "BACKGROUND")
    self.tabFrame.bg:SetAllPoints()
    self.tabFrame.bg:SetColorTexture(0.06, 0.06, 0.08, 0.95)

    self.tabs = {}
    local tabNames = { "Damage", "Healing", "Targets", "Deaths" }
    local tabWidth = 85

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, self.tabFrame, "BackdropTemplate")
        tab:SetSize(tabWidth, 22)
        tab:SetPoint("LEFT", self.tabFrame, "LEFT", (i - 1) * (tabWidth + 2) + 4, 0)
        tab:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        tab:SetBackdropColor(0.15, 0.15, 0.2, 1)
        tab:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        tab.text:SetPoint("CENTER")
        tab.text:SetText(name)
        tab.text:SetTextColor(0.9, 0.9, 0.9, 1)

        tab:SetScript("OnClick", function()
            self:SelectTab(i)
        end)
        tab:SetScript("OnEnter", function(btn)
            btn:SetBackdropColor(0.2, 0.2, 0.25, 1)
        end)
        tab:SetScript("OnLeave", function(btn)
            if self.selectedTab ~= i then
                btn:SetBackdropColor(0.15, 0.15, 0.2, 1)
            end
        end)
        self.tabs[i] = tab
    end

    self.selectedTab = 1

    -- Content area with scroll
    self.content = CreateFrame("Frame", nil, self.frame)
    self.content:SetPoint("TOPLEFT", self.tabFrame, "BOTTOMLEFT", 4, -4)
    self.content:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -4, 20)
    self.content:SetClipsChildren(true)

    -- Scroll child
    self.scrollChild = CreateFrame("Frame", nil, self.content)
    self.scrollChild:SetPoint("TOPLEFT", 0, 0)
    self.scrollChild:SetWidth(self.content:GetWidth() or 380)
    self.scrollChild:SetHeight(1)

    -- Scroll wheel
    self.scrollOffset = 0
    self.content:EnableMouseWheel(true)
    self.content:SetScript("OnMouseWheel", function(_, delta)
        self:OnScroll(delta)
    end)

    -- Resize handle
    self.resizeHandle = CreateFrame("Frame", nil, self.frame)
    self.resizeHandle:SetSize(16, 16)
    self.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
    self.resizeHandle:EnableMouse(true)

    self.resizeHandle.tex = self.resizeHandle:CreateTexture(nil, "OVERLAY")
    self.resizeHandle.tex:SetAllPoints()
    self.resizeHandle.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    self.resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            self.frame:StartSizing("BOTTOMRIGHT")
        end
    end)
    self.resizeHandle:SetScript("OnMouseUp", function()
        self.frame:StopMovingOrSizing()
        self:UpdateLayout()
    end)

    -- Make draggable
    self.titleBar:EnableMouse(true)
    self.titleBar:RegisterForDrag("LeftButton")
    self.titleBar:SetScript("OnDragStart", function() self.frame:StartMoving() end)
    self.titleBar:SetScript("OnDragStop", function() self.frame:StopMovingOrSizing() end)

    -- Size changed callback
    self.frame:SetScript("OnSizeChanged", function()
        self:UpdateLayout()
    end)

    self.frame:Hide()
end

-- Update layout when resized
function DetailWindow:UpdateLayout()
    if self.scrollChild then
        self.scrollChild:SetWidth(self.content:GetWidth() or 380)
    end
    -- Re-render current tab
    if self.currentActor then
        self:SelectTab(self.selectedTab)
    end
end

-- Scroll handling
function DetailWindow:OnScroll(delta)
    local maxScroll = math.max(0, (self.scrollChild:GetHeight() or 0) - (self.content:GetHeight() or 200))
    self.scrollOffset = self.scrollOffset - (delta * 30)
    self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset))
    self.scrollChild:SetPoint("TOPLEFT", 0, self.scrollOffset)
end

-- Show detail window for actor
function DetailWindow:Show(actor, instance)
    if not actor then return end

    if not self.frame then
        self:Initialize()
    end

    self.currentActor = actor
    self.currentInstance = instance
    self.selectedSpell = nil
    self.scrollOffset = 0

    -- Update header
    self:UpdateHeader()

    -- Update content
    self:SelectTab(self.selectedTab)

    -- Show frame
    self.frame:Show()
end

-- Update function for live updates (called by Core timer)
function DetailWindow:Update()
    if not self.frame or not self.frame:IsShown() then return end
    if not self.currentActor then return end

    -- Re-fetch actor data from current segment to get updated values
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    if segment and self.currentActor.guid then
        local updatedActor = segment.actors[self.currentActor.guid]
        if updatedActor then
            self.currentActor = updatedActor
        end
    end

    -- Update header
    self:UpdateHeader()

    -- Update content
    self:SelectTab(self.selectedTab)
end

-- Update header with actor info
function DetailWindow:UpdateHeader()
    local actor = self.currentActor
    if not actor then return end

    -- Set icon
    local icon = actor.class and ("Interface\\Icons\\ClassIcon_" .. actor.class) or "Interface\\Icons\\INV_Misc_QuestionMark"
    self.header.icon:SetTexture(icon)

    -- Set name with class color
    local r, g, b = Utils.GetClassColor(actor.class)
    self.header.name:SetText(string.format("|cff%02x%02x%02x%s|r", r*255, g*255, b*255, actor.name or "Unknown"))

    -- Get segment duration
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1
    if duration == 0 then duration = 1 end

    -- Calculate stats
    local dps = actor.damage / duration
    local hps = actor.healing / duration

    -- Stats line 1
    local statsText1 = string.format(
        "|cffff6666Damage:|r %s (%.1fk/s)  |cff66ff66Healing:|r %s (%.1fk/s)",
        Utils.FormatNumber(actor.damage), dps / 1000,
        Utils.FormatNumber(actor.healing), hps / 1000
    )
    self.header.stats1:SetText(statsText1)

    -- Stats line 2
    local statsText2 = string.format(
        "Deaths: %d  |  Interrupts: %d  |  Dispels: %d  |  Absorbs: %s",
        actor.deaths or 0, actor.interrupts or 0, actor.dispels or 0,
        Utils.FormatNumber(actor.absorbs or 0)
    )
    self.header.stats2:SetText(statsText2)

    -- Update title
    self.titleBar.title:SetText((actor.name or "Unknown") .. " - Details")
end

-- Select tab
function DetailWindow:SelectTab(index)
    self.selectedTab = index
    self.scrollOffset = 0
    self.scrollChild:SetPoint("TOPLEFT", 0, 0)

    -- Update tab button appearance
    for i, tab in ipairs(self.tabs) do
        if i == index then
            tab:SetBackdropColor(0.3, 0.3, 0.4, 1)
            tab:SetBackdropBorderColor(0.4, 0.6, 0.9, 1)
        else
            tab:SetBackdropColor(0.15, 0.15, 0.2, 1)
            tab:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        end
    end

    -- Clear content
    self:ClearContent()

    -- Populate based on tab
    if index == 1 then
        self:ShowDamageAbilities()
    elseif index == 2 then
        self:ShowHealingAbilities()
    elseif index == 3 then
        self:ShowTargets()
    elseif index == 4 then
        self:ShowDeaths()
    end
end

-- Clear content
function DetailWindow:ClearContent()
    for _, bar in ipairs(self.abilityBars) do
        bar:Hide()
    end
end

-- Create ability bar
function DetailWindow:CreateAbilityBar(index)
    local bar = CreateFrame("Button", nil, self.scrollChild, "BackdropTemplate")
    bar:SetHeight(28)
    bar:EnableMouse(true)
    bar:RegisterForClicks("AnyUp")

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(0.06, 0.06, 0.08, 0.9)

    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetAllPoints()
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.statusBar:SetStatusBarColor(0.3, 0.3, 0.6, 0.6)
    bar.statusBar:SetAlpha(0.7)

    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(24, 24)
    bar.icon:SetPoint("LEFT", 2, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetPoint("LEFT", bar.icon, "RIGHT", 6, 4)
    bar.name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bar.name:SetTextColor(1, 1, 1, 1)
    bar.name:SetJustifyH("LEFT")
    bar.name:SetShadowOffset(1, -1)
    bar.name:SetShadowColor(0, 0, 0, 1)

    -- Sub text (hits, crits, etc.)
    bar.subText = bar:CreateFontString(nil, "OVERLAY")
    bar.subText:SetPoint("TOPLEFT", bar.icon, "RIGHT", 6, -8)
    bar.subText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    bar.subText:SetTextColor(0.7, 0.7, 0.7, 1)

    bar.value = bar:CreateFontString(nil, "OVERLAY")
    bar.value:SetPoint("RIGHT", -4, 4)
    bar.value:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bar.value:SetTextColor(1, 1, 1, 1)
    bar.value:SetShadowOffset(1, -1)
    bar.value:SetShadowColor(0, 0, 0, 1)

    bar.percent = bar:CreateFontString(nil, "OVERLAY")
    bar.percent:SetPoint("RIGHT", -4, -8)
    bar.percent:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    bar.percent:SetTextColor(0.8, 0.8, 0.8, 1)

    bar.highlight = bar:CreateTexture(nil, "HIGHLIGHT")
    bar.highlight:SetAllPoints()
    bar.highlight:SetColorTexture(1, 1, 1, 0.1)

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

-- Show damage abilities tab
function DetailWindow:ShowDamageAbilities()
    local actor = self.currentActor
    if not actor or not actor.abilities then return end

    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1
    if duration == 0 then duration = 1 end

    -- Sort abilities by damage
    local sorted = {}
    for spellId, ability in pairs(actor.abilities) do
        if (ability.damage or 0) > 0 then
            table.insert(sorted, ability)
        end
    end
    table.sort(sorted, function(a, b) return (a.damage or 0) > (b.damage or 0) end)

    local total = actor.damage
    if total == 0 then total = 1 end
    local maxValue = sorted[1] and sorted[1].damage or 1

    local contentWidth = self.content:GetWidth() or 380
    local yOffset = 0

    for i, ability in ipairs(sorted) do
        if i > 50 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        bar:SetWidth(contentWidth - 8)

        -- Icon
        local spellInfo = Utils.GetSpellInfo(ability.spellId)
        bar.icon:SetTexture(spellInfo and spellInfo.icon or ability.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Name
        bar.name:SetText(ability.name or "Unknown")

        -- Stats
        local hits = ability.damageHits or 0
        local crits = ability.damageCrits or 0
        local critPercent = hits > 0 and ((crits / hits) * 100) or 0
        local avgDamage = hits > 0 and (ability.damage / hits) or 0

        bar.subText:SetText(string.format("%d hits | %d crits (%.0f%%) | Avg: %s", hits, crits, critPercent, Utils.FormatNumber(avgDamage)))

        -- Value
        local dps = ability.damage / duration
        bar.value:SetText(string.format("%s (%.1fk/s)", Utils.FormatNumber(ability.damage), dps / 1000))

        -- Percent
        local pct = (ability.damage / total) * 100
        bar.percent:SetText(string.format("%.1f%%", pct))

        -- Bar fill
        bar.statusBar:SetValue(ability.damage / maxValue)
        bar.statusBar:SetStatusBarColor(0.8, 0.2, 0.2, 0.7)

        -- Tooltip with detailed info
        bar:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(ability.name or "Unknown", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Total Damage:", Utils.FormatNumber(ability.damage), 0.7, 0.7, 0.7, 1, 0.5, 0.5)
            GameTooltip:AddDoubleLine("DPS:", string.format("%.1f", dps), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Hits:", string.format("%d", hits), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Crits:", string.format("%d (%.1f%%)", crits, critPercent), 0.7, 0.7, 0.7, 1, 0.5, 0.5)
            GameTooltip:AddDoubleLine("Average:", Utils.FormatNumber(avgDamage), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Min:", Utils.FormatNumber(ability.damageMin or 0), 0.7, 0.7, 0.7, 0.5, 1, 0.5)
            GameTooltip:AddDoubleLine("Max:", Utils.FormatNumber(ability.damageMax or 0), 0.7, 0.7, 0.7, 1, 0.5, 0.5)
            if ability.misses then
                local totalMisses = 0
                for _, count in pairs(ability.misses) do totalMisses = totalMisses + count end
                if totalMisses > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Misses:", 0.8, 0.8, 0.8)
                    for missType, count in pairs(ability.misses) do
                        if count > 0 then
                            GameTooltip:AddDoubleLine(missType, count, 0.6, 0.6, 0.6, 1, 0.5, 0.5)
                        end
                    end
                end
            end
            GameTooltip:Show()
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

        yOffset = yOffset + 30
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Show healing abilities tab
function DetailWindow:ShowHealingAbilities()
    local actor = self.currentActor
    if not actor or not actor.abilities then return end

    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1
    if duration == 0 then duration = 1 end

    -- Sort abilities by healing
    local sorted = {}
    for spellId, ability in pairs(actor.abilities) do
        if (ability.healing or 0) > 0 or (ability.overhealing or 0) > 0 then
            table.insert(sorted, ability)
        end
    end
    table.sort(sorted, function(a, b) return (a.healing or 0) > (b.healing or 0) end)

    local total = actor.healing
    if total == 0 then total = 1 end
    local maxValue = sorted[1] and sorted[1].healing or 1
    if maxValue == 0 then maxValue = 1 end

    local contentWidth = self.content:GetWidth() or 380
    local yOffset = 0

    for i, ability in ipairs(sorted) do
        if i > 50 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        bar:SetWidth(contentWidth - 8)

        -- Icon
        local spellInfo = Utils.GetSpellInfo(ability.spellId)
        bar.icon:SetTexture(spellInfo and spellInfo.icon or ability.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        -- Name
        bar.name:SetText(ability.name or "Unknown")

        -- Stats
        local hits = ability.healingHits or 0
        local crits = ability.healingCrits or 0
        local critPercent = hits > 0 and ((crits / hits) * 100) or 0
        local overheal = ability.overhealing or 0
        local totalHeal = (ability.healing or 0) + overheal
        local overhealPct = totalHeal > 0 and ((overheal / totalHeal) * 100) or 0

        bar.subText:SetText(string.format("%d hits | %d crits (%.0f%%) | Overheal: %.0f%%", hits, crits, critPercent, overhealPct))

        -- Value
        local hps = (ability.healing or 0) / duration
        bar.value:SetText(string.format("%s (%.1fk/s)", Utils.FormatNumber(ability.healing or 0), hps / 1000))

        -- Percent
        local pct = ((ability.healing or 0) / total) * 100
        bar.percent:SetText(string.format("%.1f%%", pct))

        -- Bar fill
        bar.statusBar:SetValue((ability.healing or 0) / maxValue)
        bar.statusBar:SetStatusBarColor(0.2, 0.8, 0.2, 0.7)

        -- Tooltip
        bar:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(ability.name or "Unknown", 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Effective Healing:", Utils.FormatNumber(ability.healing or 0), 0.7, 0.7, 0.7, 0.5, 1, 0.5)
            GameTooltip:AddDoubleLine("Overhealing:", Utils.FormatNumber(overheal), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
            GameTooltip:AddDoubleLine("HPS:", string.format("%.1f", hps), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Hits:", string.format("%d", hits), 0.7, 0.7, 0.7, 1, 1, 1)
            GameTooltip:AddDoubleLine("Crits:", string.format("%d (%.1f%%)", crits, critPercent), 0.7, 0.7, 0.7, 1, 0.5, 0.5)
            GameTooltip:AddDoubleLine("Overheal %:", string.format("%.1f%%", overhealPct), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

        yOffset = yOffset + 30
    end

    if #sorted == 0 then
        local noData = self.scrollChild:CreateFontString(nil, "OVERLAY")
        noData:SetPoint("CENTER", 0, 0)
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noData:SetTextColor(0.6, 0.6, 0.6, 1)
        noData:SetText("No healing data")
    end

    self.scrollChild:SetHeight(math.max(yOffset, 50))
end

-- Show targets tab
function DetailWindow:ShowTargets()
    local actor = self.currentActor
    if not actor or not actor.targets then return end

    local sorted = {}
    for guid, target in pairs(actor.targets) do
        table.insert(sorted, target)
    end
    table.sort(sorted, function(a, b) return (a.damage or 0) > (b.damage or 0) end)

    local total = actor.damage
    if total == 0 then total = 1 end
    local maxValue = sorted[1] and sorted[1].damage or 1

    local contentWidth = self.content:GetWidth() or 380
    local yOffset = 0

    for i, target in ipairs(sorted) do
        if i > 30 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        bar:SetWidth(contentWidth - 8)

        bar.icon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")
        bar.name:SetText(target.name or "Unknown")
        bar.subText:SetText(string.format("%d hits", target.hits or 0))
        bar.value:SetText(Utils.FormatNumber(target.damage or 0))

        local pct = ((target.damage or 0) / total) * 100
        bar.percent:SetText(string.format("%.1f%%", pct))

        bar.statusBar:SetValue((target.damage or 0) / maxValue)
        bar.statusBar:SetStatusBarColor(0.8, 0.5, 0.2, 0.7)

        bar:SetScript("OnEnter", function() end)
        bar:SetScript("OnLeave", function() end)

        yOffset = yOffset + 30
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Show deaths tab
function DetailWindow:ShowDeaths()
    local actor = self.currentActor
    if not actor or not actor.deathLog then return end

    local contentWidth = self.content:GetWidth() or 380
    local yOffset = 0

    if #actor.deathLog == 0 then
        local noDeaths = self.scrollChild:CreateFontString(nil, "OVERLAY")
        noDeaths:SetPoint("CENTER", 0, 0)
        noDeaths:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noDeaths:SetTextColor(0.6, 0.6, 0.6, 1)
        noDeaths:SetText("No deaths recorded")
        self.scrollChild:SetHeight(50)
        return
    end

    for i, death in ipairs(actor.deathLog) do
        if i > 20 then break end

        local bar = self:GetAbilityBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        bar:SetWidth(contentWidth - 8)

        bar.icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")

        local timeStr = death.timestamp and date("%H:%M:%S", death.timestamp) or "Unknown"
        bar.name:SetText(string.format("Death #%d - %s", i, timeStr))
        bar.subText:SetText(string.format("Killed by: %s (%s)", death.killerName or "Unknown", death.spellName or "Unknown"))
        bar.value:SetText(Utils.FormatNumber(death.damage or 0))

        if death.overkill and death.overkill > 0 then
            bar.percent:SetText("Overkill: " .. Utils.FormatNumber(death.overkill))
        else
            bar.percent:SetText("")
        end

        bar.statusBar:SetValue(1)
        bar.statusBar:SetStatusBarColor(0.8, 0.1, 0.1, 0.8)

        yOffset = yOffset + 30
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Hide
function DetailWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end
