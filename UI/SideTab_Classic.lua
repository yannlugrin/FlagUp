local _, ns = ...
---@cast ns FlagUp.Namespace

-- Loaded by the Classic TOCs; UI/SideTab_Mainline.lua is its twin for retail and Forever, with the same functions and
-- fields. Classic has no large side tabs: each tab is an icon button drawn as the game's action buttons are.

local SideTab = {}
ns.SideTab = SideTab

SideTab.X, SideTab.GAP = 4, 4
local SIZE = 36
-- The action button's border, as its template draws it.
local BORDER_TEXTURE = "Interface\\Buttons\\UI-Quickslot2"
local BORDER_SIZE = 40
local BORDER_COORDS = { 0.1875, 0.796875, 0.1875, 0.796875 }
local BORDER_ALPHA = 0.5
local PUSHED_TEXTURE = "Interface\\Buttons\\UI-Quickslot-Depress"
local HIGHLIGHT_TEXTURE = "Interface\\Buttons\\ButtonHilight-Square"
-- The action button's checked glow, as the lit tab.
local LIT_TEXTURE = "Interface\\Buttons\\CheckButtonHilight"

---A tab drawn as an action button.
---@class FlagUp.SideTab.ClassicTab: FlagUp.SideTab.Tab, Button
---@field Lit Texture shown while the tab is lit

---A new tab, its icon empty.
---@param parent Frame
---@return FlagUp.SideTab.Tab
function SideTab.New(parent)
    local tab = CreateFrame("Button", nil, parent) --[[@as FlagUp.SideTab.ClassicTab]]
    tab:SetSize(SIZE, SIZE)

    tab.Icon = tab:CreateTexture(nil, "BACKGROUND")
    tab.Icon:SetAllPoints()

    tab:SetNormalTexture(BORDER_TEXTURE)
    local border = tab:GetNormalTexture()
    border:ClearAllPoints()
    border:SetPoint("CENTER")
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetTexCoord(unpack(BORDER_COORDS))
    border:SetAlpha(BORDER_ALPHA)
    tab:SetPushedTexture(PUSHED_TEXTURE)
    tab:SetHighlightTexture(HIGHLIGHT_TEXTURE, "ADD")

    tab.Lit = tab:CreateTexture(nil, "OVERLAY")
    tab.Lit:SetTexture(LIT_TEXTURE)
    tab.Lit:SetBlendMode("ADD")
    tab.Lit:SetAllPoints()
    tab.Lit:Hide()
    return tab
end

---Calls a function when the tab is clicked.
---@param tab FlagUp.SideTab.Tab
---@param handler fun()
function SideTab.SetOnClick(tab, handler)
    local classicTab = tab --[[@as FlagUp.SideTab.ClassicTab]]
    classicTab:SetScript("OnClick", handler)
end

---Lights the tab up, while an item is held over it, or puts it out.
---@param tab FlagUp.SideTab.Tab
---@param lit boolean
function SideTab.SetLit(tab, lit)
    local classicTab = tab --[[@as FlagUp.SideTab.ClassicTab]]
    classicTab.Lit:SetShown(lit)
end
