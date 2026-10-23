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
---@field itemID integer for its tooltip
---@field name string
---@field icon number|string
---@field color ColorMixin the quality colour
---@field count integer how many are sent
---@field checked boolean unchecked: it stays in the bags this time
---@field onToggle fun()? a click on its checkbox
---@field uncheckedWhy string? unchecked by the settings, not by hand: why, for its checkbox's tooltip
---@field onIgnore fun()? a click on its Ignore button

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

---An attachment of a mail, ready to show.
---@class FlagUp.MailAttachment
---@field itemID integer for its tooltip
---@field icon number|string
---@field count integer

---A mail being sent, ready to show.
---@class FlagUp.SendingMail
---@field recipient string
---@field part integer? with several mails to the recipient: which one this is
---@field parts integer? with several mails to the recipient: how many
---@field status "sent"|"sending"|"waiting"|"failed"|"stopped"
---@field attachments FlagUp.MailAttachment[]
---@field error string? on a failed mail: the game's error

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
local SKINNED_CHECKBOX_SIZE = 16
local IGNORE_BUTTON_SIZE = 16
-- The game's loot Pass button, as the Ignore button.
local IGNORE_TEXTURE, IGNORE_TEXTURE_DOWN = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", "Interface\\Buttons\\UI-GroupLoot-Pass-Down"
local MAIL_TITLE_HEIGHT = 18
local SPINNER_SIZE = 16
local ATTACHMENT_SIZE, ATTACHMENT_GAP = 26, 2
-- As many as the row's width holds; a mail's twelve take two rows.
local ATTACHMENTS_PER_ROW = 9
local MAIL_ERROR_HEIGHT = 14
local MAIL_BOTTOM_PADDING = 8
local DIMMED_ALPHA = 0.5

-- Panel ------------------------------------------------------------------------------------------

local panel = CreateFrame("Frame", "FlagUpMailPanel", UIParent, "ButtonFrameTemplate")
panel:SetWidth(WIDTH)
panel:SetTitle(C_AddOns.GetAddOnMetadata(addonName, "Title"))
ButtonFrameTemplate_HidePortrait(panel)
panel:Hide()
MailPanel.Panel = panel

panel.Inset:Hide()

---A list of the panel, in an inset with its scroll bar: the preview's items, or the mails being sent.
local function createList()
    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", PADDING, LIST_TOP)
    list:SetPoint("BOTTOMRIGHT", -PADDING, LIST_BOTTOM)

    list.Inset = CreateFrame("Frame", nil, list, "InsetFrameTemplate")
    list.Inset:SetPoint("TOPLEFT", -3, 3)
    list.Inset:SetPoint("BOTTOMRIGHT", 3, -3)

    list.ScrollBox = CreateFrame("Frame", nil, list, "WowScrollBoxList")
    list.ScrollBox:SetPoint("TOPLEFT")
    list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, 0)

    list.ScrollBar = CreateFrame("EventFrame", nil, list, "MinimalScrollBar")
    list.ScrollBar:SetPoint("TOPLEFT", list.ScrollBox, "TOPRIGHT", 6, 0)
    list.ScrollBar:SetPoint("BOTTOMLEFT", list.ScrollBox, "BOTTOMRIGHT", 6, 0)
    return list
end

-- Preview ----------------------------------------------------------------------------------------

local list = createList()
panel.List = list

list.Empty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
list.Empty:SetPoint("LEFT", 12, 0)
list.Empty:SetPoint("RIGHT", -12, 0)
list.Empty:SetText(L["Nothing to send."])

---An item's row; createItemRow adds its regions the first time the row is used.
---@class FlagUp.MailItemRow: Frame
---@field Checkbox CheckButton
---@field Icon Texture
---@field IconHover Frame over the icon: the item's tooltip
---@field Name FontString
---@field Count FontString
---@field IgnoreButton Button
---@field item FlagUp.MailItem the item shown

