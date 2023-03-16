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

function SWAB_ItemUtility.GetName(_name, _prefixKey, _suffixKey)
    local itemNamePrefix = getText(_prefixKey)
    local itemNameSuffix = getText(_suffixKey)

    if itemNamePrefix == _prefixKey then
        itemNamePrefix = ""
    end

    if itemNameSuffix == _suffixKey then
        itemNameSuffix = ""
    end

    return itemNamePrefix..getText(_name)..itemNameSuffix
end


function SWAB_ItemUtility.GetContaminatedName(_name, _refreshAction)
    local prefixKey = nil
    local suffixKey = nil

    if _refreshAction == "wash" or _refreshAction == "none" then
        prefixKey = "ContextMenu_SWAB_ContaminatedWashablePrefix"
        suffixKey = "ContextMenu_SWAB_ContaminatedWashableSuffix"
    elseif _refreshAction == "replace_filter" then
        prefixKey = "ContextMenu_SWAB_ContaminatedFilterablePrefix"
        suffixKey = "ContextMenu_SWAB_ContaminatedFilterableSuffix"
    else
        print("SWAB: Error, unrecognized refresh action: "..tostring(_refreshAction))
    end

    return SWAB_ItemUtility.GetName(_name, prefixKey, suffixKey)
end

function SWAB_ItemUtility.GetMissingFilterName(_name)
    return SWAB_ItemUtility.GetName(_name, "ContextMenu_SWAB_MissingFilterablePrefix", "ContextMenu_SWAB_MissingFilterableSuffix")
end

function SWAB_ItemUtility.GetUsedFilterName(_name)
    return SWAB_ItemUtility.GetName(_name, "ContextMenu_SWAB_UsedFilterPrefix", "ContextMenu_SWAB_UsedFilterSuffix")
end