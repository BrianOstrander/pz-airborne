SWAB_InventoryContextMenu = {}

function SWAB_InventoryContextMenu.OnFillInventoryObjectContextMenu(_playerIndex, _context, _itemStack)

    local item = nil

    for _, itemStackData in pairs(_itemStack) do
        
        if type(itemStackData) == "table" then
            item = itemStackData.items[1]
        elseif type(itemStackData) == "userdata" then
            item = itemStackData
        end

        if item then
            break
        end
    end

    if not item then
        return
    end

    local itemModData = item:getModData()

    if itemModData.SwabRespiratoryItem then
        if itemModData.SwabRespiratoryExposure_RefreshAction == "wash" then
            SWAB_InventoryContextMenu.AddDecontaminateMaskOption(_context, item)
        elseif itemModData.SwabRespiratoryExposure_RefreshAction == "replace_filter" then
            SWAB_InventoryContextMenu.AddRemoveFilterOption(_context, item)
            SWAB_InventoryContextMenu.AddInsertFilterOption(_context, item)
            SWAB_InventoryContextMenu.AddReplaceFilterOption(_context, item)
        end
    elseif itemModData.SwabRespiratoryItemFilter then
        SWAB_InventoryContextMenu.AddInsertSpecificFilterOption(_context, item)
    end
end
Events.OnFillInventoryObjectContextMenu.Add(SWAB_InventoryContextMenu.OnFillInventoryObjectContextMenu)

function SWAB_InventoryContextMenu.AddDecontaminateMaskOption(_context, _item)
    if PZMath.equal(1, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is not contaminated, no need to decontaminate it.
        return
    end

    local water = SWAB_InventoryContextMenu.GetBestWaterSource(SWAB_DecontaminateMask.GetRequiredWater())

    if not water then
        return
    end

    -- TODO: Localize
    _context:addOption(
        "Decontaminate",
        {
            item = _item,
            water = water,
        },
        SWAB_InventoryContextMenu.OnDecontaminateMask
    )
end

function SWAB_InventoryContextMenu.AddRemoveFilterOption(_context, _item)
    if PZMath.equal(0, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is contaminated, no filter to remove.
        return
    end
    -- TODO: Localize
    _context:addOption("Remove Filter", _item, SWAB_InventoryContextMenu.OnRemoveFilter)
end

function SWAB_InventoryContextMenu.AddInsertFilterOption(_context, _item)
    if not PZMath.equal(0, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is not completely contaminated, need to remove or replace filter instead.
        return
    end

    local filter = SWAB_InventoryContextMenu.GetBestFilter(0)

    if not filter then
        -- No filter available for insertion.
        return
    end

    -- TODO: Localize
    _context:addOption(
        "Insert Filter",
        {
            target = _item,
            filter = filter,
        },
        SWAB_InventoryContextMenu.OnInsertFilter
    )
end

-- Item being passed in is a filter that we want to find a mask to insert it into.
function SWAB_InventoryContextMenu.AddInsertSpecificFilterOption(_context, _item)
    if PZMath.equal(0, _item:getUsedDelta()) then
        -- This shouldn't happen, but just incase we don't want to waste time inserting dead filters.
        return
    end

    local filterTarget = SWAB_InventoryContextMenu.GetBestFilterTarget(0)

    if not filterTarget then
        -- No filter target available for insertion.
        return
    end

    -- TODO: Localize

    if 0 < filterTarget:getModData().SwabRespiratoryExposure_ProtectionRemaining then
        -- We found a filter target that needs replacement.
        _context:addOption(
            "Replace Filter",
            {
                target = filterTarget,
                filter = _item,
            },
            SWAB_InventoryContextMenu.OnReplaceFilter
        )
    else
        -- Must have found a filter target with no filter at all.
        _context:addOption(
            "Insert Filter",
            {
                target = filterTarget,
                filter = _item,
            },
            SWAB_InventoryContextMenu.OnInsertFilter
        )
    end
end

function SWAB_InventoryContextMenu.AddReplaceFilterOption(_context, _item)
    local protectionRemaining = _item:getModData().SwabRespiratoryExposure_ProtectionRemaining
    if PZMath.equal(0, protectionRemaining) or PZMath.equal(1, protectionRemaining) then
        -- This is not contaminated, no need to replace a filter.
        return
    end

    local filter = SWAB_InventoryContextMenu.GetBestFilter(protectionRemaining)

    if not filter then
        -- No better filter available for replacement.
        return
    end

    -- TODO: Localize
    _context:addOption(
        "Replace Filter",
        {
            target = _item,
            filter = filter,
        },
        SWAB_InventoryContextMenu.OnReplaceFilter
    )
end

------------------------------------------------------------------------
-------------------------------QUEUES-----------------------------------
------------------------------------------------------------------------

function SWAB_InventoryContextMenu.OnDecontaminateMask(_payload)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.item)
    ISTimedActionQueue.add(
        SWAB_DecontaminateMask:new(
            getPlayer(),
            _payload.water, -- sink or bottle
            {}, -- soaps
            _payload.item,
            _payload.item:getModData().SwabRespiratoryExposure_ProtectionRemaining,
            0, -- blood
            0, -- dirt,
            true
        )
    )
end

function SWAB_InventoryContextMenu.OnRemoveFilter(_item)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _item)
    ISTimedActionQueue.add(SWAB_RemoveFilter:new(getPlayer(), _item, 30))
end

function SWAB_InventoryContextMenu.OnInsertFilter(_payload)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.target)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.filter)
    ISTimedActionQueue.add(SWAB_InsertFilter:new(getPlayer(), _payload.target, _payload.filter , 30))
