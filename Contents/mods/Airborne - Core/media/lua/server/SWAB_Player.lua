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
        --modData.contaminationAbsorbed = 0.0
        _player:getModData()[SWAB_Config.playerModDataId] = modData
        _player:transmitModData()
    end
end
Events.OnCreatePlayer.Add(SWAB_Player.OnCreatePlayer)

-- function SWAB_Player.OnUpdate(_player)
--     for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
--         local modData = player:getModData()[SWAB_Config.playerModDataId]

--         if modData then
--             modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposure(player)
--             -- if modData.respiratoryExposure == 0.0 then
--             --     modData.respiratoryExposure = 1.0
--             -- else
--             --     modData.respiratoryExposure = PZMath.clampFloat(modData.respiratoryExposure - 0.15, 0.0, 1.0)
--             -- end

--             -- player:getModData()[SWAB_Config.playerModDataId] = modData
--         end
--     end
-- end
-- Events.OnPlayerUpdate.Add(SWAB_Player.OnUpdate)

function SWAB_Player.OnUpdate(_player)
    local modData = _player:getModData()[SWAB_Config.playerModDataId]

    if modData then
        modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposure(_player)
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

            return _player:getSquare():getModData()[SWAB_Config.squareExposureModDataId]

            -- local room = _player:getSquare():getRoom()

            -- if room then
            --     room = room:getRoomDef()

            --     local roomData = ModData.get(SWAB_Config.getRoomModDataId(room))
            --     if roomData then
            --         -- Rooms have their exposures calculated elsewhere
            --         return roomData.respiratoryExposure
            --     end
            --     return -1 -- temp
            --     -- It's normal to not have roomdata for a couple updates, it means a player must have entered
            --     -- a room for the first time
            -- else
            --     print("SWAB: Error, player is inside but unable to find a room")
            -- end


            -- TODO: check for open doors and windows, broken walls or windows, etc

            -- if _player:getSquare():getE() then
            --     return tostring(_player:getSquare():getE():getRoomID())
            -- else 
            --     return "uh nil"
            -- end

            -- return SWAB_Player.CalculateBreeze(_player:getSquare(), IsoDirections.S)

            -- for _, square in ipairs(_player:getSquare():getRoom():getSquares()) do
            --     local breezeN = SWAB_Player.CalculateBreeze(square, square:getN())
            --     return breezeN
            -- end
            --return 4
        end
    end
end

-- function SWAB_Player.CalculateBreeze(_originSquare, _direction)

--     local neighborSquare = nil

--     if _direction == IsoDirections.N then
--         neighborSquare = _originSquare:getN()
--     elseif _direction == IsoDirections.E then
--         neighborSquare = _originSquare:getE()
--     elseif _direction == IsoDirections.S then
--         neighborSquare = _originSquare:getS()
--     elseif _direction == IsoDirections.W then
--         neighborSquare = _originSquare:getW()
--     else
--         print("SWAB: Error, invalid IsoDirection: "..tostring(_direction))
--         return 0
--     end

--     if not neighborSquare then
--         -- No neighbor, we hit a wall
--         return 0
--     end
    
--     if _originSquare:getRoomID() == neighborSquare:getRoomID() then
--         -- Same room
--         return 0
--     end

--     --local props = _originSquare:getProperties()
	
--     if neighborSquare:getRoomID() == -1 then
--         -- Outdoors

--         local window = _originSquare:getWindowTo(neighborSquare)
        
--         if window then
--             if window:IsOpen() or window:isSmashed() then
--                 -- Window open or smashed
--                 return 6
--             else 
--         end

--         local door = _originSquare:getDoorTo(neighborSquare)

--         if door then
--             if door:IsOpen() or door:isDestroyed() then
--                 -- Door open or smashed
--                 return 6
--             end
--         end
        
--         -- Missing or smashed window or door
--         return "uh"
--     else
--         -- Another room
--         return 0 -- temp
--     end
-- end

-- function SWAB_Player.EveryTenMinutes()
--     for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
--         local modData = player:getModData()[SWAB_Config.playerModDataId]

--         if modData then
--             if modData.contaminationAbsorbed == 0.0 then
--                 modData.contaminationAbsorbed = 1.0
--             else
--                 modData.contaminationAbsorbed = PZMath.clampFloat(modData.contaminationAbsorbed - 0.15, 0.0, 1.0)
--             end

--             player:getModData()[SWAB_Config.playerModDataId] = modData
--         end
--     end
-- end
-- Events.EveryTenMinutes.Add(SWAB_Player.EveryTenMinutes)