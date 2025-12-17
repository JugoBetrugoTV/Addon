--[[ LibDataBroker-1.1 - Data broker library ]]
local MAJOR, MINOR = "LibDataBroker-1.1", 4
local LibDataBroker = LibStub:NewLibrary(MAJOR, MINOR)

if not LibDataBroker then return end

LibDataBroker.callbacks = LibDataBroker.callbacks or LibStub("CallbackHandler-1.0"):New(LibDataBroker)
LibDataBroker.attributestorage = LibDataBroker.attributestorage or {}
LibDataBroker.namestorage = LibDataBroker.namestorage or {}
LibDataBroker.proxystorage = LibDataBroker.proxystorage or {}

local attributestorage = LibDataBroker.attributestorage
local namestorage = LibDataBroker.namestorage
local proxystorage = LibDataBroker.proxystorage
local callbacks = LibDataBroker.callbacks

local domt = {
    __metatable = "access denied",
    __index = function(self, key)
        return attributestorage[self] and attributestorage[self][key]
    end,
    __newindex = function(self, key, value)
        if not attributestorage[self] then
            attributestorage[self] = {}
        end
        if attributestorage[self][key] == value then return end
        attributestorage[self][key] = value
        local name = namestorage[self]
        if name then
            callbacks:Fire("LibDataBroker_AttributeChanged", name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged_"..name, name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged_"..name.."_"..key, name, key, value, self)
            callbacks:Fire("LibDataBroker_AttributeChanged__"..key, name, key, value, self)
        end
    end,
}

function LibDataBroker:NewDataObject(name, dataobj)
    if proxystorage[name] then return nil end

    if dataobj then
        if type(dataobj) ~= "table" then
            error("LibDataBroker:NewDataObject(name, dataobj): 'dataobj' - table expected, got " .. type(dataobj), 2)
        end
    else
        dataobj = {}
    end

    local proxy = setmetatable({}, domt)
    proxystorage[name] = proxy
    namestorage[proxy] = name
    attributestorage[proxy] = {}

    for key, value in pairs(dataobj) do
        proxy[key] = value
    end

    callbacks:Fire("LibDataBroker_DataObjectCreated", name, proxy)
    return proxy
end

function LibDataBroker:DataObjectIterator()
    return pairs(proxystorage)
end

function LibDataBroker:GetDataObjectByName(name)
    return proxystorage[name]
end

function LibDataBroker:GetNameByDataObject(dataobj)
    return namestorage[dataobj]
end