end

function SWAB_InventoryContextMenu.OnReplaceFilter(_payload)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.target)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.filter)
    ISTimedActionQueue.add(SWAB_ReplaceFilter:new(getPlayer(), _payload.target, _payload.filter , 30))
end

------------------------------------------------------------------------
-------------------------------UTILITY----------------------------------
------------------------------------------------------------------------

function SWAB_InventoryContextMenu.GetBestWaterSource(_waterAmount)
    local result = nil

    -- Check for nearby water sources first
    for x = getPlayer():getX() - 1, getPlayer():getX() + 1 do
        for y = getPlayer():getY() - 1, getPlayer():getY() + 1 do
            local squareObjects = getCell():getGridSquare(x, y, getPlayer():getZ()):getObjects()
            for i = 0, squareObjects:size() - 1 do
                local squareObject = squareObjects:get(i)
                if SWAB_DecontaminateMask.HasRequiredWater(squareObject, SWAB_DecontaminateMask.GetRequiredWater()) then
                    if not result or IsoUtils.DistanceTo(getPlayer():getX(), getPlayer():getY(), x, y) < IsoUtils.DistanceTo(getPlayer():getX(), getPlayer():getY(), result:getX(), result:getY()) then
                        result = squareObject
                    end
                end
            end
        end
    end
    
    if not result then
        local inventory = getPlayer():getInventory()
        result = inventory:getFirstEvalArgRecurse(SWAB_DecontaminateMask.HasRequiredWater, _waterAmount)
    end

    return result
end

-- function SWAB_InventoryContextMenu.GetBestSoapSource()
-- end

function SWAB_InventoryContextMenu.GetBestFilter(_usedDeltaMinimum)
    local inventory = getPlayer():getInventory()
    local result = inventory:getBestTypeEval("SWAB.StandardFilter", SWAB_InventoryContextMenu.EvaluateFilter)

    if result then
        if PZMath.equal(1, result:getUsedDelta()) then
            -- We already found an unused filter in our main inventory.
            return result
        elseif result:getUsedDelta() <= _usedDeltaMinimum then
            -- We don't care about results lower than our usedDeltaMinimum
            result = nil
        end
    end

    subInventoryResult = inventory:getBestTypeEvalRecurse("SWAB.StandardFilter", SWAB_InventoryContextMenu.EvaluateFilter)

    if subInventoryResult then
        if _usedDeltaMinimum < subInventoryResult:getUsedDelta() then
            if not result or result:getUsedDelta() < subInventoryResult:getUsedDelta() then
                -- Either the first result was nil, or we are a better filter.
                result = subInventoryResult
            end
        end
    end

    return result
end

function SWAB_InventoryContextMenu.GetBestFilterTarget()
    local result = nil
    local items = getPlayer():getInventory():getItems()
    for itemIndex = 0, items:size() - 1 do
        local item = items:get(itemIndex)
        local itemModData = item:getModData()
        if itemModData.SwabRespiratoryItem then
            if item:isWorn() then
                -- Always assume we're replacing filters on worn protection.
                return item
            end

            if not result then
                -- No result yet? Set one.
                result = item
            elseif itemModData.SwabRespiratoryExposure_ProtectionRemaining < result:getModData().SwabRespiratoryExposure_ProtectionRemaining then
                -- We assume we want to get the lowest protection.
                result = item
            end
        end
    end

    return result
end

------------------------------------------------------------------------
------------------------------PREDICATES--------------------------------
------------------------------------------------------------------------

function SWAB_InventoryContextMenu.EvaluateFilter(_filter1, _filter2)
    return _filter1:getUsedDelta() - _filter2:getUsedDelta()
end