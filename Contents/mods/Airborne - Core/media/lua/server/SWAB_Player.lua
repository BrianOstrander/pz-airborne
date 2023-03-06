require "SWAB_Config"
require "SWAB_Data"
require "SWAB_Utilities"

SWAB_Player = {}

function SWAB_Player.OnCreatePlayer(_, _player)
	local modData = _player:getModData()[SWAB_Config.playerModDataId]

    if not modData then
        if SWAB_Config.debug.logging then
            print("SWAB: SWAB_Player.OnCreatePlayer initialize")
        end
        modData = {}
        modData.isInitialized = true
        -- A float between 0-10, measures raw exposure to respiratory toxins.
        modData.respiratoryExposure = 0
        -- An integer between 0-10, measures raw exposure to respiratory toxins.
        modData.respiratoryExposureLevel = 0
        -- An integer between 0-10, measures how respiratory toxins that are
        -- actually affecting the player, incase they have trait or profession
        -- modifiers that change their sensitivities to toxins.
        modData.respiratoryAbsorptionLevel = 0
        -- A float, the rate at which their toxin absorption is going up per day.
        modData.respiratoryAbsorptionRate = 0
        -- A float, the total toxins absorbed.
        modData.respiratoryAbsorption = 0
        _player:getModData()[SWAB_Config.playerModDataId] = modData
        _player:transmitModData()
    end
end
Events.OnCreatePlayer.Add(SWAB_Player.OnCreatePlayer)

function SWAB_Player.EveryOneMinute()
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        local modData = player:getModData()[SWAB_Config.playerModDataId]

        if not modData or not modData.isInitialized then
            -- Must be before mod data is initialized by the game.
            return
        end

        -- If the player is teleporting, it's possible for this to be nil, so we keep the value the same.
        modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposure(player) or modData.respiratoryExposure

        if modData.respiratoryExposure then
            modData.respiratoryExposure = SWAB_Player.CalculateRespiratoryExposureWithProtection(player, modData.respiratoryExposure)
            modData.respiratoryExposureLevel = SWAB_Player.CalculateRespiratoryExposureLevel(player, modData.respiratoryExposure)
            modData.respiratoryAbsorptionLevel = SWAB_Player.CalculateRespiratoryAbsorptionLevel(player, modData.respiratoryExposureLevel)
            modData.respiratoryAbsorptionRate = SWAB_Player.CalculateRespiratoryAbsorptionRate(player, modData.respiratoryAbsorptionLevel)
           
            -- Level rate is divided by minutes in day.
            modData.respiratoryAbsorption = PZMath.max(0, modData.respiratoryAbsorption + (modData.respiratoryAbsorptionRate / 1440))
        end
    end
end
Events.EveryOneMinute.Add(SWAB_Player.EveryOneMinute)

-- Calculates the amount of respiratory toxins the player would be exposed to without
-- wearing any protective gear, from the environment.
function SWAB_Player.CalculateRespiratoryExposure(_player)
    local vehicle = _player:getVehicle()
    if vehicle then
        -- If we're cruising with any openings in our car, we get maximum exposure
        local vehicleMaximumExposure = 8
        if math.abs(vehicle:getCurrentSpeedKmHour()) < 12 then
            -- Staying under 5km/h reduces our exposure
            vehicleMaximumExposure = 6
        end

        -- Check all parts
        for i = 0, vehicle:getPartCount() do
            local part = vehicle:getPartByIndex(i);
            -- We found a valid window or door
            if part and (part:getWindow() or part:getDoor()) then
                if part:getInventoryItem() then 
                    -- The window or door is not missing
                    if part:getWindow() then
                        if part:getWindow():isOpen() then
                            -- Window is open
                            return vehicleMaximumExposure
                        end
                    elseif part:getDoor() then
                        if part:getDoor():isOpen() then
                            -- Door is open
                            return vehicleMaximumExposure
                        end
                    end
                else
                    -- The window or door is missing
                    return vehicleMaximumExposure
                end
            end
        end

        -- No doors or windows are open, and are all intact
        return 4
    else
        if _player:isOutside() then
            -- This may error out on topmost level? Not tested
            local squareAbove = nil
            local squareAboveX = _player:getX()
            local squareAboveY = _player:getY()
            local squareAboveZ = _player:getZ() + 1
            repeat
                squareAbove = getCell():getGridSquare(squareAboveX, squareAboveY, squareAboveZ)
                squareAboveZ = squareAboveZ + 1
            until not squareAbove or squareAbove:Is(IsoFlagType.attachedFloor)

            if squareAbove and squareAbove:Is(IsoFlagType.attachedFloor) then
                -- Must be under a patio
                return 6
            else
                -- Outside and entirely unprotected
                -- TODO: rain adds + 1, and fog adds + 2
                return 7
            end
        else
            -- Inside a room

            if _player:getSquare() then
                return _player:getSquare():getModData()[SWAB_Config.squareExposureModDataId]
            end
        end
    end

    -- Player must have been teleporting, be dead, or some other edge case
    return nil
end


