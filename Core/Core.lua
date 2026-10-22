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
---@field SettingsPanel FlagUp.SettingsPanel
---@field Launcher FlagUp.Launcher
---@field MailPanel FlagUp.MailPanel

ns.L = LibStub("AceLocale-3.0"):GetLocale(addonName)

-- Events -----------------------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")

frame:SetScript("OnEvent", function(_, event, ...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        ns.Store.Init()
    elseif event == "PLAYER_LOGIN" then
        ns.Launcher.Register()
    elseif event == "MAIL_SHOW" then
        ns.MailPanel.Open()
    end
end)
