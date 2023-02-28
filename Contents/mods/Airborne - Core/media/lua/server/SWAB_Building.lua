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
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        local room = player:getSquare():getRoom()
        if room then

            local entry = {}
            entry.def = room:getRoomDef():getBuilding()
            entry.modDataId = SWAB_Config.getBuildingModDataId(entry.def)
            entry.modData = ModData.getOrCreate(entry.modDataId)

            buildings[entry.modDataId] = entry
        end 
    end

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

    for count, building in ipairs(buildingsSorted) do
        SWAB_Building.UpdateBuilding(building, ticksSinceLastUpdate, SWAB_Config.buildingUpdatesPerTick < count)
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
    
    if SWAB_Config.debug.logging then
        print("SWAB: SWAB_Building.InitializeBuilding ".._modDataId)
    end
end

function SWAB_Building.UpdateBuilding(_modData, _tickDelta, _skip)
    if _skip then
        _modData.ticksSinceUpdate = _modData.ticksSinceUpdate + _tickDelta
        return
    end

    _modData.ticksSinceUpdate = 0

    local buildingDef = getWorld():getMetaGrid():getBuildingAt(_modData.x, _modData.y)
    local roomDefArray = buildingDef:getRooms()

    if _modData.lastRoomIndexInitialized < (roomDefArray:size() - 1) then
        -- We still have rooms to initialize
        _modData.lastRoomIndexInitialized = _modData.lastRoomIndexInitialized + 1

        SWAB_Building.InitializeRoom(roomDefArray:get(_modData.lastRoomIndexInitialized):getIsoRoom())
    else
        -- We can update a room
        _modData.lastRoomIndexUpdated = _modData.lastRoomIndexUpdated + 1

        if roomDefArray:size() <= _modData.lastRoomIndexUpdated then
            _modData.lastRoomIndexUpdated = 0
        end

        SWAB_Building.UpdateRoom(roomDefArray:get(_modData.lastRoomIndexUpdated):getIsoRoom())
    end
end

function SWAB_Building.InitializeRoom(_room)
    local squares = _room:getSquares()
    for squareIndex = 0, squares:size() - 1 do
        local square = squares:get(squareIndex)
        
        local squareAbove = nil
        local squareAboveX = square:getX()
        local squareAboveY = square:getY()
        local squareAboveZ = square:getZ() + 1
        repeat
            local squareAbove = getCell():getGridSquare(squareAboveX, squareAboveY, squareAboveZ)
            if squareAbove and not squareAbove:Is(IsoFlagType.attachedFloor) then
                squareAbove:getModData()[SWAB_Config.squareFloorClaimDeltaModDataId] = square:getZ() - squareAboveZ
            end
            squareAboveZ = squareAboveZ + 1
        until not squareAbove or squareAbove:Is(IsoFlagType.attachedFloor)
        square:getModData()[SWAB_Config.squareCeilingHeightModDataId] = squareAboveZ - 1
    end
end

function SWAB_Building.UpdateRoom(_room)
    local squares = _room:getSquares()
    for squareIndex = 0, squares:size() - 1 do
        local square = squares:get(squareIndex)
        local squareExposurePrevious = square:getModData()[SWAB_Config.squareExposureModDataId]
        local squareExposure = SWAB_Building.CalculateSquareExposure(square)
        
        if not squareExposure then
            squareExposure = squareExposurePrevious
        end

        if squareExposure then
            if squareExposure < SWAB_Config.buildingContaminationBaseline then
                squareExposure = PZMath.max(squareExposure - SWAB_Config.buildingContaminationDecayRate, 0)
            else
                squareExposure = PZMath.max(squareExposure - SWAB_Config.buildingContaminationDecayRate, SWAB_Config.buildingContaminationBaseline)
            end
            square:getModData()[SWAB_Config.squareExposureModDataId] = squareExposure

            if SWAB_Config.debug.visualizeExposure then
                local highlightedFloor = square:getFloor()
                if highlightedFloor then
                    square:getFloor():setHighlighted(true, false)
                    square:getFloor():setHighlightColor(1.0, 0.0, 0.0, (squareExposure - 4)/3)
                end
            end
        end
    end
end

function SWAB_Building.CalculateSquareExposure(_square)
    local directions = { IsoDirections.N, IsoDirections.E, IsoDirections.S, IsoDirections.W }

    local highestExposure = nil

    for _, direction in ipairs(directions) do
        
        -- Doing it this way out of an ill concieved idea that it might be more efficient
        local neighbor = SWAB_Building.GetNeighboringSquare(_square, direction)
        local neighborExposure = SWAB_Building.CalculateSquareExposureFromNeighbor(_square, neighbor)
        
        if neighborExposure then
            if not highestExposure or highestExposure < neighborExposure then
                -- We take the highest level of exposure from our neighboring tiles
                highestExposure = neighborExposure
            end
        end
    end

    return highestExposure
end

function SWAB_Building.CalculateSquareExposureFromNeighbor(_square, _neighbor)
    if not _neighbor then
        return nil
    end
    
    if _neighbor:getRoomID() == -1 then
        if _neighbor:getModData()[SWAB_Config.squareFloorClaimDeltaModDataId] then
            return _neighbor:getModData()[SWAB_Config.squareExposureModDataId]
        end
        return 7
    else
        return _neighbor:getModData()[SWAB_Config.squareExposureModDataId]
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
            local windowNorth = target:getWall(true)
            -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
            if windowNorth then
                -- We are a wall that a window can be placed into.
                if not SWAB_Building.porousWallsNorth[windowNorth:getTextureName()] then
                    -- It's not a porous material
                    return nil
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
            local windowWest = target:getWall(false)
            -- It's possible for getWall to return nil if this is a wall-type window, like the floor to ceiling ones.
            if windowWest then
                -- We are a wall that a window can be placed into.
                if not SWAB_Building.porousWallsWest[target:getWall(false):getTextureName()] then
                    -- It's not a porous material
                    return nil
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