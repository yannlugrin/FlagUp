local _, ns = ...
---@cast ns FlagUp.Namespace

---The player's characters: the recipients of each ruleset and faction.
---@class FlagUp.Characters
local Characters = {}
ns.Characters = Characters

---A character the player can mail.
---@class FlagUp.Character
---@field typed boolean typed by the player; false: it logged in with Flag Up

---The characters and rules of one ruleset and faction: mail only reaches a character of both.
---@class FlagUp.RulesetFaction
---@field characters table<string, FlagUp.Character> by name, "First Surname"

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

---The character's whole name, "First Surname". On Forever, UnitFullName returns the surname where retail returns the
---realm.
---@return string
local function playerName()
    local name, surname = UnitFullName("player")
    return surname and (name .. " " .. surname) or name
end

---Adds the character being played to the known characters of its ruleset and faction, creating their entry with the
---first one. A character typed before becomes known. Call on PLAYER_LOGIN.
function Characters.RecordPlayer()
    local key = ruleset() .. "-" .. UnitFactionGroup("player")
    local entry = ns.data.rulesetFactions[key]
    if not entry then
        entry = { characters = {} }
        ns.data.rulesetFactions[key] = entry
    end
    entry.characters[playerName()] = { typed = false }
end
