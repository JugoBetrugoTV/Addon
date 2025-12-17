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
