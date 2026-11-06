-- Core/Detect.lua: pure Cyrillic detection on raw UTF-8 bytes. No WoW API.
local ADDON, ns = ...

local find = string.find
local sub = string.sub

-- U+0400..U+04FF (Cyrillic) encodes as 0xD0..0xD3 + 0x80..0xBF.
-- U+0500..U+052F (Cyrillic Supplement) encodes as 0xD4 + 0x80..0xAF.
-- 0xD4 0xB0 and up is Armenian and is deliberately excluded.
local CYR_MAIN = "[\208-\211][\128-\191]"
local CYR_SUPP = "\212[\128-\175]"

--- True if the string contains at least one Cyrillic letter.
function ns.IsCyrillic(s)
    if not s or s == "" then
        return false
    end
    return find(s, CYR_MAIN) ~= nil or find(s, CYR_SUPP) ~= nil
end

--- True if the character-name part of a sender (before any "-Realm") is Cyrillic.
function ns.NameIsCyrillic(sender)
    if not sender or sender == "" then
        return false
    end
    local dash = find(sender, "-", 1, true)
    if dash then
        sender = sub(sender, 1, dash - 1)
    end
    return ns.IsCyrillic(sender)
end
