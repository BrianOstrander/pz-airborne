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
        _player:getModData()[SWAB_Config.playerModDataId] = modData
        _player:transmitModData()
    end
end
Events.OnCreatePlayer.Add(SWAB_Player.OnCreatePlayer)

function SWAB_Player.OnUpdate(_player)
    local modData = _player:getModData()[SWAB_Config.playerModDataId]

    if modData then
        -- If the player is teleporting, it's possible for this to be nil, so we keep the value the same.
        modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposure(_player) or modData.respiratoryExposure
    end
end
Events.OnPlayerUpdate.Add(SWAB_Player.OnUpdate)

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
                return 8
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