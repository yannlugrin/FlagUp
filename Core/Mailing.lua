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
---@field split boolean only `count` of the stack goes: it is split into a free bag slot, then attached from there

---An item the rules send, with how much and from which stacks.
---@class FlagUp.Shipment
---@field itemID integer
---@field recipient string
---@field count integer how many go: as the rules say, or as set by hand
---@field ruleCount integer how many the rules send; dropped on a recipient: all the bags hold
---@field bagCount integer how many the bags hold
---@field dropped boolean? dropped on a recipient at the mailbox: it goes there, whatever the rules
---@field droppedOn string? the rules send it here, but it was dropped on that other recipient: none goes here
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

---Whether the bags hold some of an item that can be mailed: not bound, not of an equipment set.
---@param itemID integer
---@return boolean
function Mailing.Mailable(itemID)
    return bagStacks()[itemID] ~= nil
end

---What the rules send from the bags, for the character being played, item by item; ignored items are left out. An
---amount set by hand replaces the rules' (Keep and Full stacks only included), up to what the bags hold. An item
---dropped on a recipient goes there, all of it, whatever the rules and even ignored; when the rules send it to
---another recipient, that one keeps its shipment, at 0.
---@param amounts table<integer, integer>? by item ID: how many go, set by hand
---@param dropped table<integer, string>? by item ID: the recipient it was dropped on
---@return FlagUp.Shipment[]
function Mailing.Shipments(amounts, dropped)
    local character = ns.Characters.PlayerName()
    local shipments = {}
    for itemID, stacks in pairs(bagStacks()) do
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        local _, _, quality, _, _, _, _, stackSize, _, _, sellPrice = C_Item.GetItemInfo(itemID)
        local total = 0
        for _, stack in ipairs(stacks) do total = total + stack.count end

        local ruleRecipient, ruleAmount
        if classID and quality and not ns.Ignored.IsIgnored(itemID, character) then
            local place = { classID = classID, subClassID = subClassID, itemID = itemID }
            ruleRecipient = ns.Rules.Value(place, "sendTo", character)
            if ruleRecipient and qualityPasses(place, character, quality) then
                ruleAmount = amountToSend(place, character, total, stackSize)
            end
        end

        local droppedOn = dropped and dropped[itemID]
        local recipient, fullAmount = ruleRecipient, ruleAmount
        if droppedOn then recipient, fullAmount = droppedOn, total end
        if fullAmount then
            local amount = fullAmount
            if amounts and amounts[itemID] then amount = math.min(amounts[itemID], total) end
            if amount > 0 then
                shipments[#shipments + 1] = {
                    itemID = itemID, recipient = recipient, count = amount, ruleCount = fullAmount, bagCount = total,
                    dropped = droppedOn and true or nil,
                    attachments = attachmentsFor(itemID, stacks, amount), sellPrice = sellPrice or 0,
                }
            end
        end
        if droppedOn and ruleAmount and ruleAmount > 0 and ruleRecipient ~= droppedOn then
            shipments[#shipments + 1] = {
                itemID = itemID, recipient = ruleRecipient, count = 0, ruleCount = ruleAmount, bagCount = total,
                droppedOn = droppedOn, attachments = {}, sellPrice = sellPrice or 0,
            }
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

---The postage of a number of attachments, in copper.
---@param attachments integer
---@return integer
function Mailing.Postage(attachments)
    return attachments * POSTAGE_PER_ATTACHMENT
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

---The free slots of the bags that take any item: the backpack and the plain bags.
---@return integer
local function freeSlotCount()
    local count = 0
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local free, family = C_Container.GetContainerNumFreeSlots(bag)
        if family == 0 then count = count + free end
    end
    return count
end

---A free slot of a bag that takes any item.
---@return integer? bag nil: none
---@return integer? slot
local function freeSlot()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        local _, family = C_Container.GetContainerNumFreeSlots(bag)
        if family == 0 then
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                if not C_Container.GetContainerItemInfo(bag, slot) then return bag, slot end
            end
        end
    end
    return nil, nil
end

