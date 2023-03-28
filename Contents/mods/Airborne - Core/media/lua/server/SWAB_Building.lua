require "SWAB_Config"
require "SWAB_Utilities"

SWAB_Building = {}

SWAB_Building.porousWallsNorth = {}
SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_41"] = true
SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_45"] = true
SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_49"] = true
SWAB_Building.porousWallsNorth["walls_exterior_wooden_01_53"] = true
SWAB_Building.porousWallsNorth["constructedobjects_01_65"] = true
SWAB_Building.porousWallsNorth["constructedobjects_01_73"] = true

SWAB_Building.porousWallsWest = {}
SWAB_Building.porousWallsWest["walls_exterior_wooden_01_40"] = true
SWAB_Building.porousWallsWest["walls_exterior_wooden_01_44"] = true
SWAB_Building.porousWallsWest["walls_exterior_wooden_01_52"] = true
SWAB_Building.porousWallsWest["walls_exterior_wooden_01_48"] = true
SWAB_Building.porousWallsWest["constructedobjects_01_64"] = true
SWAB_Building.porousWallsWest["constructedobjects_01_72"] = true

SWAB_Building.lastTick = 0
SWAB_Building.buildingUpdateTickDelay = 0
SWAB_Building.ElectricGridEnabled = false


function SWAB_Building.OnTick(_tick)

    -- This tick calculation is probably overkill
    local tickDelta = 0
    if SWAB_Building.lastTick == 0 then
        SWAB_Building.lastTick = _tick
    else
        tickDelta = _tick - SWAB_Building.lastTick
        SWAB_Building.lastTick = _tick
    end

    SWAB_Building.buildingUpdateTickDelay = SWAB_Building.buildingUpdateTickDelay - tickDelta
    
    if 0 < SWAB_Building.buildingUpdateTickDelay then
        return
    end
    
    local tickOverflow = 0 - SWAB_Building.buildingUpdateTickDelay
    local ticksSinceLastUpdate = tickOverflow + SWAB_Config.buildingUpdateTickDelay    

    SWAB_Building.buildingUpdateTickDelay = SWAB_Config.buildingUpdateTickDelay

    local buildings = {}
    local buildingCount = 0
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        -- Teleporting players may not have squares
        if player:getSquare() then 
            local room = player:getSquare():getRoom()
            if room then

                local entry = {}
                entry.def = room:getRoomDef():getBuilding()
                entry.modDataId = SWAB_Config.getBuildingModDataId(entry.def)
                entry.modData = ModData.getOrCreate(entry.modDataId)

                buildings[entry.modDataId] = entry
                buildingCount = buildingCount + 1
            end
        end
    end

    if buildingCount == 0 then
        return
    end

    SWAB_Building.ElectricGridEnabled = SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier

    local buildingsSorted = {}
    for _, b in pairs(buildings) do
        if not b.modData.isInitialized then
            SWAB_Building.InitializeBuilding(b.def, b.modDataId, b.modData)
        end

        table.insert(buildingsSorted, b.modData)
    end

    -- Sort it so entries that have been updated the longest ago come first
    table.sort(
        buildingsSorted,
        function(b1, b2)
            return b2.ticksSinceUpdate < b1.ticksSinceUpdate
        end
    )

    local squareUpdatesPerTickRemaining = SWAB_Config.squareUpdatesPerTick
    local buildingIndex = 1

    while 0 < squareUpdatesPerTickRemaining do
        squareUpdatesPerTickRemaining = squareUpdatesPerTickRemaining - SWAB_Building.UpdateBuilding(buildingsSorted[buildingIndex], _tick, ticksSinceLastUpdate, squareUpdatesPerTickRemaining)
        buildingIndex = buildingIndex + 1
        if buildingCount < buildingIndex then
            break
        end
    end
end
Events.OnTick.Add(SWAB_Building.OnTick)

