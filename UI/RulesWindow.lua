local addonName, ns = ...
---@cast ns StashPost.Namespace

local L = ns.L

---@class StashPost.RulesWindow
---@field Window Frame the rules window
local RulesWindow = {}
ns.RulesWindow = RulesWindow

---A line of the tree, ready to show.
---@class StashPost.TreeLine
---@field kind "category"|"subcategory"|"item"
---@field name string
---@field rule string? the rule the character being played uses, as shown in the Rule column; nil on a plain heading
---@field inherited boolean? the line inherits all its fields: its rule is greyed out
---@field overridden boolean? the character being played overrides the line: a glyph follows its name
---@field collapsed boolean? on a category or subcategory
---@field icon number|string? on an item
---@field color ColorMixin? the quality colour, on an item
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
-- The Rule column takes the width left of the name's, up to 28 from the right, over the scroll bar.
local NAME_WIDTH = 340
-- A cell starts where its column header's text does: 8 into the header.
local NAME_LEFT, RULE_LEFT = 10, NAME_WIDTH + 8
-- The rule leaves room for a category's +/- mark on the right.
local RULE_RIGHT = -28
local OVERRIDE_GLYPH_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Glyphs\\Person"
local OVERRIDE_GLYPH_SIZE = 12
local CATEGORY_HEIGHT, LINE_HEIGHT = 28, 22
local SUBCATEGORY_INDENT, ITEM_INDENT = 14, 34
local ICON_SIZE = 18
local LINE_HIGHLIGHT_TEXTURE = "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"

local PANE_GAP = 16
local PANE_PADDING = 12
local FIELD_SPACING = 12
-- A field's controls start right of its checkbox and label.
local FIELD_CONTROLS_LEFT = 120
local CHECKBOX_SIZE = 26
local INHERITED_ALPHA = 0.5
local RULE_DROPDOWN_WIDTH = 200
local QUALITY_COLUMNS, QUALITY_COLUMN_WIDTH = 2, 105
local KEEP_INPUT_WIDTH = 50
local SKINNED_CHECKBOX_SIZE = 16
local SKINNED_CHECKBOX_LABEL_GAP = 6

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
---@field OverrideGlyph Texture
---@field Rule FontString

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
    row.Name:SetWordWrap(false)

    row.OverrideGlyph = row:CreateTexture(nil, "ARTWORK")
    row.OverrideGlyph:SetTexture(OVERRIDE_GLYPH_TEXTURE)
    row.OverrideGlyph:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
    row.OverrideGlyph:SetSize(OVERRIDE_GLYPH_SIZE, OVERRIDE_GLYPH_SIZE)
    row.OverrideGlyph:SetPoint("LEFT", row.Name, "RIGHT", 4, 0)

    row.Rule = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    row.Rule:SetPoint("LEFT", RULE_LEFT, 0)
    row.Rule:SetPoint("RIGHT", RULE_RIGHT, 0)
    row.Rule:SetWordWrap(false)
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

    -- The name is as wide as its text, so the glyph follows it, within the name column.
    local glyphSpace = line.overridden and OVERRIDE_GLYPH_SIZE + 4 or 0
    local nameSpace = RULE_LEFT - 8 - nameLeft - glyphSpace
    row.Name:SetWidth(math.min(row.Name:GetUnboundedStringWidth(), nameSpace))
    row.OverrideGlyph:SetShown(line.overridden == true)

    row.Rule:SetText(line.rule or "")
    if line.inherited then
        row.Rule:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    else
        row.Rule:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
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

-- Right pane: the shared rule ----------------------------------------------------------------------

-- The pane starts at the top of the column headers and fills the window's right side.
local pane = CreateFrame("Frame", nil, window)
pane:SetPoint("TOPLEFT", tree.ColumnDisplay, "TOPRIGHT", PANE_GAP, 0)
pane:SetPoint("BOTTOMRIGHT", -TREE_LEFT, TREE_BOTTOM)
window.Pane = pane

pane.Inset = CreateFrame("Frame", nil, pane, "InsetFrameTemplate")
pane.Inset:SetPoint("TOPLEFT", -3, 3)
pane.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

