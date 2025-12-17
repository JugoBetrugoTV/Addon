--[[ LibDBIcon-1.0 - Minimap icon library ]]
local MAJOR, MINOR = "LibDBIcon-1.0", 49
local LibDBIcon = LibStub:NewLibrary(MAJOR, MINOR)

if not LibDBIcon then return end

local LibDataBroker = LibStub("LibDataBroker-1.1")

LibDBIcon.objects = LibDBIcon.objects or {}
LibDBIcon.callbackRegistered = LibDBIcon.callbackRegistered or nil
LibDBIcon.callbacks = LibDBIcon.callbacks or LibStub("CallbackHandler-1.0"):New(LibDBIcon)
LibDBIcon.notCreated = LibDBIcon.notCreated or {}
LibDBIcon.radius = LibDBIcon.radius or 80

local isDraggingButton = false

local function GetPosition(angle, radius)
    return cos(angle) * radius, sin(angle) * radius
end

local function OnDragStart(self)
    self:LockHighlight()
    self.isMouseDown = true
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        local db = LibDBIcon.objects[self.dataObject].db
        if db then
            db.minimapPos = angle
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER", GetPosition(angle, db.radius or LibDBIcon.radius))
        end
    end)
end

local function OnDragStop(self)
    self:SetScript("OnUpdate", nil)
    self.isMouseDown = nil
    self:UnlockHighlight()
end

local function OnEnter(self)
    if isDraggingButton then return end

    local obj = self.dataObject
    if obj.OnTooltipShow then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT")
        obj.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    elseif obj.OnEnter then
        obj.OnEnter(self)
    end
end

local function OnLeave(self)
    local obj = self.dataObject
    GameTooltip:Hide()
    if obj.OnLeave then
        obj.OnLeave(self)
    end
end

local function OnClick(self, button)
    local obj = self.dataObject
    if obj.OnClick then
        obj.OnClick(self, button)
    end
end

local function CreateButton(name, object, db)
    local button = CreateFrame("Button", "LibDBIcon10_"..name, Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetSize(32, 32)
    button:SetFrameLevel(8)
    button:RegisterForClicks("anyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture(136477)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
    button:SetScript("OnClick", OnClick)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(56, 56)
    overlay:SetTexture(136430)
    overlay:SetPoint("TOPLEFT")
    button.overlay = overlay

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    button.icon = icon

    button.dataObject = object
    button.db = db

    if object.icon then
        icon:SetTexture(object.icon)
    end

    LibDBIcon.objects[name] = button

    local angle = db and db.minimapPos or 225
    local radius = db and db.radius or LibDBIcon.radius
    button:SetPoint("CENTER", Minimap, "CENTER", GetPosition(angle, radius))

    if db and db.hide then
        button:Hide()
    else
        button:Show()
    end

    LibDBIcon.callbacks:Fire("LibDBIcon_IconCreated", button, name)

    return button
end

function LibDBIcon:Register(name, object, db)
    if self.objects[name] then return end
    if not object.icon then return end

    if LibDataBroker:GetDataObjectByName(name) then
        CreateButton(name, object, db)
    else
        self.notCreated[name] = {object, db}
    end
end

function LibDBIcon:Unregister(name)
    if not self.objects[name] then return end
    self.objects[name]:Hide()
    self.objects[name] = nil
end

function LibDBIcon:Hide(name)
    if not self.objects[name] then return end
    self.objects[name]:Hide()
end

function LibDBIcon:Show(name)
    if not self.objects[name] then return end
    self.objects[name]:Show()
end

function LibDBIcon:IsRegistered(name)
    return self.objects[name] ~= nil
end

function LibDBIcon:Refresh(name, db)
    if not self.objects[name] then return end
    local button = self.objects[name]
    if db then
        button.db = db
    end
    local angle = button.db and button.db.minimapPos or 225
    local radius = button.db and button.db.radius or self.radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", GetPosition(angle, radius))

    if button.db and button.db.hide then
        button:Hide()
    else
        button:Show()
    end
end

function LibDBIcon:GetMinimapButton(name)
    return self.objects[name]
end

function LibDBIcon:Lock(name)
    if not self.objects[name] then return end
    self.objects[name]:SetScript("OnDragStart", nil)
    self.objects[name]:SetScript("OnDragStop", nil)
end

function LibDBIcon:Unlock(name)
    if not self.objects[name] then return end
    self.objects[name]:SetScript("OnDragStart", OnDragStart)
    self.objects[name]:SetScript("OnDragStop", OnDragStop)
end

-- Register callback for data object creation
if not LibDBIcon.callbackRegistered then
    LibDataBroker.callbacks:RegisterCallback("LibDataBroker_DataObjectCreated", function(event, name, object)
        if LibDBIcon.notCreated[name] then
            CreateButton(name, object, LibDBIcon.notCreated[name][2])
            LibDBIcon.notCreated[name] = nil
        end
    end)
    LibDBIcon.callbackRegistered = true
end
