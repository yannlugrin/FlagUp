local _, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---What the bags hold that the rules send, and how it goes into mail.
---@class FlagUp.Mailing
local Mailing = {}
ns.Mailing = Mailing

-- The game's postage: 30 copper per attachment.
local POSTAGE_PER_ATTACHMENT = 30
-- The last bag read: every equipped bag, the fifth slot included (bag 5, retail's reagent bag, which takes any item
-- on Forever); a client without it stops at the fourth bag.
local LAST_BAG = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS

---A stack in the bags.
---@class FlagUp.BagStack
---@field bag integer
---@field slot integer
---@field count integer

---A stack to attach to a mail, whole or a part split from it.
---@class FlagUp.Attachment: FlagUp.BagStack
---@field itemID integer
---@field split boolean only `count` of the stack goes: it is split onto the cursor, then attached

---An item the rules send, with how much and from which stacks.
---@class FlagUp.Shipment
---@field itemID integer
---@field recipient string
---@field count integer how many go: as the rules say, or as set by hand
---@field ruleCount integer how many the rules send
---@field bagCount integer how many the bags hold
---@field attachments FlagUp.Attachment[]
---@field sellPrice integer what a vendor pays for one, in copper; 0: a vendor won't buy it

---Whether a bag slot holds an item of an equipment set: it stays with the character.
---@param bag integer
---@param slot integer
---@return boolean
local function inEquipmentSet(bag, slot)
    if not C_Container.GetContainerItemEquipmentSetInfo then return false end
    return (C_Container.GetContainerItemEquipmentSetInfo(bag, slot)) == true
end

---The stacks the bags hold of each item, left out: bound ones, which can't be mailed, and those of an equipment set.
---@return table<integer, FlagUp.BagStack[]> by item ID
local function bagStacks()
    local stacks = {}
    for bag = BACKPACK_CONTAINER, LAST_BAG do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and not info.isBound and not inEquipmentSet(bag, slot) then
                stacks[info.itemID] = stacks[info.itemID] or {}
                table.insert(stacks[info.itemID], { bag = bag, slot = slot, count = info.stackCount })
            end
        end
    end
    return stacks
end

---How much of an item goes, for the character being played: the bags' total less Keep, rounded down to full stacks
---when only full stacks go. 0: nothing.
---@param place FlagUp.LinePlace
---@param character string
---@param total integer
---@param stackSize integer
---@return integer
local function amountToSend(place, character, total, stackSize)
    local amount = total - ns.Rules.Value(place, "keep", character)
    if amount <= 0 then return 0 end
    if stackSize > 1 and ns.Rules.Value(place, "fullStacksOnly", character) then
        amount = math.floor(amount / stackSize) * stackSize
    end
    return amount
end

---Whether the item's quality passes the qualities a line sets, on Armor and Weapon; none selected: every quality.
---@param place FlagUp.LinePlace
---@param character string
---@param quality integer
---@return boolean
local function qualityPasses(place, character, quality)
    if place.classID ~= Enum.ItemClass.Armor and place.classID ~= Enum.ItemClass.Weapon then return true end
    local qualities = ns.Rules.Value(place, "qualities", character)
    return next(qualities) == nil or qualities[quality] == true
end

---The stacks that make up an amount: whole stacks, largest first, while they fit; then the rest split from a larger
---stack.
---@param itemID integer
---@param stacks FlagUp.BagStack[]
---@param amount integer
---@return FlagUp.Attachment[]
local function attachmentsFor(itemID, stacks, amount)
    table.sort(stacks, function(a, b) return a.count > b.count end)
    local attachments, remaining, used = {}, amount, {}
    for index, stack in ipairs(stacks) do
        if remaining == 0 then break end
        if stack.count <= remaining then
            attachments[#attachments + 1] = {
                itemID = itemID, bag = stack.bag, slot = stack.slot, count = stack.count, split = false,
            }
            remaining = remaining - stack.count
            used[index] = true
        end
    end
    -- Every stack left is larger than what remains: the smallest of them gives it.
    for index = #stacks, 1, -1 do
        if remaining == 0 then break end
        if not used[index] then
            local stack = stacks[index]
            attachments[#attachments + 1] = {
                itemID = itemID, bag = stack.bag, slot = stack.slot, count = remaining, split = true,
            }
            remaining = 0
        end
    end
    return attachments
end

