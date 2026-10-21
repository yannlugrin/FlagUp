local addonName, ns = ...
---@cast ns StashPost.Namespace

---@class StashPost.Skin
local Skin = {}
ns.Skin = Skin

---@type table? EllesmereUI's skinning functions, once it hands them over
local S
---@type fun(S: table)[]
local pending = {}

---Calls `skin` with EllesmereUI's skinning functions: at once if they are already handed over, else when they are.
---Never called without EllesmereUI, or when its skinning is off for this add-on.
---@param skin fun(S: table)
function Skin.Apply(skin)
    if S then
        skin(S)
    else
        pending[#pending + 1] = skin
    end
end

if EllesmereUI and EllesmereUI.RegisterSkin then
    EllesmereUI.RegisterSkin(addonName, function(skinFunctions)
        S = skinFunctions
        for _, skin in ipairs(pending) do skin(S) end
        pending = {}
    end)
end
