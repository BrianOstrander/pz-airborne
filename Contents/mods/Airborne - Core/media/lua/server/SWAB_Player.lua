require "SWAB_Config"
require "SWAB_Data"
require "SWAB_Utilities"

SWAB_Player = {}

function SWAB_Player.OnCreatePlayer(_, _player)
	local modData = _player:getModData().swab_player

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
        -- An integer between 0-5, measures the current sickness level.
        modData.respiratorySicknessLevel = 0
        -- Maximum the endurance modifier is allowed to be.
        modData.enduranceMaximum = 1

        _player:getModData().swab_player = modData
        _player:transmitModData()
    end
end
Events.OnCreatePlayer.Add(SWAB_Player.OnCreatePlayer)

function SWAB_Player.EveryOneMinute()
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        local modData = player:getModData().swab_player

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
            modData.respiratoryAbsorption = PZMath.min(SWAB_Config.respiratoryAbsorptionMaximum, PZMath.max(0, modData.respiratoryAbsorption + (modData.respiratoryAbsorptionRate / 1440)))
            modData.respiratorySicknessLevel = SWAB_Player.CalculateRespiratorySicknessLevel(
                player,
                modData.respiratorySicknessLevel,
                modData.respiratoryAbsorption
            )

            SWAB_Player.ApplyEffects(
                player,
                SWAB_Config.GetRespiratorySicknessEffects(modData.respiratorySicknessLevel),
                SWAB_Config.GetRespiratoryExposureEffects(modData.respiratoryAbsorptionLevel)
            )
        end
    end
end
Events.EveryOneMinute.Add(SWAB_Player.EveryOneMinute)

function SWAB_Player.OnTick(_ticks)
    for _, player in ipairs(SWAB_Utilities.GetPlayers()) do
        local modData = player:getModData().swab_player

        if modData then
            if modData.enduranceMaximum then
                local stats = player:getStats()
                if modData.enduranceMaximum < stats:getEndurance() then
                    -- Apply the enduranceMaximum we calculated on the last minute, doing it on tick to minimize ping-ponging.
                    player:getStats():setEndurance(modData.enduranceMaximum)
                end
            end
        end
    end
end
Events.OnTick.Add(SWAB_Player.OnTick)

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
                return _player:getSquare():getModData().swab_square_exposure
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
                if itemModData.SwabRespiratoryItem and not itemModData.SwabRespiratoryExposure_RequiredBodyLocation or item:getBodyLocation() == itemModData.SwabRespiratoryExposure_RequiredBodyLocation then
                    -- We've established this is an item that provides respiratory protection, and that there is no required location for equiping it,
                    -- or it's equiped in the correct location.
                    local itemProtectionDurationInMinutes = itemModData.SwabRespiratoryExposure_ProtectionDuration * SWAB_Config.itemRespiratoryProtectionDurationMultiplier
                    
                    local itemProtectionRemaining = itemModData.SwabRespiratoryExposure_ProtectionRemaining
                    local itemProtectionRemainingUpdated = PZMath.max(0, itemProtectionRemaining - (1 / itemProtectionDurationInMinutes))
                    if not PZMath.equal(itemProtectionRemaining, itemProtectionRemainingUpdated) then
                        -- Item still has some protection remaining
                        local wasFresh = PZMath.equal(1, itemProtectionRemaining)
                        itemProtectionRemaining = itemProtectionRemainingUpdated
                        itemModData.SwabRespiratoryExposure_ProtectionRemaining = itemProtectionRemaining
                        if PZMath.equal(0, itemProtectionRemaining) then
                            -- Item has been contaminated
                            item:setName(SWAB_ItemUtility.GetContaminatedName(getItemNameFromFullType(item:getFullType()), itemModData.SwabRespiratoryExposure_RefreshAction))
                            item:setCustomName(true)
                        else
                            -- Item is clean and still providing protection.
                            local itemExposure = PZMath.max(0, PZMath.floor(_respiratoryExposure) + itemModData.SwabRespiratoryExposure_Reduction) * itemModData.SwabRespiratoryExposure_Falloff
                            _respiratoryExposure = PZMath.min(_respiratoryExposure, itemExposure)

                            if wasFresh then
                                -- This item went from fresh to used.
                                item:setName(SWAB_ItemUtility.GetUsedName(getItemNameFromFullType(item:getFullType()), itemModData.SwabRespiratoryExposure_RefreshAction))
                                item:setCustomName(true)
                            end
                        end 
                    end

                    -- We can never reduce our exposure below the item's rated minimum.
                    

                    -- There's a chance that wearing this item is no better than going without it.
                    -- We return here since only one respiratory item can be worn at a time.
                    return _respiratoryExposure
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

