require "TimedActions/ISBaseTimedAction"

SWAB_DecontaminateMask = ISBaseTimedAction:derive("SWAB_DecontaminateMask")

function SWAB_DecontaminateMask:isValid()
    return SWAB_DecontaminateMask.HasRequiredWater(self.sink, SWAB_DecontaminateMask.GetRequiredWater())
end

function SWAB_DecontaminateMask:update()
    self.item:setJobDelta(self:getJobDelta())
    if self:isSink() then
        self.character:faceThisObjectAlt(self.sink)
    end
    self.character:setMetabolicTarget(Metabolics.HeavyDomestic)
end

function SWAB_DecontaminateMask:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "")
    self:setOverrideHandModels(nil, nil)
    self.sound = self.character:playSound("WashClothing")
    self.character:reportEvent("EventWashClothing")
end

function SWAB_DecontaminateMask:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function SWAB_DecontaminateMask:stop()
    self:stopSound()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function SWAB_DecontaminateMask:isSink()
    return self.sink.getWaterAmount ~= nil
end

function SWAB_DecontaminateMask.GetSoapRemaining(soaps)
    local total = 0
    for _,soap in ipairs(soaps) do
        total = total + soap:getRemainingUses()
    end
    return total
end

function SWAB_DecontaminateMask.GetRequiredSoap(item)
    local total = 0
    if instanceof(item, "Clothing") then
        local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
        if coveredParts then
            for i=1,coveredParts:size() do
                local part = coveredParts:get(i-1)
                if item:getBlood(part) > 0 then
                    total = total + 1
                end
            end
        end
    else
        if item:getBloodLevel() > 0 then
            total = total + 1
        end
    end
    return total
end

function SWAB_DecontaminateMask.GetRequiredWater()
    return 10
end

function SWAB_DecontaminateMask.HasRequiredWater(_item, _amount)
    if _item.getWaterAmount then
        -- Must be a sink or maybe a barrel?
        if _item:isTaintedWater() then
            return false
        end
        return _amount <= _item:getWaterAmount()
    elseif _item.getDrainableUsesInt then
        -- Liquid container item, like a water bottle
        return _amount <= _item:getDrainableUsesInt()
    end
    return false
end

function SWAB_DecontaminateMask:useSoap(item, part)
    local blood = 0
    if part then
        blood = item:getBlood(part)
    else
        blood = item:getBloodLevel()
    end
    if blood > 0 then
        for i,soap in ipairs(self.soaps) do
            if soap:getRemainingUses() > 0 then
                soap:Use()
                return true
            end
        end
    else
        return true
    end
    return false
end

function SWAB_DecontaminateMask:perform()
    self:stopSound()
    self.item:setJobDelta(0.0)
    local item = self.item
    local water = SWAB_DecontaminateMask.GetRequiredWater()
    if instanceof(item, "Clothing") then
        local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
        if coveredParts then
            for j=0,coveredParts:size()-1 do
                if self.noSoap == false then
                    self:useSoap(item, coveredParts:get(j))
                end
                item:setBlood(coveredParts:get(j), 0)
                item:setDirt(coveredParts:get(j), 0)
            end
        end
        item:setWetness(100)
        item:setDirtyness(0)
    else
        self:useSoap(item, nil)
    end
    item:setBloodLevel(0)
    item:getModData().SwabRespiratoryExposure_ProtectionRemaining = 1
    
    self.character:resetModel()
    sendClothing(self.character)
    if self.character:isPrimaryHandItem(item) then
        self.character:setPrimaryHandItem(item)
    end
    if self.character:isSecondaryHandItem(item) then
        self.character:setSecondaryHandItem(item)
    end
    triggerEvent("OnClothingUpdated", self.character)
    
    if self:isSink() then
        ISTakeWaterAction.SendTakeWaterCommand(self.character, self.sink, water)
    else
        -- Liquid container item, like a water bottle
        self.sink:setUsedDelta(PZMath.max(0, self.sink:getDrainableUsesInt() - SWAB_DecontaminateMask.GetRequiredWater()) / (1 / self.sink:getUseDelta()))
    end
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function SWAB_DecontaminateMask:new(_character, _sink, _soaps, _item, _contaminationAmount, _bloodAmount, _dirtAmount, _noSoap)
    local result = {}
    setmetatable(result, self)
    self.__index = self
    result.character = _character
    result.sink = _sink
    result.soaps = _soaps
    result.item = _item
    result.noSoap = _noSoap

    if result.character:isTimedActionInstant() then
        result.maxTime = 1
    else
        result.maxTime = PZMath.min(500, (_bloodAmount + _dirtAmount + (_contaminationAmount * 30)) * 15)
        
        if result.noSoap == true then
            result.maxTime = PZMath.min(800, result.maxTime * 5)
        end

        result.maxTime = PZMath.max(100, result.maxTime)
    end

    result.forceProgressBar = true
    result.stopOnWalk = true
    result.stopOnRun = true
    
    return result
end
