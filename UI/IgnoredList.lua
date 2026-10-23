local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The rules window's Ignored tab: the items ignored in the ruleset and faction being played, to take back.
---@class FlagUp.IgnoredList
---@field View Frame the tab's content
local IgnoredList = {}
ns.IgnoredList = IgnoredList

local window = ns.RulesWindow.Window

-- The tab's content takes the place of the toolbar, the tree and the pane.
local VIEW_LEFT, VIEW_TOP, VIEW_BOTTOM = 16, -30, 12
-- The filter starts where the toolbar does, right of the portrait.
local FILTER_LEFT, FILTER_WIDTH = 48, 300
local LIST_TOP = -58
local COLUMN_HEADER_HEIGHT = 24
local SCROLL_BAR_SPACE = 20
local ITEM_COLUMN_WIDTH = 600
local ROW_HEIGHT = 24
local ICON_SIZE = 18
local REMOVE_SIZE = 16
-- The game's ready check cross, as the Stop ignoring button.
local REMOVE_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local CLEAR_SIZE = 16

local view = CreateFrame("Frame", nil, window)
view:SetPoint("TOPLEFT", VIEW_LEFT, VIEW_TOP)
view:SetPoint("BOTTOMRIGHT", -VIEW_LEFT, VIEW_BOTTOM)
view:Hide()
IgnoredList.View = view

-- Filter -----------------------------------------------------------------------------------------

view.Filter = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
view.Filter:SetWidth(FILTER_WIDTH)
view.Filter:SetPoint("TOPLEFT", FILTER_LEFT, 0)

-- While a filter is set: back to every category.
view.ClearFilter = CreateFrame("Button", nil, view)
view.ClearFilter:SetSize(CLEAR_SIZE, CLEAR_SIZE)
view.ClearFilter:SetPoint("LEFT", view.Filter, "RIGHT", 6, 0)
-- The rows' cross, grey: red again under the mouse.
view.ClearFilter:SetNormalTexture(REMOVE_TEXTURE)
view.ClearFilter:GetNormalTexture():SetDesaturated(true)
view.ClearFilter:SetScript("OnEnter", function(button)
    button:GetNormalTexture():SetDesaturated(false)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["All categories"], HIGHLIGHT_FONT_COLOR:GetRGB())
    GameTooltip:Show()
end)
view.ClearFilter:SetScript("OnLeave", function(button)
    button:GetNormalTexture():SetDesaturated(true)
    GameTooltip_Hide()
end)
view.ClearFilter:Hide()

-- List -------------------------------------------------------------------------------------------

local list = CreateFrame("Frame", nil, view)
list:SetPoint("TOPLEFT", 0, LIST_TOP)
list:SetPoint("BOTTOMRIGHT")
view.List = list

list.Inset = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
list.Inset:SetPoint("TOPLEFT", -3, 3)
list.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

list.ColumnDisplay = CreateFrame("Frame", nil, list, "ColumnDisplayTemplate")
list.ColumnDisplay:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 0, 0)
list.ColumnDisplay:SetPoint("BOTTOMRIGHT", list, "TOPRIGHT", 0, 0)
list.ColumnDisplay:SetHeight(COLUMN_HEADER_HEIGHT)
list.ColumnDisplay:LayoutColumns({
    { title = L["Item"], width = ITEM_COLUMN_WIDTH },
    { title = L["Ignored by"], width = 0 },
})

list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
list.ScrollBox:SetPoint("TOPLEFT")
list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 0)

list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
list.ScrollBar:SetPoint("TOPLEFT", list.ScrollBox, "TOPRIGHT", 6, 0)
list.ScrollBar:SetPoint("BOTTOMLEFT", list.ScrollBox, "BOTTOMRIGHT", 6, 0)

list.Empty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
list.Empty:SetPoint("LEFT", 12, 0)
list.Empty:SetPoint("RIGHT", -12, 0)

---An ignored item, ready to show.
---@class FlagUp.IgnoredRow
---@field itemID integer
---@field character string? nil: ignored by every character
---@field name string
---@field color ColorMixin
---@field icon number|string
---@field classID integer
---@field subClassID integer

---An ignored item's row; createRow adds its regions the first time the row is used.
---@class FlagUp.IgnoredRowFrame: Frame
---@field Icon Texture
---@field Name FontString
---@field IgnoredBy FontString
---@field RemoveButton Button
---@field ignored FlagUp.IgnoredRow the item shown

---@param row FlagUp.IgnoredRowFrame
local function createRow(row)
    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT", 10, 0)

    row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 6, 0)
    row.Name:SetPoint("RIGHT", row, "LEFT", ITEM_COLUMN_WIDTH - 8, 0)
    row.Name:SetWordWrap(false)

    row.RemoveButton = CreateFrame("Button", nil, row)
    row.RemoveButton:SetSize(REMOVE_SIZE, REMOVE_SIZE)
    row.RemoveButton:SetPoint("RIGHT", -8, 0)
    row.RemoveButton:SetNormalTexture(REMOVE_TEXTURE)
    row.RemoveButton:SetHighlightTexture(REMOVE_TEXTURE, "ADD")
    row.RemoveButton:SetScript("OnClick", function()
        ns.Ignored.Remove(row.ignored.itemID, row.ignored.character)
        ns.RulesWindow.Refresh()
    end)
    row.RemoveButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Stop ignoring"], HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    row.RemoveButton:SetScript("OnLeave", GameTooltip_Hide)

    -- A cell starts where its column header's text does: 8 into the header.
    row.IgnoredBy = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    row.IgnoredBy:SetPoint("LEFT", ITEM_COLUMN_WIDTH + 8, 0)
    row.IgnoredBy:SetPoint("RIGHT", row.RemoveButton, "LEFT", -8, 0)
    row.IgnoredBy:SetWordWrap(false)
