require "SWAB_Config"

SWAB_SpriteConfig = SWAB_SpriteConfig or {}

-- When SWAB_Config.AirFiltrationMultiplier = 1, AirFiltration values can
-- filter rooms of the following sizes in the specified times.
-- 0.05 : 3x3 in about an hour.
-- 0.075 : 4x3 in just over an hour.

SWAB_SpriteConfig["swab_air_filters"] = {
    {
        -- SWAB.ValuTechHomeAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 0,
        parameters = {
            AirFiltration           = 0.5,
            GeneratorUseDeltaActive = 0,
            GeneratorUseDeltaIdle   = 0,
        },
    },
    {
        -- SWAB.MassGenFacIndustrialAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 8,
        parameters = {
            AirFiltration           = 10,
            GeneratorUseDeltaActive = 0,
            GeneratorUseDeltaIdle   = 0,
        },
    },
    {
        -- SWAB.ValuTechPersonalAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 16,
        parameters = {
            AirFiltration           = 0.1,
            BatteryUseDeltaActive   = 0.0005,
            GeneratorUseDeltaIdle   = 0,
        },
    },
    {
        -- SWAB.MakeshiftAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 24,
        parameters = {
            AirFiltration           = 0.1,
            BatteryUseDeltaActive   = 0.001,
            BatteryUseDeltaIdle     = 0,
        },
    },
}