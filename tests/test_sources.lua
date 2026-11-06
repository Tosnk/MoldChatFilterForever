-- Tests for Core/Sources.lua and Core/Config.lua. Receives (ns, T) from tests/run_tests.py.
local ns, T = ...

T.case("SOURCES: order and keys match the contract", function()
    local want = { "general", "trade", "lfg", "localdefense", "other", "say", "yell", "emote",
                   "party", "raid", "instance", "guild", "whisper" }
    T.eq(#ns.SOURCES, #want, "source count")
    for i, key in ipairs(want) do
        T.eq(ns.SOURCES[i].key, key, "source " .. i)
        T.ok(ns.SOURCES[i].label and ns.SOURCES[i].label ~= "", "label " .. key)
        T.ok(ns.SOURCES[i].tooltip and ns.SOURCES[i].tooltip ~= "", "tooltip " .. key)
    end
end)

T.case("DEFAULTS: public channels on, everything else off (constitution III)", function()
    local on = { general = true, trade = true, lfg = true, localdefense = true, other = true }
    for _, src in ipairs(ns.SOURCES) do
        T.eq(ns.DEFAULTS.sources[src.key], on[src.key] == true, "default for " .. src.key)
    end
    T.eq(ns.DEFAULTS.enabled, true, "enabled")
    T.eq(ns.DEFAULTS.namesOnly, false, "namesOnly")
    T.eq(ns.DEFAULTS.spoiler, false, "spoiler")
    T.eq(ns.DEFAULTS.version, 2, "version")
end)

T.case("EventToSource: numbered channels by zoneChannelID", function()
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 1, "General"), "general")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 2, "Trade"), "trade")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 26, "LookingForGroup"), "lfg")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 22, "LocalDefense"), "localdefense")
end)

T.case("EventToSource: zoneChannelID wins over a misleading base name", function()
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 2, "General"), "trade")
end)

T.case("EventToSource: base-name fallback when zoneChannelID is 0 or nil", function()
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 0, "Trade"), "trade")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", nil, "LookingForGroup"), "lfg")
end)

T.case("EventToSource: custom, world and unknown Blizzard channels are 'other'", function()
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 0, "World"), "other")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 0, "Торговля"), "other")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 23, "WorldDefense"), "other")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", 999, nil), "other")
    T.eq(ns.EventToSource("CHAT_MSG_CHANNEL", nil, nil), "other")
end)

T.case("EventToSource: every non-channel event in the contract", function()
    local want = {
        CHAT_MSG_SAY = "say", CHAT_MSG_YELL = "yell",
        CHAT_MSG_EMOTE = "emote", CHAT_MSG_TEXT_EMOTE = "emote",
        CHAT_MSG_PARTY = "party", CHAT_MSG_PARTY_LEADER = "party",
        CHAT_MSG_RAID = "raid", CHAT_MSG_RAID_LEADER = "raid", CHAT_MSG_RAID_WARNING = "raid",
        CHAT_MSG_INSTANCE_CHAT = "instance", CHAT_MSG_INSTANCE_CHAT_LEADER = "instance",
        CHAT_MSG_BATTLEGROUND = "instance", CHAT_MSG_BATTLEGROUND_LEADER = "instance",
        CHAT_MSG_GUILD = "guild", CHAT_MSG_OFFICER = "guild",
        CHAT_MSG_WHISPER = "whisper",
    }
    for event, key in pairs(want) do
        T.eq(ns.EventToSource(event), key, event)
    end
end)

T.case("EventToSource: events we must never touch map to nil", function()
    T.eq(ns.EventToSource("CHAT_MSG_WHISPER_INFORM"), nil)
    T.eq(ns.EventToSource("CHAT_MSG_BN_WHISPER"), nil)
    T.eq(ns.EventToSource("CHAT_MSG_SYSTEM"), nil)
    T.eq(ns.EventToSource("CHAT_MSG_MONSTER_SAY"), nil)
end)

T.case("CHAT_EVENTS: hooks CHAT_MSG_CHANNEL plus every source event, nothing else", function()
    local seen = {}
    for _, ev in ipairs(ns.CHAT_EVENTS) do
        seen[ev] = true
        T.ok(ev == "CHAT_MSG_CHANNEL" or ns.EventToSource(ev) ~= nil, "unexpected hook " .. ev)
    end
    T.ok(seen.CHAT_MSG_CHANNEL, "CHAT_MSG_CHANNEL hooked")
    T.ok(seen.CHAT_MSG_WHISPER, "whisper hooked (off by default)")
    T.no(seen.CHAT_MSG_WHISPER_INFORM, "own outgoing whisper not hooked")
end)

T.case("InitDB: fresh install gets defaults, existing keys kept, unknown keys kept", function()
    local fresh = ns.InitDB(nil)
    T.eq(fresh.enabled, true)
    T.eq(fresh.sources.party, false)
    T.eq(fresh.version, 2)

    local old = { enabled = false, sources = { trade = false }, futureKey = "x" }
    local db = ns.InitDB(old)
    T.eq(db, old, "same table returned")
    T.eq(db.enabled, false, "existing value kept")
    T.eq(db.sources.trade, false, "existing source kept")
    T.eq(db.sources.general, true, "missing source filled")
    T.eq(db.futureKey, "x", "unknown key kept")
end)

T.case("ResetDefaults: restores every user-facing setting", function()
    local db = ns.InitDB({ version = 2, enabled = false, namesOnly = true, spoiler = true, sources = { party = true, trade = false } })
    ns.ResetDefaults()
    T.eq(db.enabled, true)
    T.eq(db.namesOnly, false)
    T.eq(db.spoiler, false)
    T.eq(db.sources.party, false)
    T.eq(db.sources.trade, true)
end)

T.case("RunWhenLoaded: runs immediately once db exists", function()
    ns.InitDB(nil)
    local ran = false
    ns.RunWhenLoaded(function() ran = true end)
    T.ok(ran)
end)
