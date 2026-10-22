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
-- The pane leaves as much room on the window's right as the tree on its left.
local PANE_WIDTH = WIDTH - TREE_LEFT - TREE_WIDTH - PANE_GAP - TREE_LEFT
local FIELD_SPACING = 12
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
window:SetFrameStrata("HIGH")
window:SetToplevel(true)
table.insert(UISpecialFrames, "FlagUpRulesWindow")
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

pane.Name = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pane.Name:SetPoint("TOPLEFT", PANE_PADDING, -PANE_PADDING)
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

---The fields a line can have, with their controls.
---@class FlagUp.FieldSet
---@field RuleField FlagUp.Field
---@field RuleDropdown FlagUp.Dropdown
---@field QualitiesField FlagUp.Field on an equipment category or subcategory
---@field QualityCheckboxes table<integer, FlagUp.LabeledCheckbox> by item quality (Enum.ItemQuality)
---@field KeepField FlagUp.Field on an item
---@field KeepInput EditBox

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
pane.Divider:SetPoint("TOPLEFT", pane.RemoveRuleButton, "BOTTOMLEFT", 0, -FIELD_SPACING)
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

---The selected line's character overrides, ready to show.
---@class FlagUp.OverridesDetail
---@field characters string[] the tags: the character being played, then the characters that override the line
---@field selected string the character whose override shows
---@field addable string[] the + menu: the known characters without an override on the line, the one being played left out
---@field rule FlagUp.RuleFieldDetail the selected character's fields
---@field qualities FlagUp.QualitiesFieldDetail? on an equipment category or subcategory
---@field keep FlagUp.KeepFieldDetail? on an item

---The selected line, ready to show.
---@class FlagUp.RuleDetail
---@field name string
---@field path string? the categories above the line (Trade Goods › Herb)
---@field color ColorMixin? the quality colour, on an item
---@field rule FlagUp.RuleFieldDetail
---@field qualities FlagUp.QualitiesFieldDetail? on an equipment category or subcategory
---@field keep FlagUp.KeepFieldDetail? on an item
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

    return fields
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

    pane.Name:SetText(detail.name)
    if detail.color then
        pane.Name:SetTextColor(detail.color:GetRGB())
    else
        pane.Name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end
    pane.Path:SetText(detail.path or "")

    local last = stackFields(pane.Path, showFieldSet(pane.Shared, detail))
    pane.RemoveRuleButton:ClearAllPoints()
    pane.RemoveRuleButton:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -FIELD_SPACING)

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
            rootDescription:CreateButton(name, function() end)
        end
    end)

    stackFields(pane.Tags, showFieldSet(pane.Override, overrides))

    -- Only a character with an override has one to remove.
    local hasOverride = overrides.rule.set or (overrides.qualities ~= nil and overrides.qualities.set)
        or (overrides.keep ~= nil and overrides.keep.set)
    pane.RemoveOverrideButton:SetShown(hasOverride)
    pane.RemoveOverrideButton:SetText(L["Remove %s's override"]:format(overrides.selected))
    pane.RemoveOverrideButton:SetWidth(math.max(BUTTON_WIDTH, pane.RemoveOverrideButton:GetTextWidth() + 24))
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
    S.Inset(pane.Inset)
    for _, set in ipairs({ pane.Shared, pane.Override }) do
        S.Dropdown(set.RuleDropdown)
        local checkboxes = { set.RuleField.Checkbox, set.QualitiesField.Checkbox, set.KeepField.Checkbox }
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
end)
