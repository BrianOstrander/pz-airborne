debugScenarios = debugScenarios or {}
SWAB_DebugScenarios = {}

function SWAB_DebugScenarios.GetScenarios()
    return {
        {
            name = "Clothing",
            ignore = false,
            setSandbox = SWAB_DebugScenarios.SetSandbox,
            onStart = SWAB_DebugScenarios.OnStart,
            locations = {
                {
                    name = "Driveway",
                    position = { x = 10659, y = 9403, z = 0 },
                },
            },
            items = {
                "WristWatch_Right_DigitalBlack",
                "SWAB.Hat_MakeshiftGasMask",
                "SWAB.MakeshiftOveralls",
                "Scissors",
            },
            duplicatePerGender = true,
        },
        {
            name = "Crafting",
            ignore = false,
            setSandbox = SWAB_DebugScenarios.SetSandbox,
            onStart = SWAB_DebugScenarios.OnStart,
            locations = {
                {
                    name = "Driveway",
                    position = { x = 10659, y = 9403, z = 0 },
                },
            },
            items = {
                "WristWatch_Right_DigitalBlack",
                "HuntingKnife",
                { type = "DuctTape",                count = 25 },
                { type = "Sheet",                   count = 25 },
                { type = "WaterBottleEmpty",        count = 25 },
                { type = "SWAB.StandardFilter",     count = 25 },
                { type = "SWAB.MakeshiftFilter",    count = 25 },
            }
        },
        {
            name = "Atmospherics",
            ignore = false,
            setSandbox = SWAB_DebugScenarios.SetSandbox,
            onStart = SWAB_DebugScenarios.OnStart,
            locations = {
                {
                    name = "Shed",
                    position = { x = 10660, y = 9392, z = 0 },
                },
                {
                    name = "Motel",
                    position = { x = 10612, y = 9823, z = 0 },
                },
                {
                    name = "Firehouse",
                    position = { x = 8146, y = 11753, z = 0 },
                },
                {
                    name = "Warehouse",
                    position = { x = 10612, y = 9324, z = 0 },
                },
                {
                    name = "Prison",
                    position = { x = 7708, y = 11893, z = 0 },
                },
                {
                    name = "School",
                    position = { x = 10609, y = 9975, z = 0 },
                },
                {
                    name = "Crossroads",
                    position = { x = 13935, y = 5920, z = 0 },
                },
                {
                    name = "Field",
                    position = { x = 8129, y = 11844, z = 0 },
                },
            },
            items = {
                "WristWatch_Right_DigitalBlack",
                "SWAB.Hat_MakeshiftGasMask",
                "Hat_GasMask",
                "SWAB.ValuTechHomeAirPurifier",
                "SWAB.MassGenFacIndustrialAirPurifier",
                "SWAB.ValuTechPersonalAirPurifier",
                "SWAB.MakeshiftAirPurifier",
            }
        },
    }
end

function SWAB_DebugScenarios.SetSandbox()
    SandboxVars.VehicleEasyUse = true
    SandboxVars.Zombies = 5
end

function SWAB_DebugScenarios.OnStart(_scenario, _isFemale)
    getPlayer():setFemale(_isFemale)
    getPlayer():setGodMod(true)
    getPlayer():setUnlimitedCarry(true)
    getPlayer():setNoClip(true)
    getPlayer():setInvisible(true)
    ISFastTeleportMove.cheat = true
    --ISWorldMap.setHideUnvisitedAreas(false)

    SWAB_DebugScenarios.CleanupInventory()

    for _, itemEntry in ipairs(_scenario.items) do
        if type(itemEntry) == "string" then
            getPlayer():getInventory():AddItem(itemEntry)
        else
            -- Must be a table with more specific spawn instructions.
            for i = 1, (itemEntry.count or 1) do
                local item = getPlayer():getInventory():AddItem(itemEntry.type)
                if itemEntry.initialize then
                    itemEntry.initialize(item)
                end
            end
        end
    end

    SWAB_DebugScenarios.GivePerks(
        10,
        {
            Perks.Woodwork,
            Perks.Mechanics,
            Perks.Electricity,
        }
    )

    getPlayer():getKnownRecipes():add("Generator")

    -- Cleans up zombies every minute.
    Events.EveryOneMinute.Add(SWAB_DebugScenarios.EveryOneMinute)
end

function SWAB_DebugScenarios.GivePerks(_level, _perks)
    for _, perk in ipairs(_perks) do
        for i = 1, _level do
            getPlayer():LevelPerk(perk)
        end
    end
end

function SWAB_DebugScenarios.CleanupInventory()
    -- Not sure why, but debug scenarios have a bunch of clothing in their inventory.
    local items = getPlayer():getInventory():getItems()
    local itemsForRemoval = {}

    for itemIndex = 0, items:size() - 1 do
        local item = items:get(itemIndex)
        if instanceof(item, "Clothing") and not getPlayer():isEquipped(item) then
            table.insert(itemsForRemoval, item)
        end
    end

    for _, item in ipairs(itemsForRemoval) do
        getPlayer():getInventory():Remove(item)
    end
end

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

function SWAB_DebugScenarios.InitializeScenario(_location, _scenario, _isFemale)
    local name = "SWAB | ".._scenario.name.." - ".._location.name

    if _scenario.duplicatePerGender then
        name = name.." ( "
        if _isFemale then
            name = name.."Female"
        else
            name = name.."Male"
        end
        name = name.." )"
    end

    return {
        name = name,
        startLoc = _location.position,
        setSandbox = _scenario.setSandbox,
        onStart = function() _scenario.onStart(_scenario, _isFemale) end
    }
end

function SWAB_DebugScenarios.Initialize()

    local defaultScenarios = {}

    for scenario_key, scenario in pairs(debugScenarios) do
        defaultScenarios[scenario_key] = scenario
        debugScenarios[scenario_key] = nil
    end

    for scenarioIndex, scenario in ipairs(SWAB_DebugScenarios.GetScenarios()) do
        if not scenario.ignore then
            for locationIndex, location in ipairs(scenario.locations) do
                local debugScenarioKey = "swab_debug_scenario_"..scenarioIndex.."_"..locationIndex.."_"

                debugScenarios[debugScenarioKey.."female"] = SWAB_DebugScenarios.InitializeScenario(
                    location,
                    scenario,
                    true
                )

                if scenario.duplicatePerGender then
                    debugScenarios[debugScenarioKey.."male"] = SWAB_DebugScenarios.InitializeScenario(
                        location,
                        scenario,
                        false
                    )
                end
            end
        end
    end

    for scenario_key, scenario in pairs(defaultScenarios) do
        debugScenarios[scenario_key] = scenario
    end 
end

SWAB_DebugScenarios.Initialize()