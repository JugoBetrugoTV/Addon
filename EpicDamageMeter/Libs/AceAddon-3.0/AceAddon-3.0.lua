--[[ AceAddon-3.0 - Addon framework ]]
local MAJOR, MINOR = "AceAddon-3.0", 13
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end

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
    safecall(addon.OnInitialize, addon)
end

function AceAddon:EnableAddon(addon)
    if type(addon) == "string" then addon = AceAddon:GetAddon(addon) end
    if self.statuses[addon.name] then return false end

    self.statuses[addon.name] = true

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
        for i, addon in ipairs(AceAddon.initializequeue) do
            if IsAddOnLoaded(addon.name) then
                AceAddon:InitializeAddon(addon)
                table.remove(AceAddon.initializequeue, i)
            end
        end
    elseif event == "PLAYER_LOGIN" then
        for name, addon in pairs(AceAddon.addons) do
            if not AceAddon.statuses[name] then
                AceAddon.initializequeue[#AceAddon.initializequeue + 1] = addon
            end
        end
        for i, addon in ipairs(AceAddon.initializequeue) do
            AceAddon:InitializeAddon(addon)
        end
        wipe(AceAddon.initializequeue)

        for name, addon in pairs(AceAddon.addons) do
            AceAddon:EnableAddon(addon)
        end
    end
end

AceAddon.frame:SetScript("OnEvent", onEvent)
AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
