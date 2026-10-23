local addonName, ns = ...
---@cast ns FlagUp.Namespace

local L = ns.L
local LibDBIcon = LibStub("LibDBIcon-1.0")

---The minimap button and the add-on compartment entry.
---@class FlagUp.Launcher
local Launcher = {}
ns.Launcher = Launcher

local title = C_AddOns.GetAddOnMetadata(addonName, "Title")

---LibDBIcon calls the data object from the minimap button with that button, from the compartment with its menu.
---@param frame Frame?
---@return boolean
local function isMinimapButton(frame)
    return frame ~= nil and frame == LibDBIcon:GetMinimapButton(addonName)
end

local dataObject = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type = "launcher",
    label = title,
    icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture"),
    OnClick = function(frame, button)
        -- The compartment opens the settings, as other add-ons' entries do.
        if not isMinimapButton(frame) then
            ns.SettingsPanel.Open()
            return
        end
        if button ~= "RightButton" then
            ns.RulesWindow.Toggle()
            return
        end
        -- Not owned by the clicked button: a menu closes with its owner, and EllesmereUI's minimap button bar hides
        -- on the press that picks an option, before the option's click lands.
        MenuUtil.CreateContextMenu(nil, function(_, root)
            root:CreateButton(L["Open"], function() ns.RulesWindow.Window:Show() end)
            root:CreateButton(L["Settings"], function() ns.SettingsPanel.Open() end)
        end)
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine(title)
        if not isMinimapButton(tooltip:GetOwner()) then
            tooltip:AddLine(L["Click: open the settings"], 1, 1, 1)
            return
        end
        tooltip:AddLine(L["Click: show or hide the rules window"], 1, 1, 1)
        tooltip:AddLine(L["Right-click: menu"], 1, 1, 1)
    end,
})

---Shows the minimap button and the add-on compartment entry as the settings say. Call once the settings are loaded.
function Launcher.Register()
    LibDBIcon:Register(addonName, dataObject, ns.settings.launcher)
end

---@param shown boolean
function Launcher.SetMinimapButtonShown(shown)
    ns.settings.launcher.hide = not shown
    if shown then LibDBIcon:Show(addonName) else LibDBIcon:Hide(addonName) end
end

---@param shown boolean
function Launcher.SetCompartmentShown(shown)
    if shown then
        LibDBIcon:AddButtonToCompartment(addonName)
    else
        LibDBIcon:RemoveButtonFromCompartment(addonName)
        -- LibDBIcon clears the field; nil would read back as the default, shown.
        ns.settings.launcher.showInCompartment = false
    end
end
