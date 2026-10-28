local _, ns = ...
---@cast ns FlagUp.Namespace

-- Loaded by the retail and Forever TOCs; UI/SideTab_Classic.lua is its twin for the Classic TOC, with the same
-- functions and fields.

---The tabs down the mailbox panel's right edge: the game's large side tabs.
---@class FlagUp.SideTab
---@field X number the tabs' left from the panel's right edge: the tab art's padding on the right
---@field GAP number the space between two tabs
local SideTab = {}
ns.SideTab = SideTab

SideTab.X, SideTab.GAP = -2, 0
-- As large as the community frame's tab icons.
local ICON_SIZE = 34

---A tab beside the mailbox panel, as both files build it.
---@class FlagUp.SideTab.Tab: Frame
---@field Icon Texture

---A large side tab.
---@class FlagUp.SideTab.MainlineTab: FlagUp.SideTab.Tab
---@field TabGlow Texture
---@field TabGlowAnimation AnimationGroup
---@field SetChecked fun(self: FlagUp.SideTab.MainlineTab, checked: boolean)
---@field SetCustomOnMouseUpHandler fun(self: FlagUp.SideTab.MainlineTab, handler: fun())

---A new tab, its icon empty.
---@param parent Frame
---@return FlagUp.SideTab.Tab
function SideTab.New(parent)
    local tab = CreateFrame("Frame", nil, parent, "LargeSideTabButtonTemplate") --[[@as FlagUp.SideTab.MainlineTab]]
    tab:SetChecked(false)
    tab:EnableMouse(true)
    tab.Icon:SetSize(ICON_SIZE, ICON_SIZE)
    return tab
end

---Calls a function when the tab is clicked.
---@param tab FlagUp.SideTab.Tab
---@param handler fun()
function SideTab.SetOnClick(tab, handler)
    local mainlineTab = tab --[[@as FlagUp.SideTab.MainlineTab]]
    mainlineTab:SetCustomOnMouseUpHandler(handler)
end

---Lights the tab up, while an item is held over it, or puts it out.
---@param tab FlagUp.SideTab.Tab
---@param lit boolean
function SideTab.SetLit(tab, lit)
    local mainlineTab = tab --[[@as FlagUp.SideTab.MainlineTab]]
    if lit then
        mainlineTab.TabGlowAnimation:Play()
    else
        mainlineTab.TabGlowAnimation:Stop()
        mainlineTab.TabGlow:SetAlpha(0)
    end
end
