local addonName, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---@class FlagUp.RulesWindow
---@field Window Frame the rules window
local RulesWindow = {}
ns.RulesWindow = RulesWindow

local WIDTH, HEIGHT = 1040, 640
local TOOLBAR_LEFT = 64
local TOOLBAR_TOP = -30
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22

local TREE_LEFT, TREE_TOP, TREE_BOTTOM = 16, -88, 12
local TREE_WIDTH = 630
local COLUMN_HEADER_HEIGHT = 24
local HINT_HEIGHT = 24
local SCROLL_BAR_SPACE = 20
-- The Rule column takes the width left of the name's, up to 28 from the right, over the scroll bar.
local NAME_WIDTH = 340
-- A cell starts where its column header's text does: 8 into the header.
local RULE_LEFT = NAME_WIDTH + 8

local PANE_GAP = 16
local PANE_PADDING = 12
-- The line's icon, left of its name and path: as tall as both. A category or subcategory shows a crate.
local PANE_ICON_SIZE = 30
local CATEGORY_ICON = "Interface\\Icons\\INV_Crate_01"
-- The pane leaves as much room on the window's right as the tree on its left.
local PANE_WIDTH = WIDTH - TREE_LEFT - TREE_WIDTH - PANE_GAP - TREE_LEFT
local FIELD_SPACING = 12
-- Between the shared rule's Remove rule and the overrides' divider.
local SECTION_SPACING = 20
-- A field's controls start right of its checkbox and label.
local FIELD_CONTROLS_LEFT = 120
local CHECKBOX_SIZE = 26
local INHERITED_ALPHA = 0.5
local RULE_DROPDOWN_WIDTH = 200
local QUALITY_COLUMNS, QUALITY_COLUMN_WIDTH = 2, 105
local KEEP_INPUT_WIDTH = 50
local TAGS_WIDTH = PANE_WIDTH - 2 * PANE_PADDING
local TAG_GAP = 6
local ADD_TAG_WIDTH = 28
local SKINNED_CHECKBOX_SIZE = 16
local SKINNED_CHECKBOX_LABEL_GAP = 6

-- Window -----------------------------------------------------------------------------------------

-- Named: the game closes the frames listed in UISpecialFrames, by name, on Escape.
local window = CreateFrame("Frame", "FlagUpRulesWindow", UIParent, "ButtonFrameTemplate")
window:SetSize(WIDTH, HEIGHT)
window:SetPoint("CENTER")
window:SetTitle(C_AddOns.GetAddOnMetadata(addonName, "Title"))
window:SetPortraitToAsset(C_AddOns.GetAddOnMetadata(addonName, "IconTexture"))
window:SetMovable(true)
window:SetClampedToScreen(true)
-- On the game windows' layer: whichever was clicked last comes in front.
window:SetFrameStrata("MEDIUM")
window:SetToplevel(true)
table.insert(UISpecialFrames, "FlagUpRulesWindow")
window:Hide()
window.TitleContainer:EnableMouse(true)
window.TitleContainer:RegisterForDrag("LeftButton")
window.TitleContainer:SetScript("OnDragStart", function() window:StartMoving() end)
window.TitleContainer:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
RulesWindow.Window = window

---Shows the rules window, or hides it when it is shown.
function RulesWindow.Toggle()
    window:SetShown(not window:IsShown())
end

-- The tree and the right pane lay out their own insets.
window.Inset:Hide()

-- Toolbar ----------------------------------------------------------------------------------------

-- A button is as wide as its text needs, at least BUTTON_WIDTH.
window.AddCategoryButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
window.AddCategoryButton:SetText(L["Add category"])
window.AddCategoryButton:SetSize(math.max(BUTTON_WIDTH, window.AddCategoryButton:GetTextWidth() + 24), BUTTON_HEIGHT)
window.AddCategoryButton:SetPoint("TOPRIGHT", -12, TOOLBAR_TOP)
window.AddCategoryButton:SetScript("OnClick", function() ns.AddCategoryDialog.Open() end)

window.AddItemButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
window.AddItemButton:SetText(L["Add item"])
window.AddItemButton:SetSize(math.max(BUTTON_WIDTH, window.AddItemButton:GetTextWidth() + 24), BUTTON_HEIGHT)
window.AddItemButton:SetPoint("RIGHT", window.AddCategoryButton, "LEFT", -8, 0)
window.AddItemButton:SetScript("OnClick", function() ns.AddItemDialog.Open() end)

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
    { title = L["Rule"], width = 0 },
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

local treeView = CreateScrollBoxListLinearView()
treeView:SetElementInitializer("Button", function(row, line) ns.TreeRow.Init(row, line, RULE_LEFT) end)
treeView:SetElementExtentCalculator(ns.TreeRow.Height)
ScrollUtil.InitScrollBoxListWithScrollBar(tree.ScrollBox, tree.ScrollBar, treeView)

---Shows these lines in the tree, in this order.
---@param lines FlagUp.TreeLine[]
function window:ShowLines(lines)
    tree.ScrollBox:SetDataProvider(CreateDataProvider(lines), ScrollBoxConstants.RetainScrollPosition)
end

-- The tree from the rules -------------------------------------------------------------------------

-- A line's ID: "c:<class ID>" for a category, "s:<class ID>:<subclass ID>" for a subcategory, "i:<item ID>" for an item.

---@param classID integer
---@param subClassID integer? nil: the category itself
---@return string
local function categoryLineID(classID, subClassID)
    if subClassID == nil then return "c:" .. classID end
    return ("s:%d:%d"):format(classID, subClassID)
end

---@param itemID integer
---@return string
local function itemLineID(itemID)
    return "i:" .. itemID
end

---A line shown in the tree, a rule line or a plain heading, as the pane needs it.
---@class FlagUp.ShownLine
---@field place FlagUp.LinePlace
---@field name string
---@field path string the categories above it and its name (Trade Goods › Herb › Peacebloom)
---@field color ColorMixin? on an item

---@type table<string, true> the lines closed this session, by ID
local closed = {}
---@type string? the selected line's ID
local selectedID
---@type string? the character whose override the pane shows; nil: the one being played
local shownCharacter
---@type table<string, FlagUp.ShownLine> the lines of the tree last shown, by ID
local shownLines = {}
---@type table<integer, true> the items whose data the client is loading, by item ID
local loadingItems = {}

local PATH_SEPARATOR = " › "

---@param sendTo string|false
---@return string
local function ruleText(sendTo)
    return sendTo and L["Send to %s"]:format(sendTo) or L["Don't send"]
