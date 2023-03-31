SWAB_ItemConfig = SWAB_ItemConfig or {}

-- Remember to update scripts/recipes_swab.txt when adding new entries.

SWAB_ItemConfig["swab_base_washables"] = {
    {
        ids = { "Base.Hat_BandanaMask", "Base.Hat_BandanaMaskTINT" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -3,
            SwabRespiratoryExposure_Falloff               = 3,
            SwabRespiratoryExposure_ProtectionDuration    = 4 / 24,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
            SwabRespiratoryExposure_RefreshAction         = "wash",
            -- Bandanas can bea worn as a hat, so we need to specify this only works if worn as a mask.
            SwabRespiratoryExposure_RequiredBodyLocation  = "Mask",
        },
    },
    {
        ids = { "Base.Hat_SurgicalMask_Blue", "Base.Hat_SurgicalMask_Green" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -4,
            SwabRespiratoryExposure_Falloff               = 2,
            SwabRespiratoryExposure_ProtectionDuration    = 12 / 24,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
            SwabRespiratoryExposure_RefreshAction         = "none",
        },
    },
    {
        ids = { "Base.Hat_DustMask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -5,
            SwabRespiratoryExposure_Falloff               = 3,
            SwabRespiratoryExposure_ProtectionDuration    = 1,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
            SwabRespiratoryExposure_RefreshAction         = "none",
        },
    },
}

SWAB_ItemConfig["swab_base_filterables"] = {
    {
        ids = { "Base.Hat_GasMask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -7,
            SwabRespiratoryExposure_Falloff               = 3,
            SwabRespiratoryExposure_ProtectionDuration    = 4,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
            SwabRespiratoryExposure_RefreshAction         = "replace_filter",
            SwabRespiratoryExposure_CurrentFilterType     = "SWAB.StandardFilter",
        },
    },
    {
        ids = { "Base.Hat_NBCmask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -10,
            SwabRespiratoryExposure_Falloff               = 0,
            SwabRespiratoryExposure_ProtectionDuration    = 5,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = true,
            SwabRespiratoryExposure_RefreshAction         = "replace_filter",
            SwabRespiratoryExposure_CurrentFilterType     = "SWAB.StandardFilter",
        },
    },
    {
        ids = { "Base.HazmatSuit" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -8,
            SwabRespiratoryExposure_Falloff               = 4,
            SwabRespiratoryExposure_ProtectionDuration    = 6,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = true,
            SwabRespiratoryExposure_RefreshAction         = "replace_filter",
            SwabRespiratoryExposure_CurrentFilterType     = "SWAB.StandardFilter",
        },
    },
}

SWAB_ItemConfig["swab_makeshift_filterables"] = {
    -- These could be defined in the actual items script, but for my own sanity when balancing I'm
    -- keeping all these values in this one place.
    {
        ids = { "SWAB.Hat_MakeshiftGasMask" },
        parameters = {
            SwabRespiratoryItem                           = true,
            SwabRespiratoryExposure_Reduction             = -7,
            SwabRespiratoryExposure_Falloff               = 3,
            SwabRespiratoryExposure_ProtectionDuration    = 4,
            SwabRespiratoryExposure_ProtectionRemaining   = 1,
            SwabRespiratoryExposure_AutoHydrationAllowed  = false,
            SwabRespiratoryExposure_RefreshAction         = "replace_filter",
            SwabRespiratoryExposure_CurrentFilterType     = "SWAB.MakeshiftFilter",
        },
    },
}