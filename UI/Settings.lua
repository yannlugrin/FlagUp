local addonName, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L

---The settings' page in the game's Options › AddOns.
---@class FlagUp.SettingsPanel
local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local category, layout = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(addonName, "Title"))

local function addSectionHeader(name)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(name))
end

-- General ----------------------------------------------------------------------------------------

addSectionHeader(L["General"])
Settings.CreateCheckbox(category, Settings.RegisterProxySetting(category, "FlagUp_MinimapButton",
    Settings.VarType.Boolean, L["Show minimap button"], not ns.Store.DEFAULTS.profile.launcher.hide,
    function() return not ns.settings.launcher.hide end,
    function(value) ns.Launcher.SetMinimapButtonShown(value) end),
    L["A button on the edge of the minimap: click to show or hide the rules window, right-click for a menu."])
Settings.CreateCheckbox(category, Settings.RegisterProxySetting(category, "FlagUp_Compartment",
    Settings.VarType.Boolean, L["Show in the add-on compartment"],
    ns.Store.DEFAULTS.profile.launcher.showInCompartment,
    function() return ns.settings.launcher.showInCompartment == true end,
    function(value) ns.Launcher.SetCompartmentShown(value) end),
    L["Flag Up in the add-on compartment next to the minimap: click to open these settings."])

-- Mailbox ----------------------------------------------------------------------------------------

addSectionHeader(L["Mailbox"])
Settings.CreateCheckbox(category, Settings.RegisterProxySetting(category, "FlagUp_SendAutomatically",
    Settings.VarType.Boolean, L["Send automatically"], ns.Store.DEFAULTS.profile.sendAutomatically,
    function() return ns.settings.sendAutomatically end,
    function(value) ns.settings.sendAutomatically = value end),
    L["Sends as soon as the mailbox opens, without the preview."])
-- The game's own modifier key choices, as for its auto loot key.
Settings.CreateDropdown(category, Settings.RegisterProxySetting(category, "FlagUp_SendKey",
    Settings.VarType.String, L["Send key"], ns.Store.DEFAULTS.profile.sendKey,
    function() return ns.settings.sendKey end,
    function(value) ns.settings.sendKey = value end),
    Settings.CreateModifiedClickOptions({}),
    L["With automatic sending on, hold this key when opening the mailbox to skip sending. With it off, hold it to send."])

Settings.RegisterAddOnCategory(category)

---Opens the game's options on this page.
function SettingsPanel.Open()
    Settings.OpenToCategory(category:GetID())
end