---What the rules send from the bags, for the character being played, item by item; ignored items are left out. An
---amount set by hand replaces the rules' (Keep and Full stacks only included), up to what the bags hold.
---@param amounts table<integer, integer>? by item ID: how many go, set by hand
---@return FlagUp.Shipment[]
function Mailing.Shipments(amounts)
    local character = ns.Characters.PlayerName()
    local shipments = {}
    for itemID, stacks in pairs(bagStacks()) do
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        local _, _, quality, _, _, _, _, stackSize, _, _, sellPrice = C_Item.GetItemInfo(itemID)
        if classID and quality and not ns.Ignored.IsIgnored(itemID, character) then
            local place = { classID = classID, subClassID = subClassID, itemID = itemID }
            local recipient = ns.Rules.Value(place, "sendTo", character)
            if recipient and qualityPasses(place, character, quality) then
                local total = 0
                for _, stack in ipairs(stacks) do total = total + stack.count end
                local ruleAmount = amountToSend(place, character, total, stackSize)
                local amount = ruleAmount
                if amounts and amounts[itemID] then amount = math.min(amounts[itemID], total) end
                if amount > 0 then
                    shipments[#shipments + 1] = {
                        itemID = itemID, recipient = recipient, count = amount, ruleCount = ruleAmount, bagCount = total,
                        attachments = attachmentsFor(itemID, stacks, amount), sellPrice = sellPrice or 0,
                    }
                end
            end
        end
    end
    return shipments
end

---Why the settings leave a shipment unchecked: with Uncheck unsellable items on, a vendor won't buy it ("unpriced");
---with Uncheck cheap items on, its vendor value is below the postage of its stacks ("cheap"). nil: it goes.
---@param shipment FlagUp.Shipment
---@return "cheap"|"unpriced"|nil
function Mailing.UncheckReason(shipment)
    if shipment.sellPrice == 0 then return ns.settings.uncheckUnpriced and "unpriced" or nil end
    if ns.settings.uncheckCheap and Mailing.Value(shipment) < #shipment.attachments * POSTAGE_PER_ATTACHMENT then
        return "cheap"
    end
    return nil
end

---What a vendor pays for a shipment, in copper.
---@param shipment FlagUp.Shipment
---@return integer
function Mailing.Value(shipment)
    return shipment.sellPrice * shipment.count
end

---How many mails a number of attachments takes, and their postage in copper.
---@param attachments integer
---@return integer mails
---@return integer postage
function Mailing.MailsFor(attachments)
    return math.ceil(attachments / ATTACHMENTS_MAX_SEND), attachments * POSTAGE_PER_ATTACHMENT
end

-- Sending ----------------------------------------------------------------------------------------

---A mail to send, and how its sending went.
---@class FlagUp.Parcel
---@field recipient string
---@field part integer? with several mails to the recipient: which one this is
---@field parts integer? with several mails to the recipient: how many
---@field attachments FlagUp.Attachment[]
---@field status "waiting"|"sending"|"sent"|"failed"|"stopped"
---@field error string? on a failed mail: why

-- How long to wait for the server's answer to a mail, in seconds.
local ANSWER_TIMEOUT = 15
-- How long to wait after a mail's answer before starting the next one, in seconds: the game is still finishing the
-- mail answered (it resets its send mail on the same event), and ignores a mail sent at once.
local NEXT_MAIL_DELAY = 1

