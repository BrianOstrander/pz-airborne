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