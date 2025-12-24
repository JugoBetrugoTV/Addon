--[[ AceGUI-3.0 - GUI Widget Library ]]
local MAJOR, MINOR = "AceGUI-3.0", 41
local AceGUI = LibStub:NewLibrary(MAJOR, MINOR)

if not AceGUI then return end

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}
AceGUI.WidgetBase = AceGUI.WidgetBase or {}
AceGUI.WidgetContainerBase = AceGUI.WidgetContainerBase or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}
AceGUI.tooltip = AceGUI.tooltip or CreateFrame("GameTooltip", "AceGUITooltip", UIParent, "GameTooltipTemplate")

local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry
local WidgetBase = AceGUI.WidgetBase
local WidgetContainerBase = AceGUI.WidgetContainerBase

-- Widget Base Methods
local WidgetBaseMethods = {
    SetWidth = function(self, width)
        self.frame:SetWidth(width)
        self.frame.width = width
    end,

    SetRelativeWidth = function(self, width)
        self.relWidth = width
        self.width = "relative"
    end,

    SetHeight = function(self, height)
        self.frame:SetHeight(height)
        self.frame.height = height
    end,

    SetFullHeight = function(self, isFull)
        self.height = isFull and "fill" or nil
    end,

    SetFullWidth = function(self, isFull)
        if isFull then
            self.width = "fill"
        else
            self.width = nil
        end
    end,

    SetParent = function(self, parent)
        self.parent = parent
    end,

    SetCallback = function(self, name, func)
        if func then
            self.events[name] = func
        else
            self.events[name] = nil
        end
    end,

    Fire = function(self, name, ...)
        if self.events[name] then
            local success, ret = pcall(self.events[name], self, name, ...)
            if success then
                return ret
            else
                geterrorhandler()(ret)
            end
        end
    end,

    SetPoint = function(self, ...)
        self.frame:SetPoint(...)
    end,

    ClearAllPoints = function(self)
        self.frame:ClearAllPoints()
    end,

    GetNumPoints = function(self)
        return self.frame:GetNumPoints()
    end,

    GetPoint = function(self, ...)
        return self.frame:GetPoint(...)
    end,

    GetUserDataTable = function(self)
        return self.userdata
    end,

    SetUserData = function(self, key, value)
        self.userdata[key] = value
    end,

    GetUserData = function(self, key)
        return self.userdata[key]
    end,

    IsFullHeight = function(self)
        return self.height == "fill"
    end,

    IsFullWidth = function(self)
        return self.width == "fill"
    end,

    IsRelativeWidth = function(self)
        return self.width == "relative"
    end,

    Show = function(self)
        self.frame:Show()
    end,

    Hide = function(self)
        self.frame:Hide()
    end,

    IsShown = function(self)
        return self.frame:IsShown()
    end,

    Release = function(self)
        AceGUI:Release(self)
    end,
}

for method, func in pairs(WidgetBaseMethods) do
    WidgetBase[method] = func
end

-- Container Base Methods
local WidgetContainerBaseMethods = {
    PauseLayout = function(self)
        self.LayoutPaused = true
    end,

    ResumeLayout = function(self)
        self.LayoutPaused = nil
    end,

    PerformLayout = function(self)
        -- Override in container widgets
    end,

    DoLayout = function(self)
        if self.LayoutPaused then return end
        self:PerformLayout()
    end,

    AddChild = function(self, child, beforeWidget)
        if not child then return end
        child:SetParent(self)
        child.frame:SetParent(self.content or self.frame)

        if beforeWidget then
            for i, widget in pairs(self.children) do
                if widget == beforeWidget then
                    table.insert(self.children, i, child)
                    self:DoLayout()
                    return
                end
            end
        end

        table.insert(self.children, child)
        self:DoLayout()
    end,

    AddChildren = function(self, ...)
        for i = 1, select("#", ...) do
            local child = select(i, ...)
            self:AddChild(child)
        end
    end,

    ReleaseChildren = function(self)
        local children = self.children
        for i = #children, 1, -1 do
            AceGUI:Release(children[i])
            children[i] = nil
        end
    end,

    SetLayout = function(self, layout)
        self.layoutFunc = LayoutRegistry[layout]
    end,
}

for method, func in pairs(WidgetContainerBaseMethods) do
    WidgetContainerBase[method] = func
end

for method, func in pairs(WidgetBaseMethods) do
    WidgetContainerBase[method] = func
end

-- Main AceGUI methods
function AceGUI:Create(widgetType)
    local reg = WidgetRegistry[widgetType]
    if not reg then
        error(("Widget type %s doesn't exist"):format(widgetType), 2)
    end

    local widget = reg()
    widget.userdata = {}
    widget.events = {}
    widget.type = widgetType

    for method, func in pairs(WidgetBase) do
        widget[method] = widget[method] or func
    end

    if widget.children then
        for method, func in pairs(WidgetContainerBase) do
            widget[method] = widget[method] or func
        end
    end

    widget:OnAcquire()

    return widget
