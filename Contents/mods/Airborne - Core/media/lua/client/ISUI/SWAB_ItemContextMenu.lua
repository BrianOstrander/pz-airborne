SWAB_ItemContextMenu = {}

-- TODO: change name of this to be more generic
function SWAB_ItemContextMenu.OnFillInventoryObjectContextMenu(_playerIndex, _context, _itemStack)

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

        -- if type(itemStackData) == "userdata" then
        --     _context:addOption("item is userdata: "..tostring(itemStackData), nil, nil)
        --     if itemStackData.size then
        --         -- This is a java array.
        --         for i = 0, itemStackData:size() - 1 do
        --             _context:addOption(tostring(itemStackData:get(i)), nil, nil)
        --         end
        --     end
        -- else
        --     _context:addOption("item is...: "..tostring(itemStackData), nil, nil)
        -- end

        -- _context:addOption(tostring(type(item)), nil, nil)

        -- _context:addOption(tostring(itemStack), nil, nil)

        -- for _, item in pairs(itemStack.items) do
        --     _context:addOption(tostring(item), nil, nil)
        --     -- for itemK, itemV in pairs(item) do
        --     --     _context:addOption(itemK..": "..tostring(itemV), nil, nil)
        --     -- end
        --     -- _context:addOption("-----", nil, nil)
        --     -- for itemK, itemV in pairs(item) do
        --     --     local mainOption = _context:addOption(itemK..": "..tostring(itemV), nil, nil)
        --     -- end
        -- end

        --print("uh: "..tostring(_context)..", "..tostring(ISContextMenu)..", "..tostring(_context.addOption)..", "..tostring(item.getName))
        -- for _, item in pairs(itemStack.items) do
        --     _context:addOption(tostring(item), nil, nil)
        --     -- _context:addOption("-----", nil, nil)
        --     -- for itemK, itemV in pairs(item) do
        --     --     local mainOption = _context:addOption(itemK..": "..tostring(itemV), nil, nil)
        --     -- end
        -- end
        -- local mainSubMenu = ISContextMenu:getNew(_context)
        -- _context:addSubMenu(mainOption, mainSubMenu)
    end

    if not item then
        return
    end

    local itemModData = item:getModData()

    if itemModData.SwabRespiratoryItem then
        if itemModData.SwabRespiratoryExposure_RefreshAction == "wash" then
            SWAB_ItemContextMenu.AddWashMaskOption(_context, item)
        elseif itemModData.SwabRespiratoryExposure_RefreshAction == "replace_filter" then
            SWAB_ItemContextMenu.AddRemoveFilterOption(_context, item)
            SWAB_ItemContextMenu.AddInsertFilterOption(_context, item)
            SWAB_ItemContextMenu.AddReplaceFilterOption(_context, item)
        end
    end

    -- local playerInventory = getPlayer():getInventory()

    -- local filters = {}
    -- local itemsForFilterInsert = {}
    -- local itemsForFilterReplace = {}

    -- local clothingInventory = playerInventory:getItemsFromCategory("Container")
    -- for itemIndex = 0, clothingInventory:size() - 1 do
    --     local item = clothingInventory:get(itemIndex)
    --     if not item:isHidden() then
    --         local itemModData = item:getModData()
    --         if itemModData.SwabRespiratoryItem then
    --             if itemModData.SwabRespiratoryExposure_RefreshAction == "replace_filter" then
    --                 if PZMath.equal(0, itemModData.SwabRespiratoryExposure_ProtectionRemaining) then
    --                     -- This item needs a filter inserted.
    --                     table.insert(itemsForFilterInsert, item)
    --                 elseif not PZMath.equal(1, itemModData.SwabRespiratoryExposure_ProtectionRemaining) then
    --                     -- This item has a filter, but it's used.
    --                     table.insert(itemsForFilterReplace, item)
    --                 end
    --             end
    --         end
	-- 	end
	-- end

    -- if itemsForFilterReplace then
    --     -- TODO LOCALIZE
    --     local mainOption = _context:addOption("Replace Filter", nil, nil);
    --     local mainSubMenu = ISContextMenu:getNew(context)
    --     context:addSubMenu(mainOption, mainSubMenu)    
    -- end

    -- local mainOption = context:addOption(getText("ContextMenu_Wash"), nil, nil);
    -- local mainSubMenu = ISContextMenu:getNew(context)
    -- context:addSubMenu(mainOption, mainSubMenu)

    ------------------

	-- local container = nil
    -- local resItems = {}
    -- for i,v in ipairs(items) do
    --     if not instanceof(v, "InventoryItem") then
    --         for _, it in ipairs(v.items) do
    --             resItems[it] = true
    --         end
    --         container = v.items[1]:getContainer()
    --     else
    --         resItems[v] = true
    --         container = v:getContainer()
    --     end
    -- end

    -- local listItems = {}
    -- for v, _ in pairs(resItems) do
    --     table.insert(listItems, v)
    -- end

    -- local removeOption = context:addDebugOption("Delete:")
    -- local subMenuRemove = ISContextMenu:getNew(context)
    -- context:addSubMenu(removeOption, subMenuRemove)

    -- subMenuRemove:addOption("1 item", listItems[1], ISRemoveItemTool.removeItem, player)
    -- subMenuRemove:addOption("selected", listItems, ISRemoveItemTool.removeItems, player)
