--[[ AceAddon-3.0 - Addon framework ]]
local MAJOR, MINOR = "AceAddon-3.0", 13
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end

-- Compatibility for WoW 11.x API changes
-- C_AddOns.IsAddOnLoaded is the new API, fallback to old global if available
local IsAddOnLoaded
if C_AddOns and C_AddOns.IsAddOnLoaded then
    IsAddOnLoaded = C_AddOns.IsAddOnLoaded
elseif _G.IsAddOnLoaded then
    IsAddOnLoaded = _G.IsAddOnLoaded
else
    -- Fallback: always return true (will initialize on PLAYER_LOGIN anyway)
    IsAddOnLoaded = function(name) return true end
end

AceAddon.frame = AceAddon.frame or CreateFrame("Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end })

local function safecall(func, ...)
    local success, err = pcall(func, ...)
    if not success then
        geterrorhandler()(err)
    end
    return success, err
end

local Dispatchers = {}
local function Dispatch(func, ...)
    return func(...)
end

function AceAddon:NewAddon(objectorname, ...)
    local object, name
    local i = 1

    if type(objectorname) == "table" then
        object = objectorname
        name = ...
        i = 2
    else
        name = objectorname
    end

    if type(name) ~= "string" then
        error(("Usage: NewAddon([object,] name, [lib, lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2)
    end
    if self.addons[name] then
        error(("Usage: NewAddon([object,] name, [lib, lib, lib, ...]): 'name' - Addon '%s' already exists."):format(name), 2)
    end

    object = object or {}
    object.name = name

    local addonmeta = {}
    local oldmeta = getmetatable(object)
    if oldmeta then
        for k, v in pairs(oldmeta) do addonmeta[k] = v end
    end
    addonmeta.__tostring = function(self) return self.name end
    setmetatable(object, addonmeta)

    self.addons[name] = object
    object.modules = {}
    object.orderedModules = {}
    object.defaultModuleLibraries = {}

    self:EmbedLibraries(object, select(i, ...))

    if not self.statuses[name] then
        self.initializequeue[#self.initializequeue + 1] = object
    end

    return object
end

function AceAddon:GetAddon(name, silent)
    if not silent and not self.addons[name] then
        error(("Usage: GetAddon(name): 'name' - Cannot find an AceAddon '%s'."):format(tostring(name)), 2)
    end
    return self.addons[name]
end

function AceAddon:EmbedLibraries(object, ...)
    for i = 1, select("#", ...) do
        local libname = select(i, ...)
        self:EmbedLibrary(object, libname, false, 4)
    end
end

function AceAddon:EmbedLibrary(object, libname, silent, offset)
    local lib = LibStub:GetLibrary(libname, true)
    if not lib and not silent then
        error(("Usage: EmbedLibrary(addon, libname, silent, offset): 'libname' - Cannot find a library instance of %q."):format(tostring(libname)), offset or 2)
    elseif lib and type(lib.Embed) == "function" then
        lib:Embed(object)
        tinsert(self.embeds[object], libname)
    end
    return lib
end

function AceAddon:InitializeAddon(addon)
    if self.statuses[addon.name] == "initialized" then return end
    safecall(addon.OnInitialize, addon)
    self.statuses[addon.name] = "initialized"
end

function AceAddon:EnableAddon(addon)
    if type(addon) == "string" then addon = AceAddon:GetAddon(addon) end
    if self.statuses[addon.name] == "enabled" then return false end

    self.statuses[addon.name] = "enabled"

    safecall(addon.OnEnable, addon)

    if addon.modules then
        for name, module in pairs(addon.modules) do
            self:EnableAddon(module)
        end
    end

    return true
end

function AceAddon:IterateAddons() return pairs(self.addons) end
function AceAddon:IterateEmbedsOnAddon(addon) return pairs(self.embeds[addon]) end

local function onEvent(frame, event, arg1)
    if event == "ADDON_LOADED" then
        -- Iterate backwards to safely remove during iteration
        for i = #AceAddon.initializequeue, 1, -1 do
            local addon = AceAddon.initializequeue[i]
            if addon and IsAddOnLoaded(addon.name) then
                AceAddon:InitializeAddon(addon)
                table.remove(AceAddon.initializequeue, i)
            end
        end
    elseif event == "PLAYER_LOGIN" then
        -- Initialize any addons not yet initialized
        for name, addon in pairs(AceAddon.addons) do
            if not AceAddon.statuses[name] then
                AceAddon:InitializeAddon(addon)
            end
        end
        wipe(AceAddon.initializequeue)

        -- Enable all addons
        for name, addon in pairs(AceAddon.addons) do
            AceAddon:EnableAddon(addon)
        end
    end
end

AceAddon.frame:SetScript("OnEvent", onEvent)
AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
