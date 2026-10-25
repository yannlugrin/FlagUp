local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The game's icon picker, as for equipment sets, choosing a character's icon: a row of the professions' icons above
---the game's list.
---@class FlagUp.IconPicker
local IconPicker = {}
ns.IconPicker = IconPicker

-- The professions the flavor has, by skill line. Forever: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering,
-- First Aid, Fishing, Herbalism, Leatherworking, Mining, Skinning, Tailoring. Retail: Alchemy, Blacksmithing, Cooking,
-- Enchanting, Engineering, Fishing, Herbalism, Inscription, Jewelcrafting, Leatherworking, Mining, Skinning, Tailoring.
local PROFESSION_SKILL_LINES = ns.IS_FOREVER and { 171, 164, 185, 333, 202, 129, 356, 182, 165, 186, 393, 197 }
    or { 171, 164, 185, 333, 202, 356, 182, 773, 755, 165, 186, 393, 197 }
-- The game's question mark icon, the list's first: no icon chosen.
local NO_ICON = 134400
local BUTTON_LEFT, BUTTON_BOTTOM, CLASS_ICON_BUTTON_WIDTH = 11, 13, 110
-- The professions' row takes the place of the game's label, filter and list, which move down by its height, the
-- filter clear of its icons: its label, then its icons, the list's buttons a little smaller so the fourteen fit its
-- width.
local PROFESSIONS_HEIGHT = 74
local PROFESSIONS_LEFT, PROFESSIONS_LABEL_TOP, PROFESSIONS_ICONS_TOP = 24, -79, -95
local PROFESSION_BUTTON_SIZE, PROFESSION_BUTTON_GAP = 32, 3
-- The list's button art, as SelectorButtonTemplate draws it.
local EMPTY_SLOT_TEXTURE = "Interface\\Buttons\\UI-EmptySlot-Disabled"
local EMPTY_SLOT_COORD, EMPTY_SLOT_SCALE = 0.140625, 45 / 36
local SELECTED_TEXTURE = "Interface\\Buttons\\CheckButtonHilight"
local HIGHLIGHT_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"

local picker = CreateFrame("Frame", "FlagUpIconPicker", UIParent, "IconSelectorPopupFrameTemplate")
picker:SetFrameStrata("DIALOG")
picker:EnableMouse(true)
picker:Hide()
table.insert(UISpecialFrames, "FlagUpIconPicker")

-- No name to type: the box's header is the title.
picker.BorderBox.IconSelectorEditBox:Hide()

-- Opaque, as it opens over the rules window's list; the game's is see-through, beside the character sheet.
picker.BG:SetColorTexture(0, 0, 0, 1)

-- Room for the professions' row: the game's label, filter, drop area and list move down by its height.
picker:SetHeight(picker:GetHeight() + PROFESSIONS_HEIGHT)
for _, region in ipairs({ picker.BorderBox.IconSelectionText, picker.BorderBox.IconTypeDropdown,
    picker.BorderBox.IconDragArea, picker.IconSelector }) do
    local point, relativeTo, relativePoint, x, y = region:GetPoint(1)
    region:SetPoint(point, relativeTo, relativePoint, x, y - PROFESSIONS_HEIGHT)
end

picker.ClassIconButton = CreateFrame("Button", nil, picker.BorderBox, "UIPanelButtonNoTooltipTemplate")
picker.ClassIconButton:SetSize(CLASS_ICON_BUTTON_WIDTH, picker.BorderBox.OkayButton:GetHeight())
picker.ClassIconButton:SetPoint("BOTTOMLEFT", BUTTON_LEFT, BUTTON_BOTTOM)
picker.ClassIconButton:SetText(L["Class icon"])

---@type string? the character whose icon is chosen
local characterName
---@type fun()? called once the icon changed
local onChange

-- Professions --------------------------------------------------------------------------------------

---A profession's icon in the row above the list.
---@class FlagUp.ProfessionIconButton: Button
---@field SelectedTexture Texture
---@field icon number|string

picker.ProfessionsLabel = picker.BorderBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
picker.ProfessionsLabel:SetPoint("TOPLEFT", PROFESSIONS_LEFT, PROFESSIONS_LABEL_TOP)
picker.ProfessionsLabel:SetText(L["Professions"])

---@type FlagUp.ProfessionIconButton[]
picker.ProfessionButtons = {}

---Shows an icon as the one selected, in the list and in the professions' row; the question mark: none chosen.
---@param icon number|string
local function selectIcon(icon)
    picker.IconSelector:SetSelectedIndex(picker:GetIndexOfIcon(icon))
    picker.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon)
    picker:SetSelectedIconText()
    for _, button in ipairs(picker.ProfessionButtons) do button.SelectedTexture:SetShown(button.icon == icon) end
end

