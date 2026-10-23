local addonName, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The rows of a category tree: the rules window's tree and the Add category dialog's; the mailbox panel's recipient headers.
---@class FlagUp.TreeRow
local TreeRow = {}
ns.TreeRow = TreeRow

---A line of a category tree, ready to show.
---@class FlagUp.TreeLine
---@field kind "category"|"subcategory"|"item"
---@field id string? in the rules tree: identifies the line, to select it or keep it closed
---@field name string
---@field rule string? the rule the character being played uses, as shown in the Rule column; nil on a plain heading
---@field inherited boolean? the line inherits all its fields: its rule is greyed out
---@field overridden boolean? the character being played overrides the line: a glyph follows its name
---@field added boolean? in the Add category dialog: the category is already in the rules tree; the row is greyed out and marked
---@field mails string? in the mailbox panel, on a recipient's header: its number of mails, where the Rule column is
---@field collapsed boolean? on a category or subcategory that holds lines; nil on one without: no open or closed mark
---@field icon number|string? on an item
---@field color ColorMixin? the quality colour, on an item
---@field selected boolean?
---@field onClick fun()? a click on the row
---@field onToggle fun()? a click on its open or closed mark

local NAME_LEFT = 10
-- The rule leaves room for a category's +/- mark on the right; a recipient's mail count has none.
local RULE_RIGHT, MAILS_RIGHT = -28, -8
local OVERRIDE_GLYPH_TEXTURE = "Interface\\AddOns\\" .. addonName .. "\\Media\\Glyphs\\Person"
local OVERRIDE_GLYPH_SIZE = 12
local CATEGORY_HEIGHT, LINE_HEIGHT = 28, 22
local SUBCATEGORY_INDENT, ITEM_INDENT = 14, 34
local ICON_SIZE = 18
local LINE_HIGHLIGHT_TEXTURE = "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar"

---A tree row; createRow adds its regions the first time the row is used.
---@class FlagUp.TreeRow.Row: Button
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
---@field ToggleButton Button over the open or closed mark, while the line has one
---@field line FlagUp.TreeLine the line shown

---@param row FlagUp.TreeRow.Row
---@param ruleLeft number where the Rule column starts
local function createRow(row, ruleLeft)
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
    row.Rule:SetPoint("LEFT", ruleLeft, 0)
    row.Rule:SetWordWrap(false)

    row.ToggleButton = CreateFrame("Button", nil, row)
    row.ToggleButton:SetScript("OnClick", function()
        if row.line.onToggle then row.line.onToggle() end
    end)

    row:SetScript("OnClick", function()
        if row.line.onClick then row.line.onClick() end
    end)
end

---Shows a line in a row.
---@param row FlagUp.TreeRow.Row
---@param line FlagUp.TreeLine
---@param ruleLeft number where the Rule column starts
function TreeRow.Init(row, line, ruleLeft)
    if not row.Name then createRow(row, ruleLeft) end
    row.line = line

    local isCategory = line.kind == "category"
    row.CategoryBackground:SetShown(isCategory)
    row.CategoryHighlight:SetShown(isCategory)
    row.LineHighlight:SetShown(not isCategory)
    row.Selected:SetShown(line.selected == true)

    local hasStateIcon = isCategory and line.collapsed ~= nil
    row.StateIcon:SetShown(hasStateIcon)
    if hasStateIcon then
        row.StateIcon:SetAtlas(line.collapsed and "common-button-list-plus" or "common-button-list-minus", true)
    end
    local hasToggle = line.kind == "subcategory" and line.collapsed ~= nil
    row.ToggleIcon:SetShown(hasToggle)
    if hasToggle then
        row.ToggleIcon:SetAtlas(line.collapsed and "campaign_headericon_closed" or "campaign_headericon_open", true)
    end
    -- The mark takes its own clicks: the rest of the row selects.
    local mark = (hasStateIcon and row.StateIcon) or (hasToggle and row.ToggleIcon) or nil
    row.ToggleButton:SetShown(mark ~= nil and line.onToggle ~= nil)
    if mark then row.ToggleButton:SetAllPoints(mark) end
    row.Icon:SetShown(line.kind == "item")
    if line.kind == "item" then row.Icon:SetTexture(line.icon) end

    -- The name follows its mark: none on a category, the open or closed mark, the item's icon.
    local nameLeft = NAME_LEFT
    if hasToggle then
        nameLeft = SUBCATEGORY_INDENT + row.ToggleIcon:GetWidth() + 4
    elseif line.kind == "subcategory" then
        nameLeft = SUBCATEGORY_INDENT
    elseif line.kind == "item" then
        nameLeft = ITEM_INDENT + ICON_SIZE + 6
    end
    row.Name:SetPoint("LEFT", nameLeft, 0)
    row.Name:SetText(line.name)
    if line.added then
        row.Name:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    elseif line.color then
        row.Name:SetTextColor(line.color:GetRGB())
    else
        row.Name:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
    end

    -- The name is as wide as its text, so the glyph follows it, within the name column.
    local glyphSpace = line.overridden and OVERRIDE_GLYPH_SIZE + 4 or 0
    local nameSpace = ruleLeft - 8 - nameLeft - glyphSpace
    row.Name:SetWidth(math.min(row.Name:GetUnboundedStringWidth(), nameSpace))
    row.OverrideGlyph:SetShown(line.overridden == true)

    -- A recipient's mail count lines up with its items' counts, on the right.
    row.Rule:SetPoint("RIGHT", line.mails and MAILS_RIGHT or RULE_RIGHT, 0)
    row.Rule:SetJustifyH(line.mails and "RIGHT" or "LEFT")
    if line.added then
        row.Rule:SetText(L["already added"])
    else
        row.Rule:SetText(line.rule or line.mails or "")
    end
    if line.inherited or line.added then
        row.Rule:SetTextColor(GRAY_FONT_COLOR:GetRGB())
    else
        row.Rule:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    end
end

---@param line FlagUp.TreeLine
---@return number
function TreeRow.Height(_, line)
    return line.kind == "category" and CATEGORY_HEIGHT or LINE_HEIGHT
end
