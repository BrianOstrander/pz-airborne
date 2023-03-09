require "SWAB_SpriteConfig"

SWAB_SpriteUtility = {}

function SWAB_SpriteUtility.Initialize()
    -- All sprite properties and their values are hashed, and need to be calculated ahead of time.
    local valueMap = {}
    for _, spriteConfigs in pairs(SWAB_SpriteConfig) do
        for _, spriteConfig in pairs(spriteConfigs) do
            for parameterName, parameterValue in pairs(spriteConfig.parameters) do
                local valueArray = valueMap[parameterName]
                if not valueArray then
                    valueArray = ArrayList.new()
                    valueMap[parameterName] = valueArray
                end
                print("SWABTest: adding "..parameterName.." val of "..parameterValue)
                valueArray:add(tostring(parameterValue))
            end
        end
    end

    for property, values in pairs(valueMap) do
        print("SWABTest: adding "..property)
        IsoWorld.PropertyValueMap:put(property, values)
    end
end

function SWAB_SpriteUtility.OnLoadedTileDefinitions(_spriteManager)
    for _, spriteConfigs in pairs(SWAB_SpriteConfig) do
        for _, spriteConfig in pairs(spriteConfigs) do
            for spriteIndex = spriteConfig.indexBegin, (spriteConfig.indexCount or (spriteConfig.indexBegin + 4)) do
                local sprite = _spriteManager:getSprite(spriteConfig.textureSheet.."_"..spriteIndex)
                if sprite then
                    for parameterName, parameterValue in pairs(spriteConfig.parameters) do
                        print("SWABTest: setting now on "..spriteConfig.textureSheet.."_"..spriteIndex)
                        print("SWABTest: "..parameterName.." : "..parameterValue)
                        sprite:getProperties():Set(parameterName, tostring(parameterValue), false)
                    end
                else
                    print("SWAB: Error, unable to find sprite entry "..spriteConfig.textureSheet.."_"..spriteIndex)
                end
            end
        end
    end
end
Events.OnLoadedTileDefinitions.Add(SWAB_SpriteUtility.OnLoadedTileDefinitions)

SWAB_SpriteUtility.Initialize()