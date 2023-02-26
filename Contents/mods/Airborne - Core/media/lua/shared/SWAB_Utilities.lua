SWAB_Utilities = {}

function SWAB_Utilities.IsSinglePlayer()
    return not isClient() and not isServer()
end

-- Provides a table of players in the same format whether this is a server or singleplayer.
function SWAB_Utilities.GetPlayers()
    if SWAB_Utilities.IsSinglePlayer() then
        return { getPlayer() }
    end

    return getOnlinePlayers()
end
