--[[
    EpicDamageMeter - Widgets
    Reusable UI widget components
]]

local ADDON_NAME, EDM = ...

EDM.Widgets = {}
local Widgets = EDM.Widgets
local Skins = EDM.Skins

-- Localize frequently used globals for performance
local pairs = pairs
local CreateFrame = CreateFrame
local CreateColor = CreateColor
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local GameTooltip = GameTooltip

-- Create a skinned frame with backdrop
function Widgets:CreateFrame(name, parent, template)
    local frame = CreateFrame("Frame", name, parent or UIParent, template or "BackdropTemplate")
    return frame
end

-- Create a title bar
function Widgets:CreateTitleBar(parent, title, height, skinName)
    local skin = Skins:Get(skinName)
    local titleBar = CreateFrame("Frame", nil, parent)
    titleBar:SetHeight(height or (skin and skin.titleBar.height) or 22)
    titleBar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

    -- Background texture
    titleBar.texture = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBar.texture:SetAllPoints()
    if skin and skin.titleBar then
        titleBar.texture:SetColorTexture(
            skin.titleBar.backgroundColor.r,
            skin.titleBar.backgroundColor.g,
            skin.titleBar.backgroundColor.b,
            skin.titleBar.backgroundColor.a
        )
    else
        titleBar.texture:SetColorTexture(0.1, 0.1, 0.15, 0.95)
    end

    -- Gradient overlay
    if skin and skin.titleBar.gradientStart then
        titleBar.gradient = titleBar:CreateTexture(nil, "ARTWORK")
        titleBar.gradient:SetAllPoints()
        titleBar.gradient:SetTexture("Interface\\Buttons\\WHITE8X8")
        titleBar.gradient:SetGradient("VERTICAL",
            CreateColor(skin.titleBar.gradientEnd.r, skin.titleBar.gradientEnd.g, skin.titleBar.gradientEnd.b, skin.titleBar.gradientEnd.a),
            CreateColor(skin.titleBar.gradientStart.r, skin.titleBar.gradientStart.g, skin.titleBar.gradientStart.b, skin.titleBar.gradientStart.a)
        )
    end

    -- Title text
    titleBar.title = titleBar:CreateFontString(nil, "OVERLAY")
    titleBar.title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    if skin and skin.titleBar then
        titleBar.title:SetFont(skin.titleBar.font, skin.titleBar.fontSize, skin.titleBar.fontFlags)
        titleBar.title:SetTextColor(
            skin.titleBar.fontColor.r,
            skin.titleBar.fontColor.g,
            skin.titleBar.fontColor.b,
            skin.titleBar.fontColor.a
        )
    else
        titleBar.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        titleBar.title:SetTextColor(1, 1, 1, 1)
    end
    titleBar.title:SetText(title or "")

    -- Make draggable
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not EDM.db or not EDM.db.profile.locked then
            parent:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        parent:StopMovingOrSizing()
        if EDM.db then
            local point, _, _, x, y = parent:GetPoint()
            EDM.db.profile.window.point = point
            EDM.db.profile.window.x = x
            EDM.db.profile.window.y = y
        end
    end)

    return titleBar
end

-- Create close button
function Widgets:CreateCloseButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 16, size or 16)

    -- X texture
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-StopButton")
    button:SetNormalTexture(tex)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 0.2, 0.2, 0.3)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", onClick or function()
        parent:Hide()
    end)

    return button
end

-- Create minimize button
function Widgets:CreateMinimizeButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 16, size or 16)

    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    button:SetNormalTexture(tex)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 0.2, 0.3)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", onClick)

    return button
end

-- Create settings button
function Widgets:CreateSettingsButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 16, size or 16)

    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    button:SetNormalTexture(tex)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.2, 0.6, 1, 0.3)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", onClick)

    return button
end

-- Create reset button
function Widgets:CreateResetButton(parent, size, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size or 16, size or 16)

    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    button:SetNormalTexture(tex)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.2, 1, 0.2, 0.3)
    button:SetHighlightTexture(highlight)

    button:SetScript("OnClick", onClick)

    return button
end

-- Create scroll frame
function Widgets:CreateScrollFrame(parent, skinName)
    local skin = Skins:Get(skinName)

    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -22, 4)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(content)

    -- Style scrollbar
    local scrollBar = scrollFrame.ScrollBar
    if scrollBar and skin and skin.scrollbar then
        scrollBar:SetWidth(skin.scrollbar.width)
    end

    scrollFrame.content = content

    return scrollFrame
end

-- Create resize handle
function Widgets:CreateResizeHandle(parent, minWidth, minHeight, maxWidth, maxHeight)
    local handle = CreateFrame("Frame", nil, parent)
    handle:SetSize(16, 16)
    handle:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    handle:EnableMouse(true)

    local tex = handle:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    handle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and (not EDM.db or not EDM.db.profile.locked) then
            parent:StartSizing("BOTTOMRIGHT")
        end
    end)

    handle:SetScript("OnMouseUp", function(self, button)
        parent:StopMovingOrSizing()
        if EDM.db then
            EDM.db.profile.window.width = parent:GetWidth()
            EDM.db.profile.window.height = parent:GetHeight()
        end
        -- Refresh UI
        if EDM.UI then
            EDM.UI:Refresh()
        end
    end)

    -- Set resize bounds
    parent:SetResizeBounds(minWidth or 150, minHeight or 100, maxWidth or 800, maxHeight or 600)

    return handle
