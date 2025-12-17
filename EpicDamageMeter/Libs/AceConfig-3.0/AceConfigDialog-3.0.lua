--[[ AceConfigDialog-3.0 - Configuration dialog ]]
local MAJOR, MINOR = "AceConfigDialog-3.0", 86
local AceConfigDialog = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfigDialog then return end

local AceGUI = LibStub("AceGUI-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

AceConfigDialog.OpenFrames = AceConfigDialog.OpenFrames or {}
AceConfigDialog.Status = AceConfigDialog.Status or {}
AceConfigDialog.frame = AceConfigDialog.frame or CreateFrame("Frame")

local function CreateOptionsPanel(self, appName, options, container)
    if not options or not options.args then return end

    for key, opt in pairs(options.args) do
        local widget

        if opt.type == "group" then
            -- Create inline group for subgroups
            widget = AceGUI:Create("InlineGroup")
            widget:SetTitle(opt.name or key)
            widget:SetFullWidth(true)
            CreateOptionsPanel(self, appName, opt, widget)
        elseif opt.type == "toggle" then
            widget = AceGUI:Create("CheckBox")
            widget:SetLabel(opt.name or key)
            if opt.get then
                local val = opt.get(opt.handler or opt)
                widget:SetValue(val)
            end
            widget:SetCallback("OnValueChanged", function(_, _, value)
                if opt.set then
                    opt.set(opt.handler or opt, value)
                end
            end)
        elseif opt.type == "range" then
            widget = AceGUI:Create("Slider")
            widget:SetLabel(opt.name or key)
            widget:SetSliderValues(opt.min or 0, opt.max or 100, opt.step or 1)
            if opt.get then
                local val = opt.get(opt.handler or opt)
                widget:SetValue(val or opt.min or 0)
            end
            widget:SetCallback("OnValueChanged", function(_, _, value)
                if opt.set then
                    opt.set(opt.handler or opt, value)
                end
            end)
            widget:SetFullWidth(true)
        elseif opt.type == "input" then
            widget = AceGUI:Create("EditBox")
            widget:SetLabel(opt.name or key)
            if opt.get then
                local val = opt.get(opt.handler or opt)
                widget:SetText(val or "")
            end
            widget:SetCallback("OnEnterPressed", function(_, _, text)
                if opt.set then
                    opt.set(opt.handler or opt, text)
                end
            end)
            widget:SetFullWidth(true)
        elseif opt.type == "select" then
            widget = AceGUI:Create("Dropdown")
            widget:SetLabel(opt.name or key)
            if opt.values then
                widget:SetList(opt.values)
            end
            if opt.get then
                local val = opt.get(opt.handler or opt)
                widget:SetValue(val)
            end
            widget:SetCallback("OnValueChanged", function(_, _, value)
                if opt.set then
                    opt.set(opt.handler or opt, value)
                end
            end)
            widget:SetFullWidth(true)
        elseif opt.type == "execute" then
            widget = AceGUI:Create("Button")
            widget:SetText(opt.name or key)
            widget:SetCallback("OnClick", function()
                if opt.func then
                    opt.func(opt.handler or opt)
                end
            end)
        elseif opt.type == "header" then
            widget = AceGUI:Create("Heading")
            widget:SetText(opt.name or "")
            widget:SetFullWidth(true)
        elseif opt.type == "description" then
            widget = AceGUI:Create("Label")
            widget:SetText(opt.name or "")
            widget:SetFullWidth(true)
        end

        if widget then
            container:AddChild(widget)
        end
    end
end

function AceConfigDialog:Open(appName, container)
    local options = AceConfigRegistry:GetOptionsTable(appName, "dialog", appName)
    if not options then
        error(("AceConfigDialog:Open - No options table registered for %s"):format(appName), 2)
        return
    end

    local f
    if container then
        f = container
    else
        f = AceGUI:Create("Window")
        f:SetTitle(options.name or appName)
        f:SetCallback("OnClose", function(widget)
            AceConfigDialog.OpenFrames[appName] = nil
            AceGUI:Release(widget)
        end)
        f:SetLayout("Fill")
        f:SetWidth(600)
        f:SetHeight(500)
    end

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    f:AddChild(scroll)

    CreateOptionsPanel(self, appName, options, scroll)

    if not container then
        self.OpenFrames[appName] = f
    end

    return f
end

function AceConfigDialog:Close(appName)
    if self.OpenFrames[appName] then
        AceGUI:Release(self.OpenFrames[appName])
        self.OpenFrames[appName] = nil
    end
end

function AceConfigDialog:AddToBlizOptions(appName, name, parent, ...)
    -- Simplified for addon usage
    local panel = CreateFrame("Frame")
    panel.name = name or appName
    panel.parent = parent

    panel.OnShow = function()
        local container = AceGUI:Create("SimpleGroup")
        container:SetLayout("Fill")
        container.frame:SetParent(panel)
        container.frame:SetAllPoints()

        local scroll = AceGUI:Create("ScrollFrame")
        scroll:SetLayout("List")
        container:AddChild(scroll)

        local options = AceConfigRegistry:GetOptionsTable(appName, "dialog", appName)
        if options then
            CreateOptionsPanel(self, appName, options, scroll)
        end
    end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        if parent then
            category.parentCategoryID = parent
        end
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    return panel
end

function AceConfigDialog:SetDefaultSize(appName, width, height)
    self.Status[appName] = self.Status[appName] or {}
    self.Status[appName].width = width
    self.Status[appName].height = height
end
