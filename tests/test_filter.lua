-- Tests for Core/Filter.lua (ns.ShouldHide and the filter callback). Receives (ns, T).
local ns, T = ...

local ME_GUID = "Player-1-000ME"
local function stubPlayer()
    _G.UnitGUID = function(unit) return unit == "player" and ME_GUID or nil end
    _G.UnitName = function(unit) return unit == "player" and "Myself" or nil end
end
local function freshDB()
    ns.InitDB(nil)
    stubPlayer()
    return ns.db
end

local CH = "CHAT_MSG_CHANNEL"

T.case("ShouldHide: Cyrillic text in Trade is hidden by default", function()
    freshDB()
    T.ok(ns.ShouldHide(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("ShouldHide: Latin text in Trade is shown", function()
    freshDB()
    T.no(ns.ShouldHide(CH, "WTS Lionheart Helm", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("ShouldHide: Cyrillic text in Party is shown by default", function()
    freshDB()
    T.no(ns.ShouldHide("CHAT_MSG_PARTY", "го в данж", "Друг-Firemaw", "Player-1-BBB"))
end)

T.case("ShouldHide: Cyrillic in whisper, guild, raid, say, yell shown by default", function()
    freshDB()
    T.no(ns.ShouldHide("CHAT_MSG_WHISPER", "привіт", "Друг", "Player-1-BBB"))
    T.no(ns.ShouldHide("CHAT_MSG_GUILD", "привіт", "Друг", "Player-1-BBB"))
    T.no(ns.ShouldHide("CHAT_MSG_RAID", "привіт", "Друг", "Player-1-BBB"))
    T.no(ns.ShouldHide("CHAT_MSG_SAY", "привіт", "Друг", "Player-1-BBB"))
    T.no(ns.ShouldHide("CHAT_MSG_YELL", "привіт", "Друг", "Player-1-BBB"))
end)

T.case("ShouldHide: ticking Party makes Cyrillic party chat hidden", function()
    local db = freshDB()
    db.sources.party = true
    T.ok(ns.ShouldHide("CHAT_MSG_PARTY", "го в данж", "Друг-Firemaw", "Player-1-BBB"))
end)

T.case("ShouldHide: unticking Trade shows Cyrillic trade chat", function()
    local db = freshDB()
    db.sources.trade = false
    T.no(ns.ShouldHide(CH, "Продам шмот", "Stranger", "Player-1-AAA", 2, "Trade"))
end)

T.case("ShouldHide: master switch off shows everything", function()
    local db = freshDB()
    db.enabled = false
    T.no(ns.ShouldHide(CH, "Продам шмот", "Иван", "Player-1-AAA", 2, "Trade"))
end)

T.case("ShouldHide: Cyrillic-named sender with Latin text hidden when blockNames on", function()
    freshDB()
    T.ok(ns.ShouldHide(CH, "LFM SM", "Иван-Firemaw", "Player-1-AAA", 26, "LookingForGroup"))
end)

T.case("ShouldHide: Cyrillic-named sender shown when blockNames off", function()
    local db = freshDB()
    db.blockNames = false
    T.no(ns.ShouldHide(CH, "LFM SM", "Иван-Firemaw", "Player-1-AAA", 26, "LookingForGroup"))
end)

T.case("ShouldHide: Cyrillic-named sender in an unticked source is shown", function()
    freshDB()
    T.no(ns.ShouldHide("CHAT_MSG_PARTY", "LFM SM", "Иван-Firemaw", "Player-1-AAA"))
end)

T.case("ShouldHide: own message never hidden (GUID match)", function()
    freshDB()
    T.no(ns.ShouldHide(CH, "привіт усім", "Myself-Firemaw", ME_GUID, 2, "Trade"))
end)

T.case("ShouldHide: own message never hidden (name fallback when guid missing)", function()
    freshDB()
    T.no(ns.ShouldHide(CH, "привіт усім", "Myself", nil, 2, "Trade"))
    T.no(ns.ShouldHide(CH, "привіт усім", "Myself-Firemaw", "", 2, "Trade"))
end)

T.case("ShouldHide: another player with my name on another realm is not me when guid differs", function()
    freshDB()
    T.ok(ns.ShouldHide(CH, "привіт усім", "Myself-OtherRealm", "Player-2-ZZZ", 2, "Trade"))
end)

T.case("ShouldHide: custom 'World' channel is filtered as Other", function()
    freshDB()
    T.ok(ns.ShouldHide(CH, "куплю", "Stranger", "Player-1-AAA", 0, "World"))
end)

T.case("ShouldHide: events outside the contract are never hidden", function()
    freshDB()
    T.no(ns.ShouldHide("CHAT_MSG_SYSTEM", "Привет", "", nil))
    T.no(ns.ShouldHide("CHAT_MSG_BN_WHISPER", "Привет", "Друг", nil))
end)

T.case("ShouldHide: empty sender is judged on text only", function()
    freshDB()
    T.ok(ns.ShouldHide(CH, "Привет", "", nil, 2, "Trade"))
    T.no(ns.ShouldHide(CH, "Hello", nil, nil, 2, "Trade"))
end)

T.case("ShouldHide: no db loaded yet means show", function()
    ns.db = nil
    T.no(ns.ShouldHide(CH, "Привет", "Иван", "Player-1-AAA", 2, "Trade"))
    freshDB()
end)

T.case("FilterFunc: maps chat-frame args by position and counts hidden lines", function()
    freshDB()
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
end)
