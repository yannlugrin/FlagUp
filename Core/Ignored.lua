local _, ns = ...
---@cast ns FlagUp.Namespace

---The items never offered at the mailbox, whatever the rules: ignored by every character of the ruleset and faction
---being played, or by one.
---@class FlagUp.Ignored
local Ignored = {}
ns.Ignored = Ignored

---The ignored items of a ruleset and faction.
---@class FlagUp.IgnoredItems
---@field all table<integer, true> by item ID: ignored by every character
---@field characters table<string, table<integer, true>> by name, then item ID: ignored by that character

---The ignored items, created with the first one.
---@return FlagUp.IgnoredItems
local function ignoredItems()
    local entry = ns.Characters.PlayerRulesetFaction()
    if not entry.ignored then entry.ignored = { all = {}, characters = {} } end
    return entry.ignored
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

---Ignores an item.
---@param itemID integer
---@param character string? nil: by every character
function Ignored.Add(itemID, character)
    local items = ignoredItems()
    if not character then
        items.all[itemID] = true
        return
    end
    items.characters[character] = items.characters[character] or {}
    items.characters[character][itemID] = true
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
