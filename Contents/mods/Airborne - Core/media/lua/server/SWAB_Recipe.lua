SWAB_Recipe = SWAB_Recipe or {}
SWAB_Recipe.OnTest = SWAB_Recipe.OnTest or {}
SWAB_Recipe.OnCanPerform = SWAB_Recipe.OnCanPerform or {}
SWAB_Recipe.OnCreate = SWAB_Recipe.OnCreate or {}

function SWAB_Recipe.OnTest.PutStandardFiltersInBoxLarge(_item)
    if PZMath.equal(1, _item:getUsedDelta()) then
        -- This is an unused filter.
        return true
    end
    
    -- This must be a used filter.
    return false
end

function SWAB_Recipe.OnTest.PutMasksInBox(_item)
    local itemModData = _item:getModData()
    if itemModData.SwabRespiratoryExposure_ProtectionRemaining and PZMath.equal(1, itemModData.SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is an unused mask.
        return true
    end
    
    -- This must be a used mask.
    return false
end

function SWAB_Recipe.OnCreate.MakeshiftBandana(_items, _result, _player, _selectedItem)
    local iconColor = nil
    local visualColor = nil
    for itemIndex = 0, _items:size() - 1 do
        local item = _items:get(itemIndex)
        if item.getColor then
            -- Not sure every clothing item has a iconColor option or not...
            iconColor = item:getColor()
            visualColor = item:getVisual():getTint()
            break
        end
    end

    if not iconColor then
        iconColor = Color.new(0.5, 0.5, 0.5, 1.0)
    end

    if not visualColor then
        visualColor = ImmutableColor.new(0.5, 0.5, 0.5, 1.0)
    end

    _result:setColor(iconColor)
    _result:getVisual():setTint(visualColor)
    
    _result:setCustomColor(true)
end

function SWAB_Recipe.OnCanPerform.GetActivatedCharcoalFromPot(_recipe, _player, _item)
    return _item and _item:isCooked()
end

-- function SWAB_Recipe.OnCanPerform.GetBurntActivatedCharcoalFromPot(_recipe, _player, _item)
--     return _item and _item:isBurnt()
-- end

function SWAB_Recipe.OnCreate.GetActivatedCharcoalFromPot(_items, _result, _player, _selectedItem)
    -- The system seems aware that a pot is attatched to this item, and since a pot has a weight of 1,
    -- we subtract it from the item to find out how much we have left... incase the player like, ate
    -- it or something weird. The right side of the division operator is just the full weight of the
    -- ActiveCharcoalPot (3) minus the weight of a pot (1). Update this if the item ever changes!
    _result:setUsedDelta((_selectedItem:getUnequippedWeight() - 1) / 2)

	_player:getInventory():AddItem("Base.Pot")
    _player:getInventory():Remove(_selectedItem)
end