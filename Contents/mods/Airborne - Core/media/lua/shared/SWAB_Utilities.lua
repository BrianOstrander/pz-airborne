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

function SWAB_Utilities.GetGenerator(_origin)
    if not _origin:haveElectricity() then
        return nil
    end

    for z = PZMath.max(_origin:getZ() - 3, 0), PZMath.min(_origin:getZ() + 3, 8) do
        for x = (_origin:getX() - 20), (_origin:getX() + 20) do
            for y = (_origin:getY() - 20), (_origin:getY() + 20) do
                if IsoUtils.DistanceToSquared(x + 0.5, y + 0.5, _origin:getX() + 0.5, _origin:getY() + 0.5) <= 400 then
                    -- This is a square within the radius of a potential generator.
                    local square = getCell():getGridSquare(x, y, z)
                    if square then
                        local generator = square:getGenerator()
                        -- square:getFloor():setHighlighted(true, true)
                        -- square:getFloor():setHighlightColor(0.0, 1.0, 0.0, 0.5)
                        if generator and generator:isConnected() and generator:isActivated() then
                            -- Found our generator
                            return generator
                        end
                    end
                end
            end
        end
    end

    -- No generator found.
    return nil
end
