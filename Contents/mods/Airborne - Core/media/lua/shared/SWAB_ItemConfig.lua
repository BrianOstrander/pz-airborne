SWAB_ItemConfig = SWAB_ItemConfig or {}

SWAB_ItemConfig["swab_base_washables"] = {
    {
        ids = { "Base.Hat_BandanaMask", "Base.Hat_BandanaMaskTINT" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -1,
            SwabRespiratoryExposure_Minimum               = 0,
            SwabRespiratoryExposure_ProtectionDuration    = 4 / 24,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_RefreshAction         = "wash",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
    {
        ids = { "Base.Hat_SurgicalMask_Blue", "Base.Hat_SurgicalMask_Green" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -2,
            SwabRespiratoryExposure_Minimum               = 0,
            SwabRespiratoryExposure_ProtectionDuration    = 12 / 24,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_RefreshAction         = "none",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
    {
        ids = { "Base.Hat_DustMask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -4,
            SwabRespiratoryExposure_Minimum               = 0,
            SwabRespiratoryExposure_ProtectionDuration    = 1,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_RefreshAction         = "wash",
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
        },
    },
}