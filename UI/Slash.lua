-- UI/Slash.lua: /npcf and /nopetrovych, mirroring the Options panel (contracts/slash-commands.md).
local ADDON, ns = ...

local PREFIX = "|cff33ff99NoPetrovychChatFilter|r: "

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. text)
end

local function OnOff(value)
    return value and "|cff00ff00ON|r" or "|cffff0000OFF|r"
end

local function Status()
    local db = ns.db
    Print(("Filter %s, Cyrillic names only %s, spoiler instead of hiding %s, filtered this session: %d"):format(
        OnOff(db.enabled), OnOff(db.namesOnly), OnOff(db.spoiler), ns.hiddenCount or 0))
    local labels = {}
    for _, src in ipairs(ns.SOURCES) do
        if db.sources[src.key] then
            labels[#labels + 1] = src.label
        end
    end
    Print((db.spoiler and "Collapsing in: " or "Hiding in: ")
        .. (#labels > 0 and table.concat(labels, ", ") or "none"))
end

local function Usage()
    Print("commands:")
    Print("  /npcf                open the Options page")
    Print("  /npcf log            open the filtered-messages log")
    Print("  /npcf on | off | toggle")
    Print("  /npcf names          toggle 'Cyrillic names only'")
    Print("  /npcf spoiler        toggle 'Use spoiler instead of hiding'")
    Print("  /npcf status         show settings and the filtered count")
    Print("  /npcf test <text>    what would happen to this text in Trade?")
    Print("  /npcf reset          restore defaults")
    Print("  /npcf debug          where the newest collapsed line lives (for bug reports)")
end

local VERDICT = { hide = "|cffff0000hidden|r", spoiler = "|cffffd100collapsed|r" }

SLASH_NOPETROVYCHCHATFILTER1 = "/npcf"
SLASH_NOPETROVYCHCHATFILTER2 = "/nopetrovych"
SlashCmdList.NOPETROVYCHCHATFILTER = function(input)
    local db = ns.db
    if not db then
        return
    end
    local cmd, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()
    if cmd == "" then
        ns.OpenOptions()
    elseif cmd == "log" then
        ns.ToggleLog()
    elseif cmd == "on" then
        db.enabled = true
        Status()
    elseif cmd == "off" then
        db.enabled = false
        Status()
    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        Status()
    elseif cmd == "names" then
        db.namesOnly = not db.namesOnly
        Status()
    elseif cmd == "spoiler" then
        db.spoiler = not db.spoiler
        Status()
    elseif cmd == "status" then
        Status()
    elseif cmd == "debug" then
        ns.DebugReveal()
    elseif cmd == "test" then
        local action = ns.Judge("CHAT_MSG_CHANNEL", rest, "Stranger", nil, 2, "Trade")
        Print(('"%s" -> %s'):format(rest, VERDICT[action] or "|cff00ff00shown|r"))
    elseif cmd == "reset" then
        ns.ResetDefaults()
        Print("Settings reset to defaults.")
        Status()
    else
        Usage()
    end
end
