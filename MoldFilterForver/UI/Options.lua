-- UI/Options.lua: Escape > Options > AddOns > MoldFilterForver, built on the Settings API.
local ADDON, ns = ...

local category
local registered = {}   -- { setting = <Settings object>, default = <bool> }

local function AddCheckbox(layoutCategory, tbl, key, variable, label, tooltip, default)
    local setting = Settings.RegisterAddOnSetting(
        layoutCategory, variable, key, tbl, Settings.VarType.Boolean, label, default)
    Settings.CreateCheckbox(layoutCategory, setting, tooltip)
    registered[#registered + 1] = { setting = setting, default = default }
    return setting
end

local function Build()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("MoldFilterForver")

    -- Status header: text refreshed each time the page is laid out.
    local status = CreateSettingsListSectionHeaderInitializer("Hidden this session: 0")
    local baseInit = status.InitFrame
    status.InitFrame = function(self, frame)
        self.data.name = "Hidden this session: " .. tostring(ns.hiddenCount or 0)
        baseInit(self, frame)
    end
    layout:AddInitializer(status)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Filter"))
    AddCheckbox(category, ns.db, "enabled", "MFF_enabled", "Filter enabled",
        "Master switch. When off, nothing is hidden.", ns.DEFAULTS.enabled)
    AddCheckbox(category, ns.db, "blockNames", "MFF_blockNames", "Block Cyrillic-named players",
        "Hide every message from a character whose name contains Cyrillic letters, even if the message itself is in Latin letters. Applies only in the sources ticked below.",
        ns.DEFAULTS.blockNames)

    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Where to filter"))
    for _, src in ipairs(ns.SOURCES) do
        AddCheckbox(category, ns.db.sources, src.key, "MFF_src_" .. src.key, src.label,
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
        "Restores the fresh-install settings: public channels filtered, group and private chat untouched.",
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
