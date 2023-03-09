SWAB_Config = SWAB_Config or {}

SWAB_Config.version = "v1"
SWAB_Config.isInitialized = false

-- A single building will never be updated more often than this many ticks.
-- However, multiple buildings may still get updated during this time.
SWAB_Config.buildingUpdateTickDelay = 1
-- How many squares can be updated per a given tick.
SWAB_Config.squareUpdatesPerTick = 100
-- Above this number, rooms are treated as outdoors, and are not updated.
SWAB_Config.squareUpdateMaximum = 3000
-- The number of room updates without changes that will trigger it to skip updates for awhile.
SWAB_Config.roomStaleUpdateCountMaximum = 10
-- The number of updates to skip after maxing the stale update maximum.
SWAB_Config.roomSkipUpdateCount = 600
-- Difference allowed between contaminated squares before we start spreading contamination.
SWAB_Config.squareContaminationThreshold = 0.02
-- Minimum difference allowed between two tiles.
SWAB_Config.squareContaminationDeltaMinimum = 0.01
-- An entirely enclosed space with no filtration will decay to this level
-- of contamination.
SWAB_Config.buildingContaminationBaseline = 4
-- Multiplier for how long consumables like masks, filters, and air tanks last.
SWAB_Config.itemConsumptionDurationMultiplier = 1 --60

-- Floor respiratoryAbsorptionLevel to get your level
--      rate              : Per day increase in absorption
--      moodle            : Exposure moodle value
--      endurance         : Endurance effects
--          duration      : Hours to reach the limit
--          limit         : Endurance maximum for this level
SWAB_Config.respiratoryEffects = {
    {
        -- Exposure  0
        -- Moodle    0
        rate                = -1,
        moodle              = 0.5,
        endurance = {
            duration        = 0,
            limit           = 1,
        },
    },
    {
        -- Exposure  1
        -- Moodle    1
        rate                = 0.1,
        moodle              = 0.4,
        endurance = {
            duration        = 24,
            limit           = 0.77,
        },
    },
    {
        -- Exposure  2
        -- Moodle    1
        rate                = 0.25,
        moodle              = 0.4,
        endurance = {
            duration        = 24,
            limit           = 0.52,
        },
    },
    {
        -- Exposure  3
        -- Moodle    1
        rate                = 0.5,
        moodle              = 0.4,
        endurance = {
            duration        = 16,
            limit           = 0.52,
        },
    },
    {
        -- Exposure  4
        -- Moodle    1
        rate                = 1,
        moodle              = 0.4,
        endurance = {
            duration        = 10,
            limit           = 0.52,
        },
    },
    {
        -- Exposure  5
        -- Moodle    2
        rate                = 4,
        moodle              = 0.3,
        endurance = {
            duration        = 8,
            limit           = 0.27,
        },
    },
    {
        -- Exposure  6
        -- Moodle    2
        rate                = 10,
        moodle              = 0.3,
        endurance = {
            duration        = 8,
            limit           = 0.27,
        },
    },
    {
        -- Exposure  7
        -- Moodle    3
        rate                = 18,
        moodle              = 0.2,
        endurance = {
            duration        = 6,
            limit           = 0.12,
        },
    },
    {
        -- Exposure  8
        -- Moodle    3
        rate                = 28,
        moodle              = 0.2,
        endurance = {
            duration        = 6,
            limit           = 0.12,
        },
    },
    {
        -- Exposure  9
        -- Moodle    4
        rate                = 40,
        moodle              = 0.1,
        endurance = {
            duration        = 4,
            limit           = 0,
        },
    },
    {
        -- Exposure  10
        -- Moodle    4
        rate                = 75,
        moodle              = 0.1,
        endurance = {
            duration        = 2,
            limit           = 0,
        },
    },
}

SWAB_Config.respiratoryAbsorptionLevelMaximum = 10

function SWAB_Config.GetRespiratoryEffects(_respiratoryAbsorptionLevel)
    -- Just wrapping some confusion caused by Lua's table indexing.
    return SWAB_Config.respiratoryEffects[_respiratoryAbsorptionLevel + 1]
end

-- Given the number of hours, this gives back an approximate value that represents the air
-- filtration value for fully cleaning a 3x3 space within that time. This doesn't take
-- into account tick rate, possible todo. This mostly exists to make balancing easier.
function SWAB_Config.GetAirFiltrationFromDuration(_hours)
    return 0.1 / _hours
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