function SWAB_Building.InitializeBuilding(_def, _modDataId, _modData)
    _modData.isInitialized = true
    _modData.id = _modDataId
    _modData.defId = _def:getID()
    _modData.x = _def:getX()
    _modData.y = _def:getY()
    _modData.ticksSinceUpdate = 0
    _modData.lastRoomIndexInitialized = -1
    _modData.lastRoomIndexUpdated = -1
    _modData.lastRoomSquareIndex = -1
    _modData.buildingSquareUpdateBudgetMaximum = -1
    _modData.roomDatas = {}
    _modData.activeRoomCount = 0

    local rooms = _def:getRooms()

    -- TODO: check if this iteration causes lag in buildings with a high room count.
    for roomIndex = 0, rooms:size() - 1 do
        local room = rooms:get(roomIndex):getIsoRoom()
        local ignore = SWAB_Config.squareUpdateMaximum < room:getRoomDef():getArea()
        _modData.roomDatas[roomIndex] = {
            ignore                  = ignore,
            squareUpdateCount       = 0,
            staleUpdatesCount       = 0,
            skipUpdatesRemaining    = 0,
        }
        if not ignore then
            _modData.activeRoomCount = _modData.activeRoomCount + 1
        end
    end
    
    if SWAB_Config.debug.logging then
        print("SWAB: SWAB_Building.InitializeBuilding ".._modDataId)
    end
end

function SWAB_Building.UpdateBuilding(_modData, _tick, _tickDelta, _squareBudget)
    if _squareBudget == 0 then
        _modData.ticksSinceUpdate = _modData.ticksSinceUpdate + _tickDelta
        -- We're skipping this building, returning that no squares were updated.
        return 0
    end

    _modData.ticksSinceUpdate = 0

    local buildingDef = getWorld():getMetaGrid():getBuildingAt(_modData.x, _modData.y)
    local roomDefArray = buildingDef:getRooms()

    local squareBudgetRemaining = _squareBudget

    if -1 < _modData.lastRoomIndexUpdated then
        -- This building has been initialized, so lets set a proper update budget
        squareBudgetRemaining = PZMath.min(squareBudgetRemaining, _modData.buildingSquareUpdateBudgetMaximum)
    end

    local activeRoomsRemaining = _modData.activeRoomCount

    while 0 < squareBudgetRemaining and 0 < activeRoomsRemaining do
        
        local iterationResult = nil
        
        if _modData.lastRoomIndexInitialized < roomDefArray:size() then
            -- We still have rooms to initialize
            _modData.lastRoomIndexInitialized = PZMath.max(0, _modData.lastRoomIndexInitialized)

            if not _modData.roomDatas[_modData.lastRoomIndexInitialized].ignore then
                -- This room is small enough for us to initialize.
                iterationResult = SWAB_Building.IterateRoomSquares(
                    _modData,
                    roomDefArray:get(_modData.lastRoomIndexInitialized):getIsoRoom(),
                    _tick,
                    squareBudgetRemaining,
                    SWAB_Building.InitializeRoomSquare,
                    SWAB_Building.InitializeRoomDone
                )
            else
                -- Room is too big, we're ignoring it.
                _modData.lastRoomIndexInitialized = _modData.lastRoomIndexInitialized + 1
            end
        else
            -- We can update a room
            _modData.lastRoomIndexUpdated = PZMath.max(0, _modData.lastRoomIndexUpdated)
    
            if roomDefArray:size() <= _modData.lastRoomIndexUpdated then
                -- We've updated all the rooms, roll back to the first one
                _modData.lastRoomIndexUpdated = 0
            end
    
            local roomData = _modData.roomDatas[_modData.lastRoomIndexUpdated]

            if not roomData.ignore then
                -- This room is small enough for us to update.

                if 0 < roomData.skipUpdatesRemaining then
                    -- This room went to sleep earlier from having too many staleUpdates, or updates without changes,
                    -- so we are skipping it for a bit.
                    roomData.skipUpdatesRemaining = roomData.skipUpdatesRemaining - _tickDelta
                else
                    iterationResult = SWAB_Building.IterateRoomSquares(
                        _modData,
                        roomDefArray:get(_modData.lastRoomIndexUpdated):getIsoRoom(),
                        _tick,
                        squareBudgetRemaining,
                        SWAB_Building.UpdateRoomSquare,
                        SWAB_Building.UpdateRoomDone
                    )

                    roomData.squareUpdateCount = roomData.squareUpdateCount + iterationResult.updateCount

                    if iterationResult.isDone then
                        -- We've moved on to the next room
                        if roomData.squareUpdateCount == 0 then
                            -- No updates happened.
                            if SWAB_Config.roomStaleUpdateCountMaximum <= (roomData.staleUpdatesCount + 1) then
                                roomData.staleUpdatesCount = 0
                                roomData.skipUpdatesRemaining = SWAB_Config.roomSkipUpdateCount
                            else
                                roomData.staleUpdatesCount = roomData.staleUpdatesCount + 1
                            end
                        else
                            -- We had updates.
                            roomData.squareUpdateCount = 0
                            roomData.staleUpdatesCount = 0
                        end
                    end
                end
            else
                -- Room is too big, we're ignoring it.
                _modData.lastRoomIndexUpdated = _modData.lastRoomIndexUpdated + 1
            end
        end

        activeRoomsRemaining = activeRoomsRemaining - 1
        if iterationResult then
            -- Encountering stale or ignored rooms prevents us from iterating on them, causing this to be nil.
            squareBudgetRemaining = squareBudgetRemaining - iterationResult.checkCount
        end
    end

    -- Return the amount of squares we checked in this building.
    return _squareBudget - squareBudgetRemaining
