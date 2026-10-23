local _, ns = ...
---@cast ns FlagUp.Namespace

---What the bags hold that the rules send, and how it goes into mail.
---@class FlagUp.Mailing
local Mailing = {}
ns.Mailing = Mailing

-- The game's postage: 30 copper per attachment.
local POSTAGE_PER_ATTACHMENT = 30

---A stack in the bags.
---@class FlagUp.BagStack
---@field bag integer
---@field slot integer
---@field count integer

---A stack to attach to a mail, whole or a part split from it.
---@class FlagUp.Attachment: FlagUp.BagStack
---@field split boolean only `count` of the stack goes: it is split first, into a free bag slot

---An item the rules send, with how much and from which stacks.
---@class FlagUp.Shipment
---@field itemID integer
---@field recipient string
---@field count integer
---@field attachments FlagUp.Attachment[]

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
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
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
---@param stacks FlagUp.BagStack[]
---@param amount integer
---@return FlagUp.Attachment[]
local function attachmentsFor(stacks, amount)
    table.sort(stacks, function(a, b) return a.count > b.count end)
    local attachments, remaining, used = {}, amount, {}
    for index, stack in ipairs(stacks) do
        if remaining == 0 then break end
        if stack.count <= remaining then
            attachments[#attachments + 1] = { bag = stack.bag, slot = stack.slot, count = stack.count, split = false }
            remaining = remaining - stack.count
            used[index] = true
        end
    end
    -- Every stack left is larger than what remains: the smallest of them gives it.
    for index = #stacks, 1, -1 do
        if remaining == 0 then break end
        if not used[index] then
            local stack = stacks[index]
            attachments[#attachments + 1] = { bag = stack.bag, slot = stack.slot, count = remaining, split = true }
            remaining = 0
        end
    end
    return attachments
end

---What the rules send from the bags, for the character being played, item by item.
---@return FlagUp.Shipment[]
function Mailing.Shipments()
    local character = ns.Characters.PlayerName()
    local shipments = {}
    for itemID, stacks in pairs(bagStacks()) do
        local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        local _, _, quality, _, _, _, _, stackSize = C_Item.GetItemInfo(itemID)
        if classID and quality then
            local place = { classID = classID, subClassID = subClassID, itemID = itemID }
            local recipient = ns.Rules.Value(place, "sendTo", character)
            if recipient and qualityPasses(place, character, quality) then
                local total = 0
                for _, stack in ipairs(stacks) do total = total + stack.count end
                local amount = amountToSend(place, character, total, stackSize)
                if amount > 0 then
                    shipments[#shipments + 1] = {
                        itemID = itemID, recipient = recipient, count = amount,
                        attachments = attachmentsFor(stacks, amount),
                    }
                end
            end
        end
    end
    return shipments
end

---How many mails a number of attachments takes, and their postage in copper.
---@param attachments integer
---@return integer mails
---@return integer postage
function Mailing.MailsFor(attachments)
    return math.ceil(attachments / ATTACHMENTS_MAX_SEND), attachments * POSTAGE_PER_ATTACHMENT
end
