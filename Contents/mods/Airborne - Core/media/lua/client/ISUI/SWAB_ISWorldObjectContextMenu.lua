-- Copied from ISWorldObjectContextMenu.lua
local function getMoveableDisplayName(obj)
	if not obj then return nil end
	if not obj:getSprite() then return nil end
	local props = obj:getSprite():getProperties()
	if props:Is("CustomName") then
		local name = props:Val("CustomName")
		if props:Is("GroupName") then
			name = props:Val("GroupName") .. " " .. name
		end
		return Translator.getMoveableDisplayName(name)
	end
	return nil
end

SWAB_ISWorldObjectContextMenu = {}
SWAB_ISWorldObjectContextMenu.base_doWashClothingMenu = ISWorldObjectContextMenu.doWashClothingMenu

ISWorldObjectContextMenu.doWashClothingMenu = function(sink, player, context)
	local playerObj = getSpecificPlayer(player)
	if sink:getSquare():getBuilding() ~= playerObj:getBuilding() then return end;
    local playerInv = playerObj:getInventory()
	local washYourself = false
	local washEquipment = false
	local washList = {}
	local soapList = {}
	local noSoap = true

	washYourself = ISWashYourself.GetRequiredWater(playerObj) > 0

	local barList = playerInv:getItemsFromType("Soap2", true)
	for i=0, barList:size() - 1 do
        local item = barList:get(i)
		table.insert(soapList, item)
	end
    
    local bottleList = playerInv:getItemsFromType("CleaningLiquid2", true)
    for i=0, bottleList:size() - 1 do
        local item = bottleList:get(i)
        table.insert(soapList, item)
    end

	local clothingInventory = playerInv:getItemsFromCategory("Clothing")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		-- Wasn't able to reproduce the wash 'Blooo' bug, don't know the exact cause so here's a fix...
-- SWAB MOD BEGIN
        local itemModData = item:getModData()
        if not item:isHidden() and (item:hasBlood() or item:hasDirt() or (itemModData.SwabRespiratoryItem and itemModData.SwabRespiratoryExposure_RefreshAction == "wash" and itemModData.SwabRespiratoryExposure_ProtectionRemaining < 1)) then
-- SWAB MOD END
			if washEquipment == false then
				washEquipment = true
			end
			table.insert(washList, item)
		end
	end
	

    local weaponInventory = playerInv:getItemsFromCategory("Weapon")
    for i=0, weaponInventory:size() - 1 do
        local item = weaponInventory:get(i)
        if item:hasBlood() then
            if washEquipment == false then
                washEquipment = true
            end
            table.insert(washList, item)
        end
	end
	
	local clothingInventory = playerInv:getItemsFromCategory("Container")
	for i=0, clothingInventory:size() - 1 do
		local item = clothingInventory:get(i)
		if not item:isHidden() and (item:hasBlood() or item:hasDirt()) then
			washEquipment = true
			table.insert(washList, item)
		end
	end
	-- Sort clothes from least-bloody to most-bloody.
	table.sort(washList, ISWorldObjectContextMenu.compareClothingBlood)

	if washYourself or washEquipment then
		local mainOption = context:addOption(getText("ContextMenu_Wash"), nil, nil);
		local mainSubMenu = ISContextMenu:getNew(context)
		context:addSubMenu(mainOption, mainSubMenu)
	
--		if #soapList < 1 then
--			mainOption.notAvailable = true;
--			local tooltip = ISWorldObjectContextMenu.addToolTip();
--			tooltip:setName("Need soap.");
--			mainOption.toolTip = tooltip;
--			return;
--		end

		local soapRemaining = ISWashClothing.GetSoapRemaining(soapList)
		local waterRemaining = sink:getWaterAmount()
	
		if washYourself then
			local soapRequired = ISWashYourself.GetRequiredSoap(playerObj)
			local waterRequired = ISWashYourself.GetRequiredWater(playerObj)
			local option = mainSubMenu:addOption(getText("ContextMenu_Yourself"), playerObj, ISWorldObjectContextMenu.onWashYourself, sink, soapList)
			local tooltip = ISWorldObjectContextMenu.addToolTip()
			local source = getMoveableDisplayName(sink)
			if source == nil and instanceof(sink, "IsoWorldInventoryObject") and sink:getItem() then
				source = sink:getItem():getDisplayName()
			end
			if source == nil then
				source = getText("ContextMenu_NaturalWaterSource")
			end
			tooltip.description = getText("ContextMenu_WaterSource")  .. ": " .. source .. " <LINE> " 
			if soapRemaining < soapRequired then
				tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
			else
				tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
			end
			tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
			local visual = playerObj:getHumanVisual()
			local bodyBlood = 0
			local bodyDirt = 0
			for i=1,BloodBodyPartType.MAX:index() do
				local part = BloodBodyPartType.FromIndex(i-1)
				bodyBlood = bodyBlood + visual:getBlood(part)
				bodyDirt = bodyDirt + visual:getDirt(part)
			end
			if bodyBlood > 0 then
				tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(bodyBlood / BloodBodyPartType.MAX:index() * 100) .. " / 100"
			end
			if bodyDirt > 0 then
				tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(bodyDirt / BloodBodyPartType.MAX:index() * 100) .. " / 100"
			end
			option.toolTip = tooltip
			if waterRemaining < 1 then
				option.notAvailable = true
			end
		end
		
		if washEquipment then
			if #washList > 1 then
				local soapRequired = 0
				local waterRequired = 0
				for _,item in ipairs(washList) do
					soapRequired = soapRequired + ISWashClothing.GetRequiredSoap(item)
					waterRequired = waterRequired + ISWashClothing.GetRequiredWater(item)
				end
				local tooltip = ISWorldObjectContextMenu.addToolTip();
				local source = getMoveableDisplayName(sink)
				if source == nil and instanceof(sink, "IsoWorldInventoryObject") and sink:getItem() then
					source = sink:getItem():getDisplayName()
				end
				if source == nil then
					source = getText("ContextMenu_NaturalWaterSource")
				end
				tooltip.description = getText("ContextMenu_WaterSource")  .. ": " .. source .. " <LINE> "
