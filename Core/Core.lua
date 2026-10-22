local addonName, ns = ...
---@cast ns FlagUp.Namespace

---The add-on's private table, shared by every file.
---@class FlagUp.Namespace
---@field L table<string, string>
---@field db table AceDB object
---@field settings FlagUp.Settings
---@field Store FlagUp.Store
---@field Skin FlagUp.Skin
---@field TreeRow FlagUp.TreeRow
---@field RulesWindow FlagUp.RulesWindow
---@field AddItemDialog FlagUp.AddItemDialog
---@field AddCategoryDialog FlagUp.AddCategoryDialog

ns.L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Events -----------------------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns.Store.Init()
    end
end)
