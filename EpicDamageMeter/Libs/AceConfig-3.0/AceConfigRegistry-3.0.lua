--[[ AceConfigRegistry-3.0 - Configuration registry ]]
local MAJOR, MINOR = "AceConfigRegistry-3.0", 21
local AceConfigRegistry = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfigRegistry then return end

AceConfigRegistry.tables = AceConfigRegistry.tables or {}

local CallbackHandler = LibStub("CallbackHandler-1.0")
if not AceConfigRegistry.callbacks then
    AceConfigRegistry.callbacks = CallbackHandler:New(AceConfigRegistry)
end

local function validateType(optType)
    local validTypes = {
        ["execute"] = true,
        ["input"] = true,
        ["toggle"] = true,
        ["range"] = true,
        ["select"] = true,
        ["multiselect"] = true,
        ["color"] = true,
        ["keybinding"] = true,
        ["header"] = true,
        ["description"] = true,
        ["group"] = true,
    }
    return validTypes[optType]
end

function AceConfigRegistry:RegisterOptionsTable(appName, options, skipValidation)
    if type(appName) ~= "string" then
        error(("Usage: RegisterOptionsTable(appName, options): 'appName' - string expected, got %s"):format(type(appName)), 2)
    end
    if type(options) == "function" then
        self.tables[appName] = options
    elseif type(options) == "table" then
        self.tables[appName] = function() return options end
    else
        error(("Usage: RegisterOptionsTable(appName, options): 'options' - table or function expected, got %s"):format(type(options)), 2)
    end
    self.callbacks:Fire("ConfigTableChange", appName)
end

function AceConfigRegistry:GetOptionsTable(appName, uiType, uiName)
    local optionsTable = self.tables[appName]
    if type(optionsTable) == "function" then
        return optionsTable(uiType, uiName)
    else
        return optionsTable
    end
end

function AceConfigRegistry:IterateOptionsTables()
    return pairs(self.tables)
end

function AceConfigRegistry:NotifyChange(appName)
    if type(appName) ~= "string" then
        error(("Usage: NotifyChange(appName): 'appName' - string expected, got %s"):format(type(appName)), 2)
    end
    self.callbacks:Fire("ConfigTableChange", appName)
end