--				tooltip:setName(getText("ContextMenu_NeedSoap"));
				if (soapRemaining < soapRequired) then
					tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
					noSoap = true;
				else
					tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
					noSoap = false;
				end
				tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
				local option = mainSubMenu:addOption(getText("ContextMenu_WashAllClothing"), playerObj, ISWorldObjectContextMenu.onWashClothing, sink, soapList, washList, nil,  noSoap);
				option.toolTip = tooltip;
				if (waterRemaining < waterRequired) then
					option.notAvailable = true;
				end
			end
			for i,item in ipairs(washList) do
				local soapRequired = ISWashClothing.GetRequiredSoap(item)
				local waterRequired = ISWashClothing.GetRequiredWater(item)
				local tooltip = ISWorldObjectContextMenu.addToolTip();
				local source = getMoveableDisplayName(sink)
				if source == nil and instanceof(sink, "IsoWorldInventoryObject") and sink:getItem() then
					source = sink:getItem():getDisplayName()
				end
				if source == nil then
					source = getText("ContextMenu_NaturalWaterSource")
				end
				tooltip.description = getText("ContextMenu_WaterSource")  .. ": " .. source .. " <LINE> "
				--				tooltip:setName(getText("ContextMenu_NeedSoap"));
				if (soapRemaining < soapRequired) then
					tooltip.description = tooltip.description .. getText("IGUI_Washing_WithoutSoap") .. " <LINE> "
					noSoap = true;
				else
					tooltip.description = tooltip.description .. getText("IGUI_Washing_Soap") .. ": " .. tostring(math.min(soapRemaining, soapRequired)) .. " / " .. tostring(soapRequired) .. " <LINE> "
					noSoap = false;
				end
				tooltip.description = tooltip.description .. getText("ContextMenu_WaterName") .. ": " .. tostring(math.min(waterRemaining, waterRequired)) .. " / " .. tostring(waterRequired)
-- SWAB MOD BEGIN
                local itemModData = item:getModData()
                if itemModData.SwabRespiratoryItem and itemModData.SwabRespiratoryExposure_RefreshAction == "wash" and itemModData.SwabRespiratoryExposure_ProtectionRemaining < 1 then
                    tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_SWAB_mask_contamination") .. ": " .. (100 - math.ceil(itemModData.SwabRespiratoryExposure_ProtectionRemaining * 100)) .. " / 100"
                end
-- SWAB MOD END
				if (item:IsClothing() or item:IsInventoryContainer()) and (item:getBloodLevel() > 0) then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel()) .. " / 100"
				end
				if item:IsWeapon() and (item:getBloodLevel() > 0) then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_bloody") .. ": " .. math.ceil(item:getBloodLevel() * 100) .. " / 100"
				end
				if item:IsClothing() and item:getDirtyness() > 0 then
					tooltip.description = tooltip.description .. " <LINE> " .. getText("Tooltip_clothing_dirty") .. ": " .. math.ceil(item:getDirtyness()) .. " / 100"
				end
				local option = mainSubMenu:addOption(getText("ContextMenu_WashClothing", item:getDisplayName()), playerObj, ISWorldObjectContextMenu.onWashClothing, sink, soapList, nil, item, noSoap);
				option.toolTip = tooltip;
				if (waterRemaining < waterRequired) then
					option.notAvailable = true;
				end
			end
		end
	end
end