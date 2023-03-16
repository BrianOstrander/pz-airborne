SWAB_Recipe = SWAB_Recipe or {}
SWAB_Recipe.OnTest = SWAB_Recipe.OnTest or {}
SWAB_Recipe.OnCreate = SWAB_Recipe.OnCreate or {}

function SWAB_Recipe.OnTest.InsertFilterShared(_item, _requireWorn)
    local modData = _item:getModData()
    if modData and modData["SwabRespiratoryItem"] then
        if _item:isWorn() ~= _requireWorn then
            return false
        end
        if modData["SwabRespiratoryExposure_RefreshAction"] == "replace_filter" then
           return PZMath.equal(0, modData["SwabRespiratoryExposure_ProtectionRemaining"])
        end
    end
    
    return 0 < _item:getUsedDelta() -- We must be the filter...
end

function SWAB_Recipe.OnTest.InsertFilter(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, false)
end

function SWAB_Recipe.OnTest.InsertFilterWhileWorn(_item)
    return SWAB_Recipe.OnTest.InsertFilterShared(_item, true)
end

function SWAB_Recipe.OnCreate.InsertFilterShared(_items, _result, _player, _isWorn)
    print("running is worn "..tostring(_isWorn))
    local oldItem = nil
    for i = 0, _items:size() - 1 do
        local item = _items:get(i)
        local modData = item:getModData()
        if modData["SwabRespiratoryItemFilter"] then
            -- This is the filter item.
            _result:getModData()["SwabRespiratoryExposure_ProtectionRemaining"] = item:getUsedDelta()
        elseif modData["SwabRespiratoryItem"] then
            -- This is the old item we're destroying.
            oldItem = item
        else
            print("SWAB: Error, unrecognized item: "..tostring(item:getType()))
        end
    end

    if oldItem then
        if _isWorn then
            _player:setWornItem(_result:getBodyLocation(), _result);
        end
        _result:setCondition(oldItem:getCondition())
        _result:setBloodLevel(oldItem:getBloodLevel())
        _result:setDirtyness(oldItem:getDirtyness())
        _result:setWetness(oldItem:getWetness())
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

-- function SWAB_Recipe.OnTest.InsertFilter(_item)
--     local modData = _item:getModData()
--     if modData and modData["SwabRespiratoryItem"] then
--         if modData["SwabRespiratoryExposure_RefreshAction"] == "replace_filter" then
--            return PZMath.equal(0, modData["SwabRespiratoryExposure_ProtectionRemaining"])
--         end
--     end
    
--     return 0 < _item:getUsedDelta() -- We must be the filter...
-- end

-- -- When creating item in result box of crafting panel.
-- function SWAB_Recipe.OnCreate.InsertFilter(_items, _result, _player)
--     local container = nil
--     local filter = nil
--     for i = 0, _items:size() - 1 do
--         local item = _items:get(i)
--         local modData = item:getModData()
--         if modData["SwabRespiratoryItem"] then
--             container = item
--         elseif modData["SwabRespiratoryItemFilter"] then
--             filter = item
--         else
--             print("SWAB: Error, unrecognized item: "..tostring(item:getType()))
--         end
--     end
--     if container and filter then
--         container:getModData()["SwabRespiratoryExposure_ProtectionRemaining"] = filter:getUsedDelta()
--         -- We don't actually want the contaminated filter junking up the player's inventory.
--         _player:getInventory():Remove(_result)
--     end
-- end