function SWAB_Player.CalculateRespiratorySicknessLevel(_player, _respiratorySicknessLevel, _respiratoryAbsorption)

    for sicknessLevel = SWAB_Config.respiratorySicknessLevelMaximum, 0, -1 do
        local sickness = SWAB_Config.GetRespiratorySicknessEffects(sicknessLevel)
        local absorptionMinimum = sickness.absorptionMinimum

        if sicknessLevel == _respiratorySicknessLevel then
            -- To prevent ping ponging of sickness values, we make sure the player has healed a healthy amount
            -- below the sickness.absorptionMinimum before letting them heal a level of sickness.
            absorptionMinimum = sickness.absorptionHealMinimum
        end

        if absorptionMinimum <= _respiratoryAbsorption then
            return sicknessLevel
        end
    end

    -- This should never happen.
    print("SWAB: Error, unable to find a sickness level for respiratory absorption: ".._respiratoryAbsorption)
    return 0
end

-- Various moodles are taken into account when calculating the absorption rate
function SWAB_Player.CalculateRespiratoryAbsorptionRate(_player, _respiratoryAbsorptionLevel)
    local levelRate = SWAB_Config.GetRespiratoryExposureEffects(_respiratoryAbsorptionLevel).rate

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
            levelRateMultiplier = levelRateMultiplier * 0.75
        elseif _player:getTraits():contains("FastHealer") then
            levelRateMultiplier = levelRateMultiplier * 2
        end

        levelRate = levelRate * levelRateMultiplier
    else
        -- TODO: This is where veteran and asthmatic should be taken into account... I think?
        -- possibly in CalculateRespiratoryAbsorptionLevel though... or maybe only affect healing...
    end

    return levelRate
end

-- Each level of resperatory absorption affects various player stats
function SWAB_Player.ApplyEffects(_player, _sickness, _exposure)
    local modData = _player:getModData().swab_player
    local stats = _player:getStats()

    -- Endurance
    local endurance = stats:getEndurance()
    local enduranceModified = false

    if _sickness and _sickness.endurance and not PZMath.equal(_sickness.endurance.limit, 1) then
        enduranceModified = true
        endurance = PZMath.min(endurance, _sickness.endurance.limit)
    end
    
    if _exposure.endurance and not PZMath.equal(_exposure.endurance.limit, 1) then
        enduranceModified = true
        -- This stops the player from going briefly inside to reset their enduranceMaximum, 
        -- now it will never be higher than their current endurance. This means running around
        -- will push your enduranceMaximum down faster, not allowing you to recoup any endurance
        -- above the current effects limit.
        endurance = PZMath.max(PZMath.min(endurance, modData.enduranceMaximum), PZMath.min(endurance, _exposure.endurance.limit))

        if _exposure.endurance.limit < endurance then
            -- We haven't bottomed out on our enduranceMaximum yet...
            local enduranceDepletionRemaining = endurance - _exposure.endurance.limit
            -- Since duration is in hours, and we call this function every minute,
            -- we need to calculate our own modifier to enduranceMaximum by the minute.
            local enduranceDelta = (1 - _exposure.endurance.limit) / (_exposure.endurance.duration * 60)    
            -- Ensure we don't overshoot the limit when the delta is added.
            enduranceDelta = PZMath.min(enduranceDepletionRemaining, enduranceDelta)
            endurance = endurance - enduranceDelta
            -- enduranceMaximum is now the maximum the player's endurance should ever be.
        end
    end

    if enduranceModified then
        modData.enduranceMaximum = endurance
    else
        modData.enduranceMaximum = 1
    end

    -- We don't apply the enduranceMaximum here, we wait until OnTick.
end