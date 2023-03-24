require "SWAB_Config"

SWAB_ISWashClothing = {}
SWAB_ISWashClothing.base_GetRequiredSoap = ISWashClothing.GetRequiredSoap

function ISWashClothing.GetRequiredSoap(item)
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
-- SWAB MOD BEGIN
    local itemModData = item:getModData()
    if itemModData.SwabRespiratoryItem and itemModData.SwabRespiratoryExposure_RefreshAction == "wash" then
        total = total + PZMath.ceil((1 - itemModData.SwabRespiratoryExposure_ProtectionRemaining) * SWAB_Config.itemRespiratorySoapMaximum)
    end
-- SWAB MOD END
	return total
end

SWAB_ISWashClothing.base_perform = ISWashClothing.perform

function ISWashClothing:perform()
	self:stopSound()
	self.item:setJobDelta(0.0)
	local item = self.item;
	local water = ISWashClothing.GetRequiredWater(item)
-- SWAB MOD BEGIN
    local itemModData = item:getModData()
    if itemModData.SwabRespiratoryItem and itemModData.SwabRespiratoryExposure_RefreshAction == "wash" then
        item:setName(getItemNameFromFullType(self.item:getFullType()))
        item:setCustomName(false)
        itemModData.SwabRespiratoryExposure_ProtectionRemaining = 1
    end
-- SWAB MOD END
	if instanceof(item, "Clothing") then
		local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())
		if coveredParts then
			for j=0,coveredParts:size()-1 do
				if self.noSoap == false then
					self:useSoap(item, coveredParts:get(j));
				end
				item:setBlood(coveredParts:get(j), 0);
				item:setDirt(coveredParts:get(j), 0);
			end
		end
-- SWAB MOD BEGIN
        if not itemModData.SwabRespiratoryItem or not itemModData.SwabRespiratoryExposure_RefreshAction == "wash" then
            -- For some reason, soaked bandanas when worn never dry out, so lets just not make them wet.
		    item:setWetness(100);
        end
-- SWAB MOD END
		item:setDirtyness(0);
	else
		self:useSoap(item, nil);
	end
	item:setBloodLevel(0);
	
	self.character:resetModel();
	sendClothing(self.character);
	if self.character:isPrimaryHandItem(item) then
		self.character:setPrimaryHandItem(item);
	end
	if self.character:isSecondaryHandItem(item) then
		self.character:setSecondaryHandItem(item);
	end
	triggerEvent("OnClothingUpdated", self.character)
	
	local obj = self.sink
	if instanceof (obj, "Drainable") then
	 self.obj:setUsedDelta(self.startUsedDelta + (self.endUsedDelta - self.startUsedDelta) * self:getJobDelta());
	end
	ISTakeWaterAction.SendTakeWaterCommand(self.character, self.sink, water)
	
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end


SWAB_ISWashClothing.base_new = ISWashClothing.new

function ISWashClothing:new(character, sink, soapList, item, bloodAmount, dirtAmount, noSoap)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.sink = sink;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.item = item;
	o.maxTime = ((bloodAmount + dirtAmount) * 15);
-- SWAB MOD BEGIN
    print("bloodAmount: "..tostring(bloodAmount))
    local itemModData = item:getModData()
    if itemModData.SwabRespiratoryItem and itemModData.SwabRespiratoryExposure_RefreshAction == "wash" and itemModData.SwabRespiratoryExposure_ProtectionRemaining < 1 then
        o.maxTime = o.maxTime + PZMath.ceil((1 - itemModData.SwabRespiratoryExposure_ProtectionRemaining) * SWAB_Config.itemRespiratoryWashDurationMaximum)
    end
-- SWAB MOD END
	if o.maxTime > 500 then
		o.maxTime = 500;
	end
	if noSoap == true then
		o.maxTime = o.maxTime * 5;
	end
	if o.maxTime > 800 then
		o.maxTime = 800;
	end
	if o.maxTime < 100 then
		o.maxTime = 100;
	end
	o.soaps = soapList;
	o.noSoap = noSoap
	o.forceProgressBar = true;
	if character:isTimedActionInstant() then
		o.maxTime = 1;
	end
	return o;
end