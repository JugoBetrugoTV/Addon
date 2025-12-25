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
DetailWindow.spellDetailFrame = nil

-- Initialize detail window
function DetailWindow:Initialize()
    if self.frame then return end

    -- Create frame with fancy styling
    self.frame = CreateFrame("Frame", "EDMDetailWindow", UIParent, "BackdropTemplate")
    self.frame:SetSize(420, 500)
    self.frame:SetPoint("CENTER", 200, 0)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetFrameLevel(20)
    self.frame:SetMovable(true)
    self.frame:SetResizable(true)
    self.frame:EnableMouse(true)
    self.frame:SetClampedToScreen(true)
    self.frame:SetResizeBounds(350, 300, 700, 800)

    -- Apply fancy backdrop with nicer border
    self.frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    self.frame:SetBackdropColor(0.02, 0.02, 0.04, 0.98)
    self.frame:SetBackdropBorderColor(0.4, 0.5, 0.7, 0.9)

    -- Inner glow/shadow effect
    self.frame.innerGlow = CreateFrame("Frame", nil, self.frame, "BackdropTemplate")
    self.frame.innerGlow:SetPoint("TOPLEFT", 3, -3)
    self.frame.innerGlow:SetPoint("BOTTOMRIGHT", -3, 3)
    self.frame.innerGlow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.frame.innerGlow:SetBackdropColor(0, 0, 0, 0)
    self.frame.innerGlow:SetBackdropBorderColor(0.15, 0.25, 0.4, 0.5)

    -- Fancy title bar with gradient
    self.titleBar = CreateFrame("Frame", nil, self.frame)
    self.titleBar:SetHeight(32)
    self.titleBar:SetPoint("TOPLEFT", 4, -4)
    self.titleBar:SetPoint("TOPRIGHT", -4, -4)

    self.titleBar.bg = self.titleBar:CreateTexture(nil, "BACKGROUND")
    self.titleBar.bg:SetAllPoints()
    self.titleBar.bg:SetColorTexture(0.08, 0.1, 0.15, 1)

    -- Gradient overlay on title bar
    self.titleBar.gradient = self.titleBar:CreateTexture(nil, "ARTWORK")
    self.titleBar.gradient:SetAllPoints()
    self.titleBar.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
    self.titleBar.gradient:SetGradient("VERTICAL", CreateColor(0.12, 0.18, 0.28, 0.9), CreateColor(0.05, 0.07, 0.12, 0.9))

    -- Title bar accent line
    self.titleBar.accentLine = self.titleBar:CreateTexture(nil, "OVERLAY")
    self.titleBar.accentLine:SetHeight(2)
    self.titleBar.accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    self.titleBar.accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    self.titleBar.accentLine:SetColorTexture(0.3, 0.5, 0.8, 0.8)

    -- Title icon
    self.titleBar.icon = self.titleBar:CreateTexture(nil, "ARTWORK")
    self.titleBar.icon:SetSize(22, 22)
    self.titleBar.icon:SetPoint("LEFT", 8, 0)
    self.titleBar.icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    self.titleBar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    self.titleBar.title = self.titleBar:CreateFontString(nil, "OVERLAY")
    self.titleBar.title:SetPoint("LEFT", self.titleBar.icon, "RIGHT", 8, 0)
    self.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    self.titleBar.title:SetTextColor(1, 1, 1, 1)
    self.titleBar.title:SetText("Player Details")
    self.titleBar.title:SetShadowOffset(1, -1)
    self.titleBar.title:SetShadowColor(0, 0, 0, 0.8)

    -- Close button (fancy styled)
    self.closeBtn = CreateFrame("Button", nil, self.titleBar, "BackdropTemplate")
    self.closeBtn:SetSize(24, 24)
    self.closeBtn:SetPoint("RIGHT", -4, 0)
    self.closeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    self.closeBtn:SetBackdropColor(0.5, 0.1, 0.1, 0.5)
    self.closeBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.7)
    self.closeBtn.text = self.closeBtn:CreateFontString(nil, "OVERLAY")
    self.closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    self.closeBtn.text:SetPoint("CENTER", 0, 1)
    self.closeBtn.text:SetText("X")
    self.closeBtn.text:SetTextColor(1, 0.7, 0.7, 1)
    self.closeBtn:SetScript("OnClick", function() self.frame:Hide() end)
    self.closeBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.8, 0.2, 0.2, 0.8) end)
    self.closeBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.5, 0.1, 0.1, 0.5) end)

    -- Player header with better styling
    self.header = CreateFrame("Frame", nil, self.frame)
    self.header:SetHeight(80)
    self.header:SetPoint("TOPLEFT", self.titleBar, "BOTTOMLEFT", 0, 0)
    self.header:SetPoint("TOPRIGHT", self.titleBar, "BOTTOMRIGHT", 0, 0)

    self.header.bg = self.header:CreateTexture(nil, "BACKGROUND")
    self.header.bg:SetAllPoints()
    self.header.bg:SetColorTexture(0.03, 0.04, 0.06, 0.98)

    -- Player icon with border frame
    self.header.iconBorder = CreateFrame("Frame", nil, self.header, "BackdropTemplate")
    self.header.iconBorder:SetSize(58, 58)
    self.header.iconBorder:SetPoint("LEFT", 12, 0)
    self.header.iconBorder:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    self.header.iconBorder:SetBackdropColor(0.1, 0.1, 0.15, 1)
    self.header.iconBorder:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)

    -- Player icon
    self.header.icon = self.header.iconBorder:CreateTexture(nil, "ARTWORK")
    self.header.icon:SetSize(50, 50)
    self.header.icon:SetPoint("CENTER", 0, 0)
    self.header.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Player name
    self.header.name = self.header:CreateFontString(nil, "OVERLAY")
    self.header.name:SetPoint("TOPLEFT", self.header.iconBorder, "TOPRIGHT", 12, -4)
    self.header.name:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    self.header.name:SetShadowOffset(1, -1)
    self.header.name:SetShadowColor(0, 0, 0, 0.8)

    -- Player stats line 1 (Damage/Healing) - with icons
    self.header.stats1 = self.header:CreateFontString(nil, "OVERLAY")
    self.header.stats1:SetPoint("TOPLEFT", self.header.name, "BOTTOMLEFT", 0, -6)
    self.header.stats1:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    self.header.stats1:SetTextColor(0.95, 0.95, 0.95, 1)

    -- Player stats line 2 (Deaths/Interrupts/Dispels)
    self.header.stats2 = self.header:CreateFontString(nil, "OVERLAY")
    self.header.stats2:SetPoint("TOPLEFT", self.header.stats1, "BOTTOMLEFT", 0, -4)
    self.header.stats2:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    self.header.stats2:SetTextColor(0.7, 0.75, 0.8, 1)

    -- Tab buttons with better styling and icons
    self.tabFrame = CreateFrame("Frame", nil, self.frame)
    self.tabFrame:SetHeight(32)
    self.tabFrame:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, 0)
    self.tabFrame:SetPoint("TOPRIGHT", self.header, "BOTTOMRIGHT", 0, 0)

    self.tabFrame.bg = self.tabFrame:CreateTexture(nil, "BACKGROUND")
    self.tabFrame.bg:SetAllPoints()
    self.tabFrame.bg:SetColorTexture(0.04, 0.05, 0.07, 0.98)

    self.tabs = {}
    local tabNames = { "Damage", "Healing", "Targets", "All Spells" }
    local tabIcons = {
        "Interface\\Icons\\Ability_Warrior_BloodFrenzy",
        "Interface\\Icons\\Spell_Holy_FlashHeal",
        "Interface\\Icons\\Ability_Creature_Cursed_02",
        "Interface\\Icons\\Spell_Arcane_TeleportStormWind"
    }
    local tabWidth = 85

    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, self.tabFrame, "BackdropTemplate")
        tab:SetSize(tabWidth, 26)
        tab:SetPoint("LEFT", self.tabFrame, "LEFT", (i - 1) * (tabWidth + 4) + 6, 0)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        tab:SetBackdropColor(0.08, 0.1, 0.14, 0.95)
        tab:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.8)

        -- Tab icon
        tab.icon = tab:CreateTexture(nil, "ARTWORK")
        tab.icon:SetSize(16, 16)
        tab.icon:SetPoint("LEFT", 4, 0)
        tab.icon:SetTexture(tabIcons[i])
        tab.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Tab text
        tab.text = tab:CreateFontString(nil, "OVERLAY")
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        tab.text:SetPoint("LEFT", tab.icon, "RIGHT", 4, 0)
        tab.text:SetText(name)
        tab.text:SetTextColor(0.85, 0.85, 0.9, 1)
        tab.text:SetShadowOffset(1, -1)
        tab.text:SetShadowColor(0, 0, 0, 0.8)

        -- Bottom highlight line (shown when selected)
        tab.highlight = tab:CreateTexture(nil, "OVERLAY")
        tab.highlight:SetHeight(2)
        tab.highlight:SetPoint("BOTTOMLEFT", 2, 1)
        tab.highlight:SetPoint("BOTTOMRIGHT", -2, 1)
        tab.highlight:SetColorTexture(0.4, 0.6, 1, 0.9)
        tab.highlight:Hide()

        tab:SetScript("OnClick", function()
            self:SelectTab(i)
        end)
        tab:SetScript("OnEnter", function(btn)
            if self.selectedTab ~= i then
                btn:SetBackdropColor(0.12, 0.15, 0.22, 1)
                btn:SetBackdropBorderColor(0.3, 0.4, 0.5, 0.9)
            end
        end)
        tab:SetScript("OnLeave", function(btn)
            if self.selectedTab ~= i then
                btn:SetBackdropColor(0.08, 0.1, 0.14, 0.95)
                btn:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.8)
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
            -- Selected tab - bright and highlighted
            tab:SetBackdropColor(0.15, 0.2, 0.3, 1)
            tab:SetBackdropBorderColor(0.4, 0.55, 0.8, 1)
            tab.text:SetTextColor(1, 1, 1, 1)
            tab.icon:SetVertexColor(1, 1, 1, 1)
            if tab.highlight then tab.highlight:Show() end
        else
            -- Unselected tab - dimmer
            tab:SetBackdropColor(0.08, 0.1, 0.14, 0.95)
            tab:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.8)
            tab.text:SetTextColor(0.7, 0.7, 0.75, 1)
            tab.icon:SetVertexColor(0.7, 0.7, 0.7, 1)
            if tab.highlight then tab.highlight:Hide() end
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
        self:ShowAllSpells()
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
    bar:SetHeight(32)
    bar:EnableMouse(true)
    bar:RegisterForClicks("AnyUp")

    -- Fancy backdrop with subtle border
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}
    })
    bar:SetBackdropColor(0.04, 0.05, 0.07, 0.95)
    bar:SetBackdropBorderColor(0.12, 0.15, 0.2, 0.6)

    bar.statusBar = CreateFrame("StatusBar", nil, bar)
    bar.statusBar:SetPoint("TOPLEFT", 1, -1)
    bar.statusBar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar.statusBar:SetMinMaxValues(0, 1)
    bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.statusBar:SetStatusBarColor(0.3, 0.3, 0.6, 0.6)
    bar.statusBar:SetAlpha(0.8)
    bar.statusBar:EnableMouse(false) -- Pass clicks through to parent button

    -- Icon with border frame
    bar.iconBorder = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.iconBorder:SetSize(28, 28)
    bar.iconBorder:SetPoint("LEFT", 3, 0)
    bar.iconBorder:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bar.iconBorder:SetBackdropColor(0, 0, 0, 0.8)
    bar.iconBorder:SetBackdropBorderColor(0.25, 0.3, 0.4, 0.8)
    bar.iconBorder:EnableMouse(false) -- Pass clicks through to parent button

    bar.icon = bar.iconBorder:CreateTexture(nil, "ARTWORK")
    bar.icon:SetSize(24, 24)
    bar.icon:SetPoint("CENTER", 0, 0)
    bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    bar.name = bar:CreateFontString(nil, "OVERLAY")
    bar.name:SetPoint("TOPLEFT", bar.iconBorder, "TOPRIGHT", 8, -2)
    bar.name:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    bar.name:SetTextColor(1, 1, 1, 1)
    bar.name:SetJustifyH("LEFT")
    bar.name:SetShadowOffset(1, -1)
    bar.name:SetShadowColor(0, 0, 0, 1)

    -- Sub text (hits, crits, etc.)
    bar.subText = bar:CreateFontString(nil, "OVERLAY")
    bar.subText:SetPoint("BOTTOMLEFT", bar.iconBorder, "BOTTOMRIGHT", 8, 2)
    bar.subText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    bar.subText:SetTextColor(0.6, 0.65, 0.7, 1)

    bar.value = bar:CreateFontString(nil, "OVERLAY")
    bar.value:SetPoint("TOPRIGHT", -6, -4)
    bar.value:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    bar.value:SetTextColor(1, 1, 1, 1)
    bar.value:SetShadowOffset(1, -1)
    bar.value:SetShadowColor(0, 0, 0, 1)

    bar.percent = bar:CreateFontString(nil, "OVERLAY")
    bar.percent:SetPoint("BOTTOMRIGHT", -6, 3)
    bar.percent:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    bar.percent:SetTextColor(0.75, 0.8, 0.85, 1)

    -- Subtle highlight effect
    bar.highlight = bar:CreateTexture(nil, "HIGHLIGHT")
    bar.highlight:SetAllPoints()
    bar.highlight:SetColorTexture(1, 1, 1, 0.08)

    -- Left accent bar for visual flair
    bar.accent = bar:CreateTexture(nil, "OVERLAY")
    bar.accent:SetSize(3, 28)
    bar.accent:SetPoint("LEFT", 0, 0)
    bar.accent:SetColorTexture(0.4, 0.5, 0.8, 0.5)

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

        -- Enhanced tooltip with detailed info
        local abilityRef = ability
        local durationRef = duration
        bar:SetScript("OnEnter", function(self)
            DetailWindow:ShowSpellTooltip(self, abilityRef, true, durationRef)
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Click to show spell detail popup
        bar:SetScript("OnClick", function()
            DetailWindow:ShowSpellDetail(abilityRef, true, durationRef)
        end)

        -- Color the accent bar based on damage type
        if bar.accent then
            bar.accent:SetColorTexture(0.9, 0.25, 0.2, 0.7)
        end

        yOffset = yOffset + 34
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

        -- Enhanced tooltip
        local abilityRef = ability
        local durationRef = duration
        bar:SetScript("OnEnter", function(self)
            DetailWindow:ShowSpellTooltip(self, abilityRef, false, durationRef)
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Click to show spell detail popup
        bar:SetScript("OnClick", function()
            DetailWindow:ShowSpellDetail(abilityRef, false, durationRef)
        end)

        -- Color the accent bar for healing
        if bar.accent then
            bar.accent:SetColorTexture(0.2, 0.9, 0.3, 0.7)
        end

        yOffset = yOffset + 34
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

        -- Color the accent bar for targets (orange)
        if bar.accent then
            bar.accent:SetColorTexture(0.95, 0.6, 0.2, 0.7)
        end

        yOffset = yOffset + 34
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Show all spells tab (combined damage + healing + utility abilities)
function DetailWindow:ShowAllSpells()
    local actor = self.currentActor
    if not actor then return end

    local contentWidth = self.content:GetWidth() or 380
    local yOffset = 0
    local barIndex = 1

    -- Collect all abilities with their total impact
    local allAbilities = {}
    for spellId, ability in pairs(actor.abilities or {}) do
        local totalImpact = (ability.damage or 0) + (ability.healing or 0) + (ability.absorbs or 0)
        if totalImpact > 0 or (ability.damageHits or 0) + (ability.healingHits or 0) + (ability.absorbCount or 0) > 0 then
            table.insert(allAbilities, {
                spellId = spellId,
                name = ability.name,
                icon = ability.icon,
                damage = ability.damage or 0,
                healing = ability.healing or 0,
                absorbs = ability.absorbs or 0,
                total = totalImpact,
                hits = (ability.damageHits or 0) + (ability.healingHits or 0),
                crits = (ability.damageCrits or 0) + (ability.healingCrits or 0),
                damageMax = ability.damageMax or 0,
                damageMin = ability.damageMin or 0,
            })
        end
    end

    -- Sort by total impact
    table.sort(allAbilities, function(a, b)
        return a.total > b.total
    end)

    -- Display abilities
    local maxImpact = allAbilities[1] and allAbilities[1].total or 1

    for i, ability in ipairs(allAbilities) do
        if barIndex > 50 then break end

        local bar = self:GetAbilityBar(barIndex)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        bar:SetWidth(contentWidth - 8)

        -- Icon
        local spellInfo = Utils.GetSpellInfo(ability.spellId)
        bar.icon:SetTexture(ability.icon or (spellInfo and spellInfo.icon) or "Interface\\Icons\\INV_Misc_QuestionMark")
        bar.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        -- Name
        bar.name:SetText(ability.name or "Unknown")

        -- Determine type and color
        local typeStr = ""
        local barColor = {0.4, 0.4, 0.5}
        if ability.damage > 0 and ability.healing > 0 then
            typeStr = "|cffff6666DMG|r + |cff66ff66HEAL|r"
            barColor = {0.6, 0.4, 0.6}
        elseif ability.damage > 0 then
            typeStr = "|cffff6666Damage|r"
            barColor = {0.8, 0.3, 0.2}
        elseif ability.healing > 0 then
            typeStr = "|cff66ff66Healing|r"
            barColor = {0.2, 0.7, 0.3}
        elseif ability.absorbs > 0 then
            typeStr = "|cffffff66Absorb|r"
            barColor = {0.8, 0.7, 0.2}
        end

        bar.subText:SetText(string.format("%s | Hits: %d | Crits: %d", typeStr, ability.hits, ability.crits))

        -- Value
        bar.value:SetText(Utils.FormatNumber(ability.total))
        bar.value:SetTextColor(1, 0.9, 0.6, 1)

        -- Bar value
        local percent = ability.total / maxImpact
        bar.statusBar:SetValue(percent)
        bar.statusBar:SetStatusBarColor(barColor[1], barColor[2], barColor[3], 0.8)

        -- Percent text
        local totalActorDamageHealing = (actor.damage or 0) + (actor.healing or 0)
        local percentOfTotal = totalActorDamageHealing > 0 and ((ability.total / totalActorDamageHealing) * 100) or 0
        bar.percent:SetText(string.format("%.1f%%", percentOfTotal))
        bar.percent:SetTextColor(0.8, 0.8, 0.8, 1)

        -- Accent color
        if bar.accent then
            bar.accent:SetColorTexture(barColor[1], barColor[2], barColor[3], 0.6)
        end

        -- Tooltip with more details
        bar:SetScript("OnEnter", function(btn)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(ability.name or "Unknown", 1, 1, 1)
            if ability.damage > 0 then
                GameTooltip:AddLine(string.format("Damage: %s", Utils.FormatNumber(ability.damage)), 1, 0.4, 0.4)
                if ability.damageMin > 0 then
                    GameTooltip:AddLine(string.format("Min/Max: %s / %s", Utils.FormatNumber(ability.damageMin), Utils.FormatNumber(ability.damageMax)), 0.7, 0.7, 0.7)
                end
            end
            if ability.healing > 0 then
                GameTooltip:AddLine(string.format("Healing: %s", Utils.FormatNumber(ability.healing)), 0.4, 1, 0.4)
            end
            if ability.absorbs > 0 then
                GameTooltip:AddLine(string.format("Absorbs: %s", Utils.FormatNumber(ability.absorbs)), 1, 1, 0.4)
            end
            GameTooltip:AddLine(string.format("Hits: %d | Crits: %d (%.1f%%)", ability.hits, ability.crits, ability.hits > 0 and (ability.crits / ability.hits * 100) or 0), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        bar:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        bar:SetScript("OnClick", nil)

        yOffset = yOffset + 34
        barIndex = barIndex + 1
    end

    -- Add utility section (interrupts, dispels)
    local interrupts = actor.interrupts or 0
    local dispels = actor.dispels or 0
    local deaths = actor.deaths or 0

    if interrupts > 0 or dispels > 0 or deaths > 0 then
        yOffset = yOffset + 10 -- Spacer

        -- Utility header
        local headerBar = self:GetAbilityBar(barIndex)
        headerBar:ClearAllPoints()
        headerBar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        headerBar:SetWidth(contentWidth - 8)
        headerBar.icon:SetTexture("Interface\\Icons\\Trade_Engineering")
        headerBar.name:SetText("|cff88aaccUtility Summary|r")
        headerBar.subText:SetText("")
        headerBar.value:SetText("")
        headerBar.percent:SetText("")
        headerBar.statusBar:SetValue(0)
        if headerBar.accent then headerBar.accent:SetColorTexture(0.4, 0.6, 0.8, 0.7) end
        headerBar:SetScript("OnEnter", nil)
        headerBar:SetScript("OnLeave", nil)
        headerBar:SetScript("OnClick", nil)
        yOffset = yOffset + 36
        barIndex = barIndex + 1

        -- Show utility stats
        if interrupts > 0 then
            local bar = self:GetAbilityBar(barIndex)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 12, -yOffset)
            bar:SetWidth(contentWidth - 20)
            bar.icon:SetTexture("Interface\\Icons\\Ability_Kick")
            bar.name:SetText("|cff00ccffInterrupts|r")
            bar.subText:SetText("")
            bar.value:SetText(tostring(interrupts))
            bar.value:SetTextColor(0, 0.8, 1, 1)
            bar.percent:SetText("")
            bar.statusBar:SetValue(0)
            if bar.accent then bar.accent:SetColorTexture(0, 0.6, 0.8, 0.5) end
            bar:SetScript("OnEnter", nil)
            bar:SetScript("OnLeave", nil)
            yOffset = yOffset + 34
            barIndex = barIndex + 1
        end

        if dispels > 0 then
            local bar = self:GetAbilityBar(barIndex)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 12, -yOffset)
            bar:SetWidth(contentWidth - 20)
            bar.icon:SetTexture("Interface\\Icons\\Spell_Holy_DispelMagic")
            bar.name:SetText("|cff00ff00Dispels|r")
            bar.subText:SetText("")
            bar.value:SetText(tostring(dispels))
            bar.value:SetTextColor(0.3, 1, 0.4, 1)
            bar.percent:SetText("")
            bar.statusBar:SetValue(0)
            if bar.accent then bar.accent:SetColorTexture(0.2, 0.8, 0.3, 0.5) end
            bar:SetScript("OnEnter", nil)
            bar:SetScript("OnLeave", nil)
            yOffset = yOffset + 34
            barIndex = barIndex + 1
        end

        if deaths > 0 then
            local bar = self:GetAbilityBar(barIndex)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 12, -yOffset)
            bar:SetWidth(contentWidth - 20)
            bar.icon:SetTexture("Interface\\Icons\\Ability_Rogue_FeignDeath")
            bar.name:SetText("|cffff4444Deaths|r")
            bar.subText:SetText("")
            bar.value:SetText(tostring(deaths))
            bar.value:SetTextColor(1, 0.3, 0.3, 1)
            bar.percent:SetText("")
            bar.statusBar:SetValue(0)
            if bar.accent then bar.accent:SetColorTexture(1, 0.2, 0.2, 0.5) end
            bar:SetScript("OnEnter", nil)
            bar:SetScript("OnLeave", nil)
            yOffset = yOffset + 34
            barIndex = barIndex + 1
        end
    end

    -- If nothing to show
    if barIndex == 1 then
        local noData = self.scrollChild:CreateFontString(nil, "OVERLAY")
        noData:SetPoint("CENTER", 0, 0)
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noData:SetTextColor(0.6, 0.6, 0.6, 1)
        noData:SetText("No spells recorded yet")
        self.scrollChild:SetHeight(50)
        return
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Hide
function DetailWindow:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

--============================================================================
-- SPELL DETAIL POPUP
--============================================================================

-- Create mini-graph frame for tooltip
function DetailWindow:CreateMiniGraph(parent)
    local graph = CreateFrame("Frame", nil, parent)
    graph:SetSize(180, 60)

    graph.bg = graph:CreateTexture(nil, "BACKGROUND")
    graph.bg:SetAllPoints()
    graph.bg:SetColorTexture(0, 0, 0, 0.5)

    graph.lines = {}

    return graph
end

-- Draw mini-graph with damage data
function DetailWindow:DrawMiniGraph(graph, ability, isDamage)
    -- Clear existing lines
    for _, line in ipairs(graph.lines) do
        line:Hide()
    end

    if not ability or not ability.timeline or #(ability.timeline or {}) < 2 then
        -- No timeline data, show placeholder
        local noData = graph:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        noData:SetPoint("CENTER")
        noData:SetTextColor(0.5, 0.5, 0.5, 1)
        noData:SetText("No timeline data")
        return
    end

    local width, height = graph:GetSize()
    local maxValue = 0
    local points = ability.timeline

    for _, val in ipairs(points) do
        if val > maxValue then maxValue = val end
    end
    if maxValue == 0 then maxValue = 1 end

    local color = isDamage and {0.9, 0.2, 0.2} or {0.2, 0.9, 0.2}
    local lastX, lastY

    for i, val in ipairs(points) do
        local x = ((i - 1) / (#points - 1)) * width
        local y = (val / maxValue) * (height - 10) + 5

        if lastX and lastY then
            local lineIndex = #graph.lines + 1
            if not graph.lines[lineIndex] then
                graph.lines[lineIndex] = graph:CreateLine(nil, "ARTWORK")
                graph.lines[lineIndex]:SetThickness(1.5)
            end
            local line = graph.lines[lineIndex]
            line:SetVertexColor(color[1], color[2], color[3], 1)
            line:SetStartPoint("BOTTOMLEFT", graph, lastX, lastY)
            line:SetEndPoint("BOTTOMLEFT", graph, x, y)
            line:Show()
        end

        lastX, lastY = x, y
    end
end

-- Show enhanced tooltip with mini-graph
function DetailWindow:ShowSpellTooltip(bar, ability, isDamage, duration)
    if not ability then return end

    GameTooltip:SetOwner(bar, "ANCHOR_RIGHT")
    GameTooltip:AddLine(ability.name or "Unknown", 1, 1, 1)
    GameTooltip:AddLine(" ")

    if isDamage then
        local dps = (ability.damage or 0) / (duration or 1)
        local hits = ability.damageHits or 0
        local crits = ability.damageCrits or 0
        local critPct = hits > 0 and ((crits / hits) * 100) or 0
        local avgDmg = hits > 0 and ((ability.damage or 0) / hits) or 0

        GameTooltip:AddDoubleLine("Total Damage:", Utils.FormatNumber(ability.damage or 0), 0.7, 0.7, 0.7, 1, 0.5, 0.5)
        GameTooltip:AddDoubleLine("DPS:", string.format("%.1f", dps), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Total Hits:", string.format("%d", hits), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Critical Hits:", string.format("%d (%.1f%%)", crits, critPct), 0.7, 0.7, 0.7, 1, 0.8, 0.2)
        GameTooltip:AddDoubleLine("Average Hit:", Utils.FormatNumber(avgDmg), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Min Hit:", Utils.FormatNumber(ability.damageMin or 0), 0.7, 0.7, 0.7, 0.5, 1, 0.5)
        GameTooltip:AddDoubleLine("Max Hit:", Utils.FormatNumber(ability.damageMax or 0), 0.7, 0.7, 0.7, 1, 0.5, 0.5)

        -- Miss types
        if ability.misses then
            local totalMisses = 0
            for _, count in pairs(ability.misses) do totalMisses = totalMisses + count end
            if totalMisses > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Miss Breakdown:", 0.9, 0.6, 0.2)
                for missType, count in pairs(ability.misses) do
                    if count > 0 then
                        GameTooltip:AddDoubleLine(missType, count, 0.6, 0.6, 0.6, 1, 0.5, 0.5)
                    end
                end
            end
        end
    else
        local hps = (ability.healing or 0) / (duration or 1)
        local hits = ability.healingHits or 0
        local crits = ability.healingCrits or 0
        local critPct = hits > 0 and ((crits / hits) * 100) or 0
        local overheal = ability.overhealing or 0
        local totalHeal = (ability.healing or 0) + overheal
        local overhealPct = totalHeal > 0 and ((overheal / totalHeal) * 100) or 0

        GameTooltip:AddDoubleLine("Effective Healing:", Utils.FormatNumber(ability.healing or 0), 0.7, 0.7, 0.7, 0.5, 1, 0.5)
        GameTooltip:AddDoubleLine("Overhealing:", Utils.FormatNumber(overheal), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
        GameTooltip:AddDoubleLine("Overheal %:", string.format("%.1f%%", overhealPct), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
        GameTooltip:AddDoubleLine("HPS:", string.format("%.1f", hps), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Total Hits:", string.format("%d", hits), 0.7, 0.7, 0.7, 1, 1, 1)
        GameTooltip:AddDoubleLine("Critical Heals:", string.format("%d (%.1f%%)", crits, critPct), 0.7, 0.7, 0.7, 1, 0.8, 0.2)
    end

    -- Targets hit
    if ability.targets and next(ability.targets) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Targets Hit:", 0.9, 0.7, 0.3)
        local targetCount = 0
        local sortedTargets = {}
        for guid, target in pairs(ability.targets) do
            table.insert(sortedTargets, target)
            targetCount = targetCount + 1
        end
        table.sort(sortedTargets, function(a, b)
            return (isDamage and a.damage or a.healing or 0) > (isDamage and b.damage or b.healing or 0)
        end)

        for i = 1, math.min(5, #sortedTargets) do
            local target = sortedTargets[i]
            local val = isDamage and target.damage or (target.healing or 0)
            GameTooltip:AddDoubleLine(target.name or "Unknown", Utils.FormatNumber(val), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        if targetCount > 5 then
            GameTooltip:AddLine(string.format("... and %d more", targetCount - 5), 0.5, 0.5, 0.5)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff66ff66Click|r for detailed breakdown", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- Create spell detail popup window
function DetailWindow:CreateSpellDetailFrame()
    if self.spellDetailFrame then return end

    local frame = CreateFrame("Frame", "EDMSpellDetailFrame", UIParent, "BackdropTemplate")
    frame:SetSize(370, 420)
    frame:SetPoint("CENTER", 300, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(30)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:SetResizeBounds(300, 320, 520, 620)

    -- Beautiful backdrop with tooltip-style border
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.02, 0.02, 0.04, 0.98)
    frame:SetBackdropBorderColor(0.45, 0.55, 0.75, 0.9)

    -- Inner glow effect
    frame.innerGlow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.innerGlow:SetPoint("TOPLEFT", 3, -3)
    frame.innerGlow:SetPoint("BOTTOMRIGHT", -3, 3)
    frame.innerGlow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.innerGlow:SetBackdropColor(0, 0, 0, 0)
    frame.innerGlow:SetBackdropBorderColor(0.2, 0.3, 0.5, 0.4)

    -- Title bar with gradient
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetHeight(30)
    frame.titleBar:SetPoint("TOPLEFT", 4, -4)
    frame.titleBar:SetPoint("TOPRIGHT", -4, -4)

    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints()
    frame.titleBar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.titleBar.bg:SetGradient("VERTICAL", CreateColor(0.12, 0.18, 0.28, 1), CreateColor(0.06, 0.08, 0.12, 1))

    -- Accent line under title
    frame.titleBar.accent = frame.titleBar:CreateTexture(nil, "OVERLAY")
    frame.titleBar.accent:SetHeight(2)
    frame.titleBar.accent:SetPoint("BOTTOMLEFT", 0, 0)
    frame.titleBar.accent:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.titleBar.accent:SetColorTexture(0.35, 0.55, 0.85, 0.8)

    -- Icon with border
    frame.titleBar.iconBorder = CreateFrame("Frame", nil, frame.titleBar, "BackdropTemplate")
    frame.titleBar.iconBorder:SetSize(26, 26)
    frame.titleBar.iconBorder:SetPoint("LEFT", 4, 0)
    frame.titleBar.iconBorder:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.titleBar.iconBorder:SetBackdropColor(0, 0, 0, 0.8)
    frame.titleBar.iconBorder:SetBackdropBorderColor(0.3, 0.4, 0.6, 0.8)

    frame.titleBar.icon = frame.titleBar.iconBorder:CreateTexture(nil, "ARTWORK")
    frame.titleBar.icon:SetSize(22, 22)
    frame.titleBar.icon:SetPoint("CENTER", 0, 0)
    frame.titleBar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.titleBar.title = frame.titleBar:CreateFontString(nil, "OVERLAY")
    frame.titleBar.title:SetPoint("LEFT", frame.titleBar.iconBorder, "RIGHT", 8, 0)
    frame.titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    frame.titleBar.title:SetTextColor(1, 1, 1, 1)
    frame.titleBar.title:SetShadowOffset(1, -1)
    frame.titleBar.title:SetShadowColor(0, 0, 0, 0.8)

    -- Close button (styled)
    frame.closeBtn = CreateFrame("Button", nil, frame.titleBar, "BackdropTemplate")
    frame.closeBtn:SetSize(22, 22)
    frame.closeBtn:SetPoint("RIGHT", -4, 0)
    frame.closeBtn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    frame.closeBtn:SetBackdropColor(0.5, 0.1, 0.1, 0.5)
    frame.closeBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.7)
    frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY")
    frame.closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    frame.closeBtn.text:SetPoint("CENTER", 0, 1)
    frame.closeBtn.text:SetText("X")
    frame.closeBtn.text:SetTextColor(1, 0.7, 0.7, 1)
    frame.closeBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.closeBtn:SetScript("OnEnter", function(btn) btn:SetBackdropColor(0.8, 0.2, 0.2, 0.8) end)
    frame.closeBtn:SetScript("OnLeave", function(btn) btn:SetBackdropColor(0.5, 0.1, 0.1, 0.5) end)

    -- Stats section with backdrop
    frame.statsFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.statsFrame:SetHeight(120)
    frame.statsFrame:SetPoint("TOPLEFT", frame.titleBar, "BOTTOMLEFT", 4, -8)
    frame.statsFrame:SetPoint("TOPRIGHT", frame.titleBar, "BOTTOMRIGHT", -4, -8)
    frame.statsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.statsFrame:SetBackdropColor(0.03, 0.04, 0.06, 0.9)
    frame.statsFrame:SetBackdropBorderColor(0.12, 0.15, 0.22, 0.6)

    -- Create stat labels
    frame.statsLabels = {}
    local statNames = {"Total", "Per Second", "Hits", "Crits", "Crit %", "Average", "Min", "Max"}
    for i, name in ipairs(statNames) do
        local row = math.ceil(i / 2)
        local col = ((i - 1) % 2) + 1

        local label = frame.statsFrame:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        label:SetPoint("TOPLEFT", 8 + (col - 1) * 160, -8 - (row - 1) * 26)
        label:SetTextColor(0.7, 0.7, 0.7, 1)
        label:SetText(name .. ":")

        local value = frame.statsFrame:CreateFontString(nil, "OVERLAY")
        value:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
        value:SetTextColor(1, 1, 1, 1)

        frame.statsLabels[name] = value
    end

    -- Mini graph with styled backdrop
    frame.miniGraph = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.miniGraph:SetHeight(80)
    frame.miniGraph:SetPoint("TOPLEFT", frame.statsFrame, "BOTTOMLEFT", 0, -8)
    frame.miniGraph:SetPoint("TOPRIGHT", frame.statsFrame, "BOTTOMRIGHT", 0, -8)
    frame.miniGraph:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame.miniGraph:SetBackdropColor(0.02, 0.03, 0.05, 0.95)
    frame.miniGraph:SetBackdropBorderColor(0.12, 0.15, 0.22, 0.6)

    frame.miniGraph.label = frame.miniGraph:CreateFontString(nil, "OVERLAY")
    frame.miniGraph.label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    frame.miniGraph.label:SetPoint("TOP", 0, -4)
    frame.miniGraph.label:SetTextColor(0.8, 0.85, 0.9, 1)
    frame.miniGraph.label:SetText("Damage Over Time")
    frame.miniGraph.label:SetShadowOffset(1, -1)

    frame.miniGraph.lines = {}

    -- Targets section
    frame.targetsLabel = frame:CreateFontString(nil, "OVERLAY")
    frame.targetsLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    frame.targetsLabel:SetPoint("TOPLEFT", frame.miniGraph, "BOTTOMLEFT", 0, -12)
    frame.targetsLabel:SetTextColor(0.9, 0.7, 0.3, 1)
    frame.targetsLabel:SetText("Targets:")

    -- Targets list (scrollable)
    frame.targetsContent = CreateFrame("Frame", nil, frame)
    frame.targetsContent:SetPoint("TOPLEFT", frame.targetsLabel, "BOTTOMLEFT", 0, -4)
    frame.targetsContent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 24)
    frame.targetsContent:SetClipsChildren(true)

    frame.targetsScroll = CreateFrame("Frame", nil, frame.targetsContent)
    frame.targetsScroll:SetPoint("TOPLEFT", 0, 0)
    frame.targetsScroll:SetWidth(frame.targetsContent:GetWidth() or 300)
    frame.targetsScroll:SetHeight(1)

    frame.targetBars = {}

    -- Scroll
    frame.targetsContent:EnableMouseWheel(true)
    frame.targetsScrollOffset = 0
    frame.targetsContent:SetScript("OnMouseWheel", function(_, delta)
        local maxScroll = math.max(0, (frame.targetsScroll:GetHeight() or 0) - (frame.targetsContent:GetHeight() or 100))
        frame.targetsScrollOffset = frame.targetsScrollOffset - (delta * 25)
        frame.targetsScrollOffset = math.max(0, math.min(maxScroll, frame.targetsScrollOffset))
        frame.targetsScroll:SetPoint("TOPLEFT", 0, frame.targetsScrollOffset)
    end)

    -- Resize handle
    frame.resizeHandle = CreateFrame("Frame", nil, frame)
    frame.resizeHandle:SetSize(16, 16)
    frame.resizeHandle:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.resizeHandle:EnableMouse(true)
    frame.resizeHandle.tex = frame.resizeHandle:CreateTexture(nil, "OVERLAY")
    frame.resizeHandle.tex:SetAllPoints()
    frame.resizeHandle.tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    frame.resizeHandle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then frame:StartSizing("BOTTOMRIGHT") end
    end)
    frame.resizeHandle:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

    -- Draggable
    frame.titleBar:EnableMouse(true)
    frame.titleBar:RegisterForDrag("LeftButton")
    frame.titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame.titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    frame:Hide()
    self.spellDetailFrame = frame
end

-- Show spell detail popup
function DetailWindow:ShowSpellDetail(ability, isDamage, duration)
    if not ability then return end

    if not self.spellDetailFrame then
        self:CreateSpellDetailFrame()
    end

    local frame = self.spellDetailFrame
    local DB = EDM.Database
    local segment = DB.Data.currentSegment
    duration = duration or (segment and DB:GetSegmentDuration(segment) or 1)
    if duration == 0 then duration = 1 end

    -- Update title
    local spellInfo = Utils.GetSpellInfo(ability.spellId)
    frame.titleBar.icon:SetTexture(spellInfo and spellInfo.icon or ability.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame.titleBar.title:SetText(ability.name or "Unknown Spell")

    -- Update stats
    if isDamage then
        local hits = ability.damageHits or 0
        local crits = ability.damageCrits or 0
        local critPct = hits > 0 and ((crits / hits) * 100) or 0
        local avgDmg = hits > 0 and ((ability.damage or 0) / hits) or 0
        local dps = (ability.damage or 0) / duration

        frame.statsLabels["Total"]:SetText("|cffff6666" .. Utils.FormatNumber(ability.damage or 0) .. "|r")
        frame.statsLabels["Per Second"]:SetText(Utils.FormatNumber(dps) .. " DPS")
        frame.statsLabels["Hits"]:SetText(tostring(hits))
        frame.statsLabels["Crits"]:SetText(tostring(crits))
        frame.statsLabels["Crit %"]:SetText(string.format("%.1f%%", critPct))
        frame.statsLabels["Average"]:SetText(Utils.FormatNumber(avgDmg))
        frame.statsLabels["Min"]:SetText(Utils.FormatNumber(ability.damageMin or 0))
        frame.statsLabels["Max"]:SetText("|cffff0000" .. Utils.FormatNumber(ability.damageMax or 0) .. "|r")
        frame.miniGraph.label:SetText("Damage Over Time")
    else
        local hits = ability.healingHits or 0
        local crits = ability.healingCrits or 0
        local critPct = hits > 0 and ((crits / hits) * 100) or 0
        local overheal = ability.overhealing or 0
        local totalHeal = (ability.healing or 0) + overheal
        local overhealPct = totalHeal > 0 and ((overheal / totalHeal) * 100) or 0
        local hps = (ability.healing or 0) / duration

        frame.statsLabels["Total"]:SetText("|cff66ff66" .. Utils.FormatNumber(ability.healing or 0) .. "|r")
        frame.statsLabels["Per Second"]:SetText(Utils.FormatNumber(hps) .. " HPS")
        frame.statsLabels["Hits"]:SetText(tostring(hits))
        frame.statsLabels["Crits"]:SetText(tostring(crits))
        frame.statsLabels["Crit %"]:SetText(string.format("%.1f%%", critPct))
        frame.statsLabels["Average"]:SetText("--")
        frame.statsLabels["Min"]:SetText(Utils.FormatNumber(overheal) .. " OH")
        frame.statsLabels["Max"]:SetText(string.format("%.1f%% OH", overhealPct))
        frame.miniGraph.label:SetText("Healing Over Time")
    end

    -- Update targets
    local targets = ability.targets or {}
    local sortedTargets = {}
    for guid, target in pairs(targets) do
        table.insert(sortedTargets, target)
    end
    table.sort(sortedTargets, function(a, b)
        local aVal = isDamage and (a.damage or 0) or (a.healing or 0)
        local bVal = isDamage and (b.damage or 0) or (b.healing or 0)
        return aVal > bVal
    end)

    local total = isDamage and (ability.damage or 1) or (ability.healing or 1)
    if total == 0 then total = 1 end
    local maxVal = sortedTargets[1] and (isDamage and sortedTargets[1].damage or sortedTargets[1].healing) or 1
    if maxVal == 0 then maxVal = 1 end

    local yOffset = 0
    for i, target in ipairs(sortedTargets) do
        if i > 20 then break end

        local bar = frame.targetBars[i]
        if not bar then
            bar = CreateFrame("Frame", nil, frame.targetsScroll, "BackdropTemplate")
            bar:SetHeight(22)
            bar.bg = bar:CreateTexture(nil, "BACKGROUND")
            bar.bg:SetAllPoints()
            bar.bg:SetColorTexture(0.05, 0.05, 0.07, 0.9)
            bar.statusBar = CreateFrame("StatusBar", nil, bar)
            bar.statusBar:SetAllPoints()
            bar.statusBar:SetMinMaxValues(0, 1)
            bar.statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
            bar.statusBar:SetAlpha(0.6)
            bar.statusBar:EnableMouse(false)
            bar.name = bar:CreateFontString(nil, "OVERLAY")
            bar.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            bar.name:SetPoint("LEFT", 4, 0)
            bar.name:SetTextColor(1, 1, 1, 1)
            bar.value = bar:CreateFontString(nil, "OVERLAY")
            bar.value:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            bar.value:SetPoint("RIGHT", -4, 0)
            bar.value:SetTextColor(1, 1, 1, 1)
            frame.targetBars[i] = bar
        end

        local val = isDamage and (target.damage or 0) or (target.healing or 0)
        local pct = (val / total) * 100

        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", frame.targetsScroll, "TOPLEFT", 0, -yOffset)
        bar:SetPoint("TOPRIGHT", frame.targetsScroll, "TOPRIGHT", 0, -yOffset)
        bar.name:SetText(target.name or "Unknown")
        bar.value:SetText(string.format("%s (%.1f%%)", Utils.FormatNumber(val), pct))
        bar.statusBar:SetValue(val / maxVal)
        bar.statusBar:SetStatusBarColor(isDamage and 0.8 or 0.2, isDamage and 0.3 or 0.8, isDamage and 0.3 or 0.2, 0.7)
        bar:Show()

        yOffset = yOffset + 24
    end

    -- Hide unused bars
    for i = #sortedTargets + 1, #frame.targetBars do
        if frame.targetBars[i] then
            frame.targetBars[i]:Hide()
        end
    end

    frame.targetsScroll:SetHeight(math.max(yOffset, 1))
    frame.targetsScrollOffset = 0
    frame.targetsScroll:SetPoint("TOPLEFT", 0, 0)

    frame:Show()
end