end

---What a character does with a line, as the Rule column shows it: the recipient, then whether only full stacks go,
---then how many are kept.
---@param place FlagUp.LinePlace
---@param character string
---@return string
local function treeRuleText(place, character)
    local sendTo = ns.Rules.Value(place, "sendTo", character)
    if not sendTo then return L["Don't send"] end
    local text = sendTo
    if ns.Rules.Value(place, "fullStacksOnly", character) then text = L["%s, full stacks"]:format(text) end
    if ns.Rules.HasField(place, "keep") then
        local keep = ns.Rules.Value(place, "keep", character)
        if keep > 0 then text = L["%s, keep %d"]:format(text, keep) end
    end
    return text
end

---A tree line, selected with a click. A rule line shows what the character being played does with it; a plain
---heading, above lines without being one, shows no rule.
---@param kind "category"|"subcategory"|"item"
---@param id string
---@param holdsLines boolean it has lines under it: it opens and closes
---@param shown FlagUp.ShownLine
---@return FlagUp.TreeLine
local function treeLine(kind, id, holdsLines, shown)
    shownLines[id] = shown
    local line = { kind = kind, id = id, name = shown.name, selected = id == selectedID }
    if holdsLines then line.collapsed = closed[id] == true end
    line.onToggle = function()
        closed[id] = not closed[id] or nil
        RulesWindow.Refresh()
    end
    line.onClick = function()
        if selectedID ~= id then shownCharacter = nil end
        selectedID = id
        RulesWindow.Refresh()
    end

    local rule = ns.Rules.LineAt(shown.place)
    local player = ns.Characters.PlayerName()
    local itemID = shown.place.itemID
    if rule and itemID and ns.Ignored.IsIgnored(itemID, player) then
        -- Never offered to the character being played: no rule to show.
        line.rule = L["Ignored"]
        line.inherited = true
    elseif rule then
        local override = rule.overrides and rule.overrides[player]
        line.rule = treeRuleText(shown.place, player)
        line.overridden = override ~= nil and ns.Rules.SetsAField(override)
        line.inherited = not ns.Rules.SetsAField(rule) and not line.overridden
    end
    return line
end

---An item's line; while the client loads the item's name, the line says so and the tree is shown again once loaded.
---@param itemID integer
---@param classID integer
---@param subClassID integer
---@return FlagUp.TreeLine
local function itemTreeLine(itemID, classID, subClassID)
    local name = C_Item.GetItemNameByID(itemID)
    if not name and not loadingItems[itemID] then
        loadingItems[itemID] = true
        Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
            loadingItems[itemID] = nil
            RulesWindow.Refresh()
        end)
    end
    name = name or RETRIEVING_ITEM_INFO
    local quality = C_Item.GetItemQualityByID(itemID)
    local color = quality and ColorManager.GetColorDataForItemQuality(quality).color or WHITE_FONT_COLOR
    local path = table.concat({ ns.Categories.Name(classID), ns.Categories.Name(classID, subClassID), name },
        PATH_SEPARATOR)
    local line = treeLine("item", itemLineID(itemID), false, {
        place = { classID = classID, subClassID = subClassID, itemID = itemID }, name = name, path = path, color = color,
    })
    line.icon = C_Item.GetItemIconByID(itemID)
    line.color = color
    return line
end

