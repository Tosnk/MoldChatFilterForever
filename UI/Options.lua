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

local function Header(text)
    return CreateSettingsListSectionHeaderInitializer(text)
end

local function Build()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("NoPetrovychChatFilter")

    -- Counter and the log button on one row; the label is refreshed each time the row is laid out.
    local logInit = CreateSettingsButtonInitializer("Filtered this session: 0", "Open log",
        function() ns.OpenLog() end,
        "Every message hidden or collapsed this session, with time, channel and sender.", true)
    local baseInit = logInit.InitFrame
    logInit.InitFrame = function(self, frame)
        self.data.name = "Filtered this session: " .. tostring(ns.hiddenCount or 0)
        baseInit(self, frame)
    end
    layout:AddInitializer(logInit)

    layout:AddInitializer(Header("Filter"))

    -- Master switch. Every other row is its child, so they grey out while it is off.
    local _, enabledInit = AddCheckbox(category, ns.db, "enabled", "NPCF_enabled", "Filter enabled",
        "Master switch. When off, nothing is hidden or collapsed and the options below are locked.",
        ns.DEFAULTS.enabled)
    local function filterOn()
        return ns.db.enabled == true
    end

    local _, namesInit = AddCheckbox(category, ns.db, "namesOnly", "NPCF_namesOnly",
        "Cyrillic names only",
        "Act only on messages from characters whose name contains Cyrillic letters, whatever script they type in. Cyrillic text from Latin-named players is left alone. Off: any message containing Cyrillic letters is matched too.",
        ns.DEFAULTS.namesOnly)
    namesInit:SetParentInitializer(enabledInit, filterOn)

    local _, spoilerInit = AddCheckbox(category, ns.db, "spoiler", "NPCF_spoiler",
        "Use spoiler instead of hiding",
        "Keep the line but collapse its text behind a click-to-read link instead of removing it. Follows the same matching rule and channel selection as hiding.",
        ns.DEFAULTS.spoiler)
    spoilerInit:SetParentInitializer(enabledInit, filterOn)

    layout:AddInitializer(Header("Where"))
    for _, src in ipairs(ns.SOURCES) do
        local _, init = AddCheckbox(category, ns.db.sources, src.key, "NPCF_src_" .. src.key,
            src.label, src.tooltip, src.default)
        init:SetParentInitializer(enabledInit, filterOn)
    end

    layout:AddInitializer(Header("Maintenance"))
    layout:AddInitializer(CreateSettingsButtonInitializer(
        "Reset to defaults", "Reset",
        function()
            ns.ResetDefaults()
            for _, entry in ipairs(registered) do
                entry.setting:SetValue(entry.default)
            end
        end,
        "Restores the fresh-install settings: filter on, all Cyrillic matched, spoiler on, public channels selected, group and private chat not.",
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
