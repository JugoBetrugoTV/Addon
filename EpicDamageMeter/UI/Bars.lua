--[[
    EpicDamageMeter - Bars
    Data bar display system with animations
]]

local ADDON_NAME, EDM = ...

EDM.Bars = {}
local Bars = EDM.Bars
local Skins = EDM.Skins
local Utils = EDM.Utils
local C = EDM.Constants
local LSM = LibStub("LibSharedMedia-3.0")

-- Bar pool
Bars.pool = {}
Bars.active = {}
Bars.barHeight = 18
Bars.barSpacing = 1

-- Create a data bar
function Bars:CreateBar(parent, index)
    local skin = Skins:Get()
    local barSettings = skin and skin.bar or {}

    local bar = CreateFrame("Button", nil, parent, "BackdropTemplate")
    bar:SetHeight(barSettings.height or self.barHeight)
    bar:EnableMouse(true)
    bar:RegisterForClicks("AnyUp")

    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(
        barSettings.backgroundColor and barSettings.backgroundColor.r or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.g or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.b or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.a or 0.6
    )

    -- Status bar
    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetAllPoints()
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetValue(0)

    -- Get texture
    local texturePath = barSettings.texture or "Interface\\TargetingFrame\\UI-StatusBar"
    local texture = LSM:Fetch("statusbar", texturePath) or texturePath
    bar.statusBar:SetStatusBarTexture(texture)

    -- Spark effect (optional glow at bar edge)
    bar.spark = bar.statusBar:CreateTexture(nil, "OVERLAY")
    bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    bar.spark:SetSize(16, bar:GetHeight() * 2)
    bar.spark:SetBlendMode("ADD")
    bar.spark:SetVertexColor(1, 1, 1, 0.5)
    bar.spark:Hide()

    -- Icon
    bar.icon = bar:CreateTexture(nil, "OVERLAY")
    bar.icon:SetSize(barSettings.iconSize or 16, barSettings.iconSize or 16)
    bar.icon:SetPoint("LEFT", bar, "LEFT", 2, 0)
    bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Trim icon borders

    -- Rank text
    bar.rank = bar:CreateFontString(nil, "OVERLAY")
    bar.rank:SetPoint("LEFT", bar.icon, "RIGHT", 2, 0)
    bar.rank:SetFont(
        barSettings.rankFont or "Fonts\\FRIZQT__.TTF",
        barSettings.rankFontSize or 9,
        barSettings.fontFlags or "OUTLINE"
    )
    bar.rank:SetTextColor(0.8, 0.8, 0.8, 1)
    bar.rank:SetWidth(16)
    bar.rank:SetJustifyH("CENTER")

    -- Name text
    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetPoint("LEFT", bar.rank, "RIGHT", 2, 0)
    bar.name:SetFont(
        barSettings.font or "Fonts\\FRIZQT__.TTF",
        barSettings.fontSize or 11,
        barSettings.fontFlags or "OUTLINE"
    )
    bar.name:SetTextColor(
        barSettings.fontColor and barSettings.fontColor.r or 1,
        barSettings.fontColor and barSettings.fontColor.g or 1,
        barSettings.fontColor and barSettings.fontColor.b or 1,
        barSettings.fontColor and barSettings.fontColor.a or 1
    )
    bar.name:SetJustifyH("LEFT")

    -- Value text (right side)
    bar.value = bar:CreateFontString(nil, "OVERLAY")
    bar.value:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    bar.value:SetFont(
        barSettings.font or "Fonts\\FRIZQT__.TTF",
        barSettings.fontSize or 11,
        barSettings.fontFlags or "OUTLINE"
    )
    bar.value:SetTextColor(1, 1, 1, 1)
    bar.value:SetJustifyH("RIGHT")

    -- Percent text
    bar.percent = bar:CreateFontString(nil, "OVERLAY")
    bar.percent:SetPoint("RIGHT", bar.value, "LEFT", -4, 0)
    bar.percent:SetFont(
        barSettings.font or "Fonts\\FRIZQT__.TTF",
        barSettings.fontSize - 1 or 10,
        barSettings.fontFlags or "OUTLINE"
    )
    bar.percent:SetTextColor(0.8, 0.8, 0.8, 1)
    bar.percent:SetJustifyH("RIGHT")

    -- Set name width to fill space
    bar.name:SetPoint("RIGHT", bar.percent, "LEFT", -4, 0)

    -- Shadow effect (if enabled)
    if barSettings.showShadow then
        bar.shadow = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
        bar.shadow:SetPoint("TOPLEFT", barSettings.shadowOffset or 1, -(barSettings.shadowOffset or 1))
        bar.shadow:SetPoint("BOTTOMRIGHT", barSettings.shadowOffset or 1, -(barSettings.shadowOffset or 1))
        bar.shadow:SetColorTexture(
            barSettings.shadowColor and barSettings.shadowColor.r or 0,
            barSettings.shadowColor and barSettings.shadowColor.g or 0,
            barSettings.shadowColor and barSettings.shadowColor.b or 0,
            barSettings.shadowColor and barSettings.shadowColor.a or 0.5
        )
    end

    -- Hover glow
    if barSettings.glowOnHover then
        bar.glow = bar:CreateTexture(nil, "BACKGROUND", nil, -2)
        bar.glow:SetPoint("TOPLEFT", -2, 2)
        bar.glow:SetPoint("BOTTOMRIGHT", 2, -2)
        bar.glow:SetColorTexture(
            barSettings.glowColor and barSettings.glowColor.r or 1,
            barSettings.glowColor and barSettings.glowColor.g or 1,
            barSettings.glowColor and barSettings.glowColor.b or 1,
            barSettings.glowColor and barSettings.glowColor.a or 0.3
        )
        bar.glow:Hide()
    end

    -- Hover highlight
    bar.highlight = bar:CreateTexture(nil, "HIGHLIGHT")
    bar.highlight:SetAllPoints()
    bar.highlight:SetColorTexture(1, 1, 1, 0.1)

    -- Mouse events
    bar:SetScript("OnEnter", function(self)
        if self.glow then
            self.glow:Show()
        end
        if self.actorData and EDM.Tooltip then
            EDM.Tooltip:ShowActorTooltip(self, self.actorData)
        end
    end)

    bar:SetScript("OnLeave", function(self)
        if self.glow then
            self.glow:Hide()
        end
        if EDM.Tooltip then
            EDM.Tooltip:Hide()
        end
    end)

    bar:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if IsShiftKeyDown() then
                -- Report
                if EDM.Combat and self.actorData then
                    print(string.format("%s: %s (%s/s)",
                        self.actorData.name,
                        Utils.FormatNumber(self.actorData.damage),
                        Utils.FormatNumber(self.actorData.damage / math.max(1, EDM.Combat:GetDuration()))
                    ))
                end
            elseif self.actorData and EDM.DetailWindow then
                EDM.DetailWindow:Show(self.actorData)
            end
        elseif button == "RightButton" then
            -- Context menu
            if EDM.Core then
                EDM.Core:CycleDisplayMode()
            end
        end
    end)

    -- Store data reference
    bar.actorData = nil
    bar.targetValue = 0
    bar.currentValue = 0
    bar.index = index

    return bar
