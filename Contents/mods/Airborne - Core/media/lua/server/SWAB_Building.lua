require "SWAB_Config"
require "SWAB_Utilities"

SWAB_Building = {}

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
            return b2.lastUpdated < b1.lastUpdated
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
    _modData.lastUpdated = 0
    
    if SWAB_Config.debug.logging then
        print("SWAB: SWAB_Building.InitializeBuilding ".._modDataId)
    end
end

function SWAB_Building.UpdateBuilding(_modData, _tickDelta, _skip)
    if _skip then
        _modData.lastUpdated = _modData.lastUpdated + _tickDelta
        return
    end

    _modData.lastUpdated = 0

    local buildingDef = getWorld():getMetaGrid():getBuildingAt(_modData.x, _modData.y)
    local roomDefArray = buildingDef:getRooms()

    for roomIndex = 0, roomDefArray:size() - 1 do
        local room = roomDefArray:get(roomIndex):getIsoRoom()
        local squares = room:getSquares()
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
        -- local neighborDirection = nil
        -- local offsetX = 0
        -- local offsetY = 0
        -- if direction == IsoDirections.N then
        --     neighborDirection = IsoDirections.S
        --     offsetY = -1
        -- elseif direction == IsoDirections.E then
        --     neighborDirection = IsoDirections.W
        --     offsetX = 1
        -- elseif direction == IsoDirections.S then
        --     neighborDirection = IsoDirections.N
        --     offsetY = 1
        -- elseif direction == IsoDirections.W then
        --     neighborDirection = IsoDirections.E
        --     offsetX = -1
        -- end

        -- if not neighbor then
        --     local possibleNeighbor = getCell():getGridSquare(_square:getX() + offsetX, _square:getY() + offsetY, _square:getZ())
        --     if SWAB_Building.GetNeighboringSquare(possibleNeighbor, neighborDirection) then
        --         -- Furniture or something was blocking us from accessing this neighbor, but it is valid.
        --         neighbor = possibleNeighbor
        --     end
        -- end

        local neighborExposure = SWAB_Building.CalculateSquareExposureFromNeighbor(_square, neighbor)

        if neighborExposure then
            if not highestExposure or highestExposure < neighborExposure then
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
    -- ----------------------------------------------------------
    -- This is a valid neighbor, we haven't hit a wall, closed door, or closed window

    local neighborExposure = nil
    
    if _neighbor:getRoomID() == -1 then
        neighborExposure = 7
    else
        neighborExposure = _neighbor:getModData()[SWAB_Config.squareExposureModDataId]
    end

    -- local window = _square:getWindowTo(_neighbor)
    
    -- if window then
    --     if window:IsOpen() or window:isSmashed() then
    --         -- Window open or smashed
    --         return neighborExposure
    --     end 
    --     -- Window closed
    --     return nil
    -- end

    -- local door = _square:getDoorTo(_neighbor)

    -- if door then
    --     if door:IsOpen() or door:isDestroyed() then
    --         -- Door open or smashed
    --         return neighborExposure
    --     end
    --     -- Door closed
    --     return nil
    -- end
    
    -- Missing window or door
    return neighborExposure
    -- ----------------------------------------------------------

    -- This is a valid neighbor, we haven't hit a wall, closed door, or closed window
    -- if _neighbor:getRoomID() == -1 then
    --     -- Outdoors
    --     local window = _square:getWindowTo(_neighbor)
        
    --     if window then
    --         if window:IsOpen() or window:isSmashed() then
    --             -- Window open or smashed
    --             return 7
    --         end 
    --         -- Window closed
    --         return nil
    --     end

    --     local door = _square:getDoorTo(_neighbor)

    --     if door then
    --         if door:IsOpen() or door:isDestroyed() then
    --             -- Door open or smashed
    --             return 7
    --         end
    --         -- Door closed
    --         return nil
    --     end
        
    --     -- Missing window or door
    --     return 7
    -- else
    --     -- Indoors
    --     return _neighbor:getModData()[SWAB_Config.squareExposureModDataId]
    -- end
end

function SWAB_Building.GetNeighboringSquare(_origin, _direction)
    local offsetX = 0
    local offsetY = 0
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
    
    local targetProperties = target:getProperties()

    if _direction == IsoDirections.N then
        -- North
        if targetProperties:Is("WallN") or targetProperties:Is("WallNW") then
            return nil
        end

        if targetProperties:Is("WindowN") and targetProperties:Val("WindowN") == "WindowN" then
            return nil
        end
    elseif _direction == IsoDirections.S then
        -- South
        if targetProperties:Is("WallN") or targetProperties:Is("WallNW") then
            return nil
        end

        if targetProperties:Is("WindowN") and targetProperties:Val("WindowN") == "WindowN" then
            return nil
        end
    else
        -- East or West
        if targetProperties:Is("WallW") or targetProperties:Is("WallNW") then
            return nil
        end

        if targetProperties:Is("WindowW") and targetProperties:Val("WindowW") == "WindowW" then
            return nil
        end
    end

    -- No obstructions so far

    local door = _origin:getDoorTo(neighbor)

    if door and not door:IsOpen() and not door:isDestroyed() then
        return nil
    end

    return neighbor
end