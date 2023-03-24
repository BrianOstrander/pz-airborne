require "TimedActions/ISBaseTimedAction"

SWAB_RemoveFilter = ISBaseTimedAction:derive("SWAB_RemoveFilter")

function SWAB_RemoveFilter:isValidStart()
    return 0 < self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining
end

function SWAB_RemoveFilter:isValid()
    return self.character:getInventory():contains(self.target)
end

function SWAB_RemoveFilter:start()
    -- TODO: Localize
    self.target:setJobType("Remove")
    self.target:setJobDelta(0)
end

function SWAB_RemoveFilter:update()
    self.target:setJobDelta(self:getJobDelta())
end

function SWAB_RemoveFilter:stop()
    self.target:setJobDelta(0)
    ISBaseTimedAction.stop(self)
end

function SWAB_RemoveFilter:perform()
    self.target:setJobDelta(0)

    local filter = self.character:getInventory():AddItem("SWAB.StandardFilter")
    filter:setUsedDelta(self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining)

    if not PZMath.equal(1, filter:getUsedDelta()) then
        filter:setName(getText("ContextMenu_SWAB_UsedFilter", getItemNameFromFullType(filter:getFullType())))
		filter:setCustomName(true)
	end
    
    self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining = 0
    self.target:setName(getText("ContextMenu_SWAB_MissingFilterable", getItemNameFromFullType(filter:getFullType())))
	self.target:setCustomName(true)

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function SWAB_RemoveFilter:new(_player, _target, _time)
    local result = ISBaseTimedAction.new(self, _player)
    
    result.character = _player
    result.target = _target
    result.maxTime = _time

    result.stopOnWalk = true
    result.stopOnRun = true

	return result
end
