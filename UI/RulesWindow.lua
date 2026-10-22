local addonName, ns = ...
---@cast ns StashPost.Namespace

local L = ns.L

---@class StashPost.RulesWindow
---@field Window Frame the rules window
local RulesWindow = {}
ns.RulesWindow = RulesWindow

---A line of the tree, ready to show.
---@class StashPost.TreeLine
---@field kind "category"|"subcategory"|"quality"|"item" "category" also for the By quality branch
---@field name string
---@field rule string? the rule as shown in the Rule column; nil on a plain heading
---@field customized boolean? at least one character overrides the line
---@field collapsed boolean? on a category or subcategory
---@field icon number|string? on an item
---@field color ColorMixin? the quality colour, on an item or a quality
---@field selected boolean?

local WIDTH, HEIGHT = 1040, 640
local TOOLBAR_LEFT = 64
local TOOLBAR_TOP = -30
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22

local TREE_LEFT, TREE_TOP, TREE_BOTTOM = 16, -88, 12
local TREE_WIDTH = 630
local COLUMN_HEADER_HEIGHT = 24
local HINT_HEIGHT = 24
local SCROLL_BAR_SPACE = 20
-- The column headers leave 28 at their right, over the scroll bar.
local RULE_WIDTH, OVERRIDES_WIDTH = 220, 100
local NAME_WIDTH = TREE_WIDTH - 28 - RULE_WIDTH - OVERRIDES_WIDTH
-- A cell starts where its column header's text does: 8 into the header, the headers overlapping by 2.
local NAME_LEFT, RULE_LEFT, OVERRIDES_LEFT = 10, NAME_WIDTH + 8, NAME_WIDTH + RULE_WIDTH + 6
local CATEGORY_HEIGHT, LINE_HEIGHT = 28, 22
local SUBCATEGORY_INDENT, ITEM_INDENT = 14, 34
local ICON_SIZE = 18
local LINE_HIGHLIGHT_TEXTURE = "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"

-- Window -----------------------------------------------------------------------------------------

-- Named: the game closes the frames listed in UISpecialFrames, by name, on Escape.
local window = CreateFrame("Frame", "StashPostRulesWindow", UIParent, "ButtonFrameTemplate")
window:SetSize(WIDTH, HEIGHT)
window:SetPoint("CENTER")
window:SetTitle(C_AddOns.GetAddOnMetadata(addonName, "Title"))
window:SetPortraitToAsset(C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
window:SetMovable(true)
window:SetClampedToScreen(true)
window:SetFrameStrata("HIGH")
window:SetToplevel(true)
table.insert(UISpecialFrames, "StashPostRulesWindow")
window:Hide()
window.TitleContainer:EnableMouse(true)
window.TitleContainer:RegisterForDrag("LeftButton")
window.TitleContainer:SetScript("OnDragStart", function() window:StartMoving() end)
window.TitleContainer:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
RulesWindow.Window = window

-- The tree and the right pane lay out their own insets.
window.Inset:Hide()

-- Toolbar ----------------------------------------------------------------------------------------

-- A button is as wide as its text needs, at least BUTTON_WIDTH.
window.AddCategoryButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
window.AddCategoryButton:SetText(L["Add category"])
window.AddCategoryButton:SetSize(math.max(BUTTON_WIDTH, window.AddCategoryButton:GetTextWidth() + 24), BUTTON_HEIGHT)
window.AddCategoryButton:SetPoint("TOPRIGHT", -12, TOOLBAR_TOP)

window.AddItemButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
window.AddItemButton:SetText(L["Add item"])
window.AddItemButton:SetSize(math.max(BUTTON_WIDTH, window.AddItemButton:GetTextWidth() + 24), BUTTON_HEIGHT)
window.AddItemButton:SetPoint("RIGHT", window.AddCategoryButton, "LEFT", -8, 0)

window.SearchBox = CreateFrame("EditBox", nil, window, "SearchBoxTemplate")
window.SearchBox:SetHeight(20)
window.SearchBox:SetPoint("TOPLEFT", TOOLBAR_LEFT, TOOLBAR_TOP - 1)
window.SearchBox:SetPoint("RIGHT", window.AddItemButton, "LEFT", -12, 0)

-- Tree -------------------------------------------------------------------------------------------

-- The frame the rows fill; the column headers sit above it, the inset's border around it.
local tree = CreateFrame("Frame", nil, window)
tree:SetPoint("TOPLEFT", TREE_LEFT, TREE_TOP)
tree:SetPoint("BOTTOMLEFT", TREE_LEFT, TREE_BOTTOM)
tree:SetWidth(TREE_WIDTH)
window.Tree = tree

tree.Inset = CreateFrame("Frame", nil, tree, "InsetFrameTemplate")
tree.Inset:SetPoint("TOPLEFT", -3, 3)
tree.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

tree.ColumnDisplay = CreateFrame("Frame", nil, tree, "ColumnDisplayTemplate")
tree.ColumnDisplay:SetPoint("BOTTOMLEFT", tree, "TOPLEFT", 0, 0)
tree.ColumnDisplay:SetPoint("BOTTOMRIGHT", tree, "TOPRIGHT", 0, 0)
tree.ColumnDisplay:SetHeight(COLUMN_HEADER_HEIGHT)
tree.ColumnDisplay:LayoutColumns({
    { title = L["Category or item"], width = NAME_WIDTH },
    { title = L["Rule"], width = RULE_WIDTH },
    { title = L["Overrides"], width = 0 },
})

tree.ScrollBox = CreateFrame("Frame", nil, tree, "WowScrollBoxList")
tree.ScrollBox:SetPoint("TOPLEFT")
tree.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, HINT_HEIGHT)