end

-- Create dropdown menu
function Widgets:CreateDropdown(parent, width, items, onChange)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dropdown, width or 120)

    local function Initialize(self, level)
        for i, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.checked = item.checked
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, item.value)
                UIDropDownMenu_SetText(dropdown, item.text)
                if onChange then
                    onChange(item.value, item.text)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, Initialize)

    return dropdown
end

-- Create icon with tooltip
function Widgets:CreateIcon(parent, size, texture, tooltipText)
    local icon = CreateFrame("Frame", nil, parent)
    icon:SetSize(size or 16, size or 16)

    local tex = icon:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(texture)
    icon.texture = tex

    if tooltipText then
        icon:EnableMouse(true)
        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText)
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return icon
end

-- Create status bar
function Widgets:CreateStatusBar(parent, width, height, skinName)
    local skin = Skins:Get(skinName)
    local barSettings = skin and skin.bar or {}

    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetSize(width or 200, height or (barSettings.height or 18))
    bar:SetStatusBarTexture(barSettings.texture or "Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetColorTexture(
        barSettings.backgroundColor and barSettings.backgroundColor.r or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.g or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.b or 0.1,
        barSettings.backgroundColor and barSettings.backgroundColor.a or 0.6
    )

    return bar
end

-- Create text button
function Widgets:CreateTextButton(parent, text, width, height, onClick, skinName)
    local skin = Skins:Get(skinName)
    local buttonSettings = skin and skin.button or {}

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 80, height or 22)

    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    button:SetBackdropColor(
        buttonSettings.backgroundColor and buttonSettings.backgroundColor.r or 0.15,
        buttonSettings.backgroundColor and buttonSettings.backgroundColor.g or 0.15,
        buttonSettings.backgroundColor and buttonSettings.backgroundColor.b or 0.2,
        buttonSettings.backgroundColor and buttonSettings.backgroundColor.a or 1
    )
    button:SetBackdropBorderColor(0.3, 0.3, 0.4, 1)

    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetPoint("CENTER")
    button.text:SetFont(
        buttonSettings.font or "Fonts\\FRIZQT__.TTF",
        buttonSettings.fontSize or 10,
        buttonSettings.fontFlags or ""
    )
    button.text:SetText(text)
    button.text:SetTextColor(1, 1, 1, 1)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(
            buttonSettings.hoverColor and buttonSettings.hoverColor.r or 0.25,
            buttonSettings.hoverColor and buttonSettings.hoverColor.g or 0.25,
            buttonSettings.hoverColor and buttonSettings.hoverColor.b or 0.35,
            buttonSettings.hoverColor and buttonSettings.hoverColor.a or 1
        )
    end)

    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(
            buttonSettings.backgroundColor and buttonSettings.backgroundColor.r or 0.15,
            buttonSettings.backgroundColor and buttonSettings.backgroundColor.g or 0.15,
            buttonSettings.backgroundColor and buttonSettings.backgroundColor.b or 0.2,
            buttonSettings.backgroundColor and buttonSettings.backgroundColor.a or 1
        )
    end)

    button:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(
            buttonSettings.pressedColor and buttonSettings.pressedColor.r or 0.1,
            buttonSettings.pressedColor and buttonSettings.pressedColor.g or 0.1,
            buttonSettings.pressedColor and buttonSettings.pressedColor.b or 0.15,
            buttonSettings.pressedColor and buttonSettings.pressedColor.a or 1
        )
    end)

    button:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(
            buttonSettings.hoverColor and buttonSettings.hoverColor.r or 0.25,
            buttonSettings.hoverColor and buttonSettings.hoverColor.g or 0.25,
            buttonSettings.hoverColor and buttonSettings.hoverColor.b or 0.35,
            buttonSettings.hoverColor and buttonSettings.hoverColor.a or 1
        )
    end)

    button:SetScript("OnClick", onClick)

    return button
end

-- Create separator line
function Widgets:CreateSeparator(parent, width)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetSize(width or 100, 1)
    line:SetColorTexture(0.3, 0.3, 0.4, 0.8)
    return line
end

-- Create animated glow effect
function Widgets:CreateGlow(parent, color)
    local glow = parent:CreateTexture(nil, "BACKGROUND", nil, -1)
    glow:SetPoint("TOPLEFT", -4, 4)
    glow:SetPoint("BOTTOMRIGHT", 4, -4)
    glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(color.r or 1, color.g or 1, color.b or 1, color.a or 0.3)
    glow:Hide()

    -- Animation group
    glow.animGroup = glow:CreateAnimationGroup()
    glow.animGroup:SetLooping("REPEAT")

    local fadeIn = glow.animGroup:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.1)
    fadeIn:SetToAlpha(0.4)
    fadeIn:SetDuration(0.5)
    fadeIn:SetOrder(1)

    local fadeOut = glow.animGroup:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(0.4)
    fadeOut:SetToAlpha(0.1)
    fadeOut:SetDuration(0.5)
    fadeOut:SetOrder(2)

    function glow:Start()
        self:Show()
        self.animGroup:Play()
    end

    function glow:Stop()
        self.animGroup:Stop()
        self:Hide()
    end

    return glow
end
