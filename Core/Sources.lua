-- Core/Sources.lua: the chat-source registry, defaults and event routing. No WoW API.
local ADDON, ns = ...

-- Order here is the order in the Options panel. Public channels first (default ON),
-- group and private chat after (default OFF, constitution III).
ns.SOURCES = {
    { key = "general",      label = "General",                 default = true,
      tooltip = "The zone-wide General channel, including cities.",
      zone = 1,  baseName = "General" },
    { key = "trade",        label = "Trade",                   default = true,
      tooltip = "The Trade channel in cities.",
      zone = 2,  baseName = "Trade" },
    { key = "lfg",          label = "LookingForGroup",         default = true,
      tooltip = "The LookingForGroup channel.",
      zone = 26, baseName = "LookingForGroup" },
    { key = "localdefense", label = "LocalDefense",            default = true,
      tooltip = "The LocalDefense channel.",
      zone = 22, baseName = "LocalDefense" },
    { key = "other",        label = "Other channels",          default = true,
      tooltip = "World, custom and any other numbered channel." },
    { key = "say",          label = "Say",                     default = false,
      tooltip = "Nearby /say chat.",
      events = { "CHAT_MSG_SAY" } },
    { key = "yell",         label = "Yell",                    default = false,
      tooltip = "Zone-wide /yell chat.",
      events = { "CHAT_MSG_YELL" } },
    { key = "emote",        label = "Emote",                   default = false,
      tooltip = "Custom and standard emotes.",
      events = { "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE" } },
    { key = "party",        label = "Party",                   default = false,
      tooltip = "Party and party leader chat.",
      events = { "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER" } },
    { key = "raid",         label = "Raid",                    default = false,
      tooltip = "Raid, raid leader and raid warning chat.",
      events = { "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING" } },
    { key = "instance",     label = "Instance / Battleground", default = false,
      tooltip = "Instance and battleground group chat.",
      events = { "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
                 "CHAT_MSG_BATTLEGROUND", "CHAT_MSG_BATTLEGROUND_LEADER" } },
    { key = "guild",        label = "Guild / Officer",         default = false,
      tooltip = "Guild and officer chat.",
      events = { "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER" } },
    { key = "whisper",      label = "Whisper (incoming)",      default = false,
      tooltip = "Whispers other players send you. Battle.net whispers are never filtered.",
      events = { "CHAT_MSG_WHISPER" } },
}

ns.DEFAULTS = {
    version = 1,
    enabled = true,
    hideAllCyrillic = true,  -- mode 1: hide every message containing Cyrillic (forces blockNames on)
    blockNames = true,       -- mode 2: hide every message from a Cyrillic-named sender
    sources = {},
}

local EVENT_SOURCE = {}
local ZONE_SOURCE = {}
local NAME_SOURCE = {}
ns.CHAT_EVENTS = { "CHAT_MSG_CHANNEL" }

for _, src in ipairs(ns.SOURCES) do
    ns.DEFAULTS.sources[src.key] = src.default
    if src.zone then
        ZONE_SOURCE[src.zone] = src.key
    end
    if src.baseName then
        NAME_SOURCE[src.baseName] = src.key
    end
    if src.events then
        for _, ev in ipairs(src.events) do
            EVENT_SOURCE[ev] = src.key
            ns.CHAT_EVENTS[#ns.CHAT_EVENTS + 1] = ev
        end
    end
end

--- Map a chat event (plus channel info for CHAT_MSG_CHANNEL) to a source key, or nil.
function ns.EventToSource(event, zoneChannelID, channelBaseName)
    if event == "CHAT_MSG_CHANNEL" then
        local key = zoneChannelID and ZONE_SOURCE[zoneChannelID]
        if key then
            return key
        end
        if (not zoneChannelID or zoneChannelID == 0) and channelBaseName then
            key = NAME_SOURCE[channelBaseName]
            if key then
                return key
            end
        end
        return "other"
    end
    return EVENT_SOURCE[event]
end

--- Look up a source entry by key.
function ns.SourceByKey(key)
    for _, src in ipairs(ns.SOURCES) do
        if src.key == key then
            return src
        end
    end
end
