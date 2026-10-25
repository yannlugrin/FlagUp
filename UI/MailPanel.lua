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
---@field ruleCount integer how many the rules send; another count was set by hand
---@field bagCount integer how many the bags hold
---@field onAmount fun(count: integer?)? a count typed in its box; nil: the box emptied, back to the rules' count
---@field checked boolean unchecked: it stays in the bags this time
---@field onToggle fun()? a click on its checkbox
---@field uncheckedWhy string? unchecked by the settings, not by hand: why, for its checkbox's tooltip
---@field onIgnore fun()? a click on its Ignore button
---@field dropped boolean? dropped on its recipient during this visit: tagged "by hand", with a remove button in place
---of the Ignore button
---@field onRemove fun()? a click on its remove button
---@field droppedOn string? the rules send it to its recipient, but it was dropped on that other one: its count is 0,
---and its checkbox and count box are disabled

---A recipient and the items it gets, ready to show.
---@class FlagUp.MailGroup
---@field recipient string
---@field mails integer
---@field items FlagUp.MailItem[]
---@field onDrop fun(itemID: integer) an item dropped on its header or items, or below them when it is the last

---An alt with nothing to receive yet, shown as a tab beside the panel.
---@class FlagUp.MailAlt
---@field name string
---@field class string? its class file name, for its icon; nil until it logs in with Flag Up
---@field onDrop fun(itemID: integer) an item dropped on its tab

---What the mailbox would send, ready to show.
---@class FlagUp.MailPreview
---@field groups FlagUp.MailGroup[] empty: nothing to send
---@field alts FlagUp.MailAlt[] the known characters without a group, by name
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
local AMOUNT_WIDTH, AMOUNT_HEIGHT = 44, 20
local IGNORE_BUTTON_SIZE = 16
-- The game's loot Pass button, as the Ignore button.
local IGNORE_TEXTURE, IGNORE_TEXTURE_DOWN = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", "Interface\\Buttons\\UI-GroupLoot-Pass-Down"
-- The cross the Ignored tab takes an item back with, as the remove button.
local REMOVE_TEXTURE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local DROP_ERROR_HEIGHT = 14
local MAIL_TITLE_HEIGHT = 18
local SPINNER_SIZE = 16
local ATTACHMENT_SIZE, ATTACHMENT_GAP = 26, 2
-- As many as the row's width holds; a mail's twelve take two rows.
local ATTACHMENTS_PER_ROW = 9
local MAIL_ERROR_HEIGHT = 14
local MAIL_BOTTOM_PADDING = 8
local DIMMED_ALPHA = 0.5
-- The space around the list's hint under its items.
local HINT_PADDING = 4
-- The alt tabs: down the panel's right edge, below its title, the tab art's padding on the right.
local ALT_TABS_X, ALT_TABS_TOP, ALT_TAB_GAP = -2, -36, 0
-- As large as the community frame's tab icons; an icon file's own border trimmed off.
local ALT_TAB_ICON_SIZE = 34
local ICON_BORDER_TRIM = 0.07
local CLASS_ICONS_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local UNKNOWN_CLASS_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

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

-- How to add an item by hand, under the items; the items end above it, however many lines it takes.
list.Hint = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
list.Hint:SetPoint("BOTTOMLEFT", 6, HINT_PADDING)
list.Hint:SetPoint("RIGHT", -6, 0)
list.Hint:SetJustifyH("LEFT")
list.Hint:SetText(L["Drop an item on a recipient, or on the tab of an alt with nothing to receive yet, to add all of it in your bags to that alt's mail, this time only."])

---An item's row; createItemRow adds its regions the first time the row is used.
---@class FlagUp.MailItemRow: Frame
---@field Checkbox CheckButton
---@field Icon Texture
---@field IconHover Frame over the icon: the item's tooltip
---@field Name FontString
---@field Amount EditBox how many go, to change by hand
---@field IgnoreButton Button
---@field ByHand FontString "by hand", on an item dropped on its recipient
---@field RemoveButton Button in place of the Ignore button, on an item dropped on its recipient
---@field item FlagUp.MailItem the item shown