---The rules' lines as the tree shows them: each category with a line of its own, of a subcategory or of an item,
---then its subcategories and their items, in the game's order; items by name.
---@return FlagUp.TreeLine[]
local function rulesTreeLines()
    local rules = ns.Rules.Lines()
    shownLines = {}

    -- The items' lines by class, then subclass.
    ---@type table<integer, table<integer, FlagUp.TreeLine[]>>
    local itemLines = {}
    for itemID in pairs(rules.items) do
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        if classID then
            itemLines[classID] = itemLines[classID] or {}
            itemLines[classID][subClassID] = itemLines[classID][subClassID] or {}
            table.insert(itemLines[classID][subClassID], itemTreeLine(itemID, classID, subClassID))
        end
    end

    -- The ignored items, and the categories and subcategories holding them, by class, then subclass.
    ---@type table<integer, true>
    local ignoredItems = {}
    ---@type table<integer, table<integer, true>>
    local ignoredIn = {}
    for _, entry in ipairs(ns.Ignored.Entries()) do
        ignoredItems[entry.itemID] = true
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(entry.itemID)
        if classID then
            ignoredIn[classID] = ignoredIn[classID] or {}
            ignoredIn[classID][subClassID] = true
        end
    end

    ---The ignore glyph on a heading holding ignored items: a click shows them, on the Ignored tab.
    ---@param line FlagUp.TreeLine
    ---@param classID integer
    ---@param subClassID integer?
    local function markIgnored(line, classID, subClassID)
        local held = ignoredIn[classID]
        if not held or (subClassID ~= nil and not held[subClassID]) then return end
        line.onIgnored = function() RulesWindow.ShowIgnored(classID, subClassID) end
    end

    local lines = {}
    for _, category in ipairs(ns.Categories.All()) do
        local classID = category.classID
        local subcategoryRules = rules.subcategories[classID] or {}
        local classItemLines = itemLines[classID] or {}

        ---@type FlagUp.Subcategory[]
        local shownSubcategories = {}
        for _, subcategory in ipairs(category.subcategories) do
            if subcategoryRules[subcategory.subClassID] or classItemLines[subcategory.subClassID] then
                shownSubcategories[#shownSubcategories + 1] = subcategory
            end
        end

        if rules.categories[classID] or #shownSubcategories > 0 then
            local id = categoryLineID(classID)
            local categoryLine = treeLine("category", id, #shownSubcategories > 0,
                { place = { classID = classID }, name = category.name, path = category.name })
            markIgnored(categoryLine, classID, nil)
            lines[#lines + 1] = categoryLine
            if not closed[id] then
                for _, subcategory in ipairs(shownSubcategories) do
                    local subID = categoryLineID(classID, subcategory.subClassID)
                    local subItemLines = classItemLines[subcategory.subClassID]
                    local subcategoryLine = treeLine("subcategory", subID, subItemLines ~= nil, {
                        place = { classID = classID, subClassID = subcategory.subClassID }, name = subcategory.name,
                        path = category.name .. PATH_SEPARATOR .. subcategory.name,
                    })
                    markIgnored(subcategoryLine, classID, subcategory.subClassID)
                    lines[#lines + 1] = subcategoryLine
                    if subItemLines and not closed[subID] then
                        table.sort(subItemLines, function(a, b) return a.name < b.name end)
                        for _, itemLine in ipairs(subItemLines) do
                            -- An ignored item's glyph opens the Ignored tab on its subcategory.
                            if ignoredItems[shownLines[itemLine.id].place.itemID] then
                                markIgnored(itemLine, classID, subcategory.subClassID)
                            end
                            lines[#lines + 1] = itemLine
                        end
                    end
                end
            end
        end
    end
    return lines
end

---The fields of a line, or of a character's override of it, as the pane shows them: each set or not, with the value
---it takes.
---@param place FlagUp.LinePlace
---@param fields FlagUp.Line|table the line, or the character's override of it
---@param character string? nil: the shared rule
---@return table detail rule, qualities, keep and stacks, as FlagUp.RuleDetail and FlagUp.OverridesDetail hold them
local function fieldsDetail(place, fields, character)
    local Rules = ns.Rules
    local detail = {
        rule = { set = fields.sendTo ~= nil, text = ruleText(Rules.Value(place, "sendTo", character)) },
        stacks = { set = fields.fullStacksOnly ~= nil, fullStacksOnly = Rules.Value(place, "fullStacksOnly", character) },
    }
    if Rules.HasField(place, "qualities") then
        detail.qualities = { set = fields.qualities ~= nil, selected = Rules.Value(place, "qualities", character) }
    end
    if Rules.HasField(place, "keep") then
        detail.keep = { set = fields.keep ~= nil, count = Rules.Value(place, "keep", character) }
    end
    return detail
end

---The selected line as the pane shows it: its shared rule, then the override of the character shown. A plain heading
---sets nothing: every field shows what it inherits.
---@param shown FlagUp.ShownLine
---@return FlagUp.RuleDetail
local function ruleDetail(shown)
    local line = ns.Rules.LineAt(shown.place)
    local rule = line or {}
    local overrides = rule.overrides or {}
    local player = ns.Characters.PlayerName()
    shownCharacter = shownCharacter or player

    -- The tags: the character being played, then those that override the line or ignore the item, and the one picked
    -- from +, by name.
    local itemID = shown.place.itemID
    local characters = {}
    for name in pairs(overrides) do
        if name ~= player then characters[#characters + 1] = name end
    end
    for _, name in ipairs(itemID and ns.Ignored.CharactersIgnoring(itemID) or {}) do
        if name ~= player and not tContains(characters, name) then characters[#characters + 1] = name end
    end
    if not tContains(characters, shownCharacter) and shownCharacter ~= player then
        characters[#characters + 1] = shownCharacter
    end
    table.sort(characters)
    table.insert(characters, 1, player)

    local addable = {}
    for _, name in ipairs(ns.Characters.KnownNames()) do
        if not tContains(characters, name) then addable[#addable + 1] = name end
    end

    local detail = fieldsDetail(shown.place, rule, nil) --[[@as FlagUp.RuleDetail]]
    detail.name, detail.path, detail.color = shown.name, shown.path, shown.color
    detail.itemID = shown.place.itemID
    detail.isLine = line ~= nil
    detail.ignoredByAll = itemID ~= nil and ns.Ignored.IsIgnoredByAll(itemID)
    local overridesDetail = fieldsDetail(shown.place, overrides[shownCharacter] or {}, shownCharacter)
    overridesDetail.ignored = itemID ~= nil and ns.Ignored.IsIgnoredBy(itemID, shownCharacter)
    overridesDetail.characters = characters
    overridesDetail.selected = shownCharacter
    overridesDetail.addable = addable
    overridesDetail.onSelectCharacter = function(name)
        shownCharacter = name
        RulesWindow.Refresh()
    end
    detail.overrides = overridesDetail
    return detail
end

---Shows the rules in the tree again, the selected line in the pane and the ignored items; the mailbox panel, open,
---follows the rules.
function RulesWindow.Refresh()
    window:ShowLines(rulesTreeLines())
    local shown = selectedID and shownLines[selectedID]
    window:ShowRule(shown and ruleDetail(shown) or nil)
    ns.IgnoredList.Refresh()
    ns.MailPanel.Refresh()
end

---Selects a line, opening the lines above it, and scrolls the tree to it.
---@param id string
---@param above string[] the IDs of the lines above it
local function selectLine(id, above)
    if selectedID ~= id then shownCharacter = nil end
    selectedID = id
    for _, aboveID in ipairs(above) do closed[aboveID] = nil end
    RulesWindow.Refresh()
    tree.ScrollBox:ScrollToElementDataByPredicate(function(line) return line.id == id end)
end

---Selects a category or subcategory line, shown open.
---@param classID integer
---@param subClassID integer? nil: the category itself
function RulesWindow.SelectCategory(classID, subClassID)
    selectLine(categoryLineID(classID, subClassID), { categoryLineID(classID) })
end

---Selects an item's line, its category and subcategory shown open.
---@param itemID integer
function RulesWindow.SelectItem(itemID)
    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    selectLine(itemLineID(itemID), { categoryLineID(classID), categoryLineID(classID, subClassID) })
end

window:HookScript("OnShow", RulesWindow.Refresh)

-- Dropping an item -------------------------------------------------------------------------------

-- An item dropped on the window is added; one already in the rules keeps its line and is only selected.
ns.ItemDrop.Accept(window, function(itemID)
    ns.Rules.AddItem(itemID)
    RulesWindow.SelectItem(itemID)
end)

-- Right pane -------------------------------------------------------------------------------------

-- The pane starts at the top of the column headers and fills the window's right side.
local pane = CreateFrame("Frame", nil, window)
pane:SetPoint("TOPLEFT", tree.ColumnDisplay, "TOPRIGHT", PANE_GAP, 0)
pane:SetPoint("BOTTOMRIGHT", -TREE_LEFT, TREE_BOTTOM)
window.Pane = pane

pane.Inset = CreateFrame("Frame", nil, pane, "InsetFrameTemplate")
pane.Inset:SetPoint("TOPLEFT", -3, 3)
pane.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

-- With no line selected, the pane shows only this text.
pane.NoLine = pane:CreateFontString(nil, "OVERLAY", "GameFontDisable")
pane.NoLine:SetPoint("LEFT", PANE_PADDING, 0)
pane.NoLine:SetPoint("RIGHT", -PANE_PADDING, 0)
pane.NoLine:SetText(L["Select a line in the tree."])

-- The selected line: its shared rule, then its character overrides.
local content = CreateFrame("Frame", nil, pane)
content:SetAllPoints()
content:Hide()
pane.Content = content

-- The header: an item's icon, the name and the path; the fields hang under it, from the pane's left edge.
pane.Header = CreateFrame("Frame", nil, content)
pane.Header:SetPoint("TOPLEFT", PANE_PADDING, -PANE_PADDING)
pane.Header:SetPoint("RIGHT", -PANE_PADDING, 0)

-- An item's icon, with its tooltip.
pane.Icon = content:CreateTexture(nil, "ARTWORK")
pane.Icon:SetSize(PANE_ICON_SIZE, PANE_ICON_SIZE)
pane.Icon:SetPoint("TOPLEFT", PANE_PADDING, -PANE_PADDING)

pane.IconHover = CreateFrame("Frame", nil, content)
pane.IconHover:SetAllPoints(pane.Icon)
pane.IconHover:SetScript("OnEnter", function(hover)
    if not pane.itemID then return end
    GameTooltip:SetOwner(hover, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(pane.itemID)
    GameTooltip:Show()
end)
pane.IconHover:SetScript("OnLeave", GameTooltip_Hide)

pane.Name = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pane.Name:SetPoint("TOPLEFT", pane.Icon, "TOPRIGHT", 8, 0)
pane.Name:SetPoint("RIGHT", -PANE_PADDING, 0)
pane.Name:SetJustifyH("LEFT")
pane.Name:SetWordWrap(false)

pane.Path = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
pane.Path:SetPoint("TOPLEFT", pane.Name, "BOTTOMLEFT", 0, -4)
pane.Path:SetPoint("RIGHT", -PANE_PADDING, 0)
pane.Path:SetJustifyH("LEFT")
pane.Path:SetWordWrap(false)

---A checkbox with UICheckButtonTemplate's label.
---@class FlagUp.LabeledCheckbox: CheckButton
---@field Text FontString

---A field of the line: its checkbox and label on the left, its controls on the right.
---@class FlagUp.Field: Frame
---@field Checkbox FlagUp.LabeledCheckbox checked: the line, or the character in an override, sets the field; unchecked: it takes it from above

---@param label string
---@param height number the height of its controls
---@return FlagUp.Field
local function createField(label, height)
    local field = CreateFrame("Frame", nil, content) --[[@as FlagUp.Field]]
    field:SetHeight(height)

    field.Checkbox = CreateFrame("CheckButton", nil, field, "UICheckButtonTemplate") --[[@as FlagUp.LabeledCheckbox]]
    field.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    -- Centred on the first row of controls, whatever size the skin gives the checkbox.
    field.Checkbox:SetPoint("LEFT", field, "TOPLEFT", -4, -CHECKBOX_SIZE / 2)
    field.Checkbox.Text:SetFontObject(GameFontNormal)
    field.Checkbox.Text:SetText(label)
    return field
end

---A dropdown with WowStyle1DropdownTemplate's text.
---@class FlagUp.Dropdown: DropdownButton
---@field OverrideText fun(self: FlagUp.Dropdown, text: string)
---@field SetupMenu fun(self: FlagUp.Dropdown, generator: fun(owner: FlagUp.Dropdown, rootDescription: table))
---@field GenerateMenu fun(self: FlagUp.Dropdown)

---The fields a line can have, with their controls.
---@class FlagUp.FieldSet
---@field RuleField FlagUp.Field
---@field RuleDropdown FlagUp.Dropdown
---@field QualitiesField FlagUp.Field on an equipment category or subcategory
---@field QualityCheckboxes table<integer, FlagUp.LabeledCheckbox> by item quality (Enum.ItemQuality)
---@field KeepField FlagUp.Field on an item
---@field KeepInput EditBox
---@field StacksField FlagUp.Field
---@field StacksDropdown FlagUp.Dropdown

local qualityRows = math.ceil((Enum.ItemQuality.Legendary + 1) / QUALITY_COLUMNS)

---@return FlagUp.FieldSet
local function createFieldSet()
    local set = {}

    set.RuleField = createField(L["Rule"], CHECKBOX_SIZE)
    set.RuleDropdown = CreateFrame("DropdownButton", nil, set.RuleField, "WowStyle1DropdownTemplate") --[[@as FlagUp.Dropdown]]
    set.RuleDropdown:SetWidth(RULE_DROPDOWN_WIDTH)
    set.RuleDropdown:SetPoint("LEFT", set.RuleField, "TOPLEFT", FIELD_CONTROLS_LEFT, -CHECKBOX_SIZE / 2)

    -- Qualities: one checkbox per quality, two to a row.
    set.QualitiesField = createField(L["Qualities"], qualityRows * CHECKBOX_SIZE)
    set.QualityCheckboxes = {}
    for quality = Enum.ItemQuality.Poor, Enum.ItemQuality.Legendary do
        local checkbox = CreateFrame("CheckButton", nil, set.QualitiesField, "UICheckButtonTemplate") --[[@as FlagUp.LabeledCheckbox]]
        checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
        local column = quality % QUALITY_COLUMNS
        local row = math.floor(quality / QUALITY_COLUMNS)
        checkbox:SetPoint("LEFT", set.QualitiesField, "TOPLEFT", FIELD_CONTROLS_LEFT - 4 + column * QUALITY_COLUMN_WIDTH,
            -(row + 0.5) * CHECKBOX_SIZE)
        checkbox.Text:SetText(_G["ITEM_QUALITY" .. quality .. "_DESC"])
        checkbox.Text:SetTextColor(ColorManager.GetColorDataForItemQuality(quality).color:GetRGB())
        set.QualityCheckboxes[quality] = checkbox
    end

    -- Keep in bags.
    set.KeepField = createField(L["Keep"], CHECKBOX_SIZE)
    set.KeepInput = CreateFrame("EditBox", nil, set.KeepField, "InputBoxTemplate")
    set.KeepInput:SetSize(KEEP_INPUT_WIDTH, 20)
    set.KeepInput:SetPoint("LEFT", set.KeepField, "TOPLEFT", FIELD_CONTROLS_LEFT + 6, -CHECKBOX_SIZE / 2)
    set.KeepInput:SetNumeric(true)
    set.KeepInput:SetAutoFocus(false)
    set.KeepInput:SetJustifyH("CENTER")

    -- Full stacks only, or any amount.
    set.StacksField = createField(L["Stacks"], CHECKBOX_SIZE)
    set.StacksDropdown = CreateFrame("DropdownButton", nil, set.StacksField, "WowStyle1DropdownTemplate") --[[@as FlagUp.Dropdown]]
    set.StacksDropdown:SetWidth(RULE_DROPDOWN_WIDTH)
    set.StacksDropdown:SetPoint("LEFT", set.StacksField, "TOPLEFT", FIELD_CONTROLS_LEFT, -CHECKBOX_SIZE / 2)

    return set
end

-- The shared rule.
pane.Shared = createFieldSet()

pane.RemoveRuleButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
pane.RemoveRuleButton:SetText(L["Remove rule"])
pane.RemoveRuleButton:SetSize(math.max(BUTTON_WIDTH, pane.RemoveRuleButton:GetTextWidth() + 24), BUTTON_HEIGHT)

-- The character overrides, under the shared rule.
pane.Divider = content:CreateTexture(nil, "ARTWORK")
pane.Divider:SetAtlas("Options_HorizontalDivider", true)
pane.Divider:SetPoint("TOPLEFT", pane.RemoveRuleButton, "BOTTOMLEFT", 0, -SECTION_SPACING)
pane.Divider:SetPoint("RIGHT", -PANE_PADDING, 0)

pane.OverridesTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pane.OverridesTitle:SetPoint("TOPLEFT", pane.Divider, "BOTTOMLEFT", 0, -FIELD_SPACING)
pane.OverridesTitle:SetText(L["Character overrides"])

-- One tag per character, then +; ShowRule lays them out.
pane.Tags = CreateFrame("Frame", nil, content)
pane.Tags:SetPoint("TOPLEFT", pane.OverridesTitle, "BOTTOMLEFT", 0, -FIELD_SPACING)
pane.Tags:SetPoint("RIGHT", -PANE_PADDING, 0)

---@type Button[] reused from one line to the next
pane.CharacterTags = {}

-- Opens the menu of the known characters without an override on the line.
pane.AddOverrideButton = CreateFrame("DropdownButton", nil, pane.Tags, "UIPanelButtonTemplate")
pane.AddOverrideButton:SetText("+")
pane.AddOverrideButton:SetSize(ADD_TAG_WIDTH, BUTTON_HEIGHT)

-- The selected character's override.
pane.Override = createFieldSet()

pane.RemoveOverrideButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
pane.RemoveOverrideButton:SetPoint("BOTTOMLEFT", PANE_PADDING, PANE_PADDING)
pane.RemoveOverrideButton:SetHeight(BUTTON_HEIGHT)

---An ignored item's notice, under `above`, and its Stop ignoring button under it.
---@param above Region
---@return FontString notice
---@return Button stopButton
local function createIgnoredNotice(above)
    local notice = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    notice:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -FIELD_SPACING)
    notice:SetPoint("RIGHT", -PANE_PADDING, 0)
    notice:SetJustifyH("LEFT")

    local stopButton = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    stopButton:SetText(L["Stop ignoring"])
    stopButton:SetSize(math.max(BUTTON_WIDTH, stopButton:GetTextWidth() + 24), BUTTON_HEIGHT)
    stopButton:SetPoint("TOPLEFT", notice, "BOTTOMLEFT", 0, -FIELD_SPACING)
    return notice, stopButton
end

-- An item ignored by every character: in place of the whole line. By one character: in place of its override.
pane.IgnoredNotice, pane.StopIgnoringButton = createIgnoredNotice(pane.Header)
pane.OverrideIgnoredNotice, pane.OverrideStopIgnoringButton = createIgnoredNotice(pane.Tags)

---The tag at this place, created the first time it is needed.
---@param index integer
---@return Button
local function characterTag(index)
    local tag = pane.CharacterTags[index]
    if not tag then
        tag = CreateFrame("Button", nil, pane.Tags, "UIPanelButtonTemplate")
        tag:SetHeight(BUTTON_HEIGHT)
        ns.Skin.Apply(function(S) S.Button(tag) end)
        pane.CharacterTags[index] = tag
    end
    return tag
end

---Places the tags left to right, on as many rows as the pane's width needs, and fits the tags frame to them.
---@param tags Button[]
local function layoutTags(tags)
    local x, y = 0, 0
    for _, tag in ipairs(tags) do
        local width = tag:GetWidth()
        if x > 0 and x + width > TAGS_WIDTH then
            x, y = 0, y - BUTTON_HEIGHT - TAG_GAP
        end
        tag:ClearAllPoints()
        tag:SetPoint("TOPLEFT", x, y)
        x = x + width + TAG_GAP
    end
    pane.Tags:SetHeight(BUTTON_HEIGHT - y)
end

---A field of the selected line, ready to show.
---@class FlagUp.FieldDetail
---@field set boolean the line, or the character in an override, sets the field; false: it takes it from above

---@class FlagUp.RuleFieldDetail: FlagUp.FieldDetail
---@field text string the rule as the dropdown shows it

---@class FlagUp.QualitiesFieldDetail: FlagUp.FieldDetail
---@field selected table<integer, boolean> by item quality; none selected: no filter

---@class FlagUp.KeepFieldDetail: FlagUp.FieldDetail
---@field count integer

---@class FlagUp.StacksFieldDetail: FlagUp.FieldDetail
---@field fullStacksOnly boolean only full stacks are sent, of what stacks

---The selected line's character overrides, ready to show.
---@class FlagUp.OverridesDetail
---@field characters string[] the tags: the character being played, then the characters that override the line
---@field selected string the character whose override shows
---@field addable string[] the + menu: the known characters without an override on the line, the one being played left out
---@field onSelectCharacter fun(name: string)? a click on a character's tag
---@field rule FlagUp.RuleFieldDetail the selected character's fields
---@field qualities FlagUp.QualitiesFieldDetail? on an equipment category or subcategory
---@field keep FlagUp.KeepFieldDetail? on an item
---@field stacks FlagUp.StacksFieldDetail
---@field ignored boolean? the selected character ignores the item: the notice shows in place of its fields

---The selected line, ready to show.
---@class FlagUp.RuleDetail
---@field name string
---@field path string? the categories above the line (Trade Goods › Herb)
---@field color ColorMixin? the quality colour, on an item
---@field itemID integer? on an item: its icon shows, with its tooltip; else a crate
---@field rule FlagUp.RuleFieldDetail
---@field qualities FlagUp.QualitiesFieldDetail? on an equipment category or subcategory
---@field keep FlagUp.KeepFieldDetail? on an item
---@field stacks FlagUp.StacksFieldDetail
---@field isLine boolean? false: a plain heading, with no rule to remove
---@field ignoredByAll boolean? every character ignores the item: the notice shows in place of the whole line
---@field overrides FlagUp.OverridesDetail

---Shows a field as set or taken from above: a field taken from above has its controls greyed out and disabled.
---@param field FlagUp.Field
---@param detail FlagUp.FieldDetail
---@param controls table<integer, Button|EditBox> the quality checkboxes start at 0 (Poor)
local function showField(field, detail, controls)
    field.Checkbox:SetChecked(detail.set)
    for _, control in pairs(controls) do
        control:SetEnabled(detail.set)
        control:SetAlpha(detail.set and 1 or INHERITED_ALPHA)
    end
end

---Shows the fields the detail has, and hides the others.
---@param set FlagUp.FieldSet
---@param detail FlagUp.RuleDetail|FlagUp.OverridesDetail
---@return FlagUp.Field[] fields the shown fields, in order
local function showFieldSet(set, detail)
    set.RuleField:Show()
    set.StacksField:Show()

    -- The menus are built again: the client may keep the one built when the dropdown was first shown, for another
    -- line or character.
    set.RuleDropdown:GenerateMenu()
    set.StacksDropdown:GenerateMenu()

    set.RuleDropdown:OverrideText(detail.rule.text)
    showField(set.RuleField, detail.rule, { set.RuleDropdown })
    local fields = { set.RuleField }

    set.QualitiesField:SetShown(detail.qualities ~= nil)
    if detail.qualities then
        for quality, checkbox in pairs(set.QualityCheckboxes) do
            checkbox:SetChecked(detail.qualities.selected[quality] == true)
        end
        showField(set.QualitiesField, detail.qualities, set.QualityCheckboxes)
        fields[#fields + 1] = set.QualitiesField
    end

    set.KeepField:SetShown(detail.keep ~= nil)
    if detail.keep then
        set.KeepInput:SetText(tostring(detail.keep.count))
        showField(set.KeepField, detail.keep, { set.KeepInput })
        fields[#fields + 1] = set.KeepField
    end

    set.StacksDropdown:OverrideText(detail.stacks.fullStacksOnly and L["Full stacks only"] or L["Any amount"])
    showField(set.StacksField, detail.stacks, { set.StacksDropdown })
    fields[#fields + 1] = set.StacksField

    return fields
end

---@param set FlagUp.FieldSet
local function hideFieldSet(set)
    for _, field in ipairs({ set.RuleField, set.QualitiesField, set.KeepField, set.StacksField }) do field:Hide() end
end

---Places the fields one under the other, below `previous`.
---@param previous Region as wide as the fields
---@param fields FlagUp.Field[]
---@return Region last the last field
local function stackFields(previous, fields)
    for _, field in ipairs(fields) do
        field:ClearAllPoints()
        field:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -FIELD_SPACING)
        field:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -FIELD_SPACING)
        previous = field
    end
    return previous
end

---Shows a line in the pane: its shared rule, then its character overrides.
---@param detail FlagUp.RuleDetail? nil: no line is selected
function window:ShowRule(detail)
    pane.NoLine:SetShown(detail == nil)
    content:SetShown(detail ~= nil)
    if not detail then return end

    -- The icon, then the name and path beside it: an item's own, with its tooltip; a crate for a category or
    -- subcategory.
    pane.itemID = detail.itemID
    pane.IconHover:SetShown(detail.itemID ~= nil)
    pane.Icon:SetTexture(detail.itemID and C_Item.GetItemIconByID(detail.itemID) or CATEGORY_ICON)

    pane.Name:SetText(detail.name)
    if detail.color then
        pane.Name:SetTextColor(detail.color:GetRGB())
    else
        pane.Name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end
    pane.Path:SetText(detail.path or "")
    -- As tall as the icon, or as the name and the path.
    local textHeight = pane.Name:GetStringHeight() + 4 + pane.Path:GetStringHeight()
    pane.Header:SetHeight(math.max(PANE_ICON_SIZE, textHeight))

    -- Ignored by every character: only the notice, in place of the shared rule and the overrides, with Remove rule
    -- beside Stop ignoring, to remove the line without taking the item back.
    local ignoredByAll = detail.ignoredByAll == true
    pane.IgnoredNotice:SetShown(ignoredByAll)
    pane.StopIgnoringButton:SetShown(ignoredByAll)
    for _, region in ipairs({ pane.Divider, pane.OverridesTitle, pane.Tags }) do region:SetShown(not ignoredByAll) end
    if ignoredByAll then
        pane.IgnoredNotice:SetText(L["Ignored by every character: it is not offered at the mailbox."])
        hideFieldSet(pane.Shared)
        hideFieldSet(pane.Override)
        pane.RemoveRuleButton:ClearAllPoints()
        pane.RemoveRuleButton:SetPoint("LEFT", pane.StopIgnoringButton, "RIGHT", 8, 0)
        pane.RemoveRuleButton:SetShown(detail.isLine ~= false)
        pane.RemoveOverrideButton:Hide()
        pane.OverrideIgnoredNotice:Hide()
        pane.OverrideStopIgnoringButton:Hide()
        return
    end

    local last = stackFields(pane.Header, showFieldSet(pane.Shared, detail))
    pane.RemoveRuleButton:ClearAllPoints()
    pane.RemoveRuleButton:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -FIELD_SPACING)
    pane.RemoveRuleButton:SetShown(detail.isLine ~= false)

    -- The tags: the selected character's stays highlighted.
    local overrides = detail.overrides
    local tags = {}
    for index, name in ipairs(overrides.characters) do
        local tag = characterTag(index)
        tag:SetText(name)
        tag:SetWidth(tag:GetTextWidth() + 24)
        if name == overrides.selected then
            tag:LockHighlight()
        else
            tag:UnlockHighlight()
        end
        tag:SetScript("OnClick", overrides.onSelectCharacter and function() overrides.onSelectCharacter(name) end or nil)
        tag:Show()
        tags[index] = tag
    end
    for index = #overrides.characters + 1, #pane.CharacterTags do
        pane.CharacterTags[index]:Hide()
    end
    tags[#tags + 1] = pane.AddOverrideButton
    layoutTags(tags)

    pane.AddOverrideButton:SetEnabled(#overrides.addable > 0)
    pane.AddOverrideButton:SetupMenu(function(_, rootDescription)
        for _, name in ipairs(overrides.addable) do
            rootDescription:CreateButton(name, function() overrides.onSelectCharacter(name) end)
        end
    end)

    -- Ignored by the selected character: the notice in place of its override.
    local ignored = overrides.ignored == true
    pane.OverrideIgnoredNotice:SetShown(ignored)
    pane.OverrideStopIgnoringButton:SetShown(ignored)
    if ignored then
        pane.OverrideIgnoredNotice:SetText(L["Ignored by %s: it is not offered at the mailbox for this character."]
            :format(overrides.selected))
        hideFieldSet(pane.Override)
        pane.RemoveOverrideButton:Hide()
        return
    end
    stackFields(pane.Tags, showFieldSet(pane.Override, overrides))

    -- Only a character with an override has one to remove.
    local hasOverride = overrides.rule.set or (overrides.qualities ~= nil and overrides.qualities.set)
        or (overrides.keep ~= nil and overrides.keep.set) or overrides.stacks.set
    pane.RemoveOverrideButton:SetShown(hasOverride)
    pane.RemoveOverrideButton:SetText(L["Remove %s's override"]:format(overrides.selected))
    pane.RemoveOverrideButton:SetWidth(math.max(BUTTON_WIDTH, pane.RemoveOverrideButton:GetTextWidth() + 24))
end

-- Editing the selected line ----------------------------------------------------------------------

---@return FlagUp.LinePlace?
local function selectedPlace()
    local shown = selectedID and shownLines[selectedID]
    return shown and shown.place
end

---The character a field set edits: the shown character in the overrides section; nil for the shared rule.
---@param set FlagUp.FieldSet
---@return string?
local function editedCharacter(set)
    if set == pane.Override then return shownCharacter end
    return nil
end

---@param place FlagUp.LinePlace
---@param field FlagUp.FieldName
---@param value any
---@param character string?
local function setField(place, field, value, character)
    ns.Rules.SetField(place, field, value, character)
    RulesWindow.Refresh()
end

---Frame 9's Inherit: every shared field inherited, the line and its overrides kept.
---@param place FlagUp.LinePlace
local function inheritAll(_, place)
    ns.Rules.InheritAll(place)
    RulesWindow.Refresh()
end

-- Remove, Inherit when characters override the line, then Cancel on the right. The game's popup places its buttons in
-- their order and calls OnCancel for the second one: Escape only closes it.
StaticPopupDialogs.FLAGUP_REMOVE_RULE = {
    text = "%s",
    button1 = L["Remove"],
    OnAccept = function(_, place)
        ns.Rules.RemoveLine(place)
        RulesWindow.Refresh()
    end,
    noCancelOnEscape = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

---Asks whether to remove the selected line (frame 9): Remove, Inherit when characters override it, Cancel.
---@param place FlagUp.LinePlace
local function askToRemove(place)
    local shown = shownLines[selectedID]
    local overrides = (ns.Rules.LineAt(place) or {}).overrides
    local names = {}
    for name in pairs(overrides or {}) do names[#names + 1] = name end
    table.sort(names)

    local popup = StaticPopupDialogs.FLAGUP_REMOVE_RULE
    local text
    -- An item ignored by every character shows no field to inherit: Remove or Cancel only.
    local ignoredByAll = place.itemID ~= nil and ns.Ignored.IsIgnoredByAll(place.itemID)
    if #names > 0 and ignoredByAll then
        popup.button2, popup.OnCancel, popup.button3 = CANCEL, nil, nil
        text = L["Remove the rule for %s, with the overrides of %s?"]:format(shown.name, table.concat(names, ", "))
    elseif #names > 0 then
        popup.button2, popup.OnCancel, popup.button3 = L["Inherit"], inheritAll, CANCEL
        text = L["Remove the rule for %s, with the overrides of %s? Inherit keeps the line and the overrides, every shared field inherited."]
            :format(shown.name, table.concat(names, ", "))
    else
        popup.button2, popup.OnCancel, popup.button3 = CANCEL, nil, nil
        text = L["Remove the rule for %s?"]:format(shown.name)
    end
    StaticPopup_Show("FLAGUP_REMOVE_RULE", text, nil, place)
end

-- Unchecking a line's last shared field: Remove the line, or Keep the line with every field inherited (Escape too).
StaticPopupDialogs.FLAGUP_UNCHECK_LAST_FIELD = {
    text = "%s",
    button1 = L["Remove the line"],
    button2 = L["Keep the line"],
    OnAccept = function(_, data)
        ns.Rules.RemoveLine(data.place)
        RulesWindow.Refresh()
    end,
    OnCancel = function(_, data)
        ns.Rules.SetField(data.place, data.field, nil)
        RulesWindow.Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

---Asks what to do with the selected line once its last shared field is unchecked.
---@param place FlagUp.LinePlace
---@param field FlagUp.FieldName the field unchecked
local function askAfterLastField(place, field)
    local shown = shownLines[selectedID]
    local names = {}
    for name in pairs((ns.Rules.LineAt(place) or {}).overrides or {}) do names[#names + 1] = name end
    table.sort(names)

    local text = L["%s no longer sets a field of its own. Remove the line, or keep it with every field inherited?"]
        :format(shown.name)
    if #names > 0 then
        text = text .. " " .. L["Removing it also removes the overrides of %s."]:format(table.concat(names, ", "))
    end
    StaticPopup_Show("FLAGUP_UNCHECK_LAST_FIELD", text, nil, { place = place, field = field })
end

-- A field's checkbox: checked, the line (or the character) sets the field to the value it was taking; unchecked, the
-- field is inherited again. Unchecking the line's last shared field asks first whether to keep the line.
---@param set FlagUp.FieldSet
---@param field FlagUp.FieldName
---@param checkbox CheckButton
local function wireFieldCheckbox(set, field, checkbox)
    checkbox:SetScript("OnClick", function()
        local place = selectedPlace()
        if not place then return end
        local character = editedCharacter(set)

        if checkbox:GetChecked() then
            local value = ns.Rules.Value(place, field, character)
            if type(value) == "table" then value = CopyTable(value) end
            setField(place, field, value, character)
            return
        end

        local line = ns.Rules.LineAt(place) --[[@as FlagUp.Line]]
        if not character then
            local others = CopyTable(line)
            others[field] = nil
            if not ns.Rules.SetsAField(others) then
                RulesWindow.Refresh()
                askAfterLastField(place, field)
                return
            end
        end
        setField(place, field, nil, character)
    end)
end

---@param set FlagUp.FieldSet
local function wireFieldSet(set)
    wireFieldCheckbox(set, "sendTo", set.RuleField.Checkbox)
    wireFieldCheckbox(set, "qualities", set.QualitiesField.Checkbox)
    wireFieldCheckbox(set, "keep", set.KeepField.Checkbox)
    wireFieldCheckbox(set, "fullStacksOnly", set.StacksField.Checkbox)

    -- The rule: Don't send, the characters (the edited one left out: mail never goes to itself), then a typed name.
    set.RuleDropdown:SetupMenu(function(_, root)
        local place = selectedPlace()
        if not place then return end
        local character = editedCharacter(set)
        local current = ns.Rules.Value(place, "sendTo", character)
        local function isCurrent(value) return current == value end
        local function choose(value) setField(place, "sendTo", value, character) end

        root:CreateRadio(L["Don't send"], isCurrent, choose, false)
        for _, name in ipairs(ns.Characters.Names(character)) do
            root:CreateRadio(name, isCurrent, choose, name)
        end
        root:CreateButton(L["Other character…"], function()
            ns.CharacterNameDialog.Open(character, function(name)
                ns.Characters.AddTyped(name)
                choose(name)
            end)
        end)
    end)

    set.StacksDropdown:SetupMenu(function(_, root)
        local place = selectedPlace()
        if not place then return end
        local character = editedCharacter(set)
        local current = ns.Rules.Value(place, "fullStacksOnly", character)
        local function isCurrent(value) return current == value end
        local function choose(value) setField(place, "fullStacksOnly", value, character) end
        root:CreateRadio(L["Full stacks only"], isCurrent, choose, true)
        root:CreateRadio(L["Any amount"], isCurrent, choose, false)
    end)

    for quality, checkbox in pairs(set.QualityCheckboxes) do
        checkbox:SetScript("OnClick", function()
            local place = selectedPlace()
            if not place then return end
            local character = editedCharacter(set)
            local qualities = CopyTable(ns.Rules.Value(place, "qualities", character))
            qualities[quality] = checkbox:GetChecked() or nil
            setField(place, "qualities", qualities, character)
        end)
    end

    -- The keep count is saved with Enter, or on leaving the box.
    local function saveKeep()
        local place = selectedPlace()
        if not place then return end
        local character = editedCharacter(set)
        local count = tonumber(set.KeepInput:GetText()) or 0
        if count ~= ns.Rules.Value(place, "keep", character) then setField(place, "keep", count, character) end
    end
    set.KeepInput:SetScript("OnEnterPressed", function() set.KeepInput:ClearFocus() end)
    set.KeepInput:SetScript("OnEditFocusLost", saveKeep)
end

wireFieldSet(pane.Shared)
wireFieldSet(pane.Override)

pane.RemoveRuleButton:SetScript("OnClick", function()
    local place = selectedPlace()
    if place then askToRemove(place) end
end)

-- Stop ignoring: by every character, or by the character shown.
pane.StopIgnoringButton:SetScript("OnClick", function()
    local place = selectedPlace()
    if not (place and place.itemID) then return end
    ns.Ignored.Remove(place.itemID)
    RulesWindow.Refresh()
end)

pane.OverrideStopIgnoringButton:SetScript("OnClick", function()
    local place = selectedPlace()
    if not (place and place.itemID) then return end
    ns.Ignored.Remove(place.itemID, shownCharacter)
    RulesWindow.Refresh()
end)

pane.RemoveOverrideButton:SetScript("OnClick", function()
    local place = selectedPlace()
    if not place then return end
    ns.Rules.RemoveOverride(place, shownCharacter)
    shownCharacter = nil
    RulesWindow.Refresh()
end)

-- Tabs -------------------------------------------------------------------------------------------

-- The game's tabs under the window: the rules, and the ignored items. Named: the game's tab functions find a
-- window's tabs by name.
local RULES_TAB, IGNORED_TAB = 1, 2
local TAB_LEFT, TAB_TOP, TAB_GAP = 11, 2, 3

---@type Button[]
window.Tabs = {}
for index, title in ipairs({ L["Rules"], L["Ignored"] }) do
    local tab = CreateFrame("Button", "FlagUpRulesWindowTab" .. index, window, "PanelTabButtonTemplate")
    tab:SetID(index)
    tab:SetText(title)
    if index == 1 then
        tab:SetPoint("TOPLEFT", window, "BOTTOMLEFT", TAB_LEFT, TAB_TOP)
    else
        tab:SetPoint("LEFT", window.Tabs[index - 1], "RIGHT", TAB_GAP, 0)
    end
    PanelTemplates_TabResize(tab, 0)
    window.Tabs[index] = tab
end
PanelTemplates_SetNumTabs(window, #window.Tabs)

---Shows a tab: the toolbar, the tree and the pane on the Rules tab; the list on the Ignored tab.
---@param index integer
local function showTab(index)
    PanelTemplates_SetTab(window, index)
    for _, region in ipairs({ window.SearchBox, window.AddItemButton, window.AddCategoryButton, tree, pane }) do
        region:SetShown(index == RULES_TAB)
    end
    ns.IgnoredList.View:SetShown(index == IGNORED_TAB)
end

for _, tab in ipairs(window.Tabs) do
    tab:SetScript("OnClick", function() showTab(tab:GetID()) end)
end
---Shows the Ignored tab, filtered on a category or subcategory.
---@param classID integer
---@param subClassID integer? nil: the whole category
function RulesWindow.ShowIgnored(classID, subClassID)
    showTab(IGNORED_TAB)
    ns.IgnoredList.ShowCategory(classID, subClassID)
end

-- The window opens on the Rules tab; the Ignored list, loaded after this file, starts hidden.
PanelTemplates_SetTab(window, RULES_TAB)

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
    S.Inset(pane.Inset)
    for _, set in ipairs({ pane.Shared, pane.Override }) do
        S.Dropdown(set.RuleDropdown)
        S.Dropdown(set.StacksDropdown)
        local checkboxes = { set.RuleField.Checkbox, set.QualitiesField.Checkbox, set.KeepField.Checkbox,
            set.StacksField.Checkbox }
        for _, checkbox in pairs(set.QualityCheckboxes) do checkboxes[#checkboxes + 1] = checkbox end
        for _, checkbox in ipairs(checkboxes) do
            S.Checkbox(checkbox)
            checkbox:SetSize(SKINNED_CHECKBOX_SIZE, SKINNED_CHECKBOX_SIZE)
            checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", SKINNED_CHECKBOX_LABEL_GAP, 0)
        end
        S.EditBox(set.KeepInput)
    end
    S.Button(pane.RemoveRuleButton)
    S.Button(pane.AddOverrideButton)
    S.Button(pane.RemoveOverrideButton)
    S.Button(pane.StopIgnoringButton)
    S.Button(pane.OverrideStopIgnoringButton)
    for _, tab in ipairs(window.Tabs) do S.Tab(tab) end
end)
