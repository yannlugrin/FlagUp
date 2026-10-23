local addonName, ns = ...
---@cast ns FlagUp.Namespace

---@class FlagUp.Store
local Store = {}
ns.Store = Store

---Account-wide saved data (FlagUpDB.global).
---@class FlagUp.Data
---@field rulesetFactions table<string, FlagUp.RulesetFaction> by ruleset and faction, "PvP-Alliance"

---Settings (FlagUpDB.profile; one "Default" profile shared by every character).
---@class FlagUp.Settings
---@field launcher { hide: boolean, showInCompartment: boolean, minimapPos: number? } LibDBIcon's own format: the minimap button and the add-on compartment entry
---@field sendAutomatically boolean the mailbox sends as soon as it opens
---@field sendKey "SHIFT"|"CTRL"|"ALT"|"NONE" held when the mailbox opens: skips the automatic sending, or sends while it is off

Store.DEFAULTS = {
    global = {
        rulesetFactions = {},
    },
    profile = {
        launcher = { hide = false, showInCompartment = true },
        sendAutomatically = false,
        sendKey = "SHIFT",
    },
}

---Sets ns.db, ns.data and ns.settings. Call on ADDON_LOADED.
function Store.Init()
    local db = LibStub("AceDB-3.0"):New(addonName .. "DB", Store.DEFAULTS, true)
    ns.db = db
    ns.data = db.global
    ns.settings = db.profile
end
