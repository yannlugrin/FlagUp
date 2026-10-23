local _, ns = ...
---@cast ns FlagUp.Namespace

---The game's item categories: its item classes and their subclasses, as the client names them.
---@class FlagUp.Categories
local Categories = {}
ns.Categories = Categories

---A subcategory: an item subclass.
---@class FlagUp.Subcategory
---@field subClassID integer
---@field name string

---A category: an item class and its subclasses.
---@class FlagUp.Category
---@field classID integer
---@field name string
---@field subcategories FlagUp.Subcategory[] in the game's order

-- Item classes left out of the categories, by class ID: the client knows retail's whole list, most of it without items
-- in this world.
local HIDDEN_CLASSES = {}

-- The client gives no count of item classes or subclasses: their IDs are tried up to these.
local LAST_CLASS_ID, LAST_SUBCLASS_ID = 31, 31

---@type FlagUp.Category[]?
local all

---The categories, in the game's order (by class ID), each with its subcategories in the same order.
---@return FlagUp.Category[]
function Categories.All()
    if all then return all end

    all = {}
    for classID = 0, LAST_CLASS_ID do
        local name = C_Item.GetItemClassInfo(classID)
        if name and name ~= "" and not HIDDEN_CLASSES[classID] then
            local category = { classID = classID, name = name, subcategories = {} }
            for subClassID = 0, LAST_SUBCLASS_ID do
                local subName = C_Item.GetItemSubClassInfo(classID, subClassID)
                if subName and subName ~= "" then
                    category.subcategories[#category.subcategories + 1] = { subClassID = subClassID, name = subName }
                end
            end
            all[#all + 1] = category
        end
    end
    return all
end
