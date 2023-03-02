require "SWAB_Config"
require "SWAB_Data"
require "SWAB_Utilities"

SWAB_Player = {}

function SWAB_Player.OnCreatePlayer(_, _player)
	local modData = _player:getModData()[SWAB_Config.playerModDataId]

    if not modData then
        if SWAB_Config.debug.logging then
            print("SWAB: SWAB_Player.OnCreatePlayer initialize")
        end
        modData = {}
        modData.isInitialized = true
        modData.respiratoryExposure = 0
        modData.respiratoryAbsorptionRate = 0
        _player:getModData()[SWAB_Config.playerModDataId] = modData
        _player:transmitModData()
    end
end
Events.OnCreatePlayer.Add(SWAB_Player.OnCreatePlayer)

function SWAB_Player.EveryOneMinute()
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        local modData = player:getModData()[SWAB_Config.playerModDataId]

        if not modData then
            -- Must be before mod data is initialized by the game.
            return
        end

        -- If the player is teleporting, it's possible for this to be nil, so we keep the value the same.
        modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposure(player) or modData.respiratoryExposure

        if modData.respiratoryExposure then
            modData.respiratoryAbsorptionRate = SWAB_Player.CalculateRespiratoryAbsorptionRate(player, modData.respiratoryExposure)
        end
    end
end
Events.EveryOneMinute.Add(SWAB_Player.EveryOneMinute)

function SWAB_Player.CalculateRespiratoryAbsorptionRate(_player, _respiratoryExposure)
    local items = _player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsClothing() and item:isEquipped() then
            local itemModData = item:getModData()
            if itemModData then
                if itemModData["SwabRespiratoryItem"] then
                    -- We've established this is an item that provides respiratory protection.
                    local itemConsumedDuration = itemModData["SwabRespiratoryExposure_ConsumedDuration"] * SWAB_Config.itemConsumptionDurationMultiplier
                    local itemReduction = 0
                    local itemMinimum = 0
                    
                    local itemConsumedElapsed = itemModData["SwabRespiratoryExposure_ConsumedElapsed"]
                    local itemConsumedElapsedUpdated = PZMath.min(itemConsumedDuration, itemConsumedElapsed + 1)
                    if itemConsumedElapsed ~= itemConsumedElapsedUpdated then
                        itemConsumedElapsed = itemConsumedElapsedUpdated

                        if itemConsumedDuration <= itemConsumedElapsed then
                            -- Item has been contaminated
                            local itemNamePrefix = getText("ContextMenu_SWAB_ContaminatedPrefix")
                            local itemNameSuffix = getText("ContextMenu_SWAB_ContaminatedSuffix")

                            if itemNamePrefix == "ContextMenu_SWAB_ContaminatedPrefix" then
                                itemNamePrefix = ""
                            end

                            if itemNameSuffix == "ContextMenu_SWAB_ContaminatedSuffix" then
                                itemNameSuffix = ""
                            end

                            item:setName(itemNamePrefix..getText(item:getDisplayName())..itemNameSuffix)
                        end

                        itemModData["SwabRespiratoryExposure_ConsumedElapsed"] = itemConsumedElapsed
                    end

                    
                    if itemConsumedElapsed < itemConsumedDuration then
                        -- Still not entirely contaminated.
                        itemReduction = itemModData["SwabRespiratoryExposure_Reduction"]
                        itemMinimum = itemModData["SwabRespiratoryExposure_Minimum"]
                    end

                    -- We can never reduce our exposure below the item's rated minimum.
                    local itemExposure = PZMath.max(_respiratoryExposure + itemReduction, itemMinimum)

                    -- There's a chance that wearing this item is no better than going without it.
                    return PZMath.min(itemExposure, _respiratoryExposure)
                end
            end
        end
    end

    -- There's nothing protecting us.
    return _respiratoryExposure
end

function SWAB_Player.CalculateRespiratoryExposure(_player)
    local vehicle = _player:getVehicle()
    if vehicle then
        -- If we're cruising with any openings in our car, we get maximum exposure
        local vehicleMaximumExposure = 8
        if math.abs(vehicle:getCurrentSpeedKmHour()) < 12 then
            -- Staying under 5km/h reduces our exposure
            vehicleMaximumExposure = 6
        end

        -- Check all parts
        for i = 0, vehicle:getPartCount() do
            local part = vehicle:getPartByIndex(i);
            -- We found a valid window or door
            if part and (part:getWindow() or part:getDoor()) then
                if part:getInventoryItem() then 
                    -- The window or door is not missing
                    if part:getWindow() then
                        if part:getWindow():isOpen() then
                            -- Window is open
                            return vehicleMaximumExposure
                        end
                    elseif part:getDoor() then
                        if part:getDoor():isOpen() then
                            -- Door is open
                            return vehicleMaximumExposure
                        end
                    end
                else
                    -- The window or door is missing
                    return vehicleMaximumExposure
                end
            end
        end

        -- No doors or windows are open, and are all intact
        return 4
    else
        if _player:isOutside() then
            -- This may error out on topmost level? Not tested
            local squareAbove = nil
            local squareAboveX = _player:getX()
            local squareAboveY = _player:getY()
            local squareAboveZ = _player:getZ() + 1
            repeat
                squareAbove = getCell():getGridSquare(squareAboveX, squareAboveY, squareAboveZ)
                squareAboveZ = squareAboveZ + 1
            until not squareAbove or squareAbove:Is(IsoFlagType.attachedFloor)

            if squareAbove and squareAbove:Is(IsoFlagType.attachedFloor) then
                -- Must be under a patio
                return 6
            else
                -- Outside and entirely unprotected
                -- TODO: rain adds + 1, and fog adds + 2
                return 7
            end
        else
            -- Inside a room

            if _player:getSquare() then
                return _player:getSquare():getModData()[SWAB_Config.squareExposureModDataId]
            end
        end
    end

    -- Player must have been teleporting, be dead, or some other edge case
    return nil
end