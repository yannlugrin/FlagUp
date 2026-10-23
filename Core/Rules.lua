local _, ns = ...
---@cast ns FlagUp.Namespace

---The rule lines of the character being played's ruleset and faction.
---@class FlagUp.Rules
local Rules = {}
ns.Rules = Rules

---A rule line: the fields it sets; a field it doesn't set is nil, inherited from the line above.
---@class FlagUp.Line
---@field sendTo string|false? the recipient's name; false: don't send
---@field qualities table<integer, boolean>? on Armor and Weapon lines, by item quality; empty: no filter
---@field keep integer? on an item
---@field fullStacksOnly boolean?
---@field overrides table<string, FlagUp.Line>? by the overriding character's name: the fields it overrides

---The rule lines of a ruleset and faction.
---@class FlagUp.RuleLines
---@field categories table<integer, FlagUp.Line> by item class ID
---@field subcategories table<integer, table<integer, FlagUp.Line>> by item class ID, then subclass ID
---@field items table<integer, FlagUp.Line> by item ID

---The lines, created with the first one.
---@return FlagUp.RuleLines
function Rules.Lines()
    local entry = ns.Characters.PlayerRulesetFaction()
    if not entry.rules then entry.rules = { categories = {}, subcategories = {}, items = {} } end
    return entry.rules
end

---@param classID integer
---@param subClassID integer? nil: the category itself
---@return boolean
function Rules.HasCategory(classID, subClassID)
    local lines = Rules.Lines()
    if subClassID == nil then return lines.categories[classID] ~= nil end
    return lines.subcategories[classID] ~= nil and lines.subcategories[classID][subClassID] ~= nil
end

---Adds a category or subcategory line, every field inherited; a line already there is kept as it is.
---@param classID integer
---@param subClassID integer? nil: the category itself
function Rules.AddCategory(classID, subClassID)
    local lines = Rules.Lines()
    if subClassID == nil then
        lines.categories[classID] = lines.categories[classID] or {}
        return
    end
    lines.subcategories[classID] = lines.subcategories[classID] or {}
    lines.subcategories[classID][subClassID] = lines.subcategories[classID][subClassID] or {}
end

---@param itemID integer
---@return boolean
function Rules.HasItem(itemID)
    return Rules.Lines().items[itemID] ~= nil
end

---Adds an item line, every field inherited; a line already there is kept as it is.
---@param itemID integer
function Rules.AddItem(itemID)
    local items = Rules.Lines().items
    items[itemID] = items[itemID] or {}
end

-- Resolution -------------------------------------------------------------------------------------

---Where a line is: its category, and its subcategory and item when it is one of those.
---@class FlagUp.LinePlace
---@field classID integer
---@field subClassID integer? on a subcategory or an item
---@field itemID integer? on an item

---@alias FlagUp.FieldName "sendTo"|"qualities"|"keep"|"fullStacksOnly"

---The fields of a line, in the pane's order.
---@type FlagUp.FieldName[]
Rules.FIELDS = { "sendTo", "qualities", "keep", "fullStacksOnly" }

-- The defaults, above the categories: don't send, no quality filter, nothing kept, any amount.
local DEFAULTS = { sendTo = false, qualities = {}, keep = 0, fullStacksOnly = false }

---@param place FlagUp.LinePlace
---@return FlagUp.Line?
function Rules.LineAt(place)
    local lines = Rules.Lines()
    if place.itemID then return lines.items[place.itemID] end
    if place.subClassID then
        return lines.subcategories[place.classID] and lines.subcategories[place.classID][place.subClassID]
    end
    return lines.categories[place.classID]
end

---The lines a line inherits from, closest first: its own, then its subcategory's and its category's; false where a
---line isn't there.
---@param place FlagUp.LinePlace
---@return (FlagUp.Line|false)[]
local function lineChain(place)
    local chain = {}
    if place.itemID then chain[#chain + 1] = Rules.LineAt(place) or false end
    if place.subClassID then
        chain[#chain + 1] = Rules.LineAt({ classID = place.classID, subClassID = place.subClassID }) or false
    end
    chain[#chain + 1] = Rules.LineAt({ classID = place.classID }) or false
    return chain
end

---Whether a line has a field: the rule and the stacks on every line, the qualities on Armor and Weapon categories and
---subcategories, the keep count on items.
---@param place FlagUp.LinePlace
---@param field FlagUp.FieldName
---@return boolean
function Rules.HasField(place, field)
    if field == "qualities" then
        return place.itemID == nil and (place.classID == Enum.ItemClass.Armor or place.classID == Enum.ItemClass.Weapon)
    end
    if field == "keep" then return place.itemID ~= nil end
    return true
end

---The value a field takes on a line: the closest line that sets it decides, from the line itself up to its category;
---on one line, the character's override comes before the shared value. With no line setting it, the default.
---@param place FlagUp.LinePlace
---@param field FlagUp.FieldName
---@param character string? nil: the shared value
---@return any
function Rules.Value(place, field, character)
    for _, line in ipairs(lineChain(place)) do
        if line then
            local override = character and line.overrides and line.overrides[character]
            if override and override[field] ~= nil then return override[field] end
            if line[field] ~= nil then return line[field] end
        end
    end
    return DEFAULTS[field]
end

-- Renaming ---------------------------------------------------------------------------------------

---Gives a renamed character's rules and overrides its new name: the rules that send to it, and its overrides, which
---join those under the new name (the old name's fields win where both set one).
---@param oldName string
---@param newName string
function Rules.RenameCharacter(oldName, newName)
    ---@param line FlagUp.Line
    local function renameIn(line)
        if line.sendTo == oldName then line.sendTo = newName end
        local overrides = line.overrides
        if not overrides then return end
        for _, override in pairs(overrides) do
            if override.sendTo == oldName then override.sendTo = newName end
        end
        local old = overrides[oldName]
        if old then
            overrides[oldName] = nil
            overrides[newName] = overrides[newName] or {}
            for field, value in pairs(old) do overrides[newName][field] = value end
        end
    end

    local lines = Rules.Lines()
    for _, line in pairs(lines.categories) do renameIn(line) end
    for _, subcategories in pairs(lines.subcategories) do
        for _, line in pairs(subcategories) do renameIn(line) end
    end
    for _, line in pairs(lines.items) do renameIn(line) end
end