tree.ScrollBar = CreateFrame("EventFrame", nil, tree, "MinimalScrollBar")
tree.ScrollBar:SetPoint("TOPLEFT", tree.ScrollBox, "TOPRIGHT", 6, 0)
tree.ScrollBar:SetPoint("BOTTOMLEFT", tree.ScrollBox, "BOTTOMRIGHT", 6, 0)

tree.Hint = tree:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
tree.Hint:SetPoint("BOTTOMLEFT", 8, 8)
tree.Hint:SetPoint("BOTTOMRIGHT", -8, 8)
tree.Hint:SetJustifyH("LEFT")
tree.Hint:SetText(L["Drop an item anywhere on this window to add it under its category."])

---A tree row; createRow adds its regions the first time the row is used.
---@class StashPost.TreeRow: Button
---@field CategoryBackground Texture
---@field CategoryHighlight Texture
---@field LineHighlight Texture
---@field Selected Texture
---@field StateIcon Texture
---@field ToggleIcon Texture
---@field Icon Texture
---@field Name FontString
---@field Rule FontString
---@field Overrides FontString

---@param row StashPost.TreeRow
local function createRow(row)
    -- A category is a header bar, as the game's reputation list draws its headers.
    row.CategoryBackground = row:CreateTexture(nil, "BACKGROUND")
    row.CategoryBackground:SetAtlas("common-button-list-collapseExpand")
    row.CategoryBackground:SetAllPoints()

    row.CategoryHighlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.CategoryHighlight:SetAtlas("common-button-list-collapseExpand")
    row.CategoryHighlight:SetBlendMode("ADD")
    row.CategoryHighlight:SetAlpha(0.3)
    row.CategoryHighlight:SetAllPoints()

    row.LineHighlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.LineHighlight:SetTexture(LINE_HIGHLIGHT_TEXTURE)
    row.LineHighlight:SetBlendMode("ADD")
    row.LineHighlight:SetAllPoints()

    row.Selected = row:CreateTexture(nil, "BACKGROUND", nil, 1)
    row.Selected:SetTexture(LINE_HIGHLIGHT_TEXTURE)
    row.Selected:SetBlendMode("ADD")
    row.Selected:SetAllPoints()

    row.StateIcon = row:CreateTexture(nil, "BORDER")
    row.StateIcon:SetPoint("RIGHT", -8, -1)

    -- A subcategory's open or closed mark, as the game's reputation list draws its subheaders.
    row.ToggleIcon = row:CreateTexture(nil, "ARTWORK")
    row.ToggleIcon:SetPoint("LEFT", SUBCATEGORY_INDENT, 0)

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT", ITEM_INDENT, 0)

    row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    row.Name:SetPoint("RIGHT", row, "LEFT", RULE_LEFT - 8, 0)
    row.Name:SetWordWrap(false)

    row.Rule = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    row.Rule:SetPoint("LEFT", RULE_LEFT, 0)
    row.Rule:SetPoint("RIGHT", row, "LEFT", OVERRIDES_LEFT - 8, 0)
    row.Rule:SetWordWrap(false)

    row.Overrides = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallLeft")
    row.Overrides:SetPoint("LEFT", OVERRIDES_LEFT, 0)
    row.Overrides:SetTextColor(LIGHTBLUE_FONT_COLOR:GetRGB())
    row.Overrides:SetText(L["Customized"])
