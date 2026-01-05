--[[ AceDB-3.0 - Database library ]]
local MAJOR, MINOR = "AceDB-3.0", 27
local AceDB = LibStub:NewLibrary(MAJOR, MINOR)

if not AceDB then return end

local type, pairs, next, error = type, pairs, next, error
local setmetatable, rawset = setmetatable, rawset

AceDB.db_registry = AceDB.db_registry or {}
AceDB.frame = AceDB.frame or CreateFrame("Frame")

local CallbackHandler = LibStub("CallbackHandler-1.0")
local CallbackDummy = { Fire = function() end }

local DBObjectLib = {}

local function copyTable(src, dest)
    if type(dest) ~= "table" then dest = {} end
    if type(src) == "table" then
        for k, v in pairs(src) do
            if type(v) == "table" then
                v = copyTable(v, dest[k])
            end
            dest[k] = v
        end
    end
    return dest
end

local function removeDefaults(db, defaults, blocker)
    setmetatable(db, nil)
    for k, v in pairs(defaults) do
        if k == "*" or k == "**" then
            if type(v) == "table" then
                for key, value in pairs(db) do
                    if type(value) == "table" then
                        removeDefaults(value, v)
                        if next(value) == nil then
                            db[key] = nil
                        end
                    end
                end
            end
        elseif type(v) == "table" and type(db[k]) == "table" then
            removeDefaults(db[k], v, blocker and blocker[k])
            if next(db[k]) == nil then
                db[k] = nil
            end
        else
            if blocker and (blocker[k] ~= nil) then
                -- Preserve user setting
            elseif db[k] == v then
                db[k] = nil
            end
        end
    end
end

local function initSection(db, section, svstore, key, defaults)
    local sv = rawget(db, "sv")

    local tableCreated
    if not sv[svstore] then sv[svstore] = {} end
    if not sv[svstore][key] then
        sv[svstore][key] = {}
        tableCreated = true
    end

    local tbl = sv[svstore][key]

    if defaults then
        copyTable(defaults, tbl)
    end

    rawset(db, section, tbl)

    return tableCreated, tbl
end

local dbmt = {
    __index = function(t, section)
        local keys = rawget(t, "keys")
        local key = keys[section]
        if key then
            local defaultTbl = rawget(t, "defaults")
            local defaults = defaultTbl and defaultTbl[section]

            local svstore = nil
            if section == "profile" then
                svstore = "profiles"
            elseif section == "global" then
                svstore = "global"
            elseif section == "char" then
                svstore = "char"
            elseif section == "realm" then
                svstore = "realm"
            elseif section == "class" then
                svstore = "class"
            elseif section == "race" then
                svstore = "race"
            elseif section == "faction" then
                svstore = "faction"
            elseif section == "factionrealm" then
                svstore = "factionrealm"
            elseif section == "locale" then
                svstore = "locale"
            end

            if svstore then
                if svstore == "global" then
                    if not rawget(t, "sv").global then
                        rawget(t, "sv").global = {}
                    end
                    rawset(t, section, rawget(t, "sv").global)
                    if defaults then
                        copyTable(defaults, rawget(t, "sv").global)
                    end
                else
                    initSection(t, section, svstore, key, defaults)
                end
            end

            return rawget(t, section)
        end
    end
}

local function validateDefaults(defaults, keyTbl, offset)
    if type(defaults) ~= "table" then
        error(("Usage: AceDBObject:RegisterDefaults(defaults): 'defaults' - table expected, got %s."):format(type(defaults)), 3)
    end
    for k, v in pairs(defaults) do
        if not keyTbl[k] and k ~= "global" then
            error(("Usage: AceDBObject:RegisterDefaults(defaults): 'defaults' - invalid section: %s."):format(k), 3)
        end
    end
end

function DBObjectLib:RegisterDefaults(defaults)
    if defaults then
        for section, sectiondefaults in pairs(defaults) do
            if section == "profile" then
                for k, v in pairs(sectiondefaults) do
                    self.defaults.profile[k] = v
                end
            else
                self.defaults[section] = copyTable(sectiondefaults, self.defaults[section])
            end
        end
    end
end

function DBObjectLib:SetProfile(name)
    local oldProfile = self.keys.profile
    self.keys.profile = name

    self.sv.profileKeys[self.keys.char] = name

    rawset(self, "profile", nil)

    local newProfile = self.profile

    self.callbacks:Fire("OnProfileChanged", self, name)
end

function DBObjectLib:GetProfiles(tbl)
    tbl = tbl or {}
    local curProfile = self.keys.profile

    for profileKey in pairs(self.sv.profiles) do
        tbl[#tbl + 1] = profileKey
    end

    if rawget(self.sv.profiles, curProfile) == nil then
        tbl[#tbl + 1] = curProfile
    end

    return tbl, curProfile
end

function DBObjectLib:GetCurrentProfile()
    return self.keys.profile
end

function DBObjectLib:ResetProfile(noChildren, noCallbacks)
    local profile = self.profile

    for k, v in pairs(profile) do
        profile[k] = nil
    end

    local defaults = self.defaults and self.defaults.profile
    if defaults then
        copyTable(defaults, profile)
    end

    if not noCallbacks then
        self.callbacks:Fire("OnProfileReset", self)
    end
end

function DBObjectLib:ResetDB(defaultProfile)
    local sv = self.sv
    for k, v in pairs(sv) do
        sv[k] = nil
    end

    local parent = self.parent

    initdb(self, sv, self.defaults, defaultProfile, self)

    if not noCallbacks then
        self.callbacks:Fire("OnDatabaseReset", self)
    end
end

function AceDB:New(tbl, defaults, defaultProfile)
    if type(tbl) == "string" then
        local name = tbl
        tbl = _G[name]
        if not tbl then
            tbl = {}
            _G[name] = tbl
        end
    end

    if type(defaults) ~= "table" and defaults ~= nil then
        error(("Usage: AceDB:New(tbl, defaults, defaultProfile): 'defaults' - table or nil expected, got %s."):format(type(defaults)), 2)
    end

    if type(defaultProfile) ~= "string" and defaultProfile ~= nil then
        defaultProfile = nil
    end

    defaultProfile = defaultProfile or "Default"

    local charKey = UnitName("player") .. " - " .. GetRealmName()
    local realmKey = GetRealmName()
    local classKey = select(2, UnitClass("player"))
    local raceKey = select(2, UnitRace("player"))
    local factionKey = UnitFactionGroup("player")
    local factionrealmKey = factionKey .. " - " .. GetRealmName()
    local localeKey = GetLocale()

    if not tbl.profileKeys then tbl.profileKeys = {} end
    if not tbl.profiles then tbl.profiles = {} end
    if not tbl.profiles[defaultProfile] then tbl.profiles[defaultProfile] = {} end

    tbl.profileKeys[charKey] = tbl.profileKeys[charKey] or defaultProfile

    local db = setmetatable({
        sv = tbl,
        keys = {
            char = charKey,
            realm = realmKey,
            class = classKey,
            race = raceKey,
            faction = factionKey,
            factionrealm = factionrealmKey,
            locale = localeKey,
            profile = tbl.profileKeys[charKey],
            global = "global",
        },
        defaults = {
            profile = {},
        },
        callbacks = CallbackHandler:New({}),
        parent = self,
    }, dbmt)

    if defaults then
        db:RegisterDefaults(defaults)
    end

    for funcName, func in pairs(DBObjectLib) do
        db[funcName] = func
    end

    AceDB.db_registry[db] = true

    return db
end