end

function SWAB_Building.IterateRoomSquares(_modData, _room, _tick, _squareBudget, _onIterate, _onDone)
    _modData.lastRoomSquareIndex = PZMath.max(0, _modData.lastRoomSquareIndex)
    local squares = _room:getSquares()
    local squareBeginIndex = _modData.lastRoomSquareIndex
    local squareEndIndex = PZMath.min(squares:size() - 1, _modData.lastRoomSquareIndex + _squareBudget)
    local squareUpdateCount = 0
    for squareIndex = squareBeginIndex, squareEndIndex do
        _modData.lastRoomSquareIndex = _modData.lastRoomSquareIndex + 1
        local square = squares:get(squareIndex)

        if _onIterate(_modData, _room, square, _tick) then
            squareUpdateCount = squareUpdateCount + 1
            square:getModData().swab_last_tick = _tick
        end
    end

    -- Use room def's getArea function to ensure we are initializing all tiles, not just loaded ones.
    local isDone = _room:getRoomDef():getArea() <= _modData.lastRoomSquareIndex
    if isDone then
        -- We completed iterating over an entire room
        _modData.lastRoomSquareIndex = -1
        _onDone(_modData, _room, squares:size())
    end

    return { 
        checkCount = squareEndIndex - squareBeginIndex,
        updateCount = squareUpdateCount,
        isDone = isDone,
    }
end

function SWAB_Building.InitializeRoomSquare(_modData, _room, _square, _tick)
    local squareAbove = nil
    local squareAboveX = _square:getX()
    local squareAboveY = _square:getY()
    local squareAboveZ = _square:getZ() + 1
    repeat
        local squareAbove = getCell():getGridSquare(squareAboveX, squareAboveY, squareAboveZ)
        if squareAbove and not squareAbove:Is(IsoFlagType.attachedFloor) then
            squareAbove:getModData().swab_square_floor_claim_delta = _square:getZ() - squareAboveZ
        end
        squareAboveZ = squareAboveZ + 1
    until not squareAbove or squareAbove:Is(IsoFlagType.attachedFloor)
    -- TODO: Figure out how to see if this is a spawn building, and if so set the contamination to zero.
    _square:getModData().swab_square_exposure = SWAB_Config.buildingContaminationBaseline
    _square:getModData().swab_square_ceiling_height = squareAboveZ - 1

    -- Return true so this room doesn't get put to sleep.
    return true
end

function SWAB_Building.InitializeRoomDone(_modData, _room, _squareCount)
    -- Increment the room initialization index, so we know we can move onto the next one.
    _modData.lastRoomIndexInitialized = _modData.lastRoomIndexInitialized + 1
    _modData.buildingSquareUpdateBudgetMaximum = PZMath.max(0, _modData.buildingSquareUpdateBudgetMaximum) + _squareCount

