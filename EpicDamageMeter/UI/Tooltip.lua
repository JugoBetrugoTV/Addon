--[[
    EpicDamageMeter - Tooltip
    Custom tooltip system
]]

local ADDON_NAME, EDM = ...

EDM.Tooltip = {}
local Tooltip = EDM.Tooltip
local Skins = EDM.Skins
local Utils = EDM.Utils
local C = EDM.Constants

-- Tooltip frame
Tooltip.frame = nil

-- Initialize tooltip
function Tooltip:Initialize()
    if self.frame then return end

    local skin = Skins:Get()
    local tooltipSettings = skin and skin.tooltip or {}

    -- Create tooltip frame
    self.frame = CreateFrame("Frame", "EDMTooltip", UIParent, "BackdropTemplate")
    self.frame:SetFrameStrata("TOOLTIP")
    self.frame:SetFrameLevel(100)
    self.frame:SetClampedToScreen(true)

    -- Apply backdrop
    self.frame:SetBackdrop({
        bgFile = tooltipSettings.background or "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    self.frame:SetBackdropColor(
        tooltipSettings.backgroundColor and tooltipSettings.backgroundColor.r or 0.05,
        tooltipSettings.backgroundColor and tooltipSettings.backgroundColor.g or 0.05,
        tooltipSettings.backgroundColor and tooltipSettings.backgroundColor.b or 0.08,
        tooltipSettings.backgroundColor and tooltipSettings.backgroundColor.a or 0.95
    )
    self.frame:SetBackdropBorderColor(
        tooltipSettings.borderColor and tooltipSettings.borderColor.r or 0.3,
        tooltipSettings.borderColor and tooltipSettings.borderColor.g or 0.3,
        tooltipSettings.borderColor and tooltipSettings.borderColor.b or 0.4,
        tooltipSettings.borderColor and tooltipSettings.borderColor.a or 1
    )

    -- Create lines pool
    self.lines = {}
    self.headerFont = tooltipSettings.headerFont or "Fonts\\FRIZQT__.TTF"
    self.headerFontSize = tooltipSettings.headerFontSize or 13
    self.font = tooltipSettings.font or "Fonts\\FRIZQT__.TTF"
    self.fontSize = tooltipSettings.fontSize or 11
    self.padding = tooltipSettings.padding or 10

    self.frame:Hide()
end

-- Get or create line
function Tooltip:GetLine(index, isHeader)
    if self.lines[index] then
        self.lines[index]:Show()
        return self.lines[index]
    end

    local line = self.frame:CreateFontString(nil, "OVERLAY")
    line:SetFont(
        isHeader and self.headerFont or self.font,
        isHeader and self.headerFontSize or self.fontSize,
        isHeader and "OUTLINE" or ""
    )
    line:SetJustifyH("LEFT")

    self.lines[index] = line
    return line
end

-- Add line to tooltip
function Tooltip:AddLine(text, r, g, b, isHeader)
    local index = #self.lines + 1
    local line = self:GetLine(index, isHeader)

    line:SetText(text)
    line:SetTextColor(r or 1, g or 1, b or 1, 1)

    return line
end

-- Spell school names
local SCHOOL_NAMES = {
    [1] = "Physical",
    [2] = "Holy",
    [4] = "Fire",
    [8] = "Nature",
    [16] = "Frost",
    [32] = "Shadow",
    [64] = "Arcane",
}

-- Get spell school color from constants
function Tooltip:GetSchoolColor(school)
    local color = C.SCHOOL_COLORS[school]
    if color then
        return color.r, color.g, color.b
    end
    return 0.8, 0.8, 0.8
end

-- Get spell school name
function Tooltip:GetSchoolName(school)
    return SCHOOL_NAMES[school] or "Unknown"
end

-- Add spell school breakdown line with colored bar
function Tooltip:AddSchoolLine(school, damage, percent)
    local r, g, b = self:GetSchoolColor(school)
    local name = self:GetSchoolName(school)
    local text = string.format("  |cff%02x%02x%02x■|r %s: %s (%.1f%%)",
        r * 255, g * 255, b * 255,
        name,
        Utils.FormatNumber(damage),
        percent
    )
    return self:AddLine(text, 0.9, 0.9, 0.9)
end

-- Clear tooltip
function Tooltip:Clear()
    for _, line in ipairs(self.lines) do
        line:Hide()
        line:SetText("")
    end
    wipe(self.lines)
end

-- Show tooltip for actor
function Tooltip:ShowActorTooltip(anchor, actor)
    if not actor then return end

    if not self.frame then
        self:Initialize()
    end

    self:Clear()

    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    local duration = segment and DB:GetSegmentDuration(segment) or 1
    if duration == 0 then duration = 1 end

    -- Header (player name with class color)
    local headerLine = self:AddLine(actor.name, Utils.GetClassColor(actor.class))
    headerLine:SetFont(self.headerFont, self.headerFontSize, "OUTLINE")

    -- Separator
    self:AddLine(" ")

    -- Damage
    local dps = actor.damage / duration
    self:AddLine(string.format("Damage: %s (%s/s)",
        Utils.FormatNumber(actor.damage),
        Utils.FormatNumber(dps)
    ), 1, 0.5, 0.5)

    -- Healing
    local hps = actor.healing / duration
    self:AddLine(string.format("Healing: %s (%s/s)",
        Utils.FormatNumber(actor.healing),
        Utils.FormatNumber(hps)
    ), 0.5, 1, 0.5)

    -- Overhealing
    if actor.overhealing > 0 then
        self:AddLine(string.format("Overhealing: %s",
            Utils.FormatNumber(actor.overhealing)
        ), 0.7, 0.7, 0.7)
    end

    -- Absorbs
    if actor.absorbs > 0 then
        self:AddLine(string.format("Absorbs: %s",
            Utils.FormatNumber(actor.absorbs)
        ), 0.9, 0.9, 0.5)
    end

    -- Damage taken
    if actor.damageTaken > 0 then
        self:AddLine(string.format("Damage Taken: %s",
            Utils.FormatNumber(actor.damageTaken)
        ), 1, 0.3, 0.3)
    end

    -- Separator
    self:AddLine(" ")

    -- Activity
    self:AddLine(string.format("Deaths: %d  Interrupts: %d  Dispels: %d",
        actor.deaths, actor.interrupts, actor.dispels
    ), 0.8, 0.8, 0.8)

    -- Top ability
    local topAbility = nil
    local topDamage = 0
    for spellId, ability in pairs(actor.abilities or {}) do
        if ability.damage > topDamage then
            topDamage = ability.damage
            topAbility = ability
        end
    end

    if topAbility then
        self:AddLine(" ")
        self:AddLine(string.format("Top Ability: %s (%s)",
            topAbility.name,
            Utils.FormatNumber(topAbility.damage)
        ), 0.7, 0.7, 1)
    end

    -- Spell school breakdown
    local schoolBreakdown = DB:GetSpellSchoolBreakdown(actor)
    if schoolBreakdown and #schoolBreakdown > 0 then
        self:AddLine(" ")
        self:AddLine("Damage by School:", 0.9, 0.8, 0.6)
        for i, data in ipairs(schoolBreakdown) do
            if i <= 4 then -- Limit to top 4 schools
                self:AddSchoolLine(data.school, data.damage, data.percent)
            end
        end
    end

    -- Instructions
    self:AddLine(" ")
    self:AddLine("Click for details", 0.5, 0.5, 0.5)
    self:AddLine("Right-click to change mode", 0.5, 0.5, 0.5)

    -- Calculate size
    self:Layout()

    -- Position tooltip
    self:SetPosition(anchor)

    self.frame:Show()
end

-- Layout tooltip
function Tooltip:Layout()
    local maxWidth = 0
    local totalHeight = self.padding

    for i, line in ipairs(self.lines) do
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.padding, -totalHeight)

        local width = line:GetStringWidth()
        if width > maxWidth then
            maxWidth = width
        end

        totalHeight = totalHeight + line:GetStringHeight() + 2
    end

    totalHeight = totalHeight + self.padding

    self.frame:SetSize(maxWidth + self.padding * 2, totalHeight)
