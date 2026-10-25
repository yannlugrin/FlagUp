local _, ns = ...
---@cast ns FlagUp.Namespace

---A character's icon, as the Characters tab and the mailbox panel's tabs show it.
---@class FlagUp.CharacterIcon
local CharacterIcon = {}
ns.CharacterIcon = CharacterIcon

local CLASS_ICONS_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
-- An icon file's own border, trimmed off.
local ICON_BORDER_TRIM = 0.07

---Shows a character's icon on a texture: the one chosen for it, else its class icon, else a question mark until it
---logs in with Flag Up.
---@param texture Texture
---@param character FlagUp.Character
function CharacterIcon.Show(texture, character)
    local coords = not character.icon and character.class and CLASS_ICON_TCOORDS[character.class]
    if coords then
        texture:SetTexture(CLASS_ICONS_TEXTURE)
        texture:SetTexCoord(unpack(coords))
        return
    end
    texture:SetTexture(character.icon or UNKNOWN_ICON)
    texture:SetTexCoord(ICON_BORDER_TRIM, 1 - ICON_BORDER_TRIM, ICON_BORDER_TRIM, 1 - ICON_BORDER_TRIM)
end
