local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The dialog to type a character's name: an alt Flag Up hasn't seen, such as one on another account.
---@class FlagUp.CharacterNameDialog
---@field Dialog Frame
local CharacterNameDialog = {}
ns.CharacterNameDialog = CharacterNameDialog

local WIDTH, HEIGHT = 440, 150
local PADDING = 16
local CONTENT_TOP = -34
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22
local INPUT_HEIGHT = 20

-- Dialog -----------------------------------------------------------------------------------------

-- Named: the game closes the frames listed in UISpecialFrames, by name, on Escape.
local dialog = CreateFrame("Frame", "FlagUpCharacterNameDialog", UIParent, "ButtonFrameTemplate")
dialog:SetSize(WIDTH, HEIGHT)
-- Centred over the rules window when it opens; moved on its own after.
dialog:SetPoint("CENTER", ns.RulesWindow.Window, "CENTER")
dialog:SetTitle(L["Other character"])
ButtonFrameTemplate_HidePortrait(dialog)
-- Without the portrait, the title bar spans the whole top and would take the close button's clicks.
dialog:SetTitleOffsets(0, -24)
dialog:SetMovable(true)
dialog:SetClampedToScreen(true)
dialog:SetFrameStrata("DIALOG")
dialog:SetToplevel(true)
table.insert(UISpecialFrames, "FlagUpCharacterNameDialog")
dialog:Hide()
dialog.TitleContainer:EnableMouse(true)
dialog.TitleContainer:RegisterForDrag("LeftButton")
dialog.TitleContainer:SetScript("OnDragStart", function() dialog:StartMoving() end)
dialog.TitleContainer:SetScript("OnDragStop", function() dialog:StopMovingOrSizing() end)
CharacterNameDialog.Dialog = dialog

dialog.Inset:Hide()

-- Name -------------------------------------------------------------------------------------------

dialog.Label = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormal")
dialog.Label:SetPoint("TOPLEFT", PADDING, CONTENT_TOP)
dialog.Label:SetText(L["Character name"])

dialog.OkButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
dialog.OkButton:SetText(OKAY)
dialog.OkButton:SetSize(math.max(BUTTON_WIDTH, dialog.OkButton:GetTextWidth() + 24), BUTTON_HEIGHT)
dialog.OkButton:SetPoint("TOPRIGHT", -PADDING, CONTENT_TOP - dialog.Label:GetLineHeight() - 6)

-- InputBoxTemplate draws its border 5 left of the field's edge.
dialog.Input = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
dialog.Input:SetHeight(INPUT_HEIGHT)
dialog.Input:SetPoint("LEFT", dialog, "LEFT", PADDING + 5, 0)
dialog.Input:SetPoint("RIGHT", dialog.OkButton, "LEFT", -12, 0)
dialog.Input:SetPoint("TOP", dialog.OkButton, "TOP", 0, -1)
dialog.Input:SetAutoFocus(false)

dialog.Hint = dialog:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
dialog.Hint:SetPoint("TOPLEFT", dialog.Label, "BOTTOMLEFT", 0, -6 - BUTTON_HEIGHT - 10)
dialog.Hint:SetPoint("RIGHT", -PADDING, 0)
dialog.Hint:SetJustifyH("LEFT")
dialog.Hint:SetText(L["The whole name, \"First Surname\", of a character of this ruleset and faction."])

-- A refused name's error, in red.
dialog.Error = dialog:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
dialog.Error:SetPoint("TOPLEFT", dialog.Hint, "BOTTOMLEFT", 0, -8)
dialog.Error:SetPoint("RIGHT", -PADDING, 0)
dialog.Error:SetJustifyH("LEFT")

-- Choosing the name ------------------------------------------------------------------------------

---@type fun(name: string)? called with the name once accepted
local onName
---@type string? the character the name can't be: the one the rule is for
local refused

local function accept()
    local name = strtrim(dialog.Input:GetText())
    if not name:match("^%S+ %S+$") then
        dialog.Error:SetText(L["Type the whole name: First Surname."])
        return
    end
    if name == refused then
        dialog.Error:SetText(L["A character can't mail itself."])
        return
    end
    dialog:Hide()
    if onName then onName(name) end
end

dialog.OkButton:SetScript("OnClick", accept)
dialog.Input:SetScript("OnEnterPressed", accept)

---Opens the dialog with an empty field, ready to type in.
---@param except string? the character the name can't be: the one the rule is for
---@param callback fun(name: string) called with the name once accepted
function CharacterNameDialog.Open(except, callback)
    refused, onName = except, callback
    dialog.Input:SetText("")
    dialog.Error:SetText("")
    dialog:Show()
    dialog.Input:SetFocus()
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(dialog)
    S.CloseButton(dialog.CloseButton)
    S.EditBox(dialog.Input)
    S.Button(dialog.OkButton)
end)