---@param row FlagUp.MailItemRow
local function createItemRow(row)
    row.Checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.Checkbox:SetSize(CHECKBOX_SIZE, CHECKBOX_SIZE)
    row.Checkbox:SetPoint("LEFT", 2, 0)
    -- Its tooltip shows while it is disabled too: why it can't be changed.
    row.Checkbox:SetMotionScriptsWhileDisabled(true)
    row.Checkbox:SetScript("OnClick", function()
        if row.item.onToggle then row.item.onToggle() end
    end)
    -- Dropped on another recipient: where it goes instead. Unchecked by the settings: why, and where to change it.
    row.Checkbox:SetScript("OnEnter", function(checkbox)
        local item = row.item
        if item.droppedOn then
            GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Dropped on %s: all of it goes there."]:format(ns.Characters.ShownName(item.droppedOn)),
                HIGHLIGHT_FONT_COLOR:GetRGB())
            GameTooltip:Show()
            return
        end
        if not item.uncheckedWhy then return end
        GameTooltip:SetOwner(checkbox, "ANCHOR_RIGHT")
        GameTooltip:SetText(item.uncheckedWhy, HIGHLIGHT_FONT_COLOR:GetRGB())
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

    row.RemoveButton = CreateFrame("Button", nil, row)
    row.RemoveButton:SetAllPoints(row.IgnoreButton)
    row.RemoveButton:SetNormalTexture(REMOVE_TEXTURE)
    row.RemoveButton:SetHighlightTexture(REMOVE_TEXTURE, "ADD")
    row.RemoveButton:SetScript("OnClick", function()
        if row.item.onRemove then row.item.onRemove() end
    end)
    row.RemoveButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Remove from this mail"], HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    row.RemoveButton:SetScript("OnLeave", GameTooltip_Hide)

    -- How many go: typed with Enter or on leaving the box; Escape puts the count back.
    row.Amount = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    row.Amount:SetSize(AMOUNT_WIDTH, AMOUNT_HEIGHT)
    row.Amount:SetPoint("RIGHT", row.IgnoreButton, "LEFT", -6, 0)
    row.Amount:SetNumeric(true)
    row.Amount:SetAutoFocus(false)
    row.Amount:SetJustifyH("RIGHT")
    row.Amount:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
    row.Amount:SetScript("OnEscapePressed", function(box)
        box:SetText(tostring(row.item.count))
        box:ClearFocus()
    end)
    row.Amount:SetScript("OnEditFocusLost", function(box)
        if not row.item.onAmount then return end
        local count = tonumber(box:GetText())
        if count == nil or count ~= row.item.count then row.item.onAmount(count) end
    end)
    -- How many the bags hold, and how many the rules keep, if any; set by hand: how many the rules would send.
    row.Amount:SetScript("OnEnter", function(box)
        local item = row.item
        local kept = item.bagCount - item.ruleCount
        local text
        if item.dropped or (item.count == item.ruleCount and kept == 0) then
            text = L["%d in the bags."]:format(item.bagCount)
        elseif item.count == item.ruleCount then
            text = L["%d in the bags, the rules keep %d."]:format(item.bagCount, kept)
        else
            text = L["%d in the bags, the rules send %d."]:format(item.bagCount, item.ruleCount)
        end
        GameTooltip:SetOwner(box, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:Show()
    end)
    row.Amount:SetScript("OnLeave", GameTooltip_Hide)

    row.ByHand = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.ByHand:SetPoint("RIGHT", row.Amount, "LEFT", -8, 0)
    row.ByHand:SetText(L["by hand"])

    row.Name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLeft")
    row.Name:SetPoint("LEFT", row.Icon, "RIGHT", 6, 0)
    row.Name:SetWordWrap(false)

    ns.Skin.Apply(function(S)
        S.Checkbox(row.Checkbox)
        row.Checkbox:SetSize(SKINNED_CHECKBOX_SIZE, SKINNED_CHECKBOX_SIZE)
        S.EditBox(row.Amount)
    end)
end

---@param row FlagUp.MailItemRow
---@param item FlagUp.MailItem
local function initItemRow(row, item)
    if not row.Name then createItemRow(row) end
    row.item = item

    row.Checkbox:SetChecked(item.checked)
    -- Dropped on another recipient: nothing to change here.
    row.Checkbox:SetEnabled(item.droppedOn == nil)
    if item.droppedOn then row.Amount:Disable() else row.Amount:Enable() end
    row.Icon:SetTexture(item.icon)
    row.Icon:SetDesaturated(not item.checked)
    row.Name:SetText(item.name)
    row.Name:SetTextColor(item.color:GetRGB())
    -- Dropped on its recipient: "by hand" after the name, and the remove button in place of the Ignore button.
    local dropped = item.dropped == true
    row.ByHand:SetShown(dropped)
    row.Name:SetPoint("RIGHT", dropped and row.ByHand or row.Amount, "LEFT", -8, 0)
    row.IgnoreButton:SetShown(not dropped)
    row.RemoveButton:SetShown(dropped)
    -- A count set by hand shows in gold; dropped on another recipient, in grey.
    if not row.Amount:HasFocus() then row.Amount:SetText(tostring(item.count)) end
    local countColor = item.count ~= item.ruleCount and NORMAL_FONT_COLOR or HIGHLIGHT_FONT_COLOR
    if item.droppedOn then countColor = GRAY_FONT_COLOR end
    row.Amount:SetTextColor(countColor:GetRGB())
    -- An unchecked item stays in the bags: its row is dimmed.
    local alpha = item.checked and 1 or DIMMED_ALPHA
    row.Icon:SetAlpha(alpha)
    row.Name:SetAlpha(alpha)
    row.ByHand:SetAlpha(alpha)
    row.Amount:SetAlpha(alpha)
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

---The drop handler of the recipient under the cursor: its header's or one of its items'; below the last row, the last
---recipient's. nil: the list is empty.
---@return fun(itemID: integer)?
local function dropUnderCursor()
    local found
    list.ScrollBox:ForEachFrame(function(frame, element)
        if frame:IsMouseOver() then found = element.onDrop end
    end)
    if found then return found end
    local provider = list.ScrollBox:GetDataProvider()
    local last = provider and provider:GetSize() > 0 and provider:Find(provider:GetSize())
    return last and last.onDrop or nil
end

-- While the cursor holds an item, the list takes it: dropped on a recipient's header or items, or below the last
-- recipient's, it goes to that recipient, whose header lights up while the item is over it.
local listDrop = ns.ItemDrop.Accept(list.ScrollBox, function(itemID)
    local onDrop = dropUnderCursor()
    if onDrop then onDrop(itemID) end
end)
if listDrop then
    ---@param onDrop fun(itemID: integer)? the recipient lit up; nil: none
    local function lightHeader(onDrop)
        list.ScrollBox:ForEachFrame(function(frame, element)
            if not element.header then return end
            if onDrop and element.onDrop == onDrop then frame:LockHighlight() else frame:UnlockHighlight() end
        end)
    end
    listDrop:SetScript("OnUpdate", function() lightHeader(listDrop:IsMouseOver() and dropUnderCursor() or nil) end)
    listDrop:SetScript("OnHide", function() lightHeader(nil) end)
end

-- Alt tabs ---------------------------------------------------------------------------------------

---A tab beside the panel: an alt with nothing to receive yet, to drop an item on.
---@class FlagUp.AltTab: Frame
---@field Icon Texture
---@field TabGlow Texture
---@field TabGlowAnimation AnimationGroup
---@field SetChecked fun(self: FlagUp.AltTab, checked: boolean)
---@field SetCustomOnMouseUpHandler fun(self: FlagUp.AltTab, handler: fun())
---@field alt FlagUp.MailAlt the alt shown

---@type FlagUp.AltTab[]
local altTabs = {}

---The tab at a place down the panel's edge, created the first time.
---@param index integer
---@return FlagUp.AltTab
local function altTab(index)
    if altTabs[index] then return altTabs[index] end
    local tab = CreateFrame("Frame", nil, panel, "LargeSideTabButtonTemplate") --[[@as FlagUp.AltTab]]
    tab:SetPoint("TOPLEFT", panel, "TOPRIGHT", ALT_TABS_X, ALT_TABS_TOP - (index - 1) * (tab:GetHeight() + ALT_TAB_GAP))
    tab:SetChecked(false)
    tab:EnableMouse(true)
    tab.Icon:SetSize(ALT_TAB_ICON_SIZE, ALT_TAB_ICON_SIZE)

    -- An item dropped on the tab, or clicked onto it, goes to its alt.
    local function drop()
        local kind, itemID = GetCursorInfo()
        if kind ~= "item" then return end
        ClearCursor()
        tab.alt.onDrop(itemID)
    end
    tab:SetScript("OnReceiveDrag", drop)
    tab:SetCustomOnMouseUpHandler(drop)

    -- The alt's name and what a drop does; the tab glows while an item is held over it.
    tab:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tab, "ANCHOR_RIGHT")
        GameTooltip:SetText(ns.Characters.ShownName(tab.alt.name), HIGHLIGHT_FONT_COLOR:GetRGB())
        GameTooltip:AddLine(L["Drop an item to add all of it in your bags to this alt's mail, this time only."], nil, nil,
            nil, true)
        GameTooltip:Show()
        if GetCursorInfo() == "item" then tab.TabGlowAnimation:Play() end
    end)
    tab:SetScript("OnLeave", function()
        GameTooltip_Hide()
        tab.TabGlowAnimation:Stop()
        tab.TabGlow:SetAlpha(0)
    end)

    altTabs[index] = tab
    return tab
