local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The rules window's Characters tab: the characters sharing these rules, whether they get a tab at the mailbox, their
---icon; typed ones to forget.
---@class FlagUp.CharacterList
---@field View Frame the tab's content
local CharacterList = {}
ns.CharacterList = CharacterList

local window = ns.RulesWindow.Window

-- The tab's content takes the place of the toolbar, the tree and the pane.
local VIEW_LEFT, VIEW_TOP, VIEW_BOTTOM = 16, -30, 12
-- The explanation starts where the toolbar does, right of the portrait.
local INTRO_LEFT, INTRO_TOP = 48, -6
local LIST_TOP = -58
local NOTE_HEIGHT = 30
local COLUMN_HEADER_HEIGHT = 24
local SCROLL_BAR_SPACE = 20
local MAILBOX_COLUMN_WIDTH, ICON_COLUMN_WIDTH, NAME_COLUMN_WIDTH, CLASS_COLUMN_WIDTH, KIND_COLUMN_WIDTH =
    120, 60, 300, 170, 150
local ROW_HEIGHT = 30
local CHECKBOX_SIZE = 26
local SKINNED_CHECKBOX_SIZE = 16
local ICON_SIZE = 24
local CHANGE_ICON_WIDTH, FORGET_WIDTH, BUTTON_HEIGHT = 110, 90, 22

local view = CreateFrame("Frame", nil, window)
view:SetPoint("TOPLEFT", VIEW_LEFT, VIEW_TOP)
view:SetPoint("BOTTOMRIGHT", -VIEW_LEFT, VIEW_BOTTOM)
view:Hide()
CharacterList.View = view

view.Intro = view:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
view.Intro:SetPoint("TOPLEFT", INTRO_LEFT, INTRO_TOP)
view.Intro:SetPoint("RIGHT")
view.Intro:SetJustifyH("LEFT")
view.Intro:SetText(L["The characters sharing these rules. Checked ones get a tab beside the mailbox panel, with their icon."])

-- List -------------------------------------------------------------------------------------------

local list = CreateFrame("Frame", nil, view)
list:SetPoint("TOPLEFT", 0, LIST_TOP)
list:SetPoint("BOTTOMRIGHT", 0, NOTE_HEIGHT)
view.List = list

list.Inset = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
list.Inset:SetPoint("TOPLEFT", -3, 3)
list.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

list.ColumnDisplay = CreateFrame("Frame", nil, list, "ColumnDisplayTemplate")
list.ColumnDisplay:SetPoint("BOTTOMLEFT", list, "TOPLEFT", 0, 0)
list.ColumnDisplay:SetPoint("BOTTOMRIGHT", list, "TOPRIGHT", 0, 0)
list.ColumnDisplay:SetHeight(COLUMN_HEADER_HEIGHT)
list.ColumnDisplay:LayoutColumns({
    { title = L["At the mailbox"], width = MAILBOX_COLUMN_WIDTH },
    { title = L["Icon"], width = ICON_COLUMN_WIDTH },
    { title = L["Character"], width = NAME_COLUMN_WIDTH },
    { title = L["Class"], width = CLASS_COLUMN_WIDTH },
    { title = L["Known or typed"], width = KIND_COLUMN_WIDTH },
    { title = "", width = 0 },
})

list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
list.ScrollBox:SetPoint("TOPLEFT")
list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 0)

list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
list.ScrollBar:SetPoint("TOPLEFT", list.ScrollBox, "TOPRIGHT", 6, 0)
list.ScrollBar:SetPoint("BOTTOMLEFT", list.ScrollBox, "BOTTOMRIGHT", 6, 0)

view.Note = view:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
view.Note:SetPoint("BOTTOMLEFT", 0, 0)
view.Note:SetPoint("RIGHT")
view.Note:SetHeight(NOTE_HEIGHT - 8)
view.Note:SetJustifyH("LEFT")
view.Note:SetText(L["A typed character starts hidden at the mailbox; its class is unknown until it logs in with Flag Up, so its icon is a question mark until you choose one. Characters by name."])

---A character, ready to show.
---@class FlagUp.CharacterRow
---@field name string
---@field character FlagUp.Character
---@field sentTo boolean a rule or an override sends to it: it can't be forgotten

---A character's row; createRow adds its regions the first time the row is used.
---@class FlagUp.CharacterRowFrame: Frame
---@field Checkbox CheckButton
---@field Icon Texture
---@field Name FontString
---@field Class FontString
---@field Kind FontString
---@field ChangeIconButton Button
---@field ForgetButton Button
---@field row FlagUp.CharacterRow the character shown

