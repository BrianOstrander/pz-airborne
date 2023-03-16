SWAB_Recipe = SWAB_Recipe or {}
SWAB_Recipe.OnTest = SWAB_Recipe.OnTest or {}
SWAB_Recipe.OnCreate = SWAB_Recipe.OnCreate or {}

function SWAB_Recipe.CopyItemProperties(_oldItem, _newItem, _player, _isWorn)
    if _isWorn then
        _player:setWornItem(_newItem:getBodyLocation(), _newItem);
    end
    _newItem:setFavorite(_oldItem:isFavorite())
    _newItem:setCondition(_oldItem:getCondition())
    _newItem:setBloodLevel(_oldItem:getBloodLevel())
    _newItem:setDirtyness(_oldItem:getDirtyness())
    _newItem:setWetness(_oldItem:getWetness())

    return _newItem
end

function SWAB_Recipe.OnTest.InsertFilterShared(_item, _requireWorn, _requireUsed)
    local modData = _item:getModData()
    if modData and modData["SwabRespiratoryItem"] then
        if _item:isWorn() ~= _requireWorn then
            return false
        end
        if modData["SwabRespiratoryExposure_RefreshAction"] == "replace_filter" then
            -- We can insert a new filter only when we have zero protection remaining.
           return PZMath.equal(0, modData["SwabRespiratoryExposure_ProtectionRemaining"])
        end
    end
    
    -- If we get this far we must be the filter...

    if PZMath.equal(0, _item:getUsedDelta()) then
        -- Can't insert fully used filters.
        return false
    end

    if _requireUsed then
        -- If this is a used filter insert, check to make sure the filter is actually used.
        return not PZMath.equal(1, _item:getUsedDelta())
    end

    -- Must be a new filter insert.
    return true
end

function SWAB_Recipe.OnTest.InsertFilter(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, false, false)
end

function SWAB_Recipe.OnTest.InsertFilterWhileWorn(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, true, false)
end

function SWAB_Recipe.OnTest.InsertUsedFilter(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, false, true)
end

function SWAB_Recipe.OnTest.InsertUsedFilterWhileWorn(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, true, true)
end

function SWAB_Recipe.OnCreate.InsertFilterShared(_items, _throwawayResult, _player, _isWorn)
    local oldItem = nil
    local filterUsedDelta = 0
    for i = 0, _items:size() - 1 do
        local item = _items:get(i)
        local modData = item:getModData()
        if modData["SwabRespiratoryItemFilter"] then
            -- This is the filter item.
            filterUsedDelta = item:getUsedDelta()
        elseif modData["SwabRespiratoryItem"] then
            -- This is the old item we're destroying.
            oldItem = item
        else
            print("SWAB: Error, unrecognized item: "..tostring(item:getType()))
        end
    end

    if oldItem then
        local newItem = SWAB_Recipe.CopyItemProperties(oldItem, _player:getInventory():AddItem(oldItem:getType()), _player, _isWorn)
        newItem:getModData()["SwabRespiratoryExposure_ProtectionRemaining"] = filterUsedDelta
        -- Recipes are probably easier than I'm making them out to be, but for now I'm doing this:
        _throwawayResult:setUsedDelta(0)
        _player:getModData()[SWAB_Config.playerModDataId].cleanupUsedFilters = true
    else
        print("SWAB: Error, expecting an old item, but none was found")
    end
end

function SWAB_Recipe.OnCreate.InsertFilter(_items, _result, _player)
    SWAB_Recipe.OnCreate.InsertFilterShared(_items, _result, _player, false)
end

function SWAB_Recipe.OnCreate.InsertFilterWhileWorn(_items, _result, _player)
    SWAB_Recipe.OnCreate.InsertFilterShared(_items, _result, _player, true)
end

function SWAB_Recipe.OnTest.RemoveFilterShared(_item, _requireWorn)
    local modData = _item:getModData()
    if modData and modData["SwabRespiratoryItem"] then
        if _item:isWorn() ~= _requireWorn then
            return false
        end
        if modData["SwabRespiratoryExposure_RefreshAction"] == "replace_filter" then
            -- Can't remove a fully used filter.
           return not PZMath.equal(0, modData["SwabRespiratoryExposure_ProtectionRemaining"])
        end
    end
end

function SWAB_Recipe.OnCreate.RemoveFilterShared(_items, _usedFilterResult, _player, _isWorn)
    local oldItem = nil
    for i = 0, _items:size() - 1 do
        local item = _items:get(i)
        local modData = item:getModData()
        if modData["SwabRespiratoryItem"] then
            -- This is the item the filter is being removed from.
            oldItem = item
            _usedFilterResult:setUsedDelta(modData["SwabRespiratoryExposure_ProtectionRemaining"])
            if not PZMath.equal(1, _usedFilterResult:getUsedDelta()) then
                _usedFilterResult:setName(SWAB_ItemUtility.GetUsedFilterName(_usedFilterResult:getDisplayName()))
            end
        else
            print("SWAB: Error, unrecognized item: "..tostring(item:getType()))
        end
    end

    if oldItem then
        local newItem = SWAB_Recipe.CopyItemProperties(oldItem, _player:getInventory():AddItem(oldItem:getType()), _player, _isWorn)
        newItem:getModData()["SwabRespiratoryExposure_ProtectionRemaining"] = 0
        newItem:setName(SWAB_ItemUtility.GetMissingFilterName(newItem:getDisplayName()))
    else
        print("SWAB: Error, expecting an old item, but none was found")
    end
end

function SWAB_Recipe.OnTest.RemoveFilter(_item)
    return SWAB_Recipe.OnTest.RemoveFilterShared(_item, false)
end

function SWAB_Recipe.OnTest.RemoveFilterWhileWorn(_item)
    return SWAB_Recipe.OnTest.RemoveFilterShared(_item, true)
end

function SWAB_Recipe.OnCreate.RemoveFilter(_items, _usedFilterResult, _player)
    SWAB_Recipe.OnCreate.RemoveFilterShared(_items, _usedFilterResult, _player, false)
end

function SWAB_Recipe.OnCreate.RemoveFilterWhileWorn(_items, _usedFilterResult, _player)
    SWAB_Recipe.OnCreate.RemoveFilterShared(_items, _usedFilterResult, _player, true)
end