pane.Name = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
pane.Name:SetPoint("TOPLEFT", PANE_PADDING, -PANE_PADDING)
pane.Name:SetPoint("RIGHT", -PANE_PADDING, 0)
pane.Name:SetJustifyH("LEFT")
pane.Name:SetWordWrap(false)

pane.Path = pane:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
pane.Path:SetPoint("TOPLEFT", pane.Name, "BOTTOMLEFT", 0, -4)
pane.Path:SetPoint("RIGHT", -PANE_PADDING, 0)
pane.Path:SetJustifyH("LEFT")
pane.Path:SetWordWrap(false)

---A checkbox with UICheckButtonTemplate's label.
---@class StashPost.LabeledCheckbox: CheckButton
---@field Text FontString

---A field of the line: its checkbox and label on the left, its controls on the right.
---@class StashPost.Field: Frame
---@field Checkbox StashPost.LabeledCheckbox checked: the line sets the field; unchecked: it inherits it

---@param label string
---@param height number the height of its controls
---@return StashPost.Field
local function createField(label, height)
    local field = CreateFrame("Frame", nil, pane) --[[@as StashPost.Field]]
    field:SetHeight(height)

    field.Checkbox = CreateFrame("CheckButton", nil, field, "UICheckButtonTemplate") --[[@as StashPost.LabeledCheckbox]]
    field.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    -- Centred on the first row of controls, whatever size the skin gives the checkbox.
    field.Checkbox:SetPoint("LEFT", field, "TOPLEFT", -4, -CHECKBOX_SIZE / 2)
    field.Checkbox.Text:SetFontObject(GameFontNormal)
    field.Checkbox.Text:SetText(label)
    return field
end

pane.RuleField = createField(L["Rule"], CHECKBOX_SIZE)
pane.RuleDropdown = CreateFrame("DropdownButton", nil, pane.RuleField, "WowStyle1DropdownTemplate")
pane.RuleDropdown:SetWidth(RULE_DROPDOWN_WIDTH)
pane.RuleDropdown:SetPoint("LEFT", pane.RuleField, "TOPLEFT", FIELD_CONTROLS_LEFT, -CHECKBOX_SIZE / 2)

-- Qualities, on an equipment category or subcategory: one checkbox per quality, two to a row.
local qualityRows = math.ceil((Enum.ItemQuality.Legendary + 1) / QUALITY_COLUMNS)
pane.QualitiesField = createField(L["Qualities"], qualityRows * CHECKBOX_SIZE)

---@type table<integer, StashPost.LabeledCheckbox> by item quality (Enum.ItemQuality)
pane.QualityCheckboxes = {}
for quality = Enum.ItemQuality.Poor, Enum.ItemQuality.Legendary do
    local checkbox = CreateFrame("CheckButton", nil, pane.QualitiesField, "UICheckButtonTemplate") --[[@as StashPost.LabeledCheckbox]]
    checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    local column = quality % QUALITY_COLUMNS
    local row = math.floor(quality / QUALITY_COLUMNS)
    checkbox:SetPoint("LEFT", pane.QualitiesField, "TOPLEFT", FIELD_CONTROLS_LEFT - 4 + column * QUALITY_COLUMN_WIDTH,
        -(row + 0.5) * CHECKBOX_SIZE)
    checkbox.Text:SetText(_G["ITEM_QUALITY" .. quality .. "_DESC"])
    checkbox.Text:SetTextColor(ColorManager.GetColorDataForItemQuality(quality).color:GetRGB())
    pane.QualityCheckboxes[quality] = checkbox
end

-- Keep in bags, on an item.
pane.KeepField = createField(L["Keep"], CHECKBOX_SIZE)
pane.KeepInput = CreateFrame("EditBox", nil, pane.KeepField, "InputBoxTemplate")
pane.KeepInput:SetSize(KEEP_INPUT_WIDTH, 20)
pane.KeepInput:SetPoint("LEFT", pane.KeepField, "TOPLEFT", FIELD_CONTROLS_LEFT + 6, -CHECKBOX_SIZE / 2)
pane.KeepInput:SetNumeric(true)
pane.KeepInput:SetAutoFocus(false)
pane.KeepInput:SetJustifyH("CENTER")

