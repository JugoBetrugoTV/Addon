--[[ AceAddon-3.0 - Addon framework (EDM isolated version) ]]
-- This is a self-contained version that ONLY manages EpicDamageMeter
-- It does NOT interfere with other addons' AceAddon instances
local MAJOR, MINOR = "AceAddon-3.0-EDM", 1
local AceAddon

-- Check if we already have our isolated version
if LibStub.libs["AceAddon-3.0-EDM"] then
    AceAddon = LibStub.libs["AceAddon-3.0-EDM"]
else
    AceAddon = {}
    LibStub.libs["AceAddon-3.0-EDM"] = AceAddon
    LibStub.minors["AceAddon-3.0-EDM"] = 1
end

-- Also register as AceAddon-3.0 but ONLY if no other addon has registered it yet
-- This prevents us from overwriting a newer version from another addon
local existingAceAddon = LibStub.libs["AceAddon-3.0"]
if not existingAceAddon then
    LibStub.libs["AceAddon-3.0"] = AceAddon
    LibStub.minors["AceAddon-3.0"] = 13
end

-- Initialize our isolated storage
AceAddon.frame = AceAddon.frame or CreateFrame("Frame")
AceAddon.addons = AceAddon.addons or {}
AceAddon.statuses = AceAddon.statuses or {}
AceAddon.initializequeue = AceAddon.initializequeue or {}
AceAddon.enablequeue = AceAddon.enablequeue or {}
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end })
AceAddon.ownAddons = AceAddon.ownAddons or {} -- Track addons WE created

local function safecall(func, ...)
    if not func then return true end
    local success, err = pcall(func, ...)
    if not success then
        local handler = geterrorhandler()
        if handler then handler(err) end
    end
    return success, err
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
    self.ownAddons[name] = true -- Mark as our own addon
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
    if addon and addon.OnInitialize then
        safecall(addon.OnInitialize, addon)
    end
end

function AceAddon:EnableAddon(addon)
    if type(addon) == "string" then addon = AceAddon:GetAddon(addon, true) end
    if not addon then return false end
    if self.statuses[addon.name] then return false end

    self.statuses[addon.name] = true

    if addon.OnEnable then
        safecall(addon.OnEnable, addon)
    end

    -- Only enable modules that belong to this addon
    if addon.modules then
        for name, module in pairs(addon.modules) do
            self:EnableAddon(module)
        end
    end

    return true
end

function AceAddon:IterateAddons() return pairs(self.addons) end
function AceAddon:IterateEmbedsOnAddon(addon) return pairs(self.embeds[addon]) end

-- CRITICAL FIX: Only initialize/enable OUR OWN addons, not other addons
local function onEvent(frame, event, arg1)
    if event == "ADDON_LOADED" then
        -- Only process if this is one of OUR addons being loaded
        -- Check if the loaded addon matches any addon we created
        local toInit = {}
        for i = #AceAddon.initializequeue, 1, -1 do
            local addon = AceAddon.initializequeue[i]
            -- Only initialize if:
            -- 1. This addon was created by us (in ownAddons)
            -- 2. The addon's name matches the loaded addon OR is EpicDamageMeter
            if addon and AceAddon.ownAddons[addon.name] then
                if arg1 == addon.name or arg1 == "EpicDamageMeter" or addon.name == "EpicDamageMeter" then
                    table.insert(toInit, addon)
                    table.remove(AceAddon.initializequeue, i)
                end
            end
        end
        for _, addon in ipairs(toInit) do
            AceAddon:InitializeAddon(addon)
        end
    elseif event == "PLAYER_LOGIN" then
        -- Initialize any remaining addons that belong to us
        for i = #AceAddon.initializequeue, 1, -1 do
            local addon = AceAddon.initializequeue[i]
            if addon and AceAddon.ownAddons[addon.name] then
                AceAddon:InitializeAddon(addon)
                table.remove(AceAddon.initializequeue, i)
            end
        end

        -- Enable only OUR addons
        for name, addon in pairs(AceAddon.addons) do
            if AceAddon.ownAddons[name] and not AceAddon.statuses[name] then
                AceAddon:EnableAddon(addon)
            end
        end
    end
end

AceAddon.frame:SetScript("OnEvent", onEvent)
AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
