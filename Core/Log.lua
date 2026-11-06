-- Core/Log.lua: the session log of every message the addon hid or collapsed. No WoW API.
local ADDON, ns = ...

local MAX_ENTRIES = 500

ns.log = {}          -- oldest first; each entry: { id, time, action, source, sender, text }
ns.logSeq = 0
ns.hiddenCount = 0   -- everything acted on this session (hidden + collapsed), survives a log clear

local dateFn = _G.date or (os and os.date)

--- Record a message the filter acted on. action is "hide" or "spoiler". Returns the entry.
function ns.LogAdd(action, source, sender, text)
    ns.logSeq = ns.logSeq + 1
    ns.hiddenCount = ns.hiddenCount + 1
    local entry = {
        id = ns.logSeq,
        time = dateFn and dateFn("%H:%M:%S") or "",
        action = action,
        source = source,
        sender = sender or "",
        text = text or "",
    }
    local log = ns.log
    log[#log + 1] = entry
    if #log > MAX_ENTRIES then
        table.remove(log, 1)
    end
    if ns.onLogAdded then
        ns.onLogAdded(entry)
    end
    return entry
end

--- Find a logged entry by id (newest first, since reveals target recent lines).
function ns.LogFind(id)
    local log = ns.log
    for i = #log, 1, -1 do
        if log[i].id == id then
            return log[i]
        end
    end
end

function ns.LogClear()
    ns.log = {}
    if ns.onLogCleared then
        ns.onLogCleared()
    end
end
