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
