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
    Print(("Filter %s, all Cyrillic %s, Cyrillic-named players %s, hidden this session: %d"):format(
        OnOff(db.enabled), OnOff(db.hideAllCyrillic), OnOff(ns.BlockNamesActive()), ns.hiddenCount or 0))
    local labels = {}
    for _, src in ipairs(ns.SOURCES) do
        if db.sources[src.key] then
            labels[#labels + 1] = src.label
        end
    end
    Print("Filtering: " .. (#labels > 0 and table.concat(labels, ", ") or "none"))
end

local function Usage()
    Print("commands:")
    Print("  /npcf                open the Options page")
    Print("  /npcf on | off | toggle")
    Print("  /npcf status         show settings and hidden count")
    Print("  /npcf test <text>    would this text be hidden?")
    Print("  /npcf reset          restore defaults")
end

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
    elseif cmd == "on" then
        db.enabled = true
        Status()
    elseif cmd == "off" then
        db.enabled = false
        Status()
    elseif cmd == "toggle" then
        db.enabled = not db.enabled
        Status()
    elseif cmd == "status" then
        Status()
    elseif cmd == "test" then
        local hidden = ns.ShouldHide("CHAT_MSG_CHANNEL", rest, "Stranger", nil, 2, "Trade")
        Print(('"%s" -> %s'):format(rest, hidden and "|cffff0000hidden|r" or "|cff00ff00shown|r"))
    elseif cmd == "reset" then
        ns.ResetDefaults()
        Print("Settings reset to defaults.")
        Status()
    else
        Usage()
    end
end
