-- Tests for Core/Filter.lua (ns.Judge, ns.ShouldHide and the filter callback). Receives (ns, T).
local ns, T = ...

local ME_GUID = "Player-1-000ME"
local function stubPlayer()
    _G.UnitGUID = function(unit) return unit == "player" and ME_GUID or nil end
    _G.UnitName = function(unit) return unit == "player" and "Myself" or nil end
end
--- Fresh defaults: filter on, all Cyrillic matched, hiding (spoiler off), public channels selected.
local function hideDB()
    ns.InitDB(nil)
    stubPlayer()
    return ns.db
end
--- Same, but collapsing lines instead of dropping them.
local function spoilerDB()
    local db = hideDB()
    db.spoiler = true
    return db
end

local CH = "CHAT_MSG_CHANNEL"

-- Defaults -----------------------------------------------------------------------------------

T.case("Defaults: spoiler off, names-only off, so Cyrillic trade chat is hidden", function()
    local db = hideDB()
    T.eq(db.spoiler, false)
    T.eq(db.namesOnly, false)
    T.eq(db.enabled, true)
    T.eq(ns.Judge(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"), "hide")
    T.ok(ns.ShouldHide(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"))
    T.eq(ns.Judge(CH, "WTS Lionheart Helm", "Stranger", "Player-1-AAA", 2, "Trade"), nil, "latin")
end)

T.case("Spoiler on: the same match is collapsed, never dropped", function()
    spoilerDB()
    T.eq(ns.Judge(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"), "spoiler")
    T.no(ns.ShouldHide(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("Judge returns the source key with the verdict", function()
    spoilerDB()
    local action, source = ns.Judge(CH, "Продам", "Stranger", "Player-1-AAA", 2, "Trade")
    T.eq(action, "spoiler")
    T.eq(source, "trade")
end)

-- Hide mode ----------------------------------------------------------------------------------

T.case("Hide: Cyrillic text in Trade is hidden", function()
    hideDB()
    T.ok(ns.ShouldHide(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("Hide: Latin text in Trade is shown", function()
    hideDB()
    T.no(ns.ShouldHide(CH, "WTS Lionheart Helm", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("Hide: Cyrillic-named sender with Latin text is hidden (all Cyrillic mode)", function()
    hideDB()
    T.ok(ns.ShouldHide(CH, "LFM SM", "Иван-Firemaw", "Player-1-AAA", 26, "LookingForGroup"))
end)

-- Channel selection (applies to both modes) ---------------------------------------------------

T.case("Channels: group and private chat untouched by default, in both modes", function()
    for _, mk in ipairs({ hideDB, spoilerDB }) do
        mk()
        T.eq(ns.Judge("CHAT_MSG_PARTY", "го в данж", "Друг-Firemaw", "Player-1-BBB"), nil, "party")
        T.eq(ns.Judge("CHAT_MSG_WHISPER", "привіт", "Друг", "Player-1-BBB"), nil, "whisper")
        T.eq(ns.Judge("CHAT_MSG_GUILD", "привіт", "Друг", "Player-1-BBB"), nil, "guild")
        T.eq(ns.Judge("CHAT_MSG_RAID", "привіт", "Друг", "Player-1-BBB"), nil, "raid")
        T.eq(ns.Judge("CHAT_MSG_SAY", "привіт", "Друг", "Player-1-BBB"), nil, "say")
        T.eq(ns.Judge("CHAT_MSG_YELL", "привіт", "Друг", "Player-1-BBB"), nil, "yell")
    end
end)

T.case("Channels: ticking Party makes Cyrillic party chat collapsed or hidden", function()
    local db = spoilerDB()
    db.sources.party = true
    T.eq(ns.Judge("CHAT_MSG_PARTY", "го в данж", "Друг-Firemaw", "Player-1-BBB"), "spoiler")
    db.spoiler = false
    T.eq(ns.Judge("CHAT_MSG_PARTY", "го в данж", "Друг-Firemaw", "Player-1-BBB"), "hide")
end)

T.case("Channels: unticking Trade leaves Cyrillic trade chat alone, in both modes", function()
    local db = spoilerDB()
    db.sources.trade = false
    T.eq(ns.Judge(CH, "Продам шмот", "Иван", "Player-1-AAA", 2, "Trade"), nil)
    db.spoiler = false
    T.eq(ns.Judge(CH, "Продам шмот", "Иван", "Player-1-AAA", 2, "Trade"), nil)
end)

T.case("Channels: custom 'World' channel is treated as Other", function()
    hideDB()
    T.ok(ns.ShouldHide(CH, "куплю", "Stranger", "Player-1-AAA", 0, "World"))
end)

-- Master switch ------------------------------------------------------------------------------

T.case("Master switch off shows everything, whatever the other options say", function()
    local db = spoilerDB()
    db.enabled = false
    T.eq(ns.Judge(CH, "Продам шмот", "Иван", "Player-1-AAA", 2, "Trade"), nil)
    db.spoiler = false
    T.eq(ns.Judge(CH, "Продам шмот", "Иван", "Player-1-AAA", 2, "Trade"), nil)
end)

-- Cyrillic names only ------------------------------------------------------------------------

T.case("Names only: Cyrillic text from Latin-named players is left alone", function()
    local db = hideDB()
    db.namesOnly = true
    T.eq(ns.Judge(CH, "Продам шмот", "Bob-Firemaw", "Player-1-AAA", 2, "Trade"), nil, "latin name, cyrillic text")
    T.eq(ns.Judge(CH, "Продам шмот", "Иван-Firemaw", "Player-1-BBB", 2, "Trade"), "hide", "cyrillic name, cyrillic text")
    T.eq(ns.Judge(CH, "WTS gold", "Иван-Firemaw", "Player-1-BBB", 2, "Trade"), "hide", "cyrillic name, latin text")
end)

T.case("Names only + spoiler: only Cyrillic-named senders are collapsed", function()
    local db = spoilerDB()
    db.namesOnly = true
    T.eq(ns.Judge(CH, "Продам шмот", "Bob-Firemaw", "Player-1-AAA", 2, "Trade"), nil, "latin name, cyrillic text")
    T.eq(ns.Judge(CH, "WTS gold", "Иван-Firemaw", "Player-1-BBB", 2, "Trade"), "spoiler", "cyrillic name, latin text")
end)

T.case("Names only still respects the channel selection", function()
    local db = hideDB()
    db.namesOnly = true
    T.eq(ns.Judge("CHAT_MSG_PARTY", "го", "Иван-Firemaw", "Player-1-BBB"), nil, "party off by default")
    db.sources.party = true
    T.eq(ns.Judge("CHAT_MSG_PARTY", "го", "Иван-Firemaw", "Player-1-BBB"), "hide", "party ticked")
end)

T.case("Names only off: empty sender is judged on text alone", function()
    hideDB()
    T.ok(ns.ShouldHide(CH, "Привет", "", nil, 2, "Trade"))
    T.no(ns.ShouldHide(CH, "Hello", nil, nil, 2, "Trade"))
end)

-- Own messages and foreign events ------------------------------------------------------------

T.case("Own message never touched (GUID match), in both modes", function()
    local db = spoilerDB()
    T.eq(ns.Judge(CH, "привіт усім", "Myself-Firemaw", ME_GUID, 2, "Trade"), nil)
    db.spoiler = false
    T.eq(ns.Judge(CH, "привіт усім", "Myself-Firemaw", ME_GUID, 2, "Trade"), nil)
end)

T.case("Own message never touched (name fallback when guid missing)", function()
    hideDB()
    T.no(ns.ShouldHide(CH, "привіт усім", "Myself", nil, 2, "Trade"))
    T.no(ns.ShouldHide(CH, "привіт усім", "Myself-Firemaw", "", 2, "Trade"))
end)

T.case("Another player with my name on another realm is not me when guid differs", function()
    hideDB()
    T.ok(ns.ShouldHide(CH, "привіт усім", "Myself-OtherRealm", "Player-2-ZZZ", 2, "Trade"))
end)

T.case("Events outside the contract are never touched", function()
    hideDB()
    T.eq(ns.Judge("CHAT_MSG_SYSTEM", "Привет", "", nil), nil)
    T.eq(ns.Judge("CHAT_MSG_BN_WHISPER", "Привет", "Друг", nil), nil)
end)

T.case("No db loaded yet means leave alone", function()
    ns.db = nil
    T.eq(ns.Judge(CH, "Привет", "Иван", "Player-1-AAA", 2, "Trade"), nil)
    T.no(ns.ShouldHide(CH, "Привет", "Иван", "Player-1-AAA", 2, "Trade"))
    hideDB()
end)

-- Migration and reset ------------------------------------------------------------------------

T.case("Migration: 1.0.x 'only mode 2' becomes namesOnly, other combos become all-Cyrillic", function()
    local db = ns.InitDB({ hideAllCyrillic = false, blockNames = true })
    T.eq(db.namesOnly, true, "mode 2 only")
    T.eq(db.hideAllCyrillic, nil, "old key dropped")
    T.eq(db.blockNames, nil, "old key dropped")
    T.eq(db.spoiler, false, "upgrade keeps hiding")
    T.eq(db.version, 2, "db version bumped")
    db = ns.InitDB({ hideAllCyrillic = true, blockNames = true })
    T.eq(db.namesOnly, false, "both modes")
    db = ns.InitDB({ hideAllCyrillic = false, blockNames = false })
    T.eq(db.namesOnly, false, "both off")
    db = ns.InitDB({ namesOnly = true, hideAllCyrillic = true })
    T.eq(db.namesOnly, true, "already migrated value wins")
    T.eq(db.hideAllCyrillic, nil)
    db = ns.InitDB({ version = 1, spoiler = true })
    T.eq(db.spoiler, false, "the forced spoiler of 1.1.0 is reset to the new default")
    db = ns.InitDB({ version = 2, spoiler = true })
    T.eq(db.spoiler, true, "an explicit choice on version 2 is kept")
    hideDB()
end)

T.case("ResetDefaults restores namesOnly off and spoiler off", function()
    local db = hideDB()
    db.namesOnly = true
    db.spoiler = true
    ns.ResetDefaults()
    T.eq(db.namesOnly, false)
    T.eq(db.spoiler, false)
end)

-- Filter callback -----------------------------------------------------------------------------

T.case("FilterFunc hide: maps chat-frame args by position, drops, counts and logs", function()
    hideDB()
    ns.log = {}
    ns.hiddenCount = 0
    -- (frame, event, text, sender, language, channelName, target, flags,
    --  zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid)
    local hide = ns.FilterFunc(nil, CH, "Продам", "Иван", "Common", "2. Trade - City", "", "",
        2, 2, "Trade", 7, 1001, "Player-1-AAA")
    T.eq(hide, true, "cyrillic trade line dropped")
    local show = ns.FilterFunc(nil, CH, "WTS", "Bob", "Common", "2. Trade - City", "", "",
        2, 2, "Trade", 7, 1002, "Player-1-BBB")
    T.eq(show, false, "latin trade line kept")
    T.eq(ns.hiddenCount, 1, "hidden counter")
    T.eq(#ns.log, 1, "one log entry")
    T.eq(ns.log[1].action, "hide")
    T.eq(ns.log[1].source, "trade")
    T.eq(ns.log[1].sender, "Иван")
    T.eq(ns.log[1].text, "Продам")
end)

T.case("FilterFunc spoiler: keeps the line, swaps the text, passes every other arg back", function()
    spoilerDB()
    ns.log = {}
    ns.hiddenCount = 0
    local ret = { ns.FilterFunc(nil, CH, "Продам", "Иван", "Common", "2. Trade - City", "", "",
        2, 2, "Trade", 7, 1001, "Player-1-AAA", "extra15", "extra16", "extra17") }
    T.eq(ret[1], false, "line kept")
    T.ok(ret[2]:find("|Haddon:NPCF:", 1, true), "text replaced by the spoiler link")
    T.no(ret[2]:find("Продам", 1, true), "original text not in the line")
    -- ret[1] is the drop flag, ret[n + 1] is chat arg n (text = 1, sender = 2, ..., guid = 12).
    T.eq(ret[3], "Иван", "sender passed back")
    T.eq(ret[8], 2, "zoneChannelID passed back")
    T.eq(ret[10], "Trade", "channelBaseName passed back")
    T.eq(ret[13], "Player-1-AAA", "guid passed back")
    T.eq(ret[16], "extra17", "trailing args passed back")
    T.eq(#ret, 16, "flag plus every original arg")
    T.eq(#ns.log, 1)
    T.eq(ns.log[1].action, "spoiler")
    T.eq(ns.hiddenCount, 1)
    T.eq(ns.SpoilerIdFromLink("addon:NPCF:" .. ns.log[1].id), ns.log[1].id, "link id matches the log")
    local keep = { ns.FilterFunc(nil, CH, "WTS", "Bob", "Common", "2. Trade - City", "", "",
        2, 2, "Trade", 7, 1002, "Player-1-BBB") }
    T.eq(keep[1], false)
    T.eq(#keep, 1, "untouched line returns nothing else")
end)