end

function AceGUI:Release(widget)
    if not widget then return end
    if widget.OnRelease then
        widget:OnRelease()
    end
    if widget.children then
        widget:ReleaseChildren()
    end
    if widget.frame then
        widget.frame:Hide()
        widget.frame:ClearAllPoints()
    end
end

function AceGUI:RegisterWidgetType(name, constructor, version)
    if not WidgetRegistry[name] or version > (AceGUI.WidgetVersions[name] or 0) then
        WidgetRegistry[name] = constructor
        AceGUI.WidgetVersions[name] = version
    end
end

function AceGUI:GetWidgetVersion(name)
    return AceGUI.WidgetVersions[name] or 0
end

function AceGUI:RegisterLayout(name, layoutFunc)
    LayoutRegistry[name] = layoutFunc
end

-- Default List Layout
AceGUI:RegisterLayout("List", function(content, children)
    local totalHeight = 0
    local width = content:GetWidth() or 0

    for i = 1, #children do
        local child = children[i]
        local frame = child.frame

        frame:ClearAllPoints()

        if i == 1 then
            frame:SetPoint("TOPLEFT", content)
        else
            frame:SetPoint("TOPLEFT", children[i-1].frame, "BOTTOMLEFT", 0, -5)
        end

        if child:IsFullWidth() then
            frame:SetPoint("RIGHT", content)
        end

        totalHeight = totalHeight + (frame:GetHeight() or 0) + 5
    end

    content:SetHeight(totalHeight)
end)

-- Default Flow Layout
AceGUI:RegisterLayout("Flow", function(content, children)
    local width = content:GetWidth() or 0
    local usedWidth = 0
    local rowHeight = 0
    local totalHeight = 0
    local rowStart = 1

    for i = 1, #children do
        local child = children[i]
        local frame = child.frame
        local frameWidth = frame:GetWidth() or 0
        local frameHeight = frame:GetHeight() or 0

        frame:ClearAllPoints()

        if usedWidth + frameWidth > width and i > rowStart then
            totalHeight = totalHeight + rowHeight + 5
            usedWidth = 0
            rowHeight = 0
            rowStart = i
        end

        if usedWidth == 0 then
            frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -totalHeight)
        else
            frame:SetPoint("TOPLEFT", children[i-1].frame, "TOPRIGHT", 5, 0)
        end

        usedWidth = usedWidth + frameWidth + 5
        rowHeight = math.max(rowHeight, frameHeight)
    end

    totalHeight = totalHeight + rowHeight
    content:SetHeight(totalHeight)
end)

-- Default Fill Layout
AceGUI:RegisterLayout("Fill", function(content, children)
    if #children > 0 then
        local child = children[1]
        local frame = child.frame
        frame:ClearAllPoints()
        frame:SetAllPoints(content)
    end
end)

