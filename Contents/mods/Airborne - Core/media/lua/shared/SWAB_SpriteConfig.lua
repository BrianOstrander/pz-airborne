SWAB_SpriteConfig = SWAB_SpriteConfig or {}

SWAB_SpriteConfig["swab_air_filters"] = {
    {
        -- SWAB.ValuTechHomeAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 0,
        parameters = {
            AirFiltrationDuration   = 2,
            PowerConsumptionActive  = 0,
            PowerConsumptionIdle    = 0,
        },
    },
    {
        -- SWAB.MassGenFacIndustrialAirFilter
        textureSheet = "swab_filters_01",
        indexBegin = 8,
        parameters = {
            AirFiltrationDuration   = 0.2,
            PowerConsumptionActive  = 0,
            PowerConsumptionIdle    = 0,
        },
    },
}