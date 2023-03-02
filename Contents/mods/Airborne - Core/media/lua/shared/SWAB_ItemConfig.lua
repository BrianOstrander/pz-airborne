SWAB_ItemConfig = SWAB_ItemConfig or {}

SWAB_ItemConfig["swab_default"] = {
    {
        ids = { "Base.Hat_BandanaMask", "Base.Hat_BandanaMaskTINT" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -1,
            SwabRespiratoryExposure_Minimum               = 4,
            SwabRespiratoryExposure_ConsumedDuration      = 8,
            SwabRespiratoryExposure_ConsumedElapsed       = 0,
            SwabRespiratoryExposure_RefreshAction         = "wash",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
    {
        ids = { "Base.Hat_SurgicalMask_Blue", "Base.Hat_SurgicalMask_Green" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -2,
            SwabRespiratoryExposure_Minimum               = 3,
            SwabRespiratoryExposure_ConsumedDuration      = 8,
            SwabRespiratoryExposure_ConsumedElapsed       = 0,
            SwabRespiratoryExposure_RefreshAction         = "none",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
    {
        ids = { "Base.Hat_DustMask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -4,
            SwabRespiratoryExposure_Minimum               = 2,
            SwabRespiratoryExposure_ConsumedDuration      = 8,
            SwabRespiratoryExposure_ConsumedElapsed       = 0,
            SwabRespiratoryExposure_RefreshAction         = "wash",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
}