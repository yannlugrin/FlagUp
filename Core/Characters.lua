local _, ns = ...
---@cast ns FlagUp.Namespace

---The player's characters: the recipients of each ruleset and faction.
---@class FlagUp.Characters
local Characters = {}
ns.Characters = Characters

---A character the player can mail.
---@class FlagUp.Character
---@field typed boolean typed by the player; false: it logged in with Flag Up
---@field guid string? the character's GUID, saved when it logs in: it stays the same when the character is renamed

---The characters and rules of one ruleset and faction: mail only reaches a character of both.
---@class FlagUp.RulesetFaction
---@field characters table<string, FlagUp.Character> by name, "First Surname"
---@field rules FlagUp.RuleLines? created with the first line

---The ruleset the character plays on: Normal, PvP, RP or Hardcore.
---@return string
local function ruleset()
    local rules = Enum.GameRule
    if not (C_GameRules and rules) then return "Normal" end
    if rules.HardcoreRuleset and C_GameRules.IsGameRuleActive(rules.HardcoreRuleset) then return "Hardcore" end
    if rules.RPRuleset and C_GameRules.IsGameRuleActive(rules.RPRuleset) then return "RP" end
    if rules.PvPRuleset and C_GameRules.IsGameRuleActive(rules.PvPRuleset) then return "PvP" end
    return "Normal"
end

---The character being played's whole name, "First Surname". On Forever, UnitFullName returns the surname where retail
---returns the realm.
---@return string
function Characters.PlayerName()
    local name, surname = UnitFullName("player")
    return surname and (name .. " " .. surname) or name
end

---The entry of the character being played's ruleset and faction, created with its first character.
---@return FlagUp.RulesetFaction
function Characters.PlayerRulesetFaction()
    local key = ruleset() .. "-" .. UnitFactionGroup("player")
    local entry = ns.data.rulesetFactions[key]
    if not entry then
        entry = { characters = {} }
        ns.data.rulesetFactions[key] = entry
    end
    return entry
end

---Adds the character being played to the known characters of its ruleset and faction. A character typed before
---becomes known. A character known under another name was renamed (the game can force it): its rules and overrides
---move to the new name. Call on PLAYER_LOGIN.
function Characters.RecordPlayer()
    local characters = Characters.PlayerRulesetFaction().characters
    local name, guid = Characters.PlayerName(), UnitGUID("player")

    local oldNames = {}
    for knownName, character in pairs(characters) do
        if character.guid == guid and knownName ~= name then oldNames[#oldNames + 1] = knownName end
    end
    for _, oldName in ipairs(oldNames) do
        characters[oldName] = nil
        ns.Rules.RenameCharacter(oldName, name)
    end

    characters[name] = { typed = false, guid = guid }
end

---The names of the characters of the ruleset and faction being played that logged in with Flag Up, by name.
---@return string[]
function Characters.KnownNames()
    local names = {}
    for name, character in pairs(Characters.PlayerRulesetFaction().characters) do
        if not character.typed then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

---Adds a character typed by the player, of the ruleset and faction being played; a character already there stays as
---it is.
---@param name string "First Surname"
function Characters.AddTyped(name)
    local characters = Characters.PlayerRulesetFaction().characters
    if not characters[name] then characters[name] = { typed = true } end
end

---The names of the characters of the ruleset and faction being played, known and typed, by name.
---@param except string? a character left out
---@return string[]
function Characters.Names(except)
    local names = {}
    for name in pairs(Characters.PlayerRulesetFaction().characters) do
        if name ~= except then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end