---The professions' icons, as the game gives them; one it has none for is left out.
---@return (number|string)[]
local function professionIcons()
    local icons = {}
    if not (C_TradeSkillUI and C_TradeSkillUI.GetTradeSkillTexture) then return icons end
    for _, skillLine in ipairs(PROFESSION_SKILL_LINES) do
        local icon = C_TradeSkillUI.GetTradeSkillTexture(skillLine)
        if icon and icon ~= 0 then icons[#icons + 1] = icon end
    end
    return icons
end

for index, icon in ipairs(professionIcons()) do
    local button = CreateFrame("Button", nil, picker.BorderBox) --[[@as FlagUp.ProfessionIconButton]]
    button:SetSize(PROFESSION_BUTTON_SIZE, PROFESSION_BUTTON_SIZE)
    button:SetPoint("TOPLEFT", PROFESSIONS_LEFT + (index - 1) * (PROFESSION_BUTTON_SIZE + PROFESSION_BUTTON_GAP),
        PROFESSIONS_ICONS_TOP)
    button.icon = icon

    local slot = button:CreateTexture(nil, "BACKGROUND")
    slot:SetTexture(EMPTY_SLOT_TEXTURE)
    slot:SetTexCoord(EMPTY_SLOT_COORD, 1 - EMPTY_SLOT_COORD, EMPTY_SLOT_COORD, 1 - EMPTY_SLOT_COORD)
    slot:SetSize(PROFESSION_BUTTON_SIZE * EMPTY_SLOT_SCALE, PROFESSION_BUTTON_SIZE * EMPTY_SLOT_SCALE)
    slot:SetPoint("CENTER", 0, -1)
    button:SetNormalTexture(button.icon)
    button:SetHighlightTexture(HIGHLIGHT_TEXTURE, "ADD")
    button.SelectedTexture = button:CreateTexture(nil, "OVERLAY")
    button.SelectedTexture:SetTexture(SELECTED_TEXTURE)
    button.SelectedTexture:SetBlendMode("ADD")
    button.SelectedTexture:SetAllPoints()
    button.SelectedTexture:Hide()

    button:SetScript("OnClick", function() selectIcon(button.icon) end)
    picker.ProfessionButtons[index] = button
end

-- Showing ----------------------------------------------------------------------------------------

picker:SetScript("OnShow", function(self)
    IconSelectorPopupFrameTemplateMixin.OnShow(self)
    self.iconDataProvider = CreateAndInitFromMixin(IconDataProviderMixin, IconDataProviderExtraType.None)
    self:SetIconFilter(IconSelectorPopupFrameIconFilterTypes.All)
    self.IconSelector:SetSelectionsDataProvider(GenerateClosure(self.GetIconByIndex, self),
        GenerateClosure(self.GetNumIcons, self))
    self.IconSelector:SetSelectedCallback(function(_, icon) selectIcon(icon) end)
    local character = ns.Characters.Get(characterName)
    selectIcon(character and character.icon or NO_ICON)
    self.IconSelector:ScrollToSelectedIndex()
    self.BorderBox.OkayButton:Enable()
end)

picker:SetScript("OnHide", function(self)
    IconSelectorPopupFrameTemplateMixin.OnHide(self)
    self.iconDataProvider:Release()
    self.iconDataProvider = nil
end)

---Saves an icon for the character, nil: its class icon; then closes.
---@param icon number|string|nil
local function save(icon)
    picker:Hide()
    ns.Characters.SetIcon(characterName, icon)
    if onChange then onChange() end
end

-- Okay keeps the icon selected; the question mark means none, the class icon.
function picker:OkayButton_OnClick()
    local icon = self.BorderBox.SelectedIconArea.SelectedIconButton:GetIconTexture()
    save(icon ~= NO_ICON and icon or nil)
end

picker.ClassIconButton:SetScript("OnClick", function() save(nil) end)

---Opens the picker on a character's icon, centred over the rules window.
---@param name string
---@param callback fun() called once its icon changed
function IconPicker.Open(name, callback)
    characterName, onChange = name, callback
    picker.BorderBox.EditBoxHeaderText:SetText(L["Icon for %s"]:format(ns.Characters.ShownName(name)))
    picker:ClearAllPoints()
    picker:SetPoint("CENTER", ns.RulesWindow.Window, "CENTER")
    picker:Hide()
    picker:Show()
end

-- Skin -------------------------------------------------------------------------------------------

---The scroll bars under a frame: the game's grid keeps its own a few frames down.
---@param frame Frame
---@param found Frame[]
---@return Frame[]
local function scrollBarsIn(frame, found)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.Track and (child.Back or child.Forward) then found[#found + 1] = child end
        scrollBarsIn(child, found)
    end
    return found
end

-- As EllesmereUI skins the game's own icon pickers (macros, equipment sets): its panel in place of the frame's art,
-- the box's art faded, its dropdown, scroll bar, buttons and white texts.
ns.Skin.Apply(function(S)
    S.Panel(picker)
    local box = picker.BorderBox
    S.FadeRegions(box)
    S.Dropdown(box.IconTypeDropdown)
    for _, button in ipairs({ box.OkayButton, box.CancelButton, picker.ClassIconButton }) do
        S.Button(button)
        S.WhiteButtonLabel(button)
    end
    for _, text in ipairs({ box.EditBoxHeaderText, box.IconSelectionText, picker.ProfessionsLabel }) do
        S.Font(text)
        S.White(text)
    end
    S.FadeRegions(picker.IconSelector)
    for _, scrollBar in ipairs(scrollBarsIn(picker.IconSelector, {})) do S.ScrollBar(scrollBar) end
end)
