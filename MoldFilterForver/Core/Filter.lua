-- Core/Filter.lua: the decision function and the chat-frame filter hooks.
-- WoW globals are read through _G at call time so the test harness can load this file.
local ADDON, ns = ...

local find = string.find
local sub = string.sub

ns.hiddenCount = 0

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

--- Decide whether a chat line should be dropped. Order per contracts/chat-sources.md.
function ns.ShouldHide(event, text, sender, guid, zoneChannelID, channelBaseName)
    local db = ns.db
    if not db or not db.enabled then
        return false
    end
    if isOwnMessage(sender, guid) then
        return false
    end
    local source = ns.EventToSource(event, zoneChannelID, channelBaseName)
    if not source or db.sources[source] ~= true then
        return false
    end
    if db.blockNames and ns.NameIsCyrillic(sender) then
        return true
    end
    return ns.IsCyrillic(text)
end

-- Filter signature: (chatFrame, event, text, sender, language, channelName, target, flags,
--                    zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, ...)
local function filter(_, event, text, sender, _, _, _, _, zoneChannelID, _, channelBaseName, _, _, guid)
    if ns.ShouldHide(event, text, sender, guid, zoneChannelID, channelBaseName) then
        ns.hiddenCount = ns.hiddenCount + 1
        return true
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