-- Simple Window Widget
do
    local Type = "Window"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetSize(400, 300)
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:SetResizable(true)
        frame:EnableMouse(true)
        frame:SetClampedToScreen(true)
        frame:SetFrameStrata("DIALOG")

        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })

        local titleBar = CreateFrame("Frame", nil, frame)
        titleBar:SetPoint("TOPLEFT", 10, -10)
        titleBar:SetPoint("TOPRIGHT", -10, -10)
        titleBar:SetHeight(20)
        titleBar:EnableMouse(true)
        titleBar:RegisterForDrag("LeftButton")
        titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
        titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

        local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT")
        title:SetPoint("TOPRIGHT")
        title:SetJustifyH("CENTER")
        title:SetText("Window")

        local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        closeButton:SetPoint("TOPRIGHT", -5, -5)

        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", 15, -35)
        content:SetPoint("BOTTOMRIGHT", -15, 15)

        local widget = {
            frame = frame,
            content = content,
            titleBar = titleBar,
            title = title,
            closeButton = closeButton,
            children = {},
            type = Type,
        }

        closeButton:SetScript("OnClick", function()
            widget:Fire("OnClose")
            widget:Release()
        end)

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetTitle(text)
            self.title:SetText(text)
        end

        function widget:SetStatusText(text)
            -- Status text not implemented in simple version
        end

        function widget:PerformLayout()
            if self.layoutFunc then
                self.layoutFunc(self.content, self.children)
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Label Widget
do
    local Type = "Label"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 20)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetAllPoints()
        label:SetJustifyH("LEFT")

        local widget = {
            frame = frame,
            label = label,
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetText(text)
            self.label:SetText(text)
        end

        function widget:SetFont(font, size, flags)
            self.label:SetFont(font, size, flags)
        end

        function widget:SetColor(r, g, b)
            self.label:SetTextColor(r, g, b)
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Button Widget
do
    local Type = "Button"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
        frame:SetSize(100, 24)

        local widget = {
            frame = frame,
            type = Type,
        }

        frame:SetScript("OnClick", function()
            widget:Fire("OnClick")
        end)

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetText(text)
            self.frame:SetText(text)
        end

        function widget:SetDisabled(disabled)
            if disabled then
                self.frame:Disable()
            else
                self.frame:Enable()
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- CheckBox Widget
do
    local Type = "CheckBox"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("CheckButton", nil, UIParent, "InterfaceOptionsCheckButtonTemplate")
        frame:SetSize(26, 26)

        local widget = {
            frame = frame,
            text = frame.Text or _G[frame:GetName().."Text"],
            type = Type,
        }

        frame:SetScript("OnClick", function(self)
            widget:Fire("OnValueChanged", self:GetChecked())
        end)

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetValue(value)
            self.frame:SetChecked(value)
        end

        function widget:GetValue()
            return self.frame:GetChecked()
        end

        function widget:SetLabel(text)
            if self.text then
                self.text:SetText(text)
            end
        end

        function widget:SetDisabled(disabled)
            if disabled then
                self.frame:Disable()
            else
                self.frame:Enable()
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Slider Widget
do
    local Type = "Slider"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 44)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT")
        label:SetPoint("TOPRIGHT")
        label:SetJustifyH("LEFT")
        label:SetHeight(15)

        local slider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
        slider:SetPoint("TOP", label, "BOTTOM", 0, -2)
        slider:SetPoint("LEFT", 5, 0)
        slider:SetPoint("RIGHT", -5, 0)
        slider:SetMinMaxValues(0, 100)
        slider:SetValueStep(1)
        slider:SetObeyStepOnDrag(true)

        local lowText = slider.Low or _G[slider:GetName().."Low"]
        local highText = slider.High or _G[slider:GetName().."High"]
        local valueText = slider.Text or _G[slider:GetName().."Text"]

        if lowText then lowText:SetText("") end
        if highText then highText:SetText("") end

        local widget = {
            frame = frame,
            slider = slider,
            label = label,
            lowText = lowText,
            highText = highText,
            valueText = valueText,
            type = Type,
        }

        slider:SetScript("OnValueChanged", function(self, value)
            if widget.valueText then
                widget.valueText:SetText(math.floor(value))
            end
            widget:Fire("OnValueChanged", value)
        end)

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetValue(value)
            self.slider:SetValue(value)
        end

        function widget:GetValue()
            return self.slider:GetValue()
        end

        function widget:SetSliderValues(min, max, step)
            self.slider:SetMinMaxValues(min, max)
            self.slider:SetValueStep(step)
        end

        function widget:SetLabel(text)
            self.label:SetText(text)
        end

        function widget:SetDisabled(disabled)
            if disabled then
                self.slider:Disable()
            else
                self.slider:Enable()
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Dropdown Widget
do
    local Type = "Dropdown"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 44)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT")
        label:SetPoint("TOPRIGHT")
        label:SetJustifyH("LEFT")
        label:SetHeight(15)

        local dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -2)
        UIDropDownMenu_SetWidth(dropdown, 150)

        local widget = {
            frame = frame,
            dropdown = dropdown,
            label = label,
            type = Type,
            list = {},
            value = nil,
        }

        function widget:OnAcquire()
            self.frame:Show()
            UIDropDownMenu_Initialize(self.dropdown, function(frame, level)
                for key, text in pairs(self.list) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = text
                    info.value = key
                    info.func = function()
                        self.value = key
                        UIDropDownMenu_SetSelectedValue(self.dropdown, key)
                        self:Fire("OnValueChanged", key)
                    end
                    UIDropDownMenu_AddButton(info)
                end
            end)
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetValue(value)
            self.value = value
            UIDropDownMenu_SetSelectedValue(self.dropdown, value)
        end

        function widget:GetValue()
            return self.value
        end

        function widget:SetList(list)
            self.list = list
        end

        function widget:SetLabel(text)
            self.label:SetText(text)
        end

        function widget:SetDisabled(disabled)
            -- UIDropDownMenu doesn't have built-in disable
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- EditBox Widget
do
    local Type = "EditBox"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 44)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT")
        label:SetPoint("TOPRIGHT")
        label:SetJustifyH("LEFT")
        label:SetHeight(15)

        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        editBox:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 5, -2)
        editBox:SetPoint("BOTTOMRIGHT", -5, 0)
        editBox:SetAutoFocus(false)

        local widget = {
            frame = frame,
            editBox = editBox,
            label = label,
            type = Type,
        }

        editBox:SetScript("OnEnterPressed", function(self)
            self:ClearFocus()
            widget:Fire("OnEnterPressed", self:GetText())
        end)

        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                widget:Fire("OnTextChanged", self:GetText())
            end
        end)

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetText(text)
            self.editBox:SetText(text or "")
        end

        function widget:GetText()
            return self.editBox:GetText()
        end

        function widget:SetLabel(text)
            self.label:SetText(text)
        end

        function widget:SetDisabled(disabled)
            if disabled then
                self.editBox:Disable()
            else
                self.editBox:Enable()
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Simple Group Widget
do
    local Type = "SimpleGroup"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(300, 300)

        local content = CreateFrame("Frame", nil, frame)
        content:SetAllPoints()

        local widget = {
            frame = frame,
            content = content,
            children = {},
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:PerformLayout()
            if self.layoutFunc then
                self.layoutFunc(self.content, self.children)
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- InlineGroup Widget
do
    local Type = "InlineGroup"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        frame:SetSize(300, 100)
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 10, -5)

        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", 10, -20)
        content:SetPoint("BOTTOMRIGHT", -10, 10)

        local widget = {
            frame = frame,
            content = content,
            title = title,
            children = {},
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetTitle(text)
            self.title:SetText(text)
        end

        function widget:PerformLayout()
            if self.layoutFunc then
                self.layoutFunc(self.content, self.children)
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- ScrollFrame Widget
do
    local Type = "ScrollFrame"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(400, 300)

        local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 5, -5)
        scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(scrollFrame:GetWidth(), 1)
        scrollFrame:SetScrollChild(content)

        local widget = {
            frame = frame,
            scrollFrame = scrollFrame,
            content = content,
            children = {},
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:PerformLayout()
            if self.layoutFunc then
                self.layoutFunc(self.content, self.children)
            end
            self.content:SetHeight(math.max(1, select(2, self.content:GetSize())))
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- TabGroup Widget
do
    local Type = "TabGroup"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(400, 300)

        local tabHolder = CreateFrame("Frame", nil, frame)
        tabHolder:SetPoint("TOPLEFT")
        tabHolder:SetPoint("TOPRIGHT")
        tabHolder:SetHeight(30)

        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", tabHolder, "BOTTOMLEFT", 0, -5)
        content:SetPoint("BOTTOMRIGHT")

        local widget = {
            frame = frame,
            tabHolder = tabHolder,
            content = content,
            children = {},
            tabs = {},
            tabButtons = {},
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetTabs(tabs)
            self.tabs = tabs
            for _, btn in pairs(self.tabButtons) do
                btn:Hide()
            end
            self.tabButtons = {}

            local offset = 0
            for i, tab in ipairs(tabs) do
                local btn = CreateFrame("Button", nil, self.tabHolder, "UIPanelButtonTemplate")
                btn:SetSize(80, 25)
                btn:SetPoint("BOTTOMLEFT", offset, 0)
                btn:SetText(tab.text)
                btn:SetScript("OnClick", function()
                    self:SelectTab(tab.value)
                end)
                self.tabButtons[tab.value] = btn
                offset = offset + 85
            end
        end

        function widget:SelectTab(value)
            self:Fire("OnGroupSelected", value)
        end

        function widget:PerformLayout()
            if self.layoutFunc then
                self.layoutFunc(self.content, self.children)
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Heading Widget
do
    local Type = "Heading"
    local Version = 1

    local function Constructor()
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 20)

        local left = frame:CreateTexture(nil, "BACKGROUND")
        left:SetHeight(8)
        left:SetPoint("LEFT", 3, 0)
        left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        left:SetTexCoord(0.81, 0.94, 0.5, 1)

        local right = frame:CreateTexture(nil, "BACKGROUND")
        right:SetHeight(8)
        right:SetPoint("RIGHT", -3, 0)
        right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        right:SetTexCoord(0.81, 0.94, 0.5, 1)

        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOP")
        text:SetPoint("BOTTOM")
        text:SetJustifyH("CENTER")

        local widget = {
            frame = frame,
            text = text,
            left = left,
            right = right,
            type = Type,
        }

        function widget:OnAcquire()
            self.frame:Show()
        end

        function widget:OnRelease()
            self.frame:Hide()
        end

        function widget:SetText(textStr)
            self.text:SetText(textStr)
            if textStr and textStr ~= "" then
                self.left:SetPoint("RIGHT", self.text, "LEFT", -5, 0)
                self.right:SetPoint("LEFT", self.text, "RIGHT", 5, 0)
            else
                self.left:SetPoint("RIGHT", self.frame, "CENTER", -5, 0)
                self.right:SetPoint("LEFT", self.frame, "CENTER", 5, 0)
            end
        end

        return widget
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
