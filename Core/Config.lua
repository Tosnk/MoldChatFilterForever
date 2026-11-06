-- Core/Config.lua: SavedVariables initialisation, defaults merge and reset.
-- WoW globals are read through _G at call time so the test harness can load this file.
local ADDON, ns = ...

local loadedCallbacks = {}

local function copyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            copyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

--- Fill a saved table (or a fresh one) with every missing default and expose it as ns.db.
function ns.InitDB(saved)
    saved = saved or {}
    copyDefaults(saved, ns.DEFAULTS)
    ns.db = saved
    return saved
end

--- Restore every user-facing setting to its fresh-install value.
function ns.ResetDefaults()
    local db = ns.db
    db.enabled = ns.DEFAULTS.enabled
    db.hideAllCyrillic = ns.DEFAULTS.hideAllCyrillic
    db.blockNames = ns.DEFAULTS.blockNames
    for key, value in pairs(ns.DEFAULTS.sources) do
        db.sources[key] = value
    end
end

--- Run fn now if settings are loaded, otherwise once ADDON_LOADED has initialised them.
function ns.RunWhenLoaded(fn)
    if ns.db then
        fn()
    else
        loadedCallbacks[#loadedCallbacks + 1] = fn
    end
end

local CreateFrame = _G.CreateFrame
if CreateFrame then
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function(self, event, name)
        if name ~= ADDON then
            return
        end
        self:UnregisterEvent("ADDON_LOADED")
        NoPetrovychChatFilterDB = ns.InitDB(NoPetrovychChatFilterDB)
        for _, fn in ipairs(loadedCallbacks) do
            fn()
        end
    end)
end
