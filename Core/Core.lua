local addonName, ns = ...
---@cast ns StashPost.Namespace

---The add-on's private table, shared by every file.
---@class StashPost.Namespace
---@field L table<string, string>
---@field Skin StashPost.Skin
---@field RulesWindow StashPost.RulesWindow

ns.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
