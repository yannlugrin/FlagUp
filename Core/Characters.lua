local _, ns = ...
---@cast ns FlagUp.Namespace

---The player's characters: the recipients of each household that mail reaches.
---@class FlagUp.Characters
local Characters = {}
ns.Characters = Characters

---A character the player can mail.
---@class FlagUp.Character
---@field typed boolean typed by the player; false: it logged in with Flag Up
---@field guid string? the character's GUID, saved when it logs in: it stays the same when the character is renamed
---@field faction string? "Alliance" or "Horde": its own once it logs in; typed, the faction of the character that
---typed it
---@field class string? the class file name ("WARRIOR"), saved when it logs in
---@field atMailbox boolean? it gets a tab beside the mailbox panel; nil: known characters do, typed ones don't
---@field icon number|string? the icon chosen for it; nil: its class icon

---The characters and rules of the characters mail reaches: on Forever, one ruleset and faction; elsewhere, a realm and
---the realms connected to it, both factions.
---@class FlagUp.Household
---@field characters table<string, FlagUp.Character> by name: "First Surname" on Forever, "Name-Realm" elsewhere
---@field rules FlagUp.RuleLines? created with the first line
---@field ignored FlagUp.IgnoredItems? created with the first item ignored

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

-- On Forever, characters have a surname and no realm; elsewhere, their realm, which mail names as "Name-Realm".
local IS_FOREVER = ns.IS_FOREVER

---Outside Forever: the realm being played and the realms connected to it, which mail reaches, by normalized name.
---@return table<string, true>
local function reachableRealms()
    local connected
    if C_AutoComplete and C_AutoComplete.GetAutoCompleteRealms then
        connected = C_AutoComplete.GetAutoCompleteRealms()
    else
        connected = GetAutoCompleteRealms()
    end
    local realms = { [GetNormalizedRealmName()] = true }
    for _, realm in ipairs(connected or {}) do realms[realm] = true end
    return realms
end

