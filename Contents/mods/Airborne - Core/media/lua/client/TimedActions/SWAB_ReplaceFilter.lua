require "TimedActions/ISBaseTimedAction"

SWAB_ReplaceFilter = ISBaseTimedAction:derive("SWAB_ReplaceFilter")

function SWAB_ReplaceFilter:isValidStart()
    return 0 < self.filter:getUsedDelta() and self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining < 1
end

function SWAB_ReplaceFilter:isValid()
    local inventory = self.character:getInventory()
    return inventory:contains(self.target) and inventory:contains(self.filter)
end

function SWAB_ReplaceFilter:start()
    -- TODO: Localize
    self.target:setJobType("Replace")
    self.target:setJobDelta(0)
end

function SWAB_ReplaceFilter:update()
    self.target:setJobDelta(self:getJobDelta())
end

function SWAB_ReplaceFilter:stop()
    self.target:setJobDelta(0)
    ISBaseTimedAction.stop(self)
end

function SWAB_ReplaceFilter:perform()
    self.target:setJobDelta(0)

    local filter = self.character:getInventory():AddItem("SWAB.StandardFilter")
    filter:setUsedDelta(self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining)
    filter:setName(getText("ContextMenu_SWAB_UsedFilter", filter:getDisplayName()))
    filter:setCustomName(true)

    self.target:getModData().SwabRespiratoryExposure_ProtectionRemaining = self.filter:getUsedDelta()
    self.target:setName(ScriptManager.instance:getItem(self.target:getType()):getDisplayName())
    self.target:setCustomName(false)
    
    self.character:getInventory():Remove(self.filter)
    
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function SWAB_ReplaceFilter:new(_player, _target, _filter, _time)
    local result = ISBaseTimedAction.new(self, _player)
    
    result.character = _player

    result.target = _target
    result.filter = _filter

    result.maxTime = _time

    result.stopOnWalk = true
    result.stopOnRun = true

	return result
end
