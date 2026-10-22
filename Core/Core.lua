local addonName, ns = ...
---@cast ns FlagUp.Namespace

---The add-on's private table, shared by every file.
---@class FlagUp.Namespace
---@field L table<string, string>
---@field Skin FlagUp.Skin
---@field TreeRow FlagUp.TreeRow
---@field RulesWindow FlagUp.RulesWindow
---@field AddItemDialog FlagUp.AddItemDialog
---@field AddCategoryDialog FlagUp.AddCategoryDialog

ns.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