end

-- Get bar from pool
function Bars:GetBar(parent, index)
    if self.pool[index] then
        local bar = self.pool[index]
        bar:SetParent(parent)
        bar:Show()
        return bar
    end

    local bar = self:CreateBar(parent, index)
    self.pool[index] = bar
    return bar
end

-- Return bar to pool
function Bars:ReleaseBar(bar)
    bar:Hide()
    bar.actorData = nil
end

-- Release all bars
function Bars:ReleaseAll()
    for _, bar in pairs(self.active) do
        self:ReleaseBar(bar)
    end
    wipe(self.active)
end

-- Set bar data
function Bars:SetBarData(bar, actor, rank, total, duration, mode)
    if not bar or not actor then return end

    bar.actorData = actor

    -- Calculate value based on mode
    local value = 0
    local perSecond = 0

    if mode == C.DISPLAY_MODE.DAMAGE_DONE or mode == C.DISPLAY_MODE.DPS then
        value = actor.damage
        perSecond = duration > 0 and (actor.damage / duration) or 0
    elseif mode == C.DISPLAY_MODE.HEALING_DONE or mode == C.DISPLAY_MODE.HPS then
        value = actor.healing
        perSecond = duration > 0 and (actor.healing / duration) or 0
    elseif mode == C.DISPLAY_MODE.DAMAGE_TAKEN then
        value = actor.damageTaken
    elseif mode == C.DISPLAY_MODE.DEATHS then
        value = actor.deaths
    elseif mode == C.DISPLAY_MODE.INTERRUPTS then
        value = actor.interrupts
    elseif mode == C.DISPLAY_MODE.DISPELS then
        value = actor.dispels
    elseif mode == C.DISPLAY_MODE.ABSORBS then
        value = actor.absorbs
    elseif mode == C.DISPLAY_MODE.OVERHEALING then
        value = actor.overhealing
    end

    -- Set bar fill
    local percent = total > 0 and (value / total) or 0
    bar.targetValue = percent

    -- Set color based on class
    local r, g, b = Utils.GetClassColor(actor.class)
    bar.statusBar:SetStatusBarColor(r, g, b, 1)

    -- Special colors for top 3
    if EDM.db and EDM.db.profile.bars.useClassColors then
        -- Keep class color
    elseif rank == 1 then
        bar.statusBar:SetStatusBarColor(1, 0.84, 0, 1) -- Gold
    elseif rank == 2 then
        bar.statusBar:SetStatusBarColor(0.75, 0.75, 0.75, 1) -- Silver
    elseif rank == 3 then
        bar.statusBar:SetStatusBarColor(0.80, 0.50, 0.20, 1) -- Bronze
    end

    -- Set rank
    bar.rank:SetText(rank)

    -- Set name with class color
    local coloredName = Utils.ClassColorText(actor.name, actor.class)
    bar.name:SetText(coloredName)

    -- Set value text
    if mode == C.DISPLAY_MODE.DPS or mode == C.DISPLAY_MODE.HPS then
        bar.value:SetText(Utils.FormatNumber(perSecond) .. "/s")
    else
        bar.value:SetText(Utils.FormatNumber(value))
    end

    -- Set percent
    bar.percent:SetText(Utils.FormatPercent(value, total))

    -- Set icon (using class icon if no specific spell icon)
    local icon = actor.class and ("Interface\\Icons\\ClassIcon_" .. actor.class) or "Interface\\Icons\\INV_Misc_QuestionMark"
    bar.icon:SetTexture(icon)