end

function SWAB_Building.UpdateRoomSquare(_modData, _room, _square, _tick)
    local squareExposurePrevious = _square:getModData().swab_square_exposure
    local neighbor = SWAB_Building.CalculateSquareExposure(_square)
    
    if not neighbor or not neighbor.exposure then
        return
    end

    -- CalculateSquareExposure will sometimes return an outdoor square, which should not have
    -- a contamination value specified. If so we don't bother decreasing its contamination.
    local isContaminationFinite = neighbor.square:getModData().swab_square_exposure ~= nil

    if not squareExposurePrevious then
        -- No exposure, lets set ours to zero.
        squareExposurePrevious = 0
    end

    
    if squareExposurePrevious < neighbor.exposure and SWAB_Config.squareContaminationThreshold < (neighbor.exposure - squareExposurePrevious) then
        -- We don't currently have any contamination, or we have a neighbor that can contaminate us.
        -- The contamination difference is also larger than the minimum allowed.

        if isContaminationFinite then
            -- Our neighbor is not an outdoor source, so we spread exposure instead of simply pumping it up.
            local squareExposureDelta = PZMath.max(0, (neighbor.exposure - SWAB_Config.squareContaminationDeltaMinimum) - squareExposurePrevious) * 0.5
            _square:getModData().swab_square_exposure = squareExposurePrevious + squareExposureDelta
            neighbor.square:getModData().swab_square_exposure = neighbor.exposure - squareExposureDelta
        else
            -- Our neighbor is an outdoor source, so we just pump it in.
            _square:getModData().swab_square_exposure = neighbor.exposure - SWAB_Config.squareContaminationDeltaMinimum
        end
    end

    if SWAB_Config.debug.visualizeExposure then
        local highlightedFloor = _square:getFloor()
        if highlightedFloor then
            _square:getFloor():setHighlighted(true, false)
            local squareAlpha = (neighbor.exposure - 4)/3
            if not PZMath.equal(squareExposurePrevious,_square:getModData().swab_square_exposure) then
                _square:getFloor():setHighlightColor(1.0, 1.0, 0.0, squareAlpha)
            else
                _square:getFloor():setHighlightColor(1.0, 0.0, 0.0, squareAlpha)
            end
        end
    end

    if SWAB_Building.ElectricGridEnabled or _square:haveElectricity() then
        local squareObjects = _square:getObjects()
        for i = 0, squareObjects:size() - 1 do
            local squareObject = squareObjects:get(i)
            local filtration = squareObject:getProperties():Val("AirFiltration")
            if filtration then
                -- We found a filter
                filtration = filtration * SWAB_Config.AirFiltrationMultiplier * getGameTime():getMultiplier() * PZMath.max(1, _tick - _square:getModData().swab_last_tick)
                _square:getModData().swab_square_exposure = PZMath.max(0, _square:getModData().swab_square_exposure - filtration)
                -- TODO: decrease fuel in generator
                -- TODO: decrease battery
            end
        end 
    end

    return not PZMath.equal(squareExposurePrevious,_square:getModData().swab_square_exposure)
end

function SWAB_Building.UpdateRoomDone(_modData, _room, _squareCount)
    -- Increment the room update index, so we know we can move onto the next one.
    _modData.lastRoomIndexUpdated = _modData.lastRoomIndexUpdated + 1
end