end

-- Set tooltip position
function Tooltip:SetPosition(anchor)
    if not anchor then
        self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 10, 10)
        return
    end

    -- Position relative to anchor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = x / scale, y / scale

    -- Check screen bounds
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    local tooltipWidth = self.frame:GetWidth()
    local tooltipHeight = self.frame:GetHeight()

    -- Default: show to the right and above cursor
    local xOffset = 15
    local yOffset = 15

    -- If tooltip would go off right edge, show to the left
    if x + xOffset + tooltipWidth > screenWidth then
        xOffset = -tooltipWidth - 15
    end

    -- If tooltip would go off top edge, show below
    if y + yOffset + tooltipHeight > screenHeight then
        yOffset = -tooltipHeight - 15
    end

    self.frame:ClearAllPoints()
    self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + xOffset, y + yOffset)
end

-- Hide tooltip
function Tooltip:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Show ability tooltip
function Tooltip:ShowAbilityTooltip(anchor, ability, actor)
    if not ability then return end

    if not self.frame then
        self:Initialize()
    end

    self:Clear()

    -- Header (spell name)
    self:AddLine(ability.name, 1, 1, 1)

    -- Icon
    -- (Would need additional implementation for icon in tooltip)

    self:AddLine(" ")

    -- Damage stats
    if ability.damage > 0 then
        self:AddLine(string.format("Total Damage: %s", Utils.FormatNumber(ability.damage)), 1, 0.5, 0.5)
        self:AddLine(string.format("Hits: %d (Crits: %d)", ability.damageHits, ability.damageCrits), 0.8, 0.8, 0.8)

        if ability.damageHits > 0 then
            local avgDamage = ability.damage / ability.damageHits
            local critPercent = (ability.damageCrits / ability.damageHits) * 100
            self:AddLine(string.format("Average: %s | Crit: %.1f%%",
                Utils.FormatNumber(avgDamage), critPercent), 0.8, 0.8, 0.8)
        end

        if ability.damageMin > 0 then
            self:AddLine(string.format("Min: %s | Max: %s",
                Utils.FormatNumber(ability.damageMin),
                Utils.FormatNumber(ability.damageMax)), 0.7, 0.7, 0.7)
        end
    end

    -- Healing stats
    if ability.healing > 0 then
        self:AddLine(" ")
        self:AddLine(string.format("Total Healing: %s", Utils.FormatNumber(ability.healing)), 0.5, 1, 0.5)
        self:AddLine(string.format("Hits: %d (Crits: %d)", ability.healingHits, ability.healingCrits), 0.8, 0.8, 0.8)

        if ability.overhealing > 0 then
            self:AddLine(string.format("Overhealing: %s", Utils.FormatNumber(ability.overhealing)), 0.7, 0.7, 0.7)
        end
    end

    -- Miss stats
    local totalMisses = 0
    for missType, count in pairs(ability.misses or {}) do
        totalMisses = totalMisses + count
    end

    if totalMisses > 0 then
        self:AddLine(" ")
        self:AddLine("Misses:", 0.8, 0.8, 0.8)
        for missType, count in pairs(ability.misses) do
            if count > 0 then
                self:AddLine(string.format("  %s: %d", missType, count), 0.7, 0.7, 0.7)
            end
        end
    end

    self:Layout()
    self:SetPosition(anchor)
    self.frame:Show()