end
Events.OnFillInventoryObjectContextMenu.Add(SWAB_ItemContextMenu.OnFillInventoryObjectContextMenu)

function SWAB_ItemContextMenu.AddWashMaskOption(_context, _item)
    if PZMath.equal(1, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is clean, no need to add an option.
        return
    end
    _context:addOption("Wash Mask", _item, SWAB_ItemContextMenu.OnWashMask)
end

function SWAB_ItemContextMenu.AddRemoveFilterOption(_context, _item)
    if PZMath.equal(0, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is contaminated, no filter to remove.
        return
    end
    _context:addOption("Remove Filter", _item, SWAB_ItemContextMenu.OnRemoveFilter)
end

function SWAB_ItemContextMenu.AddInsertFilterOption(_context, _item)
    if not PZMath.equal(0, _item:getModData().SwabRespiratoryExposure_ProtectionRemaining) then
        -- This is not completely contaminated, need to remove or replace filter instead.
        return
    end

    local filter = SWAB_ItemContextMenu.GetBestFilter(0)

    if not filter then
        -- No filter available for insertion.
        return
    end

    _context:addOption(
        "Insert Filter",
        {
            target = _item,
            filter = filter,
        },
        SWAB_ItemContextMenu.OnInsertFilter
    )
end

function SWAB_ItemContextMenu.AddReplaceFilterOption(_context, _item)
    local protectionRemaining = _item:getModData().SwabRespiratoryExposure_ProtectionRemaining
    if PZMath.equal(0, protectionRemaining) or PZMath.equal(1, protectionRemaining) then
        -- This is not contaminated, no need to replace a filter.
        return
    end

    local filter = SWAB_ItemContextMenu.GetBestFilter(protectionRemaining)

    if not filter then
        -- No better filter available for replacement.
        return
    end

    _context:addOption(
        "Replace Filter",
        {
            target = _item,
            filter = filter,
        },
        SWAB_ItemContextMenu.OnReplaceFilter
    )
end

------------------------------------------------------------------------
-------------------------------QUEUES-----------------------------------
------------------------------------------------------------------------

function SWAB_ItemContextMenu.OnWashMask(_item)
    print("want to clean "..tostring(_item))
end

function SWAB_ItemContextMenu.OnRemoveFilter(_item)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _item)
    ISTimedActionQueue.add(SWAB_RemoveFilter:new(getPlayer(), _item, 30))
end

function SWAB_ItemContextMenu.OnInsertFilter(_payload)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.target)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.filter)
    ISTimedActionQueue.add(SWAB_InsertFilter:new(getPlayer(), _payload.target, _payload.filter , 30))
end

function SWAB_ItemContextMenu.OnReplaceFilter(_payload)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.target)
    ISInventoryPaneContextMenu.transferIfNeeded(getPlayer(), _payload.filter)
    ISTimedActionQueue.add(SWAB_ReplaceFilter:new(getPlayer(), _payload.target, _payload.filter , 30))
end

------------------------------------------------------------------------
-------------------------------UTILITY----------------------------------
------------------------------------------------------------------------

function SWAB_ItemContextMenu.GetBestFilter(_usedDeltaMinimum)
    local inventory = getPlayer():getInventory()
    local result = inventory:getBestTypeEval("SWAB.StandardFilter", SWAB_ItemContextMenu.EvaluateFilter)

    if result then
        if PZMath.equal(1, result:getUsedDelta()) then
            -- We already found an unused filter in our main inventory.
            return result
        elseif result:getUsedDelta() <= _usedDeltaMinimum then
            -- We don't care about results lower than our usedDeltaMinimum
            result = nil
        end
    end

    subInventoryResult = inventory:getBestTypeEvalRecurse("SWAB.StandardFilter", SWAB_ItemContextMenu.EvaluateFilter)

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

------------------------------------------------------------------------
------------------------------PREDICATES--------------------------------
------------------------------------------------------------------------

function SWAB_ItemContextMenu.EvaluateFilter(_filter1, _filter2)
    return _filter1:getUsedDelta() - _filter2:getUsedDelta()
end