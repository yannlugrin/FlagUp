local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---@class FlagUp.AddItemDialog
---@field Dialog Frame the Add item dialog
local AddItemDialog = {}
ns.AddItemDialog = AddItemDialog

local WIDTH, HEIGHT = 440, 170
local PADDING = 16
local CONTENT_TOP = -34
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22
local INPUT_HEIGHT = 20

-- Dialog -----------------------------------------------------------------------------------------

-- Named: the game closes the frames listed in UISpecialFrames, by name, on Escape.
local dialog = CreateFrame("Frame", "FlagUpAddItemDialog", UIParent, "ButtonFrameTemplate")
dialog:SetSize(WIDTH, HEIGHT)
-- Centred over the rules window when it opens; moved on its own after.
dialog:SetPoint("CENTER", ns.RulesWindow.Window, "CENTER")
dialog:SetTitle(L["Add item"])
ButtonFrameTemplate_HidePortrait(dialog)
-- Without the portrait, the title bar spans the whole top and would take the close button's clicks.
dialog:SetTitleOffsets(0, -24)
dialog:SetMovable(true)
dialog:SetClampedToScreen(true)
dialog:SetFrameStrata("DIALOG")
dialog:SetToplevel(true)
table.insert(UISpecialFrames, "FlagUpAddItemDialog")
dialog:Hide()
dialog.TitleContainer:EnableMouse(true)
dialog.TitleContainer:RegisterForDrag("LeftButton")
dialog.TitleContainer:SetScript("OnDragStart", function() dialog:StartMoving() end)
dialog.TitleContainer:SetScript("OnDragStop", function() dialog:StopMovingOrSizing() end)
AddItemDialog.Dialog = dialog

dialog.Inset:Hide()

-- Item ID or link --------------------------------------------------------------------------------

dialog.Label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dialog.Label:SetPoint("TOPLEFT", PADDING, CONTENT_TOP)
dialog.Label:SetText(L["Item ID or link"])

dialog.AddButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
dialog.AddButton:SetText(L["Add"])
dialog.AddButton:SetSize(math.max(BUTTON_WIDTH, dialog.AddButton:GetTextWidth() + 24), BUTTON_HEIGHT)
dialog.AddButton:SetPoint("TOPRIGHT", -PADDING, CONTENT_TOP - dialog.Label:GetLineHeight() - 6)

-- InputBoxTemplate draws its border 5 left of the field's edge.
dialog.Input = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
dialog.Input:SetHeight(INPUT_HEIGHT)
dialog.Input:SetPoint("LEFT", dialog, "LEFT", PADDING + 5, 0)
dialog.Input:SetPoint("RIGHT", dialog.AddButton, "LEFT", -12, 0)
dialog.Input:SetPoint("TOP", dialog.AddButton, "TOP", 0, -1)
dialog.Input:SetAutoFocus(false)

dialog.Hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
dialog.Hint:SetPoint("TOPLEFT", dialog.Label, "BOTTOMLEFT", 0, -6 - BUTTON_HEIGHT - 10)
dialog.Hint:SetPoint("RIGHT", -PADDING, 0)
dialog.Hint:SetJustifyH("LEFT")
dialog.Hint:SetText(L["Type an item ID, or shift-click an item to paste its link. You can also drop an item on the rules window."])

-- A failed add's error, in red.
dialog.Error = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
dialog.Error:SetPoint("TOPLEFT", dialog.Hint, "BOTTOMLEFT", 0, -8)
dialog.Error:SetPoint("RIGHT", -PADDING, 0)
dialog.Error:SetJustifyH("LEFT")

---Shows the error of a failed add, or clears it.
---@param message string? nil: no error
function dialog:ShowError(message)
    dialog.Error:SetText(message or "")
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(dialog)
    S.CloseButton(dialog.CloseButton)
    S.EditBox(dialog.Input)
    S.Button(dialog.AddButton)
end)
