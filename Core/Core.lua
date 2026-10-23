local addonName, ns = ...
---@cast ns FlagUp.Namespace

---The add-on's private table, shared by every file.
---@class FlagUp.Namespace
---@field L table<string, string>
---@field Print fun(msg: string)
---@field db table AceDB object
---@field data FlagUp.Data
---@field settings FlagUp.Settings
---@field Store FlagUp.Store
---@field Characters FlagUp.Characters
---@field Skin FlagUp.Skin
---@field TreeRow FlagUp.TreeRow
---@field RulesWindow FlagUp.RulesWindow
---@field AddItemDialog FlagUp.AddItemDialog
---@field AddCategoryDialog FlagUp.AddCategoryDialog
---@field SettingsPanel FlagUp.SettingsPanel
---@field Launcher FlagUp.Launcher
---@field MailPanel FlagUp.MailPanel

ns.L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local L = ns.L

local title = C_AddOns.GetAddOnMetadata(addonName, "Title")

---Prints to the chat frame with the add-on's name in front.
---@param msg string
function ns.Print(msg)
    print(NORMAL_FONT_COLOR:WrapTextInColorCode(title) .. " " .. msg)
end

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
        ns.Characters.RecordPlayer()
        ns.Launcher.Register()
    elseif event == "MAIL_SHOW" then
        ns.MailPanel.Open()
    end
end)

-- Slash commands ---------------------------------------------------------------------------------

---@type table<string, fun()>
local commands = {
    open = function() ns.RulesWindow.Toggle() end,
    settings = function() ns.SettingsPanel.Open() end,
}

local function help()
    ns.Print(L["Commands: /flagup open (the rules window), /flagup settings"])
end

SLASH_FLAGUP1 = "/flagup"
SlashCmdList.FLAGUP = function(input)
    local command = (input or ""):match("^%s*(%S*)"):lower()
    local fn = commands[command]
    if fn then fn() else help() end
end