-- Using the provided raw respiratory exposure calculated as if the player had no
-- protection, we calculate how the player is protected by the gear they are wearing.
function SWAB_Player.CalculateRespiratoryExposureWithProtection(_player, _respiratoryExposure)
    local items = _player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:IsClothing() and item:isEquipped() then
            local itemModData = item:getModData()
            if itemModData then
                if itemModData["SwabRespiratoryItem"] then
                    -- We've established this is an item that provides respiratory protection.
                    local itemConsumedDuration = itemModData["SwabRespiratoryExposure_ConsumedDuration"] * SWAB_Config.itemConsumptionDurationMultiplier
                    local itemReduction = 0
                    local itemMinimum = 0
                    
                    local itemConsumedElapsed = itemModData["SwabRespiratoryExposure_ConsumedElapsed"]
                    local itemConsumedElapsedUpdated = PZMath.min(itemConsumedDuration, itemConsumedElapsed + 1)
                    if itemConsumedElapsed ~= itemConsumedElapsedUpdated then
                        itemConsumedElapsed = itemConsumedElapsedUpdated

                        if itemConsumedDuration <= itemConsumedElapsed then
                            -- Item has been contaminated
                            local itemNamePrefix = getText("ContextMenu_SWAB_ContaminatedPrefix")
                            local itemNameSuffix = getText("ContextMenu_SWAB_ContaminatedSuffix")

                            if itemNamePrefix == "ContextMenu_SWAB_ContaminatedPrefix" then
                                itemNamePrefix = ""
                            end

                            if itemNameSuffix == "ContextMenu_SWAB_ContaminatedSuffix" then
                                itemNameSuffix = ""
                            end

                            item:setName(itemNamePrefix..getText(item:getDisplayName())..itemNameSuffix)
                        end

                        itemModData["SwabRespiratoryExposure_ConsumedElapsed"] = itemConsumedElapsed
                    end

                    
                    if itemConsumedElapsed < itemConsumedDuration then
                        -- Still not entirely contaminated.
                        itemReduction = itemModData["SwabRespiratoryExposure_Reduction"]
                        itemMinimum = itemModData["SwabRespiratoryExposure_Minimum"]
                    end

                    -- We can never reduce our exposure below the item's rated minimum.
                    local itemExposure = PZMath.max(_respiratoryExposure + itemReduction, itemMinimum)

                    -- There's a chance that wearing this item is no better than going without it.
                    return PZMath.min(itemExposure, _respiratoryExposure)
                end
            end
        end
    end

    -- There's nothing protecting us.
    return _respiratoryExposure
end

-- Simply wrapping this
function SWAB_Player.CalculateRespiratoryExposureLevel(_player, _respiratoryExposure)
    return PZMath.floor(_respiratoryExposure)
end

-- Traits affect the absorption levels the player uses to calculate their absorption rate.
function SWAB_Player.CalculateRespiratoryAbsorptionLevel(_player, _respiratoryExposureLevel)
    local level = _respiratoryExposureLevel
    local traits = _player:getTraits()
    
    if traits:contains("Resilient") then
        level = level - 1
    elseif 0 < level and traits:contains("ProneToIllness") then
        -- We have to check to make sure exposure levels are above zero so players with
        -- Prone to Illness have a way to escape exposure.
        level = level + 1
    end

    return PZMath.clamp(level, 0, SWAB_Config.respiratoryAbsorptionLevelMaximum)
end

-- Various moodles are taken into account when calculating the absorption rate
function SWAB_Player.CalculateRespiratoryAbsorptionRate(_player, _respiratoryAbsorptionLevel)
    local levelRate = SWAB_Config.getRespiratoryAbsorptionLevel(_respiratoryAbsorptionLevel).rate

    if levelRate < 0 then
        -- Player is recovering from exposure
        -- Full to bursting above 4800
        -- Stuffed above 3200
        -- Well Fed above 1600
        -- Satiated above 0

        -- Hungry 0.25
        -- Very Hungry 0.45
        -- Starving 0.7

        local hunger = _player:getStats():getHunger()
        local healthFromFoodTimer = _player:getBodyDamage():getHealthFromFoodTimer()
        local levelRateMultiplier = 1
        if 0.7 < hunger then
            -- Starving
            levelRateMultiplier = 0
        elseif 0.45 < hunger then
            -- Very Hungry
            levelRateMultiplier = 0.40
        elseif 0.25 < hunger then
            -- Hungry
            levelRateMultiplier = 0.65
        elseif 0 < healthFromFoodTimer then
            -- Satiated/Well Fed/Stuffed/Full to Bursting
            -- I think the higher food timers just affect how long the healing buff lasts
            levelRateMultiplier = 2

            -- Times for health timer incase needed:
            -- Satiated = healthFromFoodTimer < 1600 then
            -- Well Fed = healthFromFoodTimer < 3200 then
            -- Stuffed = healthFromFoodTimer < 4800 then
            -- Full to Bursting is above 4800
        end

        if _player:getTraits():contains("SlowHealer") then
            levelRate = levelRate * 0.75
        elseif _player:getTraits():contains("FastHealer") then
            levelRate = levelRate * 2
        end

        levelRate = levelRate * levelRateMultiplier
    end

    return levelRate
end