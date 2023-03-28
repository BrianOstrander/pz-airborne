require "TimedActions/ISBaseTimedAction"

SWAB_InsertFilter = ISBaseTimedAction:derive("SWAB_InsertFilter")

function SWAB_InsertFilter:isValidStart()
    return 0 < self.filter:getUsedDelta() and PZMath.equal(0, self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining)
end

function SWAB_InsertFilter:isValid()
    local inventory = self.character:getInventory()
    return inventory:contains(self.target) and inventory:contains(self.filter)
end

function SWAB_InsertFilter:start()
    self.target:setJobType(getText("ContextMenu_SWAB_Insert"))
    self.target:setJobDelta(0)
end

function SWAB_InsertFilter:update()
    self.target:setJobDelta(self:getJobDelta())
end

function SWAB_InsertFilter:stop()
    self.target:setJobDelta(0)
    ISBaseTimedAction.stop(self)
end

function SWAB_InsertFilter:perform()
    self.target:setJobDelta(0)

    self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining = self.filter:getUsedDelta()
    self.target:setName(getItemNameFromFullType(self.target:getFullType()))
    self.target:setCustomName(false)
    
    self.character:getInventory():Remove(self.filter)
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function SWAB_InsertFilter:new(_player, _target, _filter, _time)
    local result = ISBaseTimedAction.new(self, _player)
    
    result.character = _player

    result.target = _target
    result.filter = _filter

    result.maxTime = _time

    result.stopOnWalk = true
    result.stopOnRun = true

	return result
end