---The mails that carry shipments, at most ATTACHMENTS_MAX_SEND attachments each, by recipient, items in the order
---given. A part stack is split into a free slot until its mail is sent, so a mail takes as many part stacks as there
---are free slots, and whole stacks with them; a sent mail frees the slots of its whole stacks. Part stacks with no free
---slot wait for the mails after, every recipient's; with none freed by then, their mails fail.
---@param shipments FlagUp.Shipment[]
---@return FlagUp.Parcel[]
function Mailing.Parcels(shipments)
    ---@type table<string, FlagUp.Attachment[]> by recipient
    local wholeStacks, partStacks = {}, {}
    local recipients = {}
    for _, shipment in ipairs(shipments) do
        local recipient = shipment.recipient
        if not wholeStacks[recipient] then
            wholeStacks[recipient], partStacks[recipient] = {}, {}
            recipients[#recipients + 1] = recipient
        end
        for _, attachment in ipairs(shipment.attachments) do
            table.insert(attachment.split and partStacks[recipient] or wholeStacks[recipient], attachment)
        end
    end
    table.sort(recipients)

    local parcels = {}
    local free = freeSlotCount()
    ---A recipient's mails: each takes as many part stacks as there are free slots, then whole stacks up to the limit.
    ---With `force`, part stacks go even with no free slot (their mails fail). The part stacks left wait.
    ---@param recipient string
    ---@param force boolean?
    local function addMails(recipient, force)
        local wholes, parts = wholeStacks[recipient], partStacks[recipient]
        while #wholes > 0 or (#parts > 0 and (free > 0 or force)) do
            local parcel = { recipient = recipient, attachments = {}, status = "waiting" }
            local partCount = math.min(#parts, ATTACHMENTS_MAX_SEND, force and ATTACHMENTS_MAX_SEND or free)
            for _ = 1, partCount do table.insert(parcel.attachments, table.remove(parts, 1)) end
            local wholeCount = math.min(#wholes, ATTACHMENTS_MAX_SEND - partCount)
            for _ = 1, wholeCount do table.insert(parcel.attachments, table.remove(wholes, 1)) end
            free = free + wholeCount
            parcels[#parcels + 1] = parcel
        end
    end

    for _, recipient in ipairs(recipients) do addMails(recipient) end
    -- The part stacks that waited, once every whole stack is sent; with no free slot then, their mails fail.
    for _, recipient in ipairs(recipients) do addMails(recipient, free == 0) end

    -- With several mails to a recipient: which one each is, in sending order.
    local counts, seen = {}, {}
    for _, parcel in ipairs(parcels) do counts[parcel.recipient] = (counts[parcel.recipient] or 0) + 1 end
    for _, parcel in ipairs(parcels) do
        if counts[parcel.recipient] > 1 then
            seen[parcel.recipient] = (seen[parcel.recipient] or 0) + 1
            parcel.part, parcel.parts = seen[parcel.recipient], counts[parcel.recipient]
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

-- How often to look whether a part stack has reached its free slot, and for how long, in seconds.
local SPLIT_CHECK_INTERVAL, SPLIT_TIMEOUT = 0.1, 5

---Splits a part stack into a free bag slot: the game attaches a whole stack from the cursor, never a part of it.
---Calls `done` once the part has landed there, unlocked, with the whole stack it makes; or with why it can't.
---@param attachment FlagUp.Attachment
---@param done fun(stack: FlagUp.Attachment?, error: string?)
local function splitIntoFreeSlot(attachment, done)
    local bag, slot = freeSlot()
    if not bag then return done(nil, L["No free bag slot to split a stack."]) end
    C_Container.SplitContainerItem(attachment.bag, attachment.slot, attachment.count)
    C_Container.PickupContainerItem(bag, slot)
    if CursorHasItem() then
        ClearCursor()
        return done(nil, L["A stack could not be split."])
    end

    local waited = 0
    local function check()
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID == attachment.itemID and info.stackCount == attachment.count and not info.isLocked then
            return done({ itemID = attachment.itemID, bag = bag, slot = slot, count = attachment.count, split = false })
        end
        waited = waited + SPLIT_CHECK_INTERVAL
        if waited >= SPLIT_TIMEOUT then return done(nil, L["A stack could not be split."]) end
        C_Timer.After(SPLIT_CHECK_INTERVAL, check)
    end
    check()
end

---Puts a mail's stacks into the game's send mail: part stacks are split into free slots first, then every stack is
---picked up whole and attached. Calls `done` once attached, or with why the mail can't go.
---@param parcel FlagUp.Parcel
---@param done fun(error: string?)
local function attach(parcel, done)
    ClearSendMail()
    for _, attachment in ipairs(parcel.attachments) do
        local info = C_Container.GetContainerItemInfo(attachment.bag, attachment.slot)
        if not info or info.itemID ~= attachment.itemID or info.stackCount < attachment.count then
            return done(L["An item to send has moved in the bags."])
        end
    end

    local function attachAll()
        for index, attachment in ipairs(parcel.attachments) do
            C_Container.PickupContainerItem(attachment.bag, attachment.slot)
            ClickSendMailItemButton(index)
            if CursorHasItem() then
                ClearCursor()
                return done(L["An item could not be attached."])
            end
        end
        done(nil)
    end

    -- The part stacks one after the other: each becomes the whole stack it makes in its free slot.
    local function splitFrom(index)
        local attachment = parcel.attachments[index]
        if not attachment then return attachAll() end
        if not attachment.split then return splitFrom(index + 1) end
        splitIntoFreeSlot(attachment, function(stack, error)
            if not stack then return done(error) end
            parcel.attachments[index] = stack
            splitFrom(index + 1)
        end)
    end
    splitFrom(1)
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

---Starts the next mail waiting, once its stacks are attached, and sends it to the server: its answer starts the next
---one. A mail that can't be put together fails at once, and the next one starts.
local function startNextMail()
    local parcel = nextToSend()
    if not parcel or sending.stopping then return finishSending() end
    parcel.status = "sending"
    sending.onChange()
    attach(parcel, function(error)
        if not sending then return end
        if error then
            parcel.status, parcel.error = "failed", error
            ClearSendMail()
            sending.onChange()
            return startNextMail()
        end
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
    end)
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