pane.RemoveRuleButton = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
pane.RemoveRuleButton:SetText(L["Remove rule"])
pane.RemoveRuleButton:SetSize(math.max(BUTTON_WIDTH, pane.RemoveRuleButton:GetTextWidth() + 24), BUTTON_HEIGHT)

---A field of the selected line, ready to show.
---@class StashPost.FieldDetail
---@field set boolean the line sets the field; false: it inherits it

---@class StashPost.RuleFieldDetail: StashPost.FieldDetail
---@field text string the rule as the dropdown shows it

---@class StashPost.QualitiesFieldDetail: StashPost.FieldDetail
---@field selected table<integer, boolean> by item quality; none selected: no filter

---@class StashPost.KeepFieldDetail: StashPost.FieldDetail
---@field count integer

---The selected line's shared rule, ready to show.
---@class StashPost.RuleDetail
---@field name string
---@field path string? the categories above the line (Trade Goods › Herb)
---@field color ColorMixin? the quality colour, on an item
---@field rule StashPost.RuleFieldDetail
---@field qualities StashPost.QualitiesFieldDetail? on an equipment category or subcategory
---@field keep StashPost.KeepFieldDetail? on an item

---Shows a field as set by the line or inherited: an inherited field's controls are greyed out and disabled.
---@param field StashPost.Field
---@param detail StashPost.FieldDetail
---@param controls table<integer, Button|EditBox> the quality checkboxes start at 0 (Poor)
local function showField(field, detail, controls)
    field.Checkbox:SetChecked(detail.set)
    for _, control in pairs(controls) do
        control:SetEnabled(detail.set)
        control:SetAlpha(detail.set and 1 or INHERITED_ALPHA)
    end
end

---Shows a line's shared rule in the pane.
---@param detail StashPost.RuleDetail
function window:ShowRule(detail)
    pane.Name:SetText(detail.name)
    if detail.color then
        pane.Name:SetTextColor(detail.color:GetRGB())
    else
        pane.Name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end
    pane.Path:SetText(detail.path or "")

    pane.RuleDropdown:OverrideText(detail.rule.text)
    showField(pane.RuleField, detail.rule, { pane.RuleDropdown })
    local fields = { pane.RuleField }

    pane.QualitiesField:SetShown(detail.qualities ~= nil)
    if detail.qualities then
        for quality, checkbox in pairs(pane.QualityCheckboxes) do
            checkbox:SetChecked(detail.qualities.selected[quality] == true)
        end
        showField(pane.QualitiesField, detail.qualities, pane.QualityCheckboxes)
        fields[#fields + 1] = pane.QualitiesField
    end

    pane.KeepField:SetShown(detail.keep ~= nil)
    if detail.keep then
        pane.KeepInput:SetText(tostring(detail.keep.count))
        showField(pane.KeepField, detail.keep, { pane.KeepInput })
        fields[#fields + 1] = pane.KeepField
    end

    -- The line's fields one under the other, below the path, then Remove rule.
    ---@type Region
    local previous = pane.Path
    for _, field in ipairs(fields) do
        field:ClearAllPoints()
        field:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -FIELD_SPACING)
        field:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -FIELD_SPACING)
        previous = field
    end
    pane.RemoveRuleButton:ClearAllPoints()
    pane.RemoveRuleButton:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -FIELD_SPACING)
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
    S.Dropdown(pane.RuleDropdown)
    local checkboxes = { pane.RuleField.Checkbox, pane.QualitiesField.Checkbox, pane.KeepField.Checkbox }
    for _, checkbox in pairs(pane.QualityCheckboxes) do checkboxes[#checkboxes + 1] = checkbox end
    for _, checkbox in ipairs(checkboxes) do
        S.Checkbox(checkbox)
        checkbox:SetSize(SKINNED_CHECKBOX_SIZE, SKINNED_CHECKBOX_SIZE)
        checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", SKINNED_CHECKBOX_LABEL_GAP, 0)
    end
    S.EditBox(pane.KeepInput)
    S.Button(pane.RemoveRuleButton)
end)
