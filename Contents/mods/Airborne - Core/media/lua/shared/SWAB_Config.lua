SWAB_Config = SWAB_Config or {}

SWAB_Config.version = "v1"
SWAB_Config.isInitialized = false

-- A single building will never be updated more often than this many ticks.
-- However, multiple buildings may still get updated during this time.
SWAB_Config.buildingUpdateTickDelay = 1
-- How many buildings may be updated per tick.
SWAB_Config.buildingUpdatesPerTick = 3
-- How many squares can we update per building.
SWAB_Config.buildingSquareUpdateBudget = 100
-- Lower decay rates mean buildings take more time to decontaminate.
SWAB_Config.buildingContaminationDecayRate = 0.025
-- An entirely enclosed space with no filtration will decay to this level
-- of contamination.
SWAB_Config.buildingContaminationBaseline = 4
-- Multiplier for how long consumables like masks, filters, and air tanks last.
SWAB_Config.itemConsumptionDurationMultiplier = 1 --60

-- When the respiratoryAbsorptionLevel floors to these values, the deltas are
-- used to increase the respiratoryAbsorption
SWAB_Config.respiratoryAbsorptionLevels = {
    {
        level = 0,
        rate = 0,
    },
    {
        level = 1,
        rate = 0.1,
    },
    {
        level = 2,
        rate = 0.25,
    },
    {
        level = 3,
        rate = 0.5,
    },
    {
        level = 4,
        rate = 1,
    },
    {
        level = 5,
        rate = 4,
    },
    {
        level = 6,
        rate = 10,
    },
    {
        level = 7,
        rate = 18,
    },
    {
        level = 8,
        rate = 28,
    },
    {
        level = 9,
        rate = 40,
    },
    {
        level = 10,
        rate = 75,
    },
}

-------------------------------------------------------
-- CONSTANTS --
-- DO NOT MESS WITH EVER
-------------------------------------------------------

SWAB_Config.moodleId = "contamination_exposure"
SWAB_Config.playerModDataId = "swab_player"
SWAB_Config.squareExposureModDataId = "swab_square_exposure"
SWAB_Config.squareFloorClaimDeltaModDataId = "swab_square_floor_claim_delta"
SWAB_Config.squareCeilingHeightModDataId = "swab_square_ceiling_height"

function SWAB_Config.getBuildingModDataId(_buildingDef)
    return "swab_building_".._buildingDef:getID()
end

function SWAB_Config.getRoomModDataId(_roomDef)
    return "swab_room_".._roomDef:getBuilding():getID()..".".._roomDef:getID()
end

-------------------------------------------------------
-- DEBUG OPTIONS -- 
-- DO NOT MESS WITH UNLESS YOU KNOW WHAT YOU ARE DOING!
-------------------------------------------------------

SWAB_Config.debug = {}

-- Forces mod to reinitialize game state every time a game is loaded.
SWAB_Config.debug.forceInitialize = true
-- Enables logging of various events.
SWAB_Config.debug.logging = true
-- Display red tiles for indoor spaces that are contaminated.
SWAB_Config.debug.visualizeExposure = true

-------------------------------------------------------
-- GAMEPLAY OPTIONS --
-------------------------------------------------------

SWAB_Config.gameplay = {}

if SWAB_Config.debug.logging then

    local gameType = "Singleplayer"

    if isServer() then
        gameType = "Server"
    elseif isClient() then
        gameType = "Client or Host"
    end 

    print("SWAB: -------")
    print("SWAB: " .. gameType .. " Running " .. SWAB_Config.version)
    print("SWAB: -------")
end