function SWAB_Building.CalculateSquareExposure(_square)
    local directions = { IsoDirections.N, IsoDirections.E, IsoDirections.S, IsoDirections.W }

    local highestExposure = nil
    local highestExposureNeighbor = nil

    for _, direction in ipairs(directions) do
        
        -- Doing it this way out of an ill concieved idea that it might be more efficient.
        local neighbor = SWAB_Building.GetNeighboringSquare(_square, direction)
        local neighborExposure = SWAB_Building.CalculateSquareExposureFromNeighbor(_square, neighbor)
        
        if neighborExposure then
            if not highestExposure or highestExposure < neighborExposure then
                -- We take the highest level of exposure from our neighboring tiles
                highestExposure = neighborExposure
                highestExposureNeighbor = neighbor
            end
        end
    end

    if 1 < _square:getModData().swab_square_ceiling_height then
        -- There is a tile above this
        local neighborAbove = getCell():getGridSquare(_square:getX(), _square:getY(), _square:getZ() + 1)
        if neighborAbove then
            local neighborAboveExposure = neighborAbove:getModData().swab_square_exposure
            if neighborAboveExposure then
                if not highestExposure or highestExposure < neighborAboveExposure then
                    -- The neighbor above us is more contaminated
                    highestExposure = neighborAboveExposure
                    highestExposureNeighbor = neighborAbove
                end
            end
        end
    end

    return { square = highestExposureNeighbor, exposure = highestExposure }
end

function SWAB_Building.CalculateSquareExposureFromNeighbor(_square, _neighbor)
    if not _neighbor then
        return nil
    end

    if _neighbor:getRoomID() == -1 then
        if _neighbor:getModData().swab_square_floor_claim_delta then
            return _neighbor:getModData().swab_square_exposure
        end
        return 6
    else
        return _neighbor:getModData().swab_square_exposure
    end
end

function SWAB_Building.GetNeighboringSquare(_origin, _direction)
    local target = nil
    local neighbor = nil
    
    if _direction == IsoDirections.N then
        target = _origin
        neighbor = getCell():getGridSquare(_origin:getX(), _origin:getY() - 1, _origin:getZ())
    elseif _direction == IsoDirections.E then
        target = getCell():getGridSquare(_origin:getX() + 1, _origin:getY(), _origin:getZ())
        neighbor = target
    elseif _direction == IsoDirections.S then
        target = getCell():getGridSquare(_origin:getX(), _origin:getY() + 1, _origin:getZ())
        neighbor = target
    elseif _direction == IsoDirections.W then
        target = _origin
        neighbor = getCell():getGridSquare(_origin:getX() - 1, _origin:getY(), _origin:getZ())
    end

    if not target or not neighbor then
        -- I think this can happen if we're requesting a square very far away from the player.
        return nil
    end

    local targetProperties = target:getProperties()

    if targetProperties:Is("WallNW") then
        -- This is a wall corner
        return nil
    end

    if _direction == IsoDirections.N or _direction == IsoDirections.S then
        -- North or South

        if targetProperties:Is("WallN") and not SWAB_Building.porousWallsNorth[target:getWall(true):getTextureName()] then
            -- This is a wall, and it's not a porous material
            return nil
        end

        if targetProperties:Is("WindowN") and targetProperties:Val("WindowN") == "WindowN" then
            -- This is a window frame and it hase a closed window in it
            local windowNorth = target:getWindow(true)
            -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
            if windowNorth then
                -- We are a wall that a window can be placed into.
                if not windowNorth:isSmashed() and not SWAB_Building.porousWallsNorth[windowNorth:getTextureName()] then
                    -- It's not a smashed window and the wall around it is not a porous material
                    return nil
                else
                    return neighbor
                end
            end
        end
    else
        -- East or West

        if targetProperties:Is("WallW") and not SWAB_Building.porousWallsWest[target:getWall(false):getTextureName()] then
            -- This is a wall, and it's not a porous material
            return nil
        end

        if targetProperties:Is("WindowW") and targetProperties:Val("WindowW") == "WindowW" then
            -- This is a window frame and it hase a closed window in it
            local windowWest = target:getWindow(false)
            -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
            if windowWest then
                -- We are a wall that a window can be placed into.
                if not windowWest:isSmashed() and not SWAB_Building.porousWallsWest[windowWest:getTextureName()] then
                    -- It's not a smashed window and the wall around it is not a porous material
                    return nil
                else
                    return neighbor
                end
            end
        end
    end

    -- No obstructions so far

    local door = _origin:getDoorTo(neighbor)

    if door and not door:IsOpen() and not door:isDestroyed() then
        -- Found a door that is closed.
        return nil
    end

    return neighbor
end