end

---Shows a tab for each alt, as many as the panel's height holds; nil: none.
---@param alts FlagUp.MailAlt[]?
local function showAltTabs(alts)
    alts = alts or {}
    local fits = math.max(0, math.floor((panel:GetHeight() + ALT_TABS_TOP) / (altTab(1):GetHeight() + ALT_TAB_GAP)))
    for index = 1, math.max(#alts, #altTabs) do
        local alt = index <= fits and alts[index] or nil
        if alt then
            local tab = altTab(index)
            tab.alt = alt
            local coords = alt.class and CLASS_ICON_TCOORDS[alt.class]
            if coords then
                tab.Icon:SetTexture(CLASS_ICONS_TEXTURE)
                tab.Icon:SetTexCoord(unpack(coords))
            else
                tab.Icon:SetTexture(UNKNOWN_CLASS_ICON)
                tab.Icon:SetTexCoord(ICON_BORDER_TRIM, 1 - ICON_BORDER_TRIM, ICON_BORDER_TRIM, 1 - ICON_BORDER_TRIM)
            end
            tab:Show()
        elseif altTabs[index] then
            altTabs[index]:Hide()
        end
    end
end

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
        row.Title:SetText(L["%s · %d of %d"]:format(ns.Characters.ShownName(mail.recipient), mail.part, mail.parts))
    else
        row.Title:SetText(ns.Characters.ShownName(mail.recipient))
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

-- An item dropped that can't be mailed: why, in red, above the summary; the list makes room for it.
panel.DropError = panel:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
panel.DropError:SetPoint("BOTTOMLEFT", list, "BOTTOMLEFT", 0, -DROP_ERROR_HEIGHT - 4)
panel.DropError:SetPoint("RIGHT", -PADDING, 0)
panel.DropError:SetJustifyH("LEFT")
panel.DropError:Hide()

---@param text string? nil: none
local function showDropError(text)
    panel.DropError:SetText(text or "")
    panel.DropError:SetShown(text ~= nil)
    local bottom = text and LIST_BOTTOM + DROP_ERROR_HEIGHT + 4 or LIST_BOTTOM
    list:SetPoint("BOTTOMRIGHT", -PADDING, bottom)
end

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
        elements[#elements + 1] = {
            header = { kind = "category", name = ns.Characters.ShownName(group.recipient), mails = mailCount(group.mails) },
            onDrop = group.onDrop,
        }
        for _, item in ipairs(group.items) do
            elements[#elements + 1] = { item = item, onDrop = group.onDrop }
        end
    end
    list.ScrollBox:SetDataProvider(CreateDataProvider(elements), ScrollBoxConstants.RetainScrollPosition)
    list.Empty:SetShown(#elements == 0)
    list.ScrollBox:SetPoint("BOTTOMRIGHT", -SCROLL_BAR_SPACE, list.Hint:GetStringHeight() + 2 * HINT_PADDING)
    showAltTabs(preview.alts)

    -- The mail count, then the postage under it.
    panel.Summary:SetText(mailCount(preview.mails) .. "\n" .. L["Postage: %s"]:format(GetMoneyString(preview.postage)))
    panel.SendButton:SetEnabled(preview.mails > 0)
end

---Shows the mails being sent, in sending order.
---@param mails FlagUp.SendingMail[]
function panel:ShowSending(mails)
    showingSending = true
    list:Hide()
    showAltTabs(nil)
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
---@type table<integer, integer> the counts set by hand during this visit to the mailbox, by item ID
local amounts = {}
---@type table<integer, string> the items dropped on a recipient during this visit to the mailbox, by item ID: the
---recipient
local dropped = {}

---An item dropped on a recipient, its header or tab: it goes there, all of it, checked; one that can't be mailed is
---refused, in red.
---@param recipient string
---@param itemID integer
local function dropOn(recipient, itemID)
    if not ns.Mailing.Mailable(itemID) then
        showDropError(L["This item can't be mailed: it is bound or in an equipment set."])
        return
    end
    showDropError(nil)
    dropped[itemID], amounts[itemID], choices[itemID] = recipient, nil, true
    MailPanel.Refresh()
end

---Whether an item goes: as checked or unchecked by hand this visit, else as the settings judge its worth.
---@param shipment FlagUp.Shipment
---@return boolean
local function isChecked(shipment)
    if shipment.droppedOn then return false end
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
        local postage = ns.Mailing.Postage(#shipment.attachments)
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
    StaticPopupDialogs.FLAGUP_IGNORE_ITEM.button2 = L["Only %s"]:format(ns.Characters.ShownName(ns.Characters.PlayerName()))
    local name = C_Item.GetItemNameByID(itemID) or RETRIEVING_ITEM_INFO
    StaticPopup_Show("FLAGUP_IGNORE_ITEM", L["Ignore %s? It will no longer be offered at the mailbox."]:format(name), nil,
        itemID)
end

---What the bags would send, by recipient and item name; an unchecked item is listed but counts for no mail.
---@return FlagUp.MailPreview
local function mailPreview()
    ---@type table<string, FlagUp.MailGroup>
    local groupsByRecipient = {}
    ---@type FlagUp.Shipment[] the checked items: what goes
    local checkedShipments = {}

    for _, shipment in ipairs(ns.Mailing.Shipments(amounts, dropped)) do
        local recipient, itemID = shipment.recipient, shipment.itemID
        local group = groupsByRecipient[recipient]
        if not group then
            group = { recipient = recipient, mails = 0, items = {},
                onDrop = function(droppedID) dropOn(recipient, droppedID) end }
            groupsByRecipient[recipient] = group
        end

        local checked = isChecked(shipment)
        local quality = C_Item.GetItemQualityByID(itemID)
        table.insert(group.items, {
            itemID = itemID,
            name = C_Item.GetItemNameByID(itemID) or RETRIEVING_ITEM_INFO,
            icon = C_Item.GetItemIconByID(itemID),
            color = quality and ColorManager.GetColorDataForItemQuality(quality).color or WHITE_FONT_COLOR,
            count = shipment.count,
            ruleCount = shipment.ruleCount,
            droppedOn = shipment.droppedOn,
            bagCount = shipment.bagCount,
            -- A count typed goes, checked; 0 unchecks the item; an emptied box goes back to the rules' count.
            onAmount = function(count)
                if count == nil then
                    amounts[itemID] = nil
                elseif count <= 0 then
                    amounts[itemID], choices[itemID] = nil, false
                else
                    amounts[itemID], choices[itemID] = count, true
                end
                MailPanel.Refresh()
            end,
            checked = checked,
            onToggle = function()
                choices[itemID] = not checked
                MailPanel.Refresh()
            end,
            uncheckedWhy = not shipment.droppedOn and uncheckedWhy(shipment) or nil,
            onIgnore = function() askToIgnore(itemID) end,
            dropped = shipment.dropped,
            -- Back to what the rules do with it.
            onRemove = function()
                dropped[itemID], amounts[itemID], choices[itemID] = nil, nil, nil
                MailPanel.Refresh()
            end,
        })
        if checked then checkedShipments[#checkedShipments + 1] = shipment end
    end

    -- The mails, as they will go.
    local parcels = ns.Mailing.Parcels(checkedShipments)
    local preview = { groups = {}, alts = {}, mails = #parcels, postage = 0 }
    for _, parcel in ipairs(parcels) do
        groupsByRecipient[parcel.recipient].mails = groupsByRecipient[parcel.recipient].mails + 1
        preview.postage = preview.postage + ns.Mailing.Postage(#parcel.attachments)
    end
    for _, group in pairs(groupsByRecipient) do
        table.sort(group.items, function(a, b) return a.name < b.name end)
        preview.groups[#preview.groups + 1] = group
    end
    table.sort(preview.groups, function(a, b) return a.recipient < b.recipient end)

    -- The known characters this one can mail that have nothing to receive yet: a tab each, by name.
    local player = ns.Characters.PlayerName()
    for _, name in ipairs(ns.Characters.KnownNames()) do
        if not groupsByRecipient[name] and ns.Characters.CanMail(player, name) then
            preview.alts[#preview.alts + 1] = {
                name = name, class = ns.Characters.Class(name),
                onDrop = function(itemID) dropOn(name, itemID) end,
            }
        end
    end
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
    for _, shipment in ipairs(ns.Mailing.Shipments(amounts, dropped)) do
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
    choices, amounts, dropped = {}, {}, {}
    showDropError(nil)
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