---@param row FlagUp.MailItemRow
local function createItemRow(row)
    row.Checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    row.Checkbox:SetPoint("LEFT", 2, 0)
    row.Checkbox:SetScript("OnClick", function()
        if row.item.onToggle then row.item.onToggle() end
    end)
    -- Unchecked by the settings: why, and where to change it.
    row.Checkbox:SetScript("OnEnter", function(checkbox)
        if not row.item.uncheckedWhy then return end
        GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
        GameTooltip:SetText(row.item.uncheckedWhy, HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:AddLine(L["Check it to send it this time; Flag Up's settings change this."], nil, nil, nil, true)
        GameTooltip:Show()
    end)
    row.Checkbox:SetScript("OnLeave", GameTooltip_Hide)

    row.Icon = row:CreateTexture(nil, "ARTWORK")
    row.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.Icon:SetPoint("LEFT", row.Checkbox, "RIGHT", 2, 0)

    row.IconHover = CreateFrame("Frame", nil, row)
    row.IconHover:SetAllPoints(row.Icon)
    row.IconHover:SetScript("OnEnter", function(hover)
        GameTooltip:SetOwner(hover, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(row.item.itemID)
        GameTooltip:Show()
    end)
    row.IconHover:SetScript("OnLeave", GameTooltip_Hide)

    row.IgnoreButton = CreateFrame("Button", nil, row)
    row.IgnoreButton:SetSize(IGNORE_BUTTON_SIZE, IGNORE_BUTTON_SIZE)
    row.IgnoreButton:SetPoint("RIGHT", -8, 0)
    row.IgnoreButton:SetNormalTexture(IGNORE_TEXTURE)
    row.IgnoreButton:SetPushedTexture(IGNORE_TEXTURE_DOWN)
    row.IgnoreButton:SetHighlightTexture(IGNORE_TEXTURE, "ADD")
    row.IgnoreButton:SetScript("OnClick", function()
        if row.item.onIgnore then row.item.onIgnore() end
    end)
    row.IgnoreButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Ignore this item"], HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    row.IgnoreButton:SetScript("OnLeave", GameTooltip_Hide)

    row.Count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightRight")
    row.Count:SetPoint("RIGHT", row.IgnoreButton, "LEFT", -6, 0)

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
    row.item = item

    row.Checkbox:SetChecked(item.checked)
    row.Icon:SetTexture(item.icon)
    row.Icon:SetDesaturated(not item.checked)
    row.Name:SetText(item.name)
    row.Name:SetTextColor(item.color:GetRGB())
    row.Count:SetText(tostring(item.count))
    -- An unchecked item stays in the bags: its row is dimmed.
    local alpha = item.checked and 1 or DIMMED_ALPHA
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

-- Sending ----------------------------------------------------------------------------------------

local sendingList = createList()
sendingList:Hide()
panel.SendingList = sendingList

---An attachment's slot in a mail's row: its icon and count, its tooltip on hover.
---@class FlagUp.AttachmentSlot: Button
---@field Icon Texture
---@field Count FontString
---@field itemID integer?

---A mail's row; createMailRow adds its regions the first time the row is used.
---@class FlagUp.MailRow: Frame
---@field Title FontString
---@field Status FontString
---@field Spinner Frame turns while the mail is being sent
---@field Slots FlagUp.AttachmentSlot[]
---@field Error FontString

local STATUS_TEXTS = { sent = L["Sent"], sending = L["Sending…"], waiting = L["Waiting"], failed = L["Failed"],
    stopped = L["Stopped"] }
local STATUS_COLORS = { sent = GREEN_FONT_COLOR, sending = HIGHLIGHT_FONT_COLOR, waiting = GRAY_FONT_COLOR,
    failed = RED_FONT_COLOR, stopped = GRAY_FONT_COLOR }

---@param slot FlagUp.AttachmentSlot
local function showAttachmentTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(slot.itemID)
    GameTooltip:Show()
end

---@param row FlagUp.MailRow
local function createMailRow(row)
    row.Status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.Status:SetPoint("TOPRIGHT", -8, -4)

    -- The game's loading ring, as the auction house shows it; it turns while shown.
    row.Spinner = CreateFrame("Frame", nil, row, "SpinnerTemplate")
    row.Spinner:SetSize(SPINNER_SIZE, SPINNER_SIZE)
    row.Spinner:SetPoint("RIGHT", row.Status, "LEFT", -4, 0)

    row.Title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    row.Title:SetPoint("TOPLEFT", 8, -4)
    row.Title:SetPoint("RIGHT", row.Status, "LEFT", -8 - SPINNER_SIZE, 0)
    row.Title:SetWordWrap(false)

    -- One slot per attachment a mail can hold, in a row.
    row.Slots = {}
    for index = 1, ATTACHMENTS_MAX_SEND do
        local slot = CreateFrame("Button", nil, row) --[[@as FlagUp.AttachmentSlot]]
        slot:SetSize(ATTACHMENT_SIZE, ATTACHMENT_SIZE)
        local column = (index - 1) % ATTACHMENTS_PER_ROW
        local line = math.floor((index - 1) / ATTACHMENTS_PER_ROW)
        slot:SetPoint("TOPLEFT", 8 + column * (ATTACHMENT_SIZE + ATTACHMENT_GAP),
            -MAIL_TITLE_HEIGHT - 4 - line * (ATTACHMENT_SIZE + ATTACHMENT_GAP))
        slot.Icon = slot:CreateTexture(nil, "ARTWORK")
        slot.Icon:SetAllPoints()
        slot.Count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        slot.Count:SetPoint("BOTTOMRIGHT", 1, 0)
        slot:SetScript("OnEnter", showAttachmentTooltip)
        slot:SetScript("OnLeave", GameTooltip_Hide)
        row.Slots[index] = slot
    end

    row.Error = row:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    row.Error:SetPoint("RIGHT", -8, 0)
    row.Error:SetJustifyH("LEFT")
    row.Error:SetWordWrap(false)
end

---The height of a mail's attachments, on as many rows as they take.
---@param mail FlagUp.SendingMail
---@return number
local function attachmentsHeight(mail)
    local rows = math.max(1, math.ceil(#mail.attachments / ATTACHMENTS_PER_ROW))
    return rows * ATTACHMENT_SIZE + (rows - 1) * ATTACHMENT_GAP
end

---@param row FlagUp.MailRow
---@param mail FlagUp.SendingMail
local function initMailRow(row, mail)
    if not row.Title then createMailRow(row) end

    if mail.parts then
        row.Title:SetText(L["%s · %d of %d"]:format(mail.recipient, mail.part, mail.parts))
    else
        row.Title:SetText(mail.recipient)
    end
    row.Status:SetText(STATUS_TEXTS[mail.status])
    row.Status:SetTextColor(STATUS_COLORS[mail.status]:GetRGB())
    row.Spinner:SetShown(mail.status == "sending")

    for index, slot in ipairs(row.Slots) do
        local attachment = mail.attachments[index]
        slot:SetShown(attachment ~= nil)
        if attachment then
            slot.itemID = attachment.itemID
            slot.Icon:SetTexture(attachment.icon)
            slot.Count:SetText(attachment.count > 1 and tostring(attachment.count) or "")
        end
    end

    -- The error sits under the attachments' last row.
    row.Error:SetPoint("TOPLEFT", 8, -MAIL_TITLE_HEIGHT - 4 - attachmentsHeight(mail) - 4)
    row.Error:SetShown(mail.error ~= nil)
    row.Error:SetText(mail.error or "")

    -- A mail still waiting is dimmed; its status stays grey.
    local alpha = mail.status == "waiting" and DIMMED_ALPHA or 1
    row.Title:SetAlpha(alpha)
    for _, slot in ipairs(row.Slots) do slot:SetAlpha(alpha) end
end

local sendingView = CreateScrollBoxListLinearView()
sendingView:SetElementInitializer("Frame", initMailRow)
sendingView:SetElementExtentCalculator(function(_, mail)
    local height = MAIL_TITLE_HEIGHT + 4 + attachmentsHeight(mail) + MAIL_BOTTOM_PADDING
    return mail.error and height + MAIL_ERROR_HEIGHT or height
end)
ScrollUtil.InitScrollBoxListWithScrollBar(sendingList.ScrollBox, sendingList.ScrollBar, sendingView)

-- Footer -----------------------------------------------------------------------------------------

panel.SendButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.SendButton:SetText(L["Send"])
panel.SendButton:SetSize(math.max(BUTTON_WIDTH, panel.SendButton:GetTextWidth() + 24), BUTTON_HEIGHT)
panel.SendButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)

panel.StopButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.StopButton:SetText(L["Stop"])
panel.StopButton:SetSize(math.max(BUTTON_WIDTH, panel.StopButton:GetTextWidth() + 24), BUTTON_HEIGHT)
panel.StopButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
panel.StopButton:Hide()

-- Once the sending is over, back to the preview: what is left in the bags.
panel.BackButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.BackButton:SetText(BACK)
panel.BackButton:SetSize(math.max(BUTTON_WIDTH, panel.BackButton:GetTextWidth() + 24), BUTTON_HEIGHT)
panel.BackButton:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
panel.BackButton:Hide()

panel.Summary = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
panel.Summary:SetPoint("LEFT", panel, "BOTTOMLEFT", PADDING, PADDING + BUTTON_HEIGHT / 2)
panel.Summary:SetPoint("RIGHT", panel.SendButton, "LEFT", -8, 0)
panel.Summary:SetJustifyH("LEFT")

---@param mails integer
---@return string
local function mailCount(mails)
    return mails == 1 and L["1 mail"] or L["%d mails"]:format(mails)
end

---@type boolean the panel shows the sending view; false: the preview
local showingSending = false

---Shows what the mailbox would send.
---@param preview FlagUp.MailPreview
function panel:ShowPreview(preview)
    showingSending = false
    list:Show()
    sendingList:Hide()
    panel.SendButton:Show()
    panel.StopButton:Hide()
    panel.BackButton:Hide()

    local elements = {}
    for _, group in ipairs(preview.groups) do
        elements[#elements + 1] = { header = { kind = "category", name = group.recipient, mails = mailCount(group.mails) } }
        for _, item in ipairs(group.items) do
            elements[#elements + 1] = { item = item }
        end
    end
    list.ScrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
    list.Empty:SetShown(#elements == 0)

    -- The mail count, then the postage under it.
    panel.Summary:SetText(mailCount(preview.mails) .. "\n" .. L["Postage: %s"]:format(GetMoneyString(preview.postage)))
    panel.SendButton:SetEnabled(preview.mails > 0)
end

---Shows the mails being sent, in sending order.
---@param mails FlagUp.SendingMail[]
function panel:ShowSending(mails)
    showingSending = true
    list:Hide()
    sendingList:Show()
    panel.SendButton:Hide()
    panel.StopButton:Show()

    sendingList.ScrollBox:SetDataProvider(CreateDataProvider(mails), ScrollBoxConstants.RetainScrollPosition)

    local sent, failed = 0, 0
    for _, mail in ipairs(mails) do
        if mail.status == "sent" then
            sent = sent + 1
        elseif mail.status == "failed" then
            failed = failed + 1
        end
    end
    if failed > 0 then
        panel.Summary:SetText(L["%d of %d sent, %d failed"]:format(sent, #mails, failed))
    else
        panel.Summary:SetText(L["%d of %d sent"]:format(sent, #mails))
    end
    -- Once every mail is sent or failed, there is nothing left to stop.
    -- Stop while mails are left; Back once the sending is over.
    local left = false
    for _, mail in ipairs(mails) do
        if mail.status == "waiting" or mail.status == "sending" then left = true end
    end
    panel.StopButton:SetShown(left)
    panel.BackButton:SetShown(not left)
end

-- The preview from the bags --------------------------------------------------------------------

---@type table<integer, boolean> the items checked or unchecked by hand during this visit to the mailbox, by item ID
local choices = {}

---Whether an item goes: as checked or unchecked by hand this visit, else as the settings judge its worth.
---@param shipment FlagUp.Shipment
---@return boolean
local function isChecked(shipment)
    local choice = choices[shipment.itemID]
    if choice ~= nil then return choice end
    return ns.Mailing.UncheckReason(shipment) == nil
end

---Why the settings leave an item unchecked, as its checkbox's tooltip says it; nil when it goes, or was chosen by hand.
---@param shipment FlagUp.Shipment
---@return string?
local function uncheckedWhy(shipment)
    if choices[shipment.itemID] ~= nil then return nil end
    local reason = ns.Mailing.UncheckReason(shipment)
    if reason == "unpriced" then return L["Unchecked: a vendor won't buy it."] end
    if reason == "cheap" then
        local _, postage = ns.Mailing.MailsFor(#shipment.attachments)
        return L["Unchecked: worth %s, less than its postage, %s."]:format(
            GetMoneyString(ns.Mailing.Value(shipment)), GetMoneyString(postage))
    end
    return nil
end

-- Ignoring an item: by every character, or by the one being played; Cancel on the right. The game's popup places its
-- buttons in their order and calls OnCancel for the second one: Escape only closes it.
StaticPopupDialogs.FLAGUP_IGNORE_ITEM = {
    text = "%s",
    button1 = L["All characters"],
    button3 = CANCEL,
    -- The rules window shows the item ignored, and the panel without it.
    OnAccept = function(_, itemID)
        ns.Ignored.Add(itemID)
        ns.RulesWindow.Refresh()
    end,
    OnCancel = function(_, itemID)
        ns.Ignored.Add(itemID, ns.Characters.PlayerName())
        ns.RulesWindow.Refresh()
    end,
    noCancelOnEscape = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

---@param itemID integer
local function askToIgnore(itemID)
    StaticPopupDialogs.FLAGUP_IGNORE_ITEM.button2 = L["Only %s"]:format(ns.Characters.PlayerName())
    local name = C_Item.GetItemNameByID(itemID) or RETRIEVING_ITEM_INFO
    StaticPopup_Show("FLAGUP_IGNORE_ITEM", L["Ignore %s? It will no longer be offered at the mailbox."]:format(name), nil,
        itemID)
end

---What the bags would send, by recipient and item name; an unchecked item is listed but counts for no mail.
---@return FlagUp.MailPreview
local function mailPreview()
    ---@type table<string, FlagUp.MailGroup>
    local groupsByRecipient = {}
    ---@type table<string, integer> by recipient: the attachments of its checked items
    local attachments = {}

    for _, shipment in ipairs(ns.Mailing.Shipments()) do
        local recipient, itemID = shipment.recipient, shipment.itemID
        local group = groupsByRecipient[recipient]
        if not group then
            group = { recipient = recipient, mails = 0, items = {} }
            groupsByRecipient[recipient] = group
            attachments[recipient] = 0
        end

        local checked = isChecked(shipment)
        local quality = C_Item.GetItemQualityByID(itemID)
        table.insert(group.items, {
            itemID = itemID,
            name = C_Item.GetItemNameByID(itemID) or RETRIEVING_ITEM_INFO,
            icon = C_Item.GetItemIconByID(itemID),
            color = quality and ColorManager.GetColorDataForItemQuality(quality).color or WHITE_FONT_COLOR,
            count = shipment.count,
            checked = checked,
            onToggle = function()
                choices[itemID] = not checked
                MailPanel.Refresh()
            end,
            uncheckedWhy = uncheckedWhy(shipment),
            onIgnore = function() askToIgnore(itemID) end,
        })
        if checked then attachments[recipient] = attachments[recipient] + #shipment.attachments end
    end

    local preview = { groups = {}, mails = 0, postage = 0 }
    for recipient, group in pairs(groupsByRecipient) do
        local mails, postage = ns.Mailing.MailsFor(attachments[recipient])
        group.mails = mails
        table.sort(group.items, function(a, b) return a.name < b.name end)
        preview.groups[#preview.groups + 1] = group
        preview.mails = preview.mails + mails
        preview.postage = preview.postage + postage
    end
    table.sort(preview.groups, function(a, b) return a.recipient < b.recipient end)
    return preview
end

-- Sending --------------------------------------------------------------------------------------------

---The mails being sent, as the sending view shows them.
---@param parcels FlagUp.Parcel[]
---@return FlagUp.SendingMail[]
local function sendingMails(parcels)
    local mails = {}
    for _, parcel in ipairs(parcels) do
        local attachments = {}
        for _, attachment in ipairs(parcel.attachments) do
            attachments[#attachments + 1] = {
                itemID = attachment.itemID, icon = C_Item.GetItemIconByID(attachment.itemID), count = attachment.count,
            }
        end
        mails[#mails + 1] = {
            recipient = parcel.recipient, part = parcel.part, parts = parcel.parts, status = parcel.status,
            attachments = attachments, error = parcel.error,
        }
    end
    return mails
end

---Sends the checked items, mail by mail; the sending view follows each mail.
local function startSending()
    local shipments = {}
    for _, shipment in ipairs(ns.Mailing.Shipments()) do
        if isChecked(shipment) then shipments[#shipments + 1] = shipment end
    end
    table.sort(shipments, function(a, b) return a.itemID < b.itemID end)
    local parcels = ns.Mailing.Parcels(shipments)
    local function show() panel:ShowSending(sendingMails(parcels)) end
    show()
    ns.Mailing.Send(parcels, show)
end

panel.SendButton:SetScript("OnClick", startSending)

panel.StopButton:SetScript("OnClick", function() ns.Mailing.Stop() end)
panel.BackButton:SetScript("OnClick", function() panel:ShowPreview(mailPreview()) end)

---@type table<string, fun(): boolean> by the Send key setting: whether that key is held
local SEND_KEY_HELD = {
    SHIFT = IsShiftKeyDown,
    CTRL = IsControlKeyDown,
    ALT = IsAltKeyDown,
    NONE = function() return false end,
}

---Whether the mailbox sends as soon as it opens: with Send automatically on, unless the Send key is held; with it
---off, only while the Send key is held, as the game's auto loot key works.
---@return boolean
local function sendsAtOnce()
    local keyHeld = SEND_KEY_HELD[ns.settings.sendKey]() == true
    if ns.settings.sendAutomatically then return not keyHeld end
    return keyHeld
end

---Shows the panel beside the open mailbox. Call on MAIL_SHOW.
function MailPanel.Open()
    -- A child of the mailbox hides with it, however it is closed (Escape, walking away, its close button).
    panel:SetParent(MailFrame)
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", MAILBOX_GAP, 0)
    panel:SetPoint("BOTTOMLEFT", MailFrame, "BOTTOMRIGHT", MAILBOX_GAP, 0)
    choices = {}
    local preview = mailPreview()
    panel:ShowPreview(preview)
    panel:Show()
    if sendsAtOnce() and preview.mails > 0 then startSending() end
end

---Shows the preview again, while the panel is open. Call when the bags change.
function MailPanel.Refresh()
    if panel:IsShown() and not showingSending then panel:ShowPreview(mailPreview()) end
end

-- Skin -------------------------------------------------------------------------------------------

ns.Skin.Apply(function(S)
    S.Shell(panel)
    S.CloseButton(panel.CloseButton)
    for _, eachList in ipairs({ list, sendingList }) do
        S.Inset(eachList.Inset)
        S.ScrollBar(eachList.ScrollBar)
    end
    S.Button(panel.SendButton)
    S.Button(panel.StopButton)
    S.Button(panel.BackButton)
end)
