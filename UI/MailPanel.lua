local addonName, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The panel attached to the mailbox's right.
---@class FlagUp.MailPanel
---@field Panel Frame
local MailPanel = {}
ns.MailPanel = MailPanel

---An item the rules choose, ready to show.
---@class FlagUp.MailItem
---@field name string
---@field icon number|string
---@field color ColorMixin the quality colour
---@field count integer how many are sent
---@field checked boolean unchecked: it stays in the bags this time

---A recipient and the items it gets, ready to show.
---@class FlagUp.MailGroup
---@field recipient string
---@field mails integer
---@field items FlagUp.MailItem[]

---What the mailbox would send, ready to show.
---@class FlagUp.MailPreview
---@field groups FlagUp.MailGroup[] empty: nothing to send
---@field mails integer
---@field postage integer in copper

local WIDTH = 320
-- The panel's border touches the mailbox's.
local MAILBOX_GAP = 2
local PADDING = 12
local LIST_TOP, LIST_BOTTOM = -30, 42
local SCROLL_BAR_SPACE = 20
local BUTTON_WIDTH, BUTTON_HEIGHT = 120, 22
-- The mail count of a recipient's header ends on the right of the row, as its items' counts do.
local MAILS_LEFT = 150
local ITEM_HEIGHT = 24
local CHECKBOX_SIZE = 26
local ICON_SIZE = 18
local UNCHECKED_ALPHA = 0.5
local SKINNED_CHECKBOX_SIZE = 16

-- Panel ------------------------------------------------------------------------------------------

local panel = CreateFrame("Frame", "FlagUpMailPanel", UIParent, "ButtonFrameTemplate")
panel:SetWidth(WIDTH)
panel:SetTitle(C_AddOns.GetAddOnMetadata(addonName, "Title"))
ButtonFrameTemplate_HidePortrait(panel)
panel:Hide()
MailPanel.Panel = panel

panel.Inset:Hide()

-- Items ------------------------------------------------------------------------------------------

local list = CreateFrame("Frame", nil, panel)
list:SetPoint("TOPLEFT", PADDING, LIST_TOP)
list:SetPoint("BOTTOMRIGHT", -PADDING, LIST_BOTTOM)
panel.List = list

list.Inset = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
list.Inset:SetPoint("TOPLEFT", -3, 3)
list.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
list.ScrollBox:SetPoint("TOPLEFT")
list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 0)

list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
list.ScrollBar:SetPoint("TOPLEFT", list.ScrollBox, "TOPRIGHT", 6, 0)
list.ScrollBar:SetPoint("BOTTOMLEFT", list.ScrollBox, "BOTTOMRIGHT", 6, 0)

list.Empty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
list.Empty:SetPoint("LEFT", 12, 0)
list.Empty:SetPoint("RIGHT", -12, 0)
list.Empty:SetText(L["Nothing to send."])

---An item's row; createItemRow adds its regions the first time the row is used.
---@class FlagUp.MailItemRow: Frame
---@field Checkbox CheckButton
---@field Icon Texture
---@field Name FontString
---@field Count FontString

---@param row FlagUp.MailItemRow
local function createItemRow(row)
    row.Checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    row.Checkbox:SetPoint("LEFT", 2, 0)

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT", row.Checkbox, "RIGHT", 2, 0)

    row.Count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
    row.Count:SetPoint("RIGHT", -8, 0)

    row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 6, 0)
    row.Name:SetPoint("RIGHT", row.Count, "LEFT", -8, 0)
    row.Name:SetWordWrap(false)

    ns.Skin.Apply(function(S)
        S.Checkbox(row.Checkbox)
        row.Checkbox:SetSize(SKINNED_CHECKBOX_SIZE, SKINNED_CHECKBOX_SIZE)
    end)
end

---@param row FlagUp.MailItemRow
---@param item FlagUp.MailItem
local function initItemRow(row, item)
    if not row.Name then createItemRow(row) end

    row.Checkbox:SetChecked(item.checked)
    row.Icon:SetTexture(item.icon)
    row.Icon:SetDesaturated(not item.checked)
    row.Name:SetText(item.name)
    row.Name:SetTextColor(item.color:GetRGB())
    row.Count:SetText(item.count)
    -- An unchecked item stays in the bags: its row is dimmed.
    local alpha = item.checked and 1 or UNCHECKED_ALPHA
    row.Icon:SetAlpha(alpha)
    row.Name:SetAlpha(alpha)
    row.Count:SetAlpha(alpha)
end

-- The list holds the recipients' headers, as tree category rows, and their items. The scroll box reuses rows by
-- frame type: an item's row is a Frame, a header's a Button.
local listView = CreateScrollBoxListLinearView()
listView:SetElementFactory(function(factory, element)
    if element.item then
        factory("Frame", function(row) initItemRow(row, element.item) end)
    else
        factory("Button", function(row) ns.TreeRow.Init(row, element.header, MAILS_LEFT) end)
    end
end)
listView:SetElementExtentCalculator(function(index, element)
    if element.item then return ITEM_HEIGHT end
    return ns.TreeRow.Height(index, element.header)
end)
ScrollUtil.InitScrollBoxListWithScrollBar(list.ScrollBox, list.ScrollBar, listView)

-- Footer -----------------------------------------------------------------------------------------

panel.SendButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.SendButton:SetText(L["Send"])
panel.SendButton:SetSize(math.max(BUTTON_WIDTH, panel.SendButton:GetTextWidth() + 24), BUTTON_HEIGHT)
panel.SendButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)

panel.Summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
panel.Summary:SetPoint("LEFT", panel, "BOTTOMLEFT", PADDING, PADDING + BUTTON_HEIGHT / 2)
panel.Summary:SetPoint("RIGHT", panel.SendButton, "LEFT", -8, 0)
panel.Summary:SetJustifyH("LEFT")

---@param mails integer
---@return string
local function mailCount(mails)
    return mails == 1 and L["1 mail"] or L["%d mails"]:format(mails)
end

---Shows what the mailbox would send.
---@param preview FlagUp.MailPreview
function panel:ShowPreview(preview)
    local elements = {}
    for _, group in ipairs(preview.groups) do
        elements[#elements + 1] = { header = { kind = "category", name = group.recipient, mails = mailCount(group.mails) } }
        for _, item in ipairs(group.items) do
            elements[#elements + 1] = { item = item }
        end
    end
    list.ScrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
    list.Empty:SetShown(#elements == 0)

    panel.Summary:SetText(L["%s · postage %s"]:format(mailCount(preview.mails), GetMoneyString(preview.postage)))
    panel.SendButton:SetEnabled(#elements > 0)
end

---Shows the panel beside the open mailbox. Call on MAIL_SHOW.
function MailPanel.Open()
    -- A child of the mailbox hides with it, however it is closed (Escape, walking away, its close button).
    panel:SetParent(MailFrame)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", MAILBOX_GAP, 0)
    panel:SetPoint("BOTTOMLEFT", MailFrame, "BOTTOMRIGHT", MAILBOX_GAP, 0)
    panel:ShowPreview({ groups = {}, mails = 0, postage = 0 })
    panel:Show()
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(panel)
    S.CloseButton(panel.CloseButton)
    S.Inset(list.Inset)
    S.ScrollBar(list.ScrollBar)
    S.Button(panel.SendButton)
end)
