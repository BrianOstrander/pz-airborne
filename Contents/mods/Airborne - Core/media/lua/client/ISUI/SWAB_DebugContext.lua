require "SWAB_Config"
require "SWAB_Data"

SWAB_DebugContext = {}

local function GetBuildingGridSquares(_allRooms)
    local buildingGridSquares = {};

    for key,value in pairs(_allRooms) do
        local currentRoom = value;
        local currentRoomSquares = currentRoom:getSquares(); -- This gives us a LIST of all the room squares.
        for i = 0, currentRoomSquares:size()-1 do
            table.insert(buildingGridSquares, currentRoomSquares:get(i));
        end
    end

    return buildingGridSquares;
end

local function GetBuildingRooms(_player)
    local buildingRooms = {};

    local buildingDef = getPlayer():getCurrentBuildingDef();
    if buildingDef then
		print(buildingDef)
	else
		return nil
	end

    local arrayOfRooms = buildingDef:getRooms();
    for i = 0, arrayOfRooms:size()-1 do
        local currentRoom = arrayOfRooms:get(i);
        local currentIsoRoom = currentRoom:getIsoRoom();
        table.insert(buildingRooms, currentIsoRoom)
    end

    return buildingRooms;
end

function SWAB_DebugContext.checkAirtight(_player, _context, _worldObjects, _test)

	local checkAirtightOption = _context:addOption(getText("ContextMenu_CheckAirtight"), _player, SWAB_DebugContext.onSelectRoot)
end
Events.OnPreFillWorldObjectContextMenu.Add(SWAB_DebugContext.checkAirtight)

function SWAB_DebugContext.onSelectRoot(_player)

	print("SWAB --- ----------------------- lol --------------")

	local allRooms = GetBuildingRooms(_player)
    if allRooms == nil then
		return
	end
    
	local buildingSquares = GetBuildingGridSquares(allRooms)
	-- local buildingSquaresUnsorted = GetBuildingGridSquares(allRooms)

	-- local buildingSquares = {}

	-- for _, buildingSquare in ipairs(buildingSquaresUnsorted) do
	-- 	buildingSquares[buildingSquare] = buildingSquare
	-- end

	print("Found "..#buildingSquares.." building squares")

	local doors = {}
	local windows = {}

	local cel = getWorld():getCell():getGridSquare(square:getX()+1, square:getY(), square:getZ());

	for _, square in ipairs(buildingSquares) do

		square:getFloor():setHighlighted(true, false)
		square:getFloor():setHighlightColor(1.0, 1.0, 0.0, 1.0)
		--square:getFloor():setHighlighted(false)

		local hasDoor = false
		local hasWindow = false

		local props = square:getProperties()
		if props then
			if props:Is(IsoFlagType.DoorWallN) or props:Is(IsoFlagType.DoorWallW) then
				table.insert(doors, square)
				hasDoor = true
			end
			if props:Is(IsoFlagType.WindowN) or props:Is(IsoFlagType.WindowW) then
				table.insert(windows, square)
				hasWindow = true
			end
		end

		
		local squareSouth = square:getCell():getGridSquare(square:getX(), square:getY()+1, square:getZ())
		props = squareSouth:getProperties()
		if props and squareSouth:getRoomID() == -1 then
			if props:Is(IsoFlagType.DoorWallN) then
				hasDoor = true
				table.insert(doors, squareSouth)
			end

			if props:Is(IsoFlagType.WindowN) then
				hasWindow = true
				table.insert(windows, squareSouth)
			end
		end


		local squareEast = square:getCell():getGridSquare(square:getX()+1, square:getY(), square:getZ())
		props = squareEast:getProperties()
		if props and squareEast:getRoomID() == -1 then
			if props:Is(IsoFlagType.DoorWallW) then
				hasDoor = true
				table.insert(doors, squareEast)
			end

			if props:Is(IsoFlagType.WindowW) then
				hasWindow = true;
				table.insert(windows, squareEast)
			end
		end
		-- for _, worldObject in ipairs(square:getWorldObjects()) do
		-- 	print(worldObject)
		-- 	local props = worldObject:getProperties()
		-- 	if props then
		-- 		print(props)
		-- 		if props:Is("DoorWallN") or props:Is("DoorWallW") then
		-- 			table.insert(doors, square)
		-- 			hasDoor = true
		-- 		end
		-- 		if props:Is(IsoFlagType.WindowN) or props:Is(IsoFlagType.WindowW) then
		-- 			table.insert(windows, square)
		-- 			hasWindow = true
		-- 		end
		-- 	end
		-- end

		if hasWindow and hasDoor then
			square:getFloor():setHighlightColor(0.0, 0.0, 1.0, 1.0)
		elseif hasWindow then
			square:getFloor():setHighlightColor(1.0, 0.0, 0.0, 1.0)
		elseif hasDoor then
			square:getFloor():setHighlightColor(0.0, 1.0, 0.0, 1.0)
		end

		-- local squareNeighbors = {
		-- 	square:getN(),
		-- 	square:getE(),
		-- 	square:getS(),
		-- 	square:getW(),
		-- }



		-- local hasDoor = square:getDoor() ~= nil
		-- local hasWindow = square:getWindow() ~= nil

		-- if not hasWindow and not hasDoor then

		-- 	for _, squareNeighbor in ipairs(squareNeighbors) do
		-- 		if square:getDoorTo(squareNeighbor) then
		-- 			hasDoor = true
		-- 		end

		-- 		if square:getWindowTo(squareNeighbor) then
		-- 			hasWindow = true
		-- 		end
		-- 	end
		-- end

		-- if hasDoor then
		-- 	table.insert(doors, door)
		-- end

		-- if hasWindow then
		-- 	table.insert(windows, square)
		-- end

		-- --square:getFloor():setHighlighted(hasWindow or hasDoor, false)
	end
    
	print("SWA --- Door Count:  "..#doors)
	print("SWA --- Window Cont: "..#windows)
end