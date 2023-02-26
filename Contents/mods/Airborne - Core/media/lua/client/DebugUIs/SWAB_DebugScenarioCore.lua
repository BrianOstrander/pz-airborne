if debugScenarios == nil then
    debugScenarios = {}
end

debugScenarios.SWAB_DebugScenarioCore = {
    name = "Airborne Debug Core",
    startLoc = {x=10660, y=9392, z=0 }, -- Muldraugh between porch and shed
    setSandbox = function()
        SandboxVars.VehicleEasyUse = true
        SandboxVars.Zombies = 5
    end,
    onStart = function()
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
}