end

-- Animate bar to target value
function Bars:AnimateBar(bar, instant)
    if not bar then return end

    if instant or not EDM.db or not EDM.db.profile.bars.animation then
        bar.statusBar:SetValue(bar.targetValue)
        bar.currentValue = bar.targetValue
    else
        -- Smooth animation using OnUpdate
        if not bar.animating then
            bar.animating = true
            bar:SetScript("OnUpdate", function(self, elapsed)
                local diff = self.targetValue - self.currentValue
                if math.abs(diff) < 0.001 then
                    self.currentValue = self.targetValue
                    self.statusBar:SetValue(self.targetValue)
                    self.animating = false
                    self:SetScript("OnUpdate", nil)
                else
                    local speed = EDM.db.profile.bars.animationSpeed or 0.3
                    local step = diff * math.min(1, elapsed / speed)
                    self.currentValue = self.currentValue + step
                    self.statusBar:SetValue(self.currentValue)

                    -- Update spark position
                    if self.spark and self.spark:IsShown() then
                        local width = self.statusBar:GetWidth()
                        self.spark:SetPoint("CENTER", self.statusBar, "LEFT", width * self.currentValue, 0)
                    end
                end
            end)
        end
    end
end

-- Position bars in container
function Bars:LayoutBars(container, bars, startIndex)
    startIndex = startIndex or 0
    local yOffset = 0
    local spacing = EDM.db and EDM.db.profile.bars.spacing or self.barSpacing
    local height = EDM.db and EDM.db.profile.bars.height or self.barHeight

    for i, bar in ipairs(bars) do
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", container, "TOPLEFT", 0, -yOffset)
        bar:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -yOffset)
        bar:SetHeight(height)
        yOffset = yOffset + height + spacing
    end

    return yOffset
end

-- Update bar appearance from settings
function Bars:ApplySettings()
    local skin = Skins:Get()
    local barSettings = skin and skin.bar or {}

    for _, bar in pairs(self.pool) do
        -- Update texture
        local texturePath = barSettings.texture or "Interface\\TargetingFrame\\UI-StatusBar"
        local texture = LSM:Fetch("statusbar", texturePath) or texturePath
        bar.statusBar:SetStatusBarTexture(texture)

        -- Update height
        bar:SetHeight(barSettings.height or self.barHeight)

        -- Update fonts
        bar.name:SetFont(
            barSettings.font or "Fonts\\FRIZQT__.TTF",
            barSettings.fontSize or 11,
            barSettings.fontFlags or "OUTLINE"
        )
        bar.value:SetFont(
            barSettings.font or "Fonts\\FRIZQT__.TTF",
            barSettings.fontSize or 11,
            barSettings.fontFlags or "OUTLINE"
        )
        bar.percent:SetFont(
            barSettings.font or "Fonts\\FRIZQT__.TTF",
            (barSettings.fontSize or 11) - 1,
            barSettings.fontFlags or "OUTLINE"
        )
        bar.rank:SetFont(
            barSettings.rankFont or "Fonts\\FRIZQT__.TTF",
            barSettings.rankFontSize or 9,
            barSettings.fontFlags or "OUTLINE"
        )

        -- Update icon size
        bar.icon:SetSize(barSettings.iconSize or 16, barSettings.iconSize or 16)
    end
end
