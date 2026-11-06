-- UI/Log.lua: the "filtered messages" window (every line hidden or collapsed this session)
-- and the click-to-read reveal for collapsed lines.
local ADDON, ns = ...

local find = string.find
local sub = string.sub

local FRAME_NAME = "NPCFLogFrame"
local frame, messages

local function SourceLabel(key)
    local src = key and ns.SourceByKey(key)
    return src and src.label or key or "?"
end

local function Line(entry)
    local tag = entry.action == "hide" and "|cffff4040hidden|r" or "|cffffd100collapsed|r"
    local sender = entry.sender ~= "" and entry.sender or "?"
    return ("|cff808080%s|r |cff33ff99[%s]|r %s |cffffffff%s|r: %s"):format(
        entry.time, SourceLabel(entry.source), tag, sender, entry.text)
end

local function Refresh()
    messages:Clear()
    if #ns.log == 0 then
        messages:AddMessage("|cff808080Nothing filtered yet this session.|r")
        return
    end
    for _, entry in ipairs(ns.log) do
        messages:AddMessage(Line(entry))
    end
    messages:ScrollToBottom()
end

local function Build()
    frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
    frame:SetSize(620, 420)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    tinsert(UISpecialFrames, FRAME_NAME)  -- Escape closes it

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("NoPetrovychChatFilter: filtered messages")
    frame.title = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    clear:SetSize(90, 22)
    clear:SetPoint("BOTTOMRIGHT", -18, 18)
    clear:SetText("Clear")
    clear:SetScript("OnClick", function() ns.LogClear() end)

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 20, 22)
    hint:SetText("Mouse wheel scrolls. Drag the title to move.")

    messages = CreateFrame("ScrollingMessageFrame", FRAME_NAME .. "Messages", frame)
    messages:SetPoint("TOPLEFT", 20, -46)
    messages:SetPoint("BOTTOMRIGHT", -20, 48)
    messages:SetFontObject(ChatFontNormal)
    messages:SetJustifyH("LEFT")
    messages:SetFading(false)
    messages:SetMaxLines(600)
    messages:SetIndentedWordWrap(true)
    messages:SetHyperlinksEnabled(true)
    messages:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
    messages:EnableMouseWheel(true)
    messages:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            if IsShiftKeyDown() then self:ScrollToTop() else self:ScrollUp() end
        else
            if IsShiftKeyDown() then self:ScrollToBottom() else self:ScrollDown() end
        end
    end)
    if messages.SetTextCopyable then
        messages:SetTextCopyable(true)
    end

    ns.onLogAdded = function(entry)
        if frame:IsShown() then
            if #ns.log == 1 then
                messages:Clear()
            end
            messages:AddMessage(Line(entry))
        end
    end
    ns.onLogCleared = function()
        if frame:IsShown() then
            Refresh()
        end
    end
end

--- Open (or refresh) the log window.
function ns.OpenLog()
    if not frame then
        Build()
    end
    Refresh()
    frame:Show()
end

function ns.ToggleLog()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        ns.OpenLog()
    end
end

-------------------------------------------------------------------------------------------------
-- Click-to-read. The collapsed line is rewritten IN PLACE in every message frame that holds it:
-- Blizzard's ChatFrame1..N first, then every other ScrollingMessageFrame in the UI (chat addons
-- such as EllesmereUIChat draw their own unnamed windows copied from Blizzard's buffers).
-- Two rewrite paths per frame: the history buffer entries directly (the way EllesmereUIChat
-- rewrites lines on this client), then TransformMessages. Only if no frame held the line any more
-- is the text shown in the item-ref popup, one frame later so the client's own link handling
-- cannot hide it.
-------------------------------------------------------------------------------------------------

local isSecret = _G.issecretvalue
local function IsPlainString(s)
    return type(s) == "string" and not (isSecret and isSecret(s))
end

