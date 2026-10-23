local _, ns = ...
---@cast ns FlagUp.Namespace

---Items dropped on a frame, wherever on it.
---@class FlagUp.ItemDrop
local ItemDrop = {}
ns.ItemDrop = ItemDrop

-- Forever throws on registering an event it doesn't know.
local canWatchCursor = C_EventUtils and C_EventUtils.IsEventValid("CURSOR_CHANGED")

---While the cursor holds an item, a frame over the whole of `frame` takes it, wherever it is dropped, and hands it to
---`onDrop`; the cursor is then emptied.
---@param frame Frame
---@param onDrop fun(itemID: integer, link: string)
function ItemDrop.Accept(frame, onDrop)
    if not canWatchCursor then return end

    local target = CreateFrame("Frame", nil, frame)
    target:SetAllPoints()
    target:SetFrameLevel(frame:GetFrameLevel() + 100)
    target:EnableMouse(true)
    target:Hide()

    local function drop()
        local kind, itemID, link = GetCursorInfo()
        if kind ~= "item" then return end
        ClearCursor()
        onDrop(itemID, link)
    end
    target:SetScript("OnReceiveDrag", drop)
    target:SetScript("OnMouseUp", drop)

    target:RegisterEvent("CURSOR_CHANGED")
    target:SetScript("OnEvent", function() target:SetShown(GetCursorInfo() == "item") end)
end
