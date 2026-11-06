-- Tests for Core/Log.lua. Receives (ns, T).
local ns, T = ...

local function fresh()
    ns.log = {}
    ns.logSeq = 0
    ns.hiddenCount = 0
    ns.onLogAdded = nil
    ns.onLogCleared = nil
end

T.case("LogAdd: records the entry, bumps the counter and returns it", function()
    fresh()
    local e = ns.LogAdd("hide", "trade", "Иван-Firemaw", "Продам шмот")
    T.eq(#ns.log, 1)
    T.eq(ns.hiddenCount, 1)
    T.eq(e.id, 1)
    T.eq(e.action, "hide")
    T.eq(e.source, "trade")
    T.eq(e.sender, "Иван-Firemaw")
    T.eq(e.text, "Продам шмот")
    T.ok(type(e.time) == "string", "time is a string")
end)

T.case("LogAdd: ids keep growing and LogFind finds by id", function()
    fresh()
    ns.LogAdd("spoiler", "general", "A", "х")
    local second = ns.LogAdd("spoiler", "general", "B", "у")
    T.eq(second.id, 2)
    T.eq(ns.LogFind(2).sender, "B")
    T.eq(ns.LogFind(1).sender, "A")
    T.eq(ns.LogFind(99), nil)
end)

T.case("LogAdd: keeps the newest 500 entries only", function()
    fresh()
    for i = 1, 505 do
        ns.LogAdd("hide", "trade", "S", tostring(i))
    end
    T.eq(#ns.log, 500)
    T.eq(ns.log[1].text, "6", "oldest kept")
    T.eq(ns.log[500].text, "505", "newest kept")
    T.eq(ns.hiddenCount, 505, "counter is not capped")
    T.eq(ns.LogFind(1), nil, "evicted entry is gone")
end)

T.case("LogAdd / LogClear: callbacks fire, clear keeps the counter", function()
    fresh()
    local added, cleared = 0, 0
    ns.onLogAdded = function() added = added + 1 end
    ns.onLogCleared = function() cleared = cleared + 1 end
    ns.LogAdd("hide", "trade", "S", "х")
    ns.LogClear()
    T.eq(added, 1)
    T.eq(cleared, 1)
    T.eq(#ns.log, 0)
    T.eq(ns.hiddenCount, 1)
    fresh()
end)

T.case("Spoiler link: SpoilerText embeds the id and SpoilerIdFromLink reads it back", function()
    local text = ns.SpoilerText(42)
    T.ok(text:find("|Haddon:NPCF:42|h", 1, true), "link prefix with id")
    T.ok(text:find("click to read", 1, true), "placeholder wording")
    T.ok(text:sub(-2) == "|h", "link closed")
    T.eq(ns.SpoilerIdFromLink("addon:NPCF:42"), 42)
    T.eq(ns.SpoilerIdFromLink("addon:buggrabber:x:y:"), nil)
    T.eq(ns.SpoilerIdFromLink("item:19019"), nil)
    T.eq(ns.SpoilerIdFromLink(nil), nil)
end)