end

---@param row FlagUp.IgnoredRowFrame
---@param ignored FlagUp.IgnoredRow
local function initRow(row, ignored)
    if not row.Name then createRow(row) end
    row.ignored = ignored
    row.Icon:SetTexture(ignored.icon)
    row.Name:SetText(ignored.name)
    row.Name:SetTextColor(ignored.color:GetRGB())
    row.IgnoredBy:SetText(ignored.character or L["All characters"])
end

local listView = CreateScrollBoxListLinearView()
listView:SetElementExtent(ROW_HEIGHT)
listView:SetElementInitializer("Frame", initRow)
ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, listView)

-- Showing the list -------------------------------------------------------------------------------

---@type { classID: integer, subClassID: integer? }? the category or subcategory the list shows; nil: every one
local filter
---@type table<integer, true> the items whose data the client is loading, by item ID
local loadingItems = {}

---The ignored items, ready to show, by name, then every character before each one; while the client loads an item's
---name, its row says so and the list is shown again once loaded.
---@return FlagUp.IgnoredRow[]
local function ignoredRows()
    local rows = {}
    for _, entry in ipairs(ns.Ignored.Entries()) do
        local itemID = entry.itemID
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        local name = C_Item.GetItemNameByID(itemID)
        if not name and not loadingItems[itemID] then
            loadingItems[itemID] = true
            Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                loadingItems[itemID] = nil
                IgnoredList.Refresh()
            end)
        end
        local quality = C_Item.GetItemQualityByID(itemID)
        rows[#rows + 1] = {
            itemID = itemID, character = entry.character, name = name or RETRIEVING_ITEM_INFO,
            color = quality and ColorManager.GetColorDataForItemQuality(quality).color or WHITE_FONT_COLOR,
            icon = C_Item.GetItemIconByID(itemID), classID = classID, subClassID = subClassID,
        }
    end
    table.sort(rows, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        return (a.character or "") < (b.character or "")
    end)
    return rows
end

---@param row FlagUp.IgnoredRow
---@return boolean
local function passesFilter(row)
    if not filter then return true end
    if row.classID ~= filter.classID then return false end
    return filter.subClassID == nil or row.subClassID == filter.subClassID
end

-- The filter: every category, then those holding ignored items, each followed by its subcategories holding some.
view.Filter:SetupMenu(function(_, root)
    -- SetupMenu builds the menu at once, as this file loads: the saved data isn't there yet, nor anything to list.
    if not ns.data then return end

    local function isCurrent(value)
        if value == false then return filter == nil end
        return filter ~= nil and filter.classID == value.classID and filter.subClassID == value.subClassID
    end
    local function choose(value)
        filter = value or nil
        IgnoredList.Refresh()
    end

    root:CreateRadio(L["All categories"], isCurrent, choose, false)
    local held = {}
    for _, row in ipairs(ignoredRows()) do
        if row.classID then
            held[row.classID] = held[row.classID] or {}
            held[row.classID][row.subClassID] = true
        end
    end
    for _, category in ipairs(ns.Categories.All()) do
        local subcategoriesHeld = held[category.classID]
        if subcategoriesHeld then
            root:CreateRadio(category.name, isCurrent, choose, { classID = category.classID })
            for _, subcategory in ipairs(category.subcategories) do
                if subcategoriesHeld[subcategory.subClassID] then
                    root:CreateRadio(category.name .. " › " .. subcategory.name, isCurrent, choose,
                        { classID = category.classID, subClassID = subcategory.subClassID })
                end
            end
        end
    end
end)

---Shows the ignored items again, as the filter leaves them.
function IgnoredList.Refresh()
    local rows = {}
    for _, row in ipairs(ignoredRows()) do
        if passesFilter(row) then rows[#rows + 1] = row end
    end
    list.ScrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
    list.Empty:SetShown(#rows == 0)
    list.Empty:SetText(filter and L["No item of this category is ignored."] or L["No item is ignored."])
    view.ClearFilter:SetShown(filter ~= nil)
    -- The menu is built again: the client may keep the one built when the dropdown was first shown.
    view.Filter:GenerateMenu()
end

---Shows the ignored items of one category or subcategory.
---@param classID integer
---@param subClassID integer? nil: the whole category
function IgnoredList.ShowCategory(classID, subClassID)
    filter = { classID = classID, subClassID = subClassID }
    IgnoredList.Refresh()
end

view.ClearFilter:SetScript("OnClick", function()
    filter = nil
    IgnoredList.Refresh()
end)

view:HookScript("OnShow", IgnoredList.Refresh)

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Dropdown(view.Filter)
    -- The header bar's background, then each column header's art.
    S.FadeRegions(list.ColumnDisplay)
    for _, header in ipairs({ list.ColumnDisplay:GetChildren() }) do
        ---@cast header Button
        S.FadeRegions(header)
        S.White(header:GetFontString())
    end
    S.Inset(list.Inset)
    S.ScrollBar(list.ScrollBar)
end)
