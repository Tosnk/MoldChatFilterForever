-- UI/Options.lua: Escape > Options > AddOns > NoPetrovychChatFilter, built on the Settings API.
local ADDON, ns = ...

local category
local registered = {}   -- { setting = <Settings object>, default = <bool> }

local function AddCheckbox(layoutCategory, tbl, key, variable, label, tooltip, default)
    local setting = Settings.RegisterAddOnSetting(
        layoutCategory, variable, key, tbl, Settings.VarType.Boolean, label, default)
    local initializer = Settings.CreateCheckbox(layoutCategory, setting, tooltip)
    registered[#registered + 1] = { setting = setting, default = default }
    return setting, initializer
end

local function Build()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("NoPetrovychChatFilter")

    -- Status header: text refreshed each time the page is laid out.
    local status = CreateSettingsListSectionHeaderInitializer("Hidden this session: 0")
    local baseInit = status.InitFrame
    status.InitFrame = function(self, frame)
        self.data.name = "Hidden this session: " .. tostring(ns.hiddenCount or 0)
        baseInit(self, frame)
    end
    layout:AddInitializer(status)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Filter"))
    AddCheckbox(category, ns.db, "enabled", "NPCF_enabled", "Filter enabled",
        "Master switch. When off, nothing is hidden.", ns.DEFAULTS.enabled)

    -- Mode 1: any Cyrillic text. Turning it on also turns on and locks mode 2.
    local allSetting, allInit = AddCheckbox(category, ns.db, "hideAllCyrillic", "NPCF_hideAllCyrillic",
        "Filter all Cyrillic messages",
        "Hide every message that contains Cyrillic letters, whoever sends it. While this is on, Cyrillic-named players are always filtered too.",
        ns.DEFAULTS.hideAllCyrillic)

    -- Mode 2: everything from Cyrillic-named senders, whatever script they type in.
    local namesSetting, namesInit = AddCheckbox(category, ns.db, "blockNames", "NPCF_blockNames",
        "Filter Cyrillic-named players",
        "Hide every message from a character whose name contains Cyrillic letters, even when the message itself is in Latin letters. With only this on, Cyrillic text from Latin-named players stays visible.",
        ns.DEFAULTS.blockNames)
    namesInit:SetParentInitializer(allInit, function()
        return not ns.db.hideAllCyrillic
    end)
    allSetting:SetValueChangedCallback(function(_, value)
        if value and not ns.db.blockNames then
            namesSetting:SetValue(true)
        end
    end)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Where to filter"))
    for _, src in ipairs(ns.SOURCES) do
        AddCheckbox(category, ns.db.sources, src.key, "NPCF_src_" .. src.key, src.label,
            src.tooltip, src.default)
    end

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Maintenance"))
    layout:AddInitializer(CreateSettingsButtonInitializer(
        "Reset to defaults", "Reset",
        function()
            ns.ResetDefaults()
            for _, entry in ipairs(registered) do
                entry.setting:SetValue(entry.default)
            end
        end,
        "Restores the fresh-install settings: both filter modes on, public channels filtered, group and private chat untouched.",
        true))

    Settings.RegisterAddOnCategory(category)
end

--- Open the game's Options panel on this addon's page.
function ns.OpenOptions()
    if category then
        Settings.OpenToCategory(category:GetID())
    end
end

if _G.Settings then
    ns.RunWhenLoaded(Build)
end
