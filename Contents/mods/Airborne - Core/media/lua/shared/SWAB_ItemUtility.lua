require "SWAB_ItemConfig"

SWAB_ItemUtility = {}
SWAB_ItemUtility.isItemCacheInitialized = false

function SWAB_ItemUtility.Initialize()
    if SWAB_ItemUtility.isItemCacheInitialized then
        return
    end

    if SWAB_Config.debug.logging then
        print("SWAB: SWAB_ItemUtility.Initialize Begin")
    end

    SWAB_ItemUtility.isItemCacheInitialized = true

    local configCount = 0
    local configItemCount = 0

    for _, itemConfigs in pairs(SWAB_ItemConfig) do
        configCount = configCount + 1
        for _, itemConfig in pairs(itemConfigs) do
            for _, itemId in pairs(itemConfig.ids) do
                configItemCount = configItemCount + 1
                -- SWAB_ItemUtility.itemCache[itemId] = {}
                -- SWAB_ItemUtility.itemCache[itemId].respiratoryExposure = itemConfig.respiratoryExposure
                local itemScript = ScriptManager.instance:getItem(itemId)
                if itemScript then
                    for parameterKey, parameterValue in pairs(itemConfig.parameters) do
                        itemScript:DoParam(parameterKey.." = "..tostring(parameterValue))
                    end
                else
                    print("SWAB: Error, unable to find an item script for "..itemId)
                end
            end
        end
    end

    if SWAB_Config.debug.logging then
        print("SWAB: SWAB_ItemUtility.Initialize Cached "..configItemCount.." from "..configCount.." configuration file(s)")
    end
end
Events.OnGameBoot.Add(SWAB_ItemUtility.Initialize)

-- function SWAB_ItemUtility.InitializeItem(_item)
--     local modData = _item:getModData()[SWAB_ItemUtility.itemConfigModDataId]

--     if modData then
--         return modData
--     end

--     modData = {}
--     -- modData.consumedDurationRemaining = 
-- end