SWAB_Core = {}

function SWAB_Core.GameBoot()
    -- Server does not seem to load translation files by default...
    -- This is required for setting contaminated item names in SWAB_Player.lua
    Translator.loadFiles()
end
Events.OnGameBoot.Add(SWAB_Core.GameBoot)