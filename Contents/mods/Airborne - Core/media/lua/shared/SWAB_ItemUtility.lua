require "SWAB_ItemConfig"

SWAB_ItemUtility = {}
SWAB_ItemUtility.isItemCacheInitialized = false

SWAB_ItemUtility.itemsByRefreshAction = {}

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

                        if parameterKey == "SwabRespiratoryExposure_RefreshAction" then
                            -- This is in place of logic that requires item tagging, which is probably possible
                            -- but I haven't had a chance to check.
                            if parameterValue then
                                if not SWAB_ItemUtility.itemsByRefreshAction[parameterValue] then
                                    SWAB_ItemUtility.itemsByRefreshAction[parameterValue] = {}
                                end
                                table.insert(SWAB_ItemUtility.itemsByRefreshAction[parameterValue], itemId)
                            else
                                print("SWAB: Error, parameter "..parameterKey.." should not be nil")
                            end
                        end
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

SWAB_ItemUtility.ItemsByRefreshAction = SWAB_ItemUtility.ItemsByRefreshAction or {}

function SWAB_ItemUtility.ItemsByRefreshAction.Get(_scriptItems, _refreshAction)
    for _, itemId in pairs(SWAB_ItemUtility.itemsByRefreshAction[_refreshAction]) do
        local all = getScriptManager():getItemsByType(itemId)
        for i = 0, all:size() - 1 do
            local scriptItem = all:get(i)
            if not _scriptItems:contains(scriptItem) then
                _scriptItems:add(scriptItem)
            end
        end
    end
end

function SWAB_ItemUtility.ItemsByRefreshAction.Wash(_scriptItems)
    SWAB_ItemUtility.ItemsByRefreshAction.Get(_scriptItems, "wash")
end

function SWAB_ItemUtility.ItemsByRefreshAction.ReplaceFilter(_scriptItems)
    SWAB_ItemUtility.ItemsByRefreshAction.Get(_scriptItems, "replace_filter")
end

function SWAB_ItemUtility.GetContaminatedName(_name, _refreshAction)
    if _refreshAction == "wash" or _refreshAction == "none" then
        return getText("ContextMenu_SWAB_ContaminatedWashable", _name)
    elseif _refreshAction == "replace_filter" then
        return getText("ContextMenu_SWAB_ContaminatedFilterable", _name)
    end

    print("SWAB: Error, unrecognized refresh action: "..tostring(_refreshAction))
    return _name
end

function SWAB_ItemUtility.GetUsedName(_name, _refreshAction)
    if _refreshAction == "wash" or _refreshAction == "none" then
        return getText("ContextMenu_SWAB_UsedWashable", _name)
    elseif _refreshAction == "replace_filter" then
        return _name
    end

    print("SWAB: Error, unrecognized refresh action: "..tostring(_refreshAction))
    return _name
end