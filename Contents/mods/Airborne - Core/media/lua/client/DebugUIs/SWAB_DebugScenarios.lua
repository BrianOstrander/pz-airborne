debugScenarios = debugScenarios or {}

SWAB_DebugScenarios = {}

SWAB_DebugScenarios.scenarios = {
    {
        name = "Shed",
        location = { x = 10660, y = 9392, z = 0 },
    },
    {
        name = "Firehouse",
        location = { x = 8146, y = 11753, z = 0 },
    },
    {
        name = "Warehouse",
        location = { x = 10612, y = 9324, z = 0 },
    },
    {
        name = "School",
        location = { x = 10609, y = 9975, z = 0 },
    },
    {
        name = "Crossroads",
        location = { x = 13935, y = 5920, z = 0 },
    },
}

-- Last player position
SWAB_DebugScenarios.playerPosition = { x = 0, y = 0 }
-- How far they can move in 1 minute before we do a cleanup
SWAB_DebugScenarios.playerDistanceThreshold = 1000

function SWAB_DebugScenarios.EveryOneMinute()
    if GameTime:getInstance() then
        local minutes = GameTime:getInstance():getMinutes()
        local playerPosition = { x = getPlayer():getX(), y = getPlayer():getY() }
        local playerDistance = PZMath.max(PZMath.abs(playerPosition.x - SWAB_DebugScenarios.playerPosition.x), PZMath.abs(playerPosition.y - SWAB_DebugScenarios.playerPosition.y))

        if SWAB_DebugScenarios.playerDistanceThreshold < playerDistance or (minutes and minutes == 1) then
            SWAB_DebugScenarios.CleanupZombies()
        end
        
        SWAB_DebugScenarios.playerPosition = playerPosition
    end

end

function SWAB_DebugScenarios.CleanupZombies()
    local radius = 50
    if isClient() then
        SendCommandToServer(string.format("/removezombies -x %d -y %d -z %d -radius %d", getPlayer():getX(), getPlayer():getY(), getPlayer():getZ(), radius))
        return
    end
    for x = (getPlayer():getX() - radius), (getPlayer():getX() + radius) do
        for y= (getPlayer():getY() - radius), (getPlayer():getY() + radius) do
            local square = getCell():getGridSquare(x, y, getPlayer():getZ())
            if square then
                for i = square:getMovingObjects():size(), 1, -1 do
                    local zombie = square:getMovingObjects():get(i - 1)
                    if instanceof(zombie, "IsoZombie") then
                        zombie:removeFromWorld()
                        zombie:removeFromSquare()
                    end
                end
            end
        end
    end
end

function SWAB_DebugScenarios.SetSandbox()
    SandboxVars.VehicleEasyUse = true
    SandboxVars.Zombies = 5
end

function SWAB_DebugScenarios.OnStart()
    getPlayer():setGodMod(true)
    getPlayer():setUnlimitedCarry(true)
    getPlayer():setNoClip(true)
    getPlayer():setInvisible(true)
    ISFastTeleportMove.cheat = true
    --ISWorldMap.setHideUnvisitedAreas(false)
    getPlayer():getInventory():AddItem("WristWatch_Right_DigitalBlack")
    getPlayer():getInventory():AddItem("Crowbar")
    getPlayer():getInventory():AddItem("Hammer")
    getPlayer():getInventory():AddItem("Screwdriver")

    for i = 1, 10 do
        getPlayer():LevelPerk(Perks.Woodwork)
        getPlayer():LevelPerk(Perks.Mechanics)
    end

    Events.EveryOneMinute.Add(SWAB_DebugScenarios.EveryOneMinute)
end

function SWAB_DebugScenarios.Initialize()

    local defaultScenarios = {}

    for scenario_key, scenario in pairs(debugScenarios) do
        defaultScenarios[scenario_key] = scenario
        debugScenarios[scenario_key] = nil
    end

    for index, scenario in ipairs(SWAB_DebugScenarios.scenarios) do
        debugScenarios["swab_debug_scenario_"..index] = {
            name = "SWAB - "..scenario.name,
            startLoc = scenario.location,
            setSandbox = SWAB_DebugScenarios.SetSandbox,
            onStart = SWAB_DebugScenarios.OnStart
        }
    end

    for scenario_key, scenario in pairs(defaultScenarios) do
        debugScenarios[scenario_key] = scenario
    end 
end

SWAB_DebugScenarios.Initialize()

-- function ISSpawnHordeUI:onRemoveZombies()
-- 	local radius = self:getRadius() + 1;
-- 	if isClient() then
-- 		SendCommandToServer(string.format("/removezombies -x %d -y %d -z %d -radius %d", self.selectX, self.selectY, self.selectZ, radius))
-- 		return
-- 	end
-- 	for x=self.selectX-radius, self.selectX + radius do
-- 		for y=self.selectY-radius, self.selectY + radius do
-- 			local sq = getCell():getGridSquare(x,y,self.selectZ);
-- 			if sq then
-- 				for i=sq:getMovingObjects():size(),1,-1 do
-- 					local testZed = sq:getMovingObjects():get(i-1);
-- 					if instanceof(testZed, "IsoZombie") then
-- 						testZed:removeFromWorld();
-- 						testZed:removeFromSquare();
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end