---A household's key outside Forever: its realms, in order, joined with "-" (normalized realm names hold no "-").
---@param realms table<string, true>
---@return string
local function realmHouseholdKey(realms)
    local names = {}
    for realm in pairs(realms) do names[#names + 1] = realm end
    table.sort(names)
    return table.concat(names, "-")
end

---The realm of a "Name-Realm" name.
---@param name string
---@return string?
local function realmOf(name)
    return name:match("%-(.+)$")
end

---The character being played's whole name: "First Surname" on Forever, where UnitFullName returns the surname in place
---of the realm; "Name-Realm" elsewhere.
---@return string
function Characters.PlayerName()
    local name, second = UnitFullName("player")
    if IS_FOREVER then return second and (name .. " " .. second) or name end
    return name .. "-" .. (second or GetNormalizedRealmName())
end

---A name as shown: outside Forever, without the realm when it is the realm being played.
---@param name string
---@return string
function Characters.ShownName(name)
    if IS_FOREVER or realmOf(name) ~= GetNormalizedRealmName() then return name end
    return (name:gsub("%-[^%-]+$", ""))
end

---A typed name as Flag Up keeps it, or nil when it isn't a character's whole name: "First Surname" on Forever;
---"Name-Realm" elsewhere, a name alone being on the realm being played. The realm is written without spaces or "-",
---as the game names it, and spelled as a realm mail reaches when it is one.
---@param text string
---@return string?
function Characters.TypedName(text)
    local name = strtrim(text)
    if IS_FOREVER then return name:match("^%S+ %S+$") and name or nil end
    if name:match("^[^%s%-]+$") then return name .. "-" .. GetNormalizedRealmName() end
    local short, realm = name:match("^([^%s%-]+)%-(.+)$")
    if not short then return nil end
    realm = realm:gsub("[%s%-]", "")
    for reachable in pairs(reachableRealms()) do
        if reachable:lower() == realm:lower() then realm = reachable end
    end
    return short .. "-" .. realm
end

---Whether mail reaches a name's realm: on Forever, always; elsewhere, the realm being played and those connected to it.
---@param name string
---@return boolean
function Characters.IsOnReachableRealm(name)
    if IS_FOREVER then return true end
    local realm = realmOf(name)
    return realm ~= nil and reachableRealms()[realm] == true
end

---How a typed name is written, for the dialog's hint and error.
---@return string
function Characters.NameForm()
    return IS_FOREVER and ns.L["First Surname"] or ns.L["Name-Realm"]
end

---@type string? outside Forever, the character being played's household key, found at its first use
local realmsKey

---The household of the character being played, created with its first character.
---@return FlagUp.Household
function Characters.PlayerHousehold()
    local households, key
    if IS_FOREVER then
        households, key = ns.data.rulesetFactions, ruleset() .. "-" .. UnitFactionGroup("player")
    else
        realmsKey = realmsKey or realmHouseholdKey(reachableRealms())
        households, key = ns.data.realmHouseholds, realmsKey
    end
    local household = households[key]
    if not household then
        household = { characters = {} }
        households[key] = household
    end
    return household
end

---Outside Forever, joins into the household being played the households of its realms saved apart: realms connected
---since, or seen before their connected realms were. Their characters are joined; their rule lines and ignored items
---are added, and on a line both have, the household being played keeps its fields, the other's filling those it leaves
---unset.
local function joinConnectedHouseholds()
    if IS_FOREVER then return end
    local household = Characters.PlayerHousehold()
    local realms = reachableRealms()

    local joined = {}
    for key, other in pairs(ns.data.realmHouseholds) do
        if other ~= household then
            for realm in key:gmatch("[^%-]+") do
                if realms[realm] then
                    joined[#joined + 1] = key
                    break
                end
            end
        end
    end

    for _, key in ipairs(joined) do
        local other = ns.data.realmHouseholds[key]
        ns.data.realmHouseholds[key] = nil
        for name, character in pairs(other.characters) do
            local current = household.characters[name]
            if not current or (current.typed and not character.typed) then household.characters[name] = character end
        end
        if other.rules then
            household.rules = household.rules or { categories = {}, subcategories = {}, items = {} }
            ns.Rules.JoinLines(household.rules, other.rules)
        end
        if other.ignored then
            household.ignored = household.ignored or { all = {}, characters = {} }
            ns.Ignored.JoinItems(household.ignored, other.ignored)
        end
    end
end

---Adds the character being played to the known characters of its household. A character typed before becomes known. A
---character known under another name was renamed (the game can force it): its rules, overrides and ignored items move
---to the new name. Outside Forever, the households of realms connected since join the household first. Call on
---PLAYER_LOGIN.
function Characters.RecordPlayer()
    joinConnectedHouseholds()

    local characters = Characters.PlayerHousehold().characters
    local name, guid = Characters.PlayerName(), UnitGUID("player")

    local oldNames = {}
    for knownName, character in pairs(characters) do
        if character.guid == guid and knownName ~= name then oldNames[#oldNames + 1] = knownName end
    end
    for _, oldName in ipairs(oldNames) do
        characters[oldName] = nil
        ns.Rules.RenameCharacter(oldName, name)
        ns.Ignored.RenameCharacter(oldName, name)
    end

    characters[name] = { typed = false, guid = guid, faction = UnitFactionGroup("player"),
        class = select(2, UnitClass("player")) }
end

---Whether mail goes from one character of the household to another. Never to itself. On retail, mail crosses
---factions only between the player's own characters (known: typed ones may be another account's) of one realm; on
---Classic, never.
---@param sender string
---@param recipient string
---@return boolean
function Characters.CanMail(sender, recipient)
    if sender == recipient then return false end
    if IS_FOREVER then return true end
    local characters = Characters.PlayerHousehold().characters
    local from, to = characters[sender], characters[recipient]
    if not (from and to and from.faction and to.faction) or from.faction == to.faction then return true end
    return ns.MAILS_ACROSS_FACTIONS and not from.typed and not to.typed and realmOf(sender) == realmOf(recipient)
end

---The names of the characters of the household being played that logged in with Flag Up, by name.
---@return string[]
function Characters.KnownNames()
    local names = {}
    for name, character in pairs(Characters.PlayerHousehold().characters) do
        if not character.typed then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end

---A character of the household being played; nil: none of that name.
---@param name string
---@return FlagUp.Character?
function Characters.Get(name)
    return Characters.PlayerHousehold().characters[name]
end

---The names of every character of the household being played, known and typed, by name.
---@return string[]
function Characters.AllNames()
    local names = {}
    for name in pairs(Characters.PlayerHousehold().characters) do names[#names + 1] = name end
    table.sort(names)
    return names
end

---Whether a character gets a tab beside the mailbox panel: as set on the Characters tab; by default, a known
---character does and a typed one doesn't.
---@param name string
---@return boolean
function Characters.IsShownAtMailbox(name)
    local character = Characters.Get(name)
    if not character then return false end
    if character.atMailbox ~= nil then return character.atMailbox end
    return not character.typed
end

---@param name string
---@param shown boolean
function Characters.SetShownAtMailbox(name, shown)
    local character = Characters.Get(name)
    if character then character.atMailbox = shown end
end

---@param name string
---@param icon number|string|nil nil: its class icon
function Characters.SetIcon(name, icon)
    local character = Characters.Get(name)
    if character then character.icon = icon end
end

---Forgets a typed character; a known one stays, as it logs in again.
---@param name string
function Characters.Forget(name)
    local characters = Characters.PlayerHousehold().characters
    if characters[name] and characters[name].typed then characters[name] = nil end
end

---Adds a character typed by the player to the household being played, of the faction being played; a character already
---there stays as it is.
---@param name string "First Surname" on Forever, "Name-Realm" elsewhere
function Characters.AddTyped(name)
    local characters = Characters.PlayerHousehold().characters
    if not characters[name] then characters[name] = { typed = true, faction = UnitFactionGroup("player") } end
end

---The names of the characters of the household being played that a character can mail, known and typed, by name.
---@param sender string
---@return string[]
function Characters.Recipients(sender)
    local names = {}
    for name in pairs(Characters.PlayerHousehold().characters) do
        if Characters.CanMail(sender, name) then names[#names + 1] = name end
    end
    table.sort(names)
    return names
end
