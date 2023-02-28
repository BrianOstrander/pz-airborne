debugScenarios = debugScenarios or {}

SWAB_DebugScenarios = {}

SWAB_DebugScenarios.scenarios = {
    {
        name = "Shed",
        location = { x = 10660, y = 9392, z = 0 },
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
end

function SWAB_DebugScenarios.Initialize()
    for index, scenario in ipairs(SWAB_DebugScenarios.scenarios) do
        debugScenarios["swab_debug_scenario_"..index] = {
            name = "SWAB - "..scenario.name,
            startLoc = scenario.location,
            setSandbox = SWAB_DebugScenarios.SetSandbox,
            onStart = SWAB_DebugScenarios.OnStart
        }
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