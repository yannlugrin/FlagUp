local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---@class FlagUp.AddCategoryDialog
---@field Dialog Frame the Add category dialog
local AddCategoryDialog = {}
ns.AddCategoryDialog = AddCategoryDialog

local WIDTH, HEIGHT = 440, 520
local PADDING = 16
local CONTENT_TOP = -34
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22
local LIST_TOP, LIST_BOTTOM = -64, 46
local SCROLL_BAR_SPACE = 20
-- "already added" sits on the right of the row, left of a category's +/- mark.
local ADDED_LEFT = 270

-- Dialog -----------------------------------------------------------------------------------------

-- Named: the game closes the frames listed in UISpecialFrames, by name, on Escape.
local dialog = CreateFrame("Frame", "FlagUpAddCategoryDialog", UIParent, "ButtonFrameTemplate")
dialog:SetSize(WIDTH, HEIGHT)
-- Centred over the rules window when it opens; moved on its own after.
dialog:SetPoint("CENTER", ns.RulesWindow.Window, "CENTER")
dialog:SetTitle(L["Add category"])
ButtonFrameTemplate_HidePortrait(dialog)
-- Without the portrait, the title bar spans the whole top and would take the close button's clicks.
dialog:SetTitleOffsets(0, -24)
dialog:SetMovable(true)
dialog:SetClampedToScreen(true)
dialog:SetFrameStrata("DIALOG")
dialog:SetToplevel(true)
table.insert(UISpecialFrames, "FlagUpAddCategoryDialog")
dialog:Hide()
dialog.TitleContainer:EnableMouse(true)
dialog.TitleContainer:RegisterForDrag("LeftButton")
dialog.TitleContainer:SetScript("OnDragStart", function() dialog:StartMoving() end)
dialog.TitleContainer:SetScript("OnDragStop", function() dialog:StopMovingOrSizing() end)
AddCategoryDialog.Dialog = dialog

dialog.Inset:Hide()

-- Filter -----------------------------------------------------------------------------------------

-- SearchBoxTemplate draws its border 6 left of the field's edge.
dialog.Filter = CreateFrame("EditBox", nil, dialog, "SearchBoxTemplate")
dialog.Filter:SetHeight(20)
dialog.Filter:SetPoint("TOPLEFT", PADDING + 6, CONTENT_TOP)
dialog.Filter:SetPoint("RIGHT", -PADDING, 0)
dialog.Filter.Instructions:SetText(FILTER)

-- Categories -------------------------------------------------------------------------------------

local list = CreateFrame("Frame", nil, dialog)
list:SetPoint("TOPLEFT", PADDING, LIST_TOP)
list:SetPoint("BOTTOMRIGHT", -PADDING, LIST_BOTTOM)
dialog.List = list

list.Inset = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
list.Inset:SetPoint("TOPLEFT", -3, 3)
list.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
list.ScrollBox:SetPoint("TOPLEFT")
list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 0)

list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
list.ScrollBar:SetPoint("TOPLEFT", list.ScrollBox, "TOPRIGHT", 6, 0)
list.ScrollBar:SetPoint("BOTTOMLEFT", list.ScrollBox, "BOTTOMRIGHT", 6, 0)

local listView = CreateScrollBoxListLinearView()
listView:SetElementInitializer("Button", function(row, line) ns.TreeRow.Init(row, line, ADDED_LEFT) end)
listView:SetElementExtentCalculator(ns.TreeRow.Height)
ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, listView)

-- Buttons ----------------------------------------------------------------------------------------

dialog.AddButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
dialog.AddButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
dialog.AddButton:SetHeight(BUTTON_HEIGHT)

dialog.CancelButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
dialog.CancelButton:SetText(CANCEL)
dialog.CancelButton:SetSize(math.max(BUTTON_WIDTH, dialog.CancelButton:GetTextWidth() + 24), BUTTON_HEIGHT)
dialog.CancelButton:SetPoint("RIGHT", dialog.AddButton, "LEFT", -8, 0)

---Shows these categories and subcategories, in this order; Add names the selected one.
---@param lines FlagUp.TreeLine[]
function dialog:ShowLines(lines)
    list.ScrollBox:SetDataProvider(CreateDataProvider(lines), ScrollBoxConstants.RetainScrollPosition)

    ---@type FlagUp.TreeLine?
    local selected
    for _, line in ipairs(lines) do
        if line.selected then selected = line end
    end
    -- With nothing selected, Add is disabled.
    dialog.AddButton:SetText(selected and L["Add %s"]:format(selected.name) or L["Add"])
    dialog.AddButton:SetEnabled(selected ~= nil)
    dialog.AddButton:SetWidth(math.max(BUTTON_WIDTH, dialog.AddButton:GetTextWidth() + 24))
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(dialog)
    S.CloseButton(dialog.CloseButton)
    S.EditBox(dialog.Filter)
    S.Inset(list.Inset)
    S.ScrollBar(list.ScrollBar)
    S.Button(dialog.AddButton)
    S.Button(dialog.CancelButton)
end)
