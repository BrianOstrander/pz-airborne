SWAB_Recipe = SWAB_Recipe or {}
SWAB_Recipe.OnTest = SWAB_Recipe.OnTest or {}
SWAB_Recipe.OnCreate = SWAB_Recipe.OnCreate or {}

function SWAB_Recipe.OnTest.PutStandardFiltersInBoxLarge(_item)
    if PZMath.equal(1, _item:getUsedDelta()) then
        -- This is an unused filter.
        return true
    end
    
    -- This must be a used filter.
    return false
end

-- SWAB_Recipe = SWAB_Recipe or {}
-- SWAB_Recipe.OnTest = SWAB_Recipe.OnTest or {}
-- SWAB_Recipe.OnCreate = SWAB_Recipe.OnCreate or {}

-- ------------------------------------------------------------------------
-- ------------------------------UTILITY-----------------------------------
-- ------------------------------------------------------------------------

-- function SWAB_Recipe.CopyItemProperties(_oldItem, _newItem, _player, _isWorn)
--     if _isWorn then
--         _player:setWornItem(_newItem:getBodyLocation(), _newItem);
--     end
--     _newItem:setFavorite(_oldItem:isFavorite())
--     _newItem:setCondition(_oldItem:getCondition())
--     _newItem:setBloodLevel(_oldItem:getBloodLevel())
--     _newItem:setDirtyness(_oldItem:getDirtyness())
--     _newItem:setWetness(_oldItem:getWetness())

--     _newItem:setTexture(_oldItem:getTexture())
--     _newItem:setWorldTexture(_oldItem:getWorldTexture())
--     _newItem:setColor(_oldItem:getColor())

--     _newItem:setColorRed(_oldItem:getColorRed())
--     _newItem:setColorGreen(_oldItem:getColorGreen())
--     _newItem:setColorBlue(_oldItem:getColorBlue())

--     _newItem:setCustomColor(_oldItem:isCustomColor())

--     -- _newItem:setIconsForTexture(_oldItem:getIconsForTexture())
--     print("uh texture?: "..tostring(_oldItem:getTexture()))
--     -- print("uh texture: "..tostring(_oldItem:getPalette()))

--     return _newItem
-- end

-- ------------------------------------------------------------------------
-- ------------------------WASHABLE PROTECTION-----------------------------
-- ------------------------------------------------------------------------

-- function SWAB_Recipe.OnTest.DecontaminateMaskShared(_item, _requireWorn)
--     local modData = _item:getModData()
--     if modData.SwabRespiratoryItem then
--         if _item:isWorn() ~= _requireWorn then
--             return false
--         end
--         if modData.SwabRespiratoryExposure_RefreshAction == "wash" then
--             -- We can wash this assuming it's not already clean.
--            return modData.SwabRespiratoryExposure_ProtectionRemaining < 1
--         end
--     end
    
--     -- If we get this far we must be the water or soap or something...
--     return true
-- end

-- function SWAB_Recipe.OnTest.DecontaminateMask(_item)
--     return SWAB_Recipe.OnTest.DecontaminateMaskShared(_item, false)
-- end

-- function SWAB_Recipe.OnTest.DecontaminateMaskWhileWorn(_item)
--     return SWAB_Recipe.OnTest.DecontaminateMaskShared(_item, true)
-- end

-- function SWAB_Recipe.OnCreate.DecontaminateMaskShared(_items, _throwawayResult, _player, _isWorn)
--     local washedItem = nil
--     for i = 0, _items:size() - 1 do
--         local item = _items:get(i)
--         local modData = item:getModData()
--         if modData.SwabRespiratoryItem then
--             -- This must be the mask.
--             washedItem = item
--         end
--     end

--     if washedItem then
--         --local washedItem = SWAB_Recipe.CopyItemProperties(washedItem, _player:getInventory():AddItem(washedItem:getType()), _player, _isWorn)
--         washedItem:setWetness(100) -- We just washed it, after all...
--         washedItem:getModData().SwabRespiratoryExposure_ProtectionRemaining = 1
--         -- This is a total hack, we don't want to actually keep the result of this recipe.
--         _player:getModData()[SWAB_Config.playerModDataId].cleanupThrowawayItems = true
--     else
--         print("SWAB: Error, expecting an old item, but none was found")
--     end
-- end

-- function SWAB_Recipe.OnCreate.DecontaminateMask(_items, _result, _player)
--     SWAB_Recipe.OnCreate.DecontaminateMaskShared(_items, _result, _player, false)
-- end

-- function SWAB_Recipe.OnCreate.DecontaminateMaskWhileWorn(_items, _result, _player)
--     SWAB_Recipe.OnCreate.DecontaminateMaskShared(_items, _result, _player, true)
-- end