end

-- Show session stats tooltip
function Tooltip:ShowSessionTooltip(anchor)
    if not self.frame then
        self:Initialize()
    end

    self:Clear()

    local DB = EDM.Database
    local stats = DB:GetSessionStats()

    -- Header
    local headerLine = self:AddLine("Session Statistics", 1, 0.82, 0)
    headerLine:SetFont(self.headerFont, self.headerFontSize, "OUTLINE")

    self:AddLine(" ")

    -- Session duration
    self:AddLine(string.format("Session Duration: %s", Utils.FormatTime(stats.sessionDuration)), 0.9, 0.9, 0.9)
    self:AddLine(string.format("Combat Time: %s (%.1f%%)",
        Utils.FormatTime(stats.totalCombatTime),
        stats.combatTimePercent
    ), 0.8, 0.8, 0.8)

    self:AddLine(" ")

    -- Combat stats
    self:AddLine(string.format("Total Fights: %d", stats.totalFights), 0.7, 0.9, 0.7)
    self:AddLine(string.format("Total Deaths: %d (%.1f/fight)",
        stats.totalDeaths,
        stats.deathsPerFight
    ), 1, 0.5, 0.5)

    self:AddLine(" ")

    -- DPS/HPS averages
    self:AddLine(string.format("Total Damage: %s", Utils.FormatNumber(stats.totalDamage)), 1, 0.6, 0.6)
    self:AddLine(string.format("Average DPS: %s", Utils.FormatNumber(stats.avgDPS)), 1, 0.7, 0.7)
    self:AddLine(string.format("Total Healing: %s", Utils.FormatNumber(stats.totalHealing)), 0.6, 1, 0.6)
    self:AddLine(string.format("Average HPS: %s", Utils.FormatNumber(stats.avgHPS)), 0.7, 1, 0.7)

    -- Boss stats
    if stats.bossKills > 0 or stats.bossWipes > 0 then
        self:AddLine(" ")
        self:AddLine(string.format("Boss Kills: %d | Wipes: %d",
            stats.bossKills, stats.bossWipes
        ), 1, 0.82, 0)
        self:AddLine(string.format("Success Rate: %.1f%%", stats.bossSuccessRate), 0.8, 0.8, 0.8)
    end

    self:Layout()
    self:SetPosition(anchor)
    self.frame:Show()
