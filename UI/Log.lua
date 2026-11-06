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

-- Click-to-read: swap the collapsed link for the original text in place, in every message
-- frame that still holds the line. That is every ScrollingMessageFrame in the UI, not only
-- ChatFrame1-10: chat addons (EllesmereUIChat, Prat...) draw their own unnamed windows copied
-- from Blizzard's buffers. If no frame holds the line any more, show it in the item-ref popup,
-- one frame later so the client's own link handling cannot hide it again.
local function EachMessageFrame(fn)
    local frame = EnumerateFrames()
    while frame do
        if not (frame.IsForbidden and frame:IsForbidden())
            and frame.TransformMessages and frame.GetObjectType
            and frame:GetObjectType() == "ScrollingMessageFrame" then
            fn(frame)
        end
        frame = EnumerateFrames(frame)
    end
end

local function Reveal(id)
    local entry = ns.LogFind(id)
    if not entry then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99NoPetrovychChatFilter|r: that line is no longer in the log (it was cleared).")
        return
    end
    local token = ns.LINK_PREFIX .. id .. "|h"
    local isSecret = _G.issecretvalue
    local function predicate(message)
        return type(message) == "string" and not (isSecret and isSecret(message))
            and find(message, token, 1, true) ~= nil
    end
    local changed = false
    local function transform(message, ...)
        local s = find(message, token, 1, true)
        local e = find(message, "|h", s + #token, true)   -- the link's closing |h
        changed = true
        return sub(message, 1, s - 1) .. entry.text .. sub(message, e + 2), ...
    end
    EachMessageFrame(function(frame)
        pcall(frame.TransformMessages, frame, predicate, transform)
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