--- Replace "<token>...|h" in message with text; nil when the token is not there.
local function Splice(message, token, text)
    local s = find(message, token, 1, true)
    if not s then
        return nil
    end
    local e = find(message, "|h", s + #token, true)   -- the link's closing |h
    if not e then
        return nil
    end
    return sub(message, 1, s - 1) .. text .. sub(message, e + 2)
end

--- Visit Blizzard's chat frames first, then every other message frame once.
local function EachMessageFrame(fn)
    local seen = {}
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if cf then
            seen[cf] = true
            fn(cf, "ChatFrame" .. i)
        end
    end
    if not EnumerateFrames then
        return
    end
    local f = EnumerateFrames()
    while f do
        if not seen[f] and not (f.IsForbidden and f:IsForbidden())
            and f.GetObjectType and f:GetObjectType() == "ScrollingMessageFrame" then
            seen[f] = true
            local parent = f.GetParent and f:GetParent()
            fn(f, (f.GetName and f:GetName()) or ("unnamed under " .. tostring(parent and parent.GetName and parent:GetName() or "?")))
        end
        f = EnumerateFrames(f)
    end
end

--- Rewrite the line in one frame. Returns true when something changed.
local function RewriteFrame(f, token, text)
    local hit = false
    -- Path 1: the history buffer entries, plain tables { message = ..., r, g, b, ... }.
    local hb = f.historyBuffer
    if hb and hb.GetNumElements and hb.GetEntryAtIndex then
        local n = hb:GetNumElements()
        for i = 1, n do
            local e = hb:GetEntryAtIndex(i)
            local m = e and e.message
            if IsPlainString(m) then
                local new = Splice(m, token, text)
                if new then
                    e.message = new
                    hit = true
                end
            end
        end
        if hit and f.MarkDisplayDirty then
            f:MarkDisplayDirty()
        end
    end
    -- Path 2: the public API, in case the buffer is not reachable on this frame.
    if not hit and f.TransformMessages then
        local function predicate(message)
            return IsPlainString(message) and find(message, token, 1, true) ~= nil
        end
        local function transform(message, ...)
            hit = true
            return Splice(message, token, text) or message, ...
        end
        pcall(f.TransformMessages, f, predicate, transform)
    end
    return hit
end

local function Reveal(id)
    local entry = ns.LogFind(id)
    if not entry then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NoPetrovychChatFilter|r: that line is no longer in the log (it was cleared).")
        return
    end
    local token = ns.LINK_PREFIX .. id .. "|h"
    local changed = false
    EachMessageFrame(function(f)
        if RewriteFrame(f, token, entry.text) then
            changed = true
        end
    end)
    entry.revealed = true
    if changed then
        return
    end
    local function popup()
        if not ItemRefTooltip then
            return
        end
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
        ItemRefTooltip:ClearLines()
        ItemRefTooltip:AddLine(entry.sender ~= "" and entry.sender or "?", 1, 0.82, 0)
        ItemRefTooltip:AddLine(entry.text, 1, 1, 1, true)
        ItemRefTooltip:Show()
    end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, popup)
    else
        popup()
    end
end
ns.Reveal = Reveal

--- /npcf debug: where is the newest collapsed line, and can it be rewritten there?
function ns.DebugReveal()
    local Print = function(t) DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NPCF debug|r: " .. t) end
    local entry
    for i = #ns.log, 1, -1 do
        if ns.log[i].action == "spoiler" then
            entry = ns.log[i]
            break
        end
    end
    Print(("EnumerateFrames %s, issecretvalue %s, NUM_CHAT_WINDOWS %s"):format(
        tostring(EnumerateFrames ~= nil), tostring(isSecret ~= nil), tostring(NUM_CHAT_WINDOWS)))
    if not entry then
        Print("no collapsed line in the log yet")
        return
    end
    local token = ns.LINK_PREFIX .. entry.id .. "|h"
    Print(("newest collapsed line id %d, revealed=%s, token %s"):format(entry.id, tostring(entry.revealed == true), token:gsub("|", "||")))
    EachMessageFrame(function(f, name)
        local n = f.GetNumMessages and f:GetNumMessages() or -1
        local hb = f.historyBuffer
        local inBuffer, inInfo, secret = 0, 0, 0
        if hb and hb.GetNumElements and hb.GetEntryAtIndex then
            for i = 1, hb:GetNumElements() do
                local e = hb:GetEntryAtIndex(i)
                local m = e and e.message
                if type(m) == "string" then
                    if isSecret and isSecret(m) then
                        secret = secret + 1
                    elseif find(m, token, 1, true) then
                        inBuffer = inBuffer + 1
                    end
                end
            end
        end
        if f.GetMessageInfo and n > 0 then
            for i = 1, n do
                local m = f:GetMessageInfo(i)
                if IsPlainString(m) and find(m, token, 1, true) then
                    inInfo = inInfo + 1
                end
            end
        end
        if n > 0 or inBuffer > 0 then
            Print(("%s: %d lines, buffer=%s, token in buffer %d, via GetMessageInfo %d, secret %d, Transform=%s, Dirty=%s"):format(
                name, n, tostring(hb ~= nil), inBuffer, inInfo, secret,
                tostring(f.TransformMessages ~= nil), tostring(f.MarkDisplayDirty ~= nil)))
        end
    end)
end

-- The click can arrive through several paths depending on the client build and chat addons;
-- listen on all of them and let the first one win for a given line.
local lastId, lastTime = nil, 0
local function OnLink(link)
    local id = ns.SpoilerIdFromLink(link)
    if not id then
        return
    end
    local now = GetTime and GetTime() or 0
    if id == lastId and now - lastTime < 0.5 then
        return
    end
    lastId, lastTime = id, now
    Reveal(id)
end

if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("SetItemRef", function(_, link) OnLink(link) end, ns)
end
if hooksecurefunc then
    if SetItemRef then
        hooksecurefunc("SetItemRef", function(link) OnLink(link) end)
    end
    if ChatFrame_OnHyperlinkShow then
        hooksecurefunc("ChatFrame_OnHyperlinkShow", function(_, link) OnLink(link) end)
    end
end
