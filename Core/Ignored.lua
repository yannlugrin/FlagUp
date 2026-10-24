local _, ns = ...
---@cast ns FlagUp.Namespace

---The items never offered at the mailbox, whatever the rules: ignored by every character of the household being
---played, or by one.
---@class FlagUp.Ignored
local Ignored = {}
ns.Ignored = Ignored

---The ignored items of a household.
---@class FlagUp.IgnoredItems
---@field all table<integer, true> by item ID: ignored by every character
---@field characters table<string, table<integer, true>> by name, then item ID: ignored by that character

---The ignored items, created with the first one.
---@return FlagUp.IgnoredItems
local function ignoredItems()
    local household = ns.Characters.PlayerHousehold()
    if not household.ignored then household.ignored = { all = {}, characters = {} } end
    return household.ignored
end

---Whether every character ignores an item.
---@param itemID integer
---@return boolean
function Ignored.IsIgnoredByAll(itemID)
    return ignoredItems().all[itemID] == true
end

---Whether a character ignores an item for itself, apart from every character ignoring it.
---@param itemID integer
---@param character string
---@return boolean
function Ignored.IsIgnoredBy(itemID, character)
    local own = ignoredItems().characters[character]
    return own ~= nil and own[itemID] == true
end

---Whether a character ignores an item: ignored by every character, or by this one.
---@param itemID integer
---@param character string
---@return boolean
function Ignored.IsIgnored(itemID, character)
    return Ignored.IsIgnoredByAll(itemID) or Ignored.IsIgnoredBy(itemID, character)
end

---The characters that ignore an item for themselves, by name.
---@param itemID integer
---@return string[]
function Ignored.CharactersIgnoring(itemID)
    local names = {}
    for name, items in pairs(ignoredItems().characters) do
        if items[itemID] then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

---Ignores an item. Ignored by every character, it is no longer ignored by each one apart.
---@param itemID integer
---@param character string? nil: by every character
function Ignored.Add(itemID, character)
    local items = ignoredItems()
    if not character then
        items.all[itemID] = true
        for name in pairs(CopyTable(items.characters)) do Ignored.Remove(itemID, name) end
        return
    end
    items.characters[character] = items.characters[character] or {}
    items.characters[character][itemID] = true
end

---Takes an item back: it is offered again.
---@param itemID integer
---@param character string? nil: ignored by every character
function Ignored.Remove(itemID, character)
    local items = ignoredItems()
    if not character then
        items.all[itemID] = nil
        return
    end
    local own = items.characters[character]
    if not own then return end
    own[itemID] = nil
    if not next(own) then items.characters[character] = nil end
end

---An item ignored, by every character or by one.
---@class FlagUp.IgnoredEntry
---@field itemID integer
---@field character string? nil: by every character

---Every item ignored in the household being played, by every character and by each one.
---@return FlagUp.IgnoredEntry[]
function Ignored.Entries()
    local items = ignoredItems()
    local entries = {}
    for itemID in pairs(items.all) do entries[#entries + 1] = { itemID = itemID } end
    for character, own in pairs(items.characters) do
        for itemID in pairs(own) do entries[#entries + 1] = { itemID = itemID, character = character } end
    end
    return entries
end

---Gives a renamed character's ignored items its new name, joined to those already under it.
---@param oldName string
---@param newName string
function Ignored.RenameCharacter(oldName, newName)
    local characters = ignoredItems().characters
    local old = characters[oldName]
    if not old then return end
    characters[oldName] = nil
    characters[newName] = characters[newName] or {}
    for itemID in pairs(old) do characters[newName][itemID] = true end
end

---Joins another household's ignored items into a household's. An item ignored by every character is no longer ignored
---by each one apart.
---@param items FlagUp.IgnoredItems the household's
---@param other FlagUp.IgnoredItems the joined household's
function Ignored.JoinItems(items, other)
    for itemID in pairs(other.all) do items.all[itemID] = true end
    for character, own in pairs(other.characters) do
        items.characters[character] = items.characters[character] or {}
        for itemID in pairs(own) do items.characters[character][itemID] = true end
    end
    for character, own in pairs(items.characters) do
        for itemID in pairs(items.all) do own[itemID] = nil end
        if not next(own) then items.characters[character] = nil end
    end
end