---@param frame FlagUp.CharacterRowFrame
local function createRow(frame)
    -- A cell starts where its column header's text does: 8 into the header.
    frame.Checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    frame.Checkbox:SetPoint("LEFT", 4, 0)
    frame.Checkbox:SetScript("OnClick", function(checkbox)
        ns.Characters.SetShownAtMailbox(frame.row.name, checkbox:GetChecked())
        ns.RulesWindow.Refresh()
    end)

    local left = MAILBOX_COLUMN_WIDTH
    frame.Icon = frame:CreateTexture(nil, "ARTWORK")
    frame.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    frame.Icon:SetPoint("LEFT", left + 8, 0)

    left = left + ICON_COLUMN_WIDTH
    frame.Name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    frame.Name:SetPoint("LEFT", left + 8, 0)
    frame.Name:SetWidth(NAME_COLUMN_WIDTH - 16)
    frame.Name:SetWordWrap(false)

    left = left + NAME_COLUMN_WIDTH
    frame.Class = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    frame.Class:SetPoint("LEFT", left + 8, 0)
    frame.Class:SetWidth(CLASS_COLUMN_WIDTH - 16)

    left = left + CLASS_COLUMN_WIDTH
    frame.Kind = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLeft")
    frame.Kind:SetPoint("LEFT", left + 8, 0)
    frame.Kind:SetWidth(KIND_COLUMN_WIDTH - 16)

    frame.ForgetButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ForgetButton:SetSize(FORGET_WIDTH, BUTTON_HEIGHT)
    frame.ForgetButton:SetPoint("RIGHT", -8, 0)
    frame.ForgetButton:SetText(L["Forget"])
    frame.ForgetButton:SetScript("OnClick", function()
        ns.Characters.Forget(frame.row.name)
        ns.RulesWindow.Refresh()
    end)
    -- Disabled while a rule sends to it: why.
    frame.ForgetButton:SetMotionScriptsWhileDisabled(true)
    frame.ForgetButton:SetScript("OnEnter", function(button)
        if button:IsEnabled() then return end
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["A rule sends to %s: change that rule first to forget it."]
            :format(ns.Characters.ShownName(frame.row.name)), HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    frame.ForgetButton:SetScript("OnLeave", GameTooltip_Hide)

    frame.ChangeIconButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.ChangeIconButton:SetSize(CHANGE_ICON_WIDTH, BUTTON_HEIGHT)
    frame.ChangeIconButton:SetPoint("RIGHT", frame.ForgetButton, "LEFT", -6, 0)
    frame.ChangeIconButton:SetText(L["Change icon"])
    frame.ChangeIconButton:SetScript("OnClick", function()
        ns.IconPicker.Open(frame.row.name, ns.RulesWindow.Refresh)
    end)

    ns.Skin.Apply(function(S)
        S.Checkbox(frame.Checkbox)
        frame.Checkbox:SetSize(SKINNED_CHECKBOX_SIZE, SKINNED_CHECKBOX_SIZE)
        S.Button(frame.ChangeIconButton)
        S.Button(frame.ForgetButton)
    end)
end

---@param frame FlagUp.CharacterRowFrame
---@param row FlagUp.CharacterRow
local function initRow(frame, row)
    if not frame.Name then createRow(frame) end
    frame.row = row
    local character = row.character
    frame.Checkbox:SetChecked(ns.Characters.IsShownAtMailbox(row.name))
    ns.CharacterIcon.Show(frame.Icon, character)
    frame.Name:SetText(ns.Characters.ShownName(row.name))
    frame.Class:SetText(character.class and LOCALIZED_CLASS_NAMES_MALE[character.class] or L["Unknown"])
    frame.Kind:SetText(character.typed and L["Typed"] or L["Known"])
    -- Only a typed character is forgotten, and not while a rule sends to it.
    frame.ForgetButton:SetShown(character.typed)
    frame.ForgetButton:SetEnabled(not row.sentTo)
end

local listView = CreateScrollBoxListLinearView()
listView:SetElementExtent(ROW_HEIGHT)
listView:SetElementInitializer("Frame", initRow)
ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, listView)

-- Showing the list -------------------------------------------------------------------------------

---Shows the characters again, by name.
function CharacterList.Refresh()
    if not ns.data then return end
    local rows = {}
    for _, name in ipairs(ns.Characters.AllNames()) do
        rows[#rows + 1] = { name = name, character = ns.Characters.Get(name), sentTo = ns.Rules.SendsTo(name) }
    end
    list.ScrollBox:SetDataProvider(CreateDataProvider(rows), ScrollBoxConstants.RetainScrollPosition)
end

view:HookScript("OnShow", CharacterList.Refresh)

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
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