---The mails that carry shipments: by recipient, at most ATTACHMENTS_MAX_SEND attachments each, items in the order
---given.
---@param shipments FlagUp.Shipment[]
---@return FlagUp.Parcel[]
function Mailing.Parcels(shipments)
    ---@type table<string, FlagUp.Attachment[]>
    local byRecipient = {}
    local recipients = {}
    for _, shipment in ipairs(shipments) do
        if not byRecipient[shipment.recipient] then
            byRecipient[shipment.recipient] = {}
            recipients[#recipients + 1] = shipment.recipient
        end
        for _, attachment in ipairs(shipment.attachments) do
            table.insert(byRecipient[shipment.recipient], attachment)
        end
    end
    table.sort(recipients)

    local parcels = {}
    for _, recipient in ipairs(recipients) do
        local attachments = byRecipient[recipient]
        local parts = Mailing.MailsFor(#attachments)
        for part = 1, parts do
            local parcel = { recipient = recipient, attachments = {}, status = "waiting" }
            if parts > 1 then parcel.part, parcel.parts = part, parts end
            for index = (part - 1) * ATTACHMENTS_MAX_SEND + 1, math.min(part * ATTACHMENTS_MAX_SEND, #attachments) do
                parcel.attachments[#parcel.attachments + 1] = attachments[index]
            end
            parcels[#parcels + 1] = parcel
        end
    end
    return parcels
end

---The sending under way.
---@class FlagUp.Sending
---@field parcels FlagUp.Parcel[]
---@field onChange fun() after each change of a mail's status
---@field current FlagUp.Parcel? the mail waiting for the server's answer
---@field stopping boolean? no mail is started after the current one
---@field lastError string? the game's last error message while the current mail was sent

---@type FlagUp.Sending?
local sending

local events = CreateFrame("Frame")

---Puts a mail's stacks into the game's send mail: whole stacks picked up, part stacks split onto the cursor.
---@param parcel FlagUp.Parcel
---@return string? error why the mail can't go
local function attach(parcel)
    ClearSendMail()
    for index, attachment in ipairs(parcel.attachments) do
        local info = C_Container.GetContainerItemInfo(attachment.bag, attachment.slot)
        if not info or info.itemID ~= attachment.itemID or info.stackCount < attachment.count then
            return L["An item to send has moved in the bags."]
        end
        if attachment.split then
            C_Container.SplitContainerItem(attachment.bag, attachment.slot, attachment.count)
        else
            C_Container.PickupContainerItem(attachment.bag, attachment.slot)
        end
        ClickSendMailItemButton(index)
        if CursorHasItem() then
            ClearCursor()
            return L["An item could not be attached."]
        end
    end
    return nil
end

---The next mail to send: the first one not answered yet. It may already show as being sent, while the queue waits
---before starting it.
---@return FlagUp.Parcel?
local function nextToSend()
    for _, parcel in ipairs(sending.parcels) do
        if parcel.status == "waiting" or parcel.status == "sending" then return parcel end
    end
    return nil
end

---Ends the sending: the mails left are stopped.
local function finishSending()
    for _, parcel in ipairs(sending.parcels) do
        if parcel.status == "waiting" or parcel.status == "sending" then parcel.status = "stopped" end
    end
    events:UnregisterAllEvents()
    local onChange = sending.onChange
    sending = nil
    onChange()
end

---Starts the mails waiting, one after the other, until one is sent to the server: its answer starts the next one.
---A mail that can't be put together fails at once, and the next one starts.
local function startNextMail()
    local parcel = nextToSend()
    while parcel and not sending.stopping do
        parcel.status = "sending"
        sending.onChange()
        local error = attach(parcel)
        if not error then
            sending.current, sending.lastError = parcel, nil
            SendMail(parcel.recipient, L["Flag Up parcel"], "")
            C_Timer.After(ANSWER_TIMEOUT, function()
                if sending and sending.current == parcel then
                    sending.current = nil
                    parcel.status, parcel.error = "failed", L["No answer from the server."]
                    ClearSendMail()
                    sending.onChange()
                    startNextMail()
                end
            end)
            return
        end
        parcel.status, parcel.error = "failed", error
        ClearSendMail()
        sending.onChange()
        parcel = nextToSend()
    end
    finishSending()
end

---The server's answer to the current mail: it is sent, or failed with the game's error; the next one starts.
---@param status "sent"|"failed"
---@param error string?
local function answered(status, error)
    local parcel = sending.current
    if not parcel then return end
    sending.current = nil
    parcel.status, parcel.error = status, error
    if status == "failed" then ClearSendMail() end
    -- The next mail shows as being sent from now: the wait before it is part of its sending.
    local upcoming = not sending.stopping and nextToSend()
    if upcoming then upcoming.status = "sending" end
    sending.onChange()
    C_Timer.After(NEXT_MAIL_DELAY, function()
        if sending then startNextMail() end
    end)
end

events:SetScript("OnEvent", function(_, event, ...)
    if event == "MAIL_SEND_SUCCESS" then
        answered("sent")
    elseif event == "MAIL_FAILED" then
        answered("failed", sending.lastError or L["The mail could not be sent."])
    elseif event == "UI_ERROR_MESSAGE" then
        -- The error's type, then its message.
        local _, message = ...
        if sending.current then sending.lastError = message end
    elseif event == "MAIL_CLOSED" then
        sending.stopping = true
    end
end)

---Sends the mails one after the other: each waits for the server's answer before the next starts; a failed mail
---keeps the game's error, and the next one goes.
---@param parcels FlagUp.Parcel[]
---@param onChange fun() after each change of a mail's status
function Mailing.Send(parcels, onChange)
    if sending then return end
    sending = { parcels = parcels, onChange = onChange }
    for _, event in ipairs({ "MAIL_SEND_SUCCESS", "MAIL_FAILED", "UI_ERROR_MESSAGE", "MAIL_CLOSED" }) do
        -- Forever throws on registering an event it doesn't know.
        if C_EventUtils.IsEventValid(event) then events:RegisterEvent(event) end
    end
    startNextMail()
end

---No mail is started after the one being sent.
function Mailing.Stop()
    if sending then sending.stopping = true end
end