end

-- Show death recap tooltip
function Tooltip:ShowDeathRecapTooltip(anchor, actor)
    if not actor then return end

    if not self.frame then
        self:Initialize()
    end

    self:Clear()

    local DB = EDM.Database
    local recap = DB:GetDeathRecap(actor)

    if not recap then
        self:AddLine("No death data available", 0.7, 0.7, 0.7)
        self:Layout()
        self:SetPosition(anchor)
        self.frame:Show()
        return
    end

    -- Header
    local headerLine = self:AddLine(string.format("Death Recap: %s", actor.name), 1, 0.3, 0.3)
    headerLine:SetFont(self.headerFont, self.headerFontSize, "OUTLINE")

    self:AddLine(" ")

    -- Killing blow
    self:AddLine("Killing Blow:", 1, 0.5, 0.5)
    self:AddLine(string.format("  %s - %s",
        recap.killerName or "Unknown",
        recap.killingBlow.spellName or "Unknown"
    ), 0.9, 0.9, 0.9)
    self:AddLine(string.format("  Damage: %s (Overkill: %s)",
        Utils.FormatNumber(recap.killingBlow.damage),
        Utils.FormatNumber(recap.killingBlow.overkill)
    ), 0.8, 0.8, 0.8)

    -- Damage sequence
    if recap.damageSequence and #recap.damageSequence > 0 then
        self:AddLine(" ")
        self:AddLine("Recent Damage:", 0.9, 0.7, 0.5)

        local totalDamage = 0
        for i, event in ipairs(recap.damageSequence) do
            if i <= 8 then -- Limit to last 8 events
                local r, g, b = self:GetSchoolColor(event.spellSchool)
                self:AddLine(string.format("  |cff%02x%02x%02x■|r %s: %s",
                    r * 255, g * 255, b * 255,
                    event.spellName,
                    Utils.FormatNumber(event.amount)
                ), 0.8, 0.8, 0.8)
                totalDamage = totalDamage + event.amount
            end
        end

        self:AddLine(" ")
        self:AddLine(string.format("Total: %s in last 10s", Utils.FormatNumber(totalDamage)), 0.9, 0.6, 0.6)
    end

    self:Layout()
    self:SetPosition(anchor)
    self.frame:Show()
end
