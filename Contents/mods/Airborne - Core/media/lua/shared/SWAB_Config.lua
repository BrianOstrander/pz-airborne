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

-- When the respiratoryAbsorptionLevel floors to these values, the rates are
-- used to increase the respiratoryAbsorption, and the moodle value maps to
-- the threshold for exposure moodles.
SWAB_Config.respiratoryAbsorptionLevels = {
    {
        -- Exposure  0
        -- Moodle    0
        rate       = -1,
        moodle     = 0.5,
    },
    {
        -- Exposure  1
        -- Moodle    1
        rate       = 0.1,
        moodle     = 0.4,
    },
    {
        -- Exposure  2
        -- Moodle    1
        rate       = 0.25,
        moodle     = 0.4,
    },
    {
        -- Exposure  3
        -- Moodle    1
        rate       = 0.5,
        moodle     = 0.4,
    },
    {
        -- Exposure  4
        -- Moodle    1
        rate       = 1,
        moodle     = 0.4,
    },
    {
        -- Exposure  5
        -- Moodle    2
        rate       = 4,
        moodle     = 0.3,
    },
    {
        -- Exposure  6
        -- Moodle    2
        rate       = 10,
        moodle     = 0.3,
    },
    {
        -- Exposure  7
        -- Moodle    3
        rate       = 18,
        moodle     = 0.2,
    },
    {
        -- Exposure  8
        -- Moodle    3
        rate       = 28,
        moodle     = 0.2,
    },
    {
        -- Exposure  9
        -- Moodle    4
        rate       = 40,
        moodle     = 0.1,
    },
    {
        -- Exposure  10
        -- Moodle    4
        rate       = 75,
        moodle     = 0.1,
    },
}

SWAB_Config.respiratoryAbsorptionLevelMaximum = 10

function SWAB_Config.getRespiratoryAbsorptionLevel(_respiratoryAbsorptionLevel)
    -- Just wrapping some confusion caused by Lua's table indexing.
    return SWAB_Config.respiratoryAbsorptionLevels[_respiratoryAbsorptionLevel + 1]
end

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