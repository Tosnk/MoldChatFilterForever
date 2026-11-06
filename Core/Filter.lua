-- Core/Filter.lua: the decision function and the chat-frame filter hooks.
-- WoW globals are read through _G at call time so the test harness can load this file.
local ADDON, ns = ...

local find = string.find
local sub = string.sub

local LINK_PREFIX = "|Haddon:NPCF:"
ns.LINK_PREFIX = LINK_PREFIX

local function isOwnMessage(sender, guid)
    local UnitGUID = _G.UnitGUID
    if guid and guid ~= "" and UnitGUID then
        local mine = UnitGUID("player")
        if mine then
            return guid == mine
        end
    end
    local UnitName = _G.UnitName
    if sender and sender ~= "" and UnitName then
        local me = UnitName("player")
        if me then
            local dash = find(sender, "-", 1, true)
            local short = dash and sub(sender, 1, dash - 1) or sender
            return short == me
        end
    end
    return false
end

--- Decide what to do with a chat line: "hide" (drop it), "spoiler" (collapse it behind a
--- click-to-read link) or nil (leave it alone). Second return is the source key.
--- Settings (specs/003): enabled is the master switch; namesOnly restricts matching to
--- Cyrillic-named senders; spoiler swaps dropping for collapsing. The channel selection
--- applies to both.
function ns.Judge(event, text, sender, guid, zoneChannelID, channelBaseName)
    local db = ns.db
    if not db or not db.enabled then
        return nil
    end
    if isOwnMessage(sender, guid) then
        return nil
    end
    local source = ns.EventToSource(event, zoneChannelID, channelBaseName)
    if not source or db.sources[source] ~= true then
        return nil
    end
    local match = ns.NameIsCyrillic(sender) or (not db.namesOnly and ns.IsCyrillic(text))
    if not match then
        return nil
    end
    return db.spoiler and "spoiler" or "hide", source
end

--- True when the line would be dropped outright.
function ns.ShouldHide(event, text, sender, guid, zoneChannelID, channelBaseName)
    return ns.Judge(event, text, sender, guid, zoneChannelID, channelBaseName) == "hide"
end

--- The replacement text for a collapsed line; the log id travels inside the link.
function ns.SpoilerText(id)
    return LINK_PREFIX .. id .. "|h|cff9d9d9d[Petrovych detected, click to read]|r|h"
end

--- Parse a clicked link back into a log id, or nil for links that are not ours.
function ns.SpoilerIdFromLink(link)
    if type(link) ~= "string" then
        return nil
    end
    local id = link:match("^addon:NPCF:(%d+)$")
    return id and tonumber(id) or nil
end

-- Filter signature: (chatFrame, event, text, sender, language, channelName, target, flags,
--                    zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, ...)
-- Returning true drops the line. Returning false plus a replacement arg list rewrites it, and
-- the client takes EVERY arg from that list, so the untouched ones are passed back verbatim.
local function filter(_, event, text, ...)
    local sender, _, _, _, _, zoneChannelID, _, channelBaseName, _, _, guid = ...
    local action, source = ns.Judge(event, text, sender, guid, zoneChannelID, channelBaseName)
    if action == "hide" then
        ns.LogAdd("hide", source, sender, text)
        return true
    elseif action == "spoiler" then
        local entry = ns.LogAdd("spoiler", source, sender, text)
        return false, ns.SpoilerText(entry.id), ...
    end
    return false
end
ns.FilterFunc = filter

local AddFilter = _G.ChatFrame_AddMessageEventFilter
if AddFilter then
    for _, event in ipairs(ns.CHAT_EVENTS) do
        AddFilter(event, filter)
    end
end