end

---@param row StashPost.TreeRow
---@param line StashPost.TreeLine
local function initRow(row, line)
    if not row.Name then createRow(row) end

    local isCategory = line.kind == "category"
    row.CategoryBackground:SetShown(isCategory)
    row.CategoryHighlight:SetShown(isCategory)
    row.LineHighlight:SetShown(not isCategory)
    row.Selected:SetShown(line.selected == true)

    row.StateIcon:SetShown(isCategory)
    if isCategory then
        row.StateIcon:SetAtlas(line.collapsed and "common-button-list-plus" or "common-button-list-minus", true)
    end
    row.ToggleIcon:SetShown(line.kind == "subcategory")
    if line.kind == "subcategory" then
        row.ToggleIcon:SetAtlas(line.collapsed and "campaign_headericon_closed" or "campaign_headericon_open", true)
    end
    row.Icon:SetShown(line.kind == "item")
    if line.kind == "item" then row.Icon:SetTexture(line.icon) end

    -- The name follows its mark: none on a category, the open or closed mark, the item's icon.
    local nameLeft = NAME_LEFT
    if line.kind == "subcategory" then
        nameLeft = SUBCATEGORY_INDENT + row.ToggleIcon:GetWidth() + 4
    elseif line.kind == "quality" then
        nameLeft = ITEM_INDENT
    elseif line.kind == "item" then
        nameLeft = ITEM_INDENT + ICON_SIZE + 6
    end
    row.Name:SetPoint("LEFT", nameLeft, 0)
    row.Name:SetText(line.name)
    if line.color then
        row.Name:SetTextColor(line.color:GetRGB())
    else
        row.Name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end

    row.Rule:SetText(line.rule or "")
    row.Overrides:SetShown(line.customized == true)
end

---@param line StashPost.TreeLine
---@return number
local function rowHeight(_, line)
    return line.kind == "category" and CATEGORY_HEIGHT or LINE_HEIGHT
end

local treeView = CreateScrollBoxListLinearView()
treeView:SetElementInitializer("Button", initRow)
treeView:SetElementExtentCalculator(rowHeight)
ScrollUtil.InitScrollBoxListWithScrollBar(tree.ScrollBox, tree.ScrollBar, treeView)

---Shows these lines in the tree, in this order.
---@param lines StashPost.TreeLine[]
function window:ShowLines(lines)
    tree.ScrollBox:SetDataProvider(CreateDataProvider(lines), ScrollBoxConstants.RetainScrollPosition)
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(window)
    S.CloseButton(window.CloseButton)
    S.EditBox(window.SearchBox)
    S.Button(window.AddItemButton)
    S.Button(window.AddCategoryButton)
    -- The header bar's background, then each column header's art.
    S.FadeRegions(tree.ColumnDisplay)
    for _, header in ipairs({ tree.ColumnDisplay:GetChildren() }) do
        ---@cast header Button
        S.FadeRegions(header)
        S.White(header:GetFontString())
    end
    S.Inset(tree.Inset)
    S.ScrollBar(tree.ScrollBar)
end)
