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