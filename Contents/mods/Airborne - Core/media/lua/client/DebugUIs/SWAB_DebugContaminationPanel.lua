require "SWAB_Config"

SWAB_DebugContaminationPanel = ISPanel:derive("SWAB_DebugContaminationPanel")
SWAB_DebugContaminationPanel.instance = nil

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function SWAB_DebugContaminationPanel.OnOpenPanel()
    if SWAB_DebugContaminationPanel.instance == nil then
        SWAB_DebugContaminationPanel.instance = SWAB_DebugContaminationPanel:new (50, 200, 250, 250, getPlayer())
        SWAB_DebugContaminationPanel.instance:initialise()
    end

    SWAB_DebugContaminationPanel.instance:addToUIManager()
    SWAB_DebugContaminationPanel.instance:setVisible(true)

    return SWAB_DebugContaminationPanel.instance
end

function SWAB_DebugContaminationPanel:initialise()
    ISPanel.initialise(self)
    -- Button initializations
    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    -- ReInit Building Button
    self.reInitBuildingButton = ISButton:new(10, self:getHeight() - (padBottom * 2) - (btnHgt * 2), btnWid, btnHgt, "ReInit Building", self, SWAB_DebugContaminationPanel.onClickReInitBuildingButton)
    self.reInitBuildingButton.internal = "REINIT_BUILDING"
    self.reInitBuildingButton.anchorTop = false
    self.reInitBuildingButton.anchorBottom = true
    self.reInitBuildingButton:initialise()
    self.reInitBuildingButton:instantiate()
    self.reInitBuildingButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.reInitBuildingButton)

    -- Decontaminate Room Button
    self.decontaminateRoomButton = ISButton:new(10 + btnWid + 10, self:getHeight() - (padBottom * 2) - (btnHgt * 2), btnWid, btnHgt, "Decon. Room", self, SWAB_DebugContaminationPanel.onClickDecontaminateRoomButton)
    self.decontaminateRoomButton.internal = "DECON_ROOM"
    self.decontaminateRoomButton.anchorTop = false
    self.decontaminateRoomButton.anchorBottom = true
    self.decontaminateRoomButton:initialise()
    self.decontaminateRoomButton:instantiate()
    self.decontaminateRoomButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.decontaminateRoomButton)

    -- Contaminate Room Button
    self.contaminateRoomButton = ISButton:new(10 + btnWid + 10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Con. Room", self, SWAB_DebugContaminationPanel.onClickContaminateRoomButton)
    self.contaminateRoomButton.internal = "CON_ROOM"
    self.contaminateRoomButton.anchorTop = false
    self.contaminateRoomButton.anchorBottom = true
    self.contaminateRoomButton:initialise()
    self.contaminateRoomButton:instantiate()
    self.contaminateRoomButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.contaminateRoomButton)

    -- -- Decontaminate Player Button
    -- self.decontaminatePlayerButton = ISButton:new(10 + btnWid + 10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Decon. Player", self, SWAB_DebugContaminationPanel.onClickDecontaminatePlayerButton)
    -- self.decontaminatePlayerButton.internal = "DECON_PLAYER"
    -- self.decontaminatePlayerButton.anchorTop = false
    -- self.decontaminatePlayerButton.anchorBottom = true
    -- self.decontaminatePlayerButton:initialise()
    -- self.decontaminatePlayerButton:instantiate()
    -- self.decontaminatePlayerButton.borderColor = {r=1, g=1, b=1, a=0.1}
    -- self:addChild(self.decontaminatePlayerButton)

    -- Close Button
    self.closeButton = ISButton:new(10, self:getHeight() - padBottom - btnHgt, btnWid, btnHgt, "Close", self, SWAB_DebugContaminationPanel.onClickCloseButton)
    self.closeButton.internal = "CLOSE"
    self.closeButton.anchorTop = false
    self.closeButton.anchorBottom = true
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self.closeButton.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(self.closeButton)

end

function SWAB_DebugContaminationPanel:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    
    local z = 10
    local x = 10
    self:drawText("Contamination Debug", x, z, 1,1,1,1, UIFont.Medium)

    z = z + 20

    local buildingModDataId = "< Outside >"
    local roomModDataId = "< Outside >"

    if getPlayer() and getPlayer():getSquare() and getPlayer():getSquare():getRoom() then
        buildingModDataId = SWAB_Config.getBuildingModDataId(getPlayer():getSquare():getBuilding():getDef())
        roomModDataId = SWAB_Config.getRoomModDataId(getPlayer():getSquare():getRoom():getRoomDef())
    end

    local playerModData = getPlayer():getModData()[SWAB_Config.playerModDataId]
    
    z = self:drawField("Position", string.format("%d, %d, %d", getPlayer():getX(), getPlayer():getY(), getPlayer():getZ()), x, z)
    z = self:drawField("Building ModData ID", buildingModDataId, x, z)
    z = self:drawField("Room ModData ID", roomModDataId, x, z)

    z = self:drawFloat("Resp. Exposure", playerModData.respiratoryExposure, x, z)
    z = self:drawField("Resp. Exposure Level", playerModData.respiratoryExposureLevel, x, z)
    z = self:drawField("Resp. Absorption Level", playerModData.respiratoryAbsorptionLevel, x, z)
    z = self:drawFloat("Resp. Absorption Rate", playerModData.respiratoryAbsorptionRate, x, z)
    z = self:drawFloat("Resp. Absorption", playerModData.respiratoryAbsorption, x, z)
    z = self:drawFloat("Endurance Maximum", playerModData.enduranceMaximum, x, z)
end

function SWAB_DebugContaminationPanel:drawFloat(_name, _value, _x, _z)
    if _value and type(_value) == "number" then
        _value = string.format("%.2f", _value)
    else
        _value = tostring(_value)
    end
    return self:drawField(_name, _value, _x, _z)
end

function SWAB_DebugContaminationPanel:drawField(_name, _value, _x, _z)
    self:drawText(_name, _x, _z, 1,1,1,1, UIFont.Small)
    self:drawText(tostring(_value), _x + 135, _z, 1,1,1,1, UIFont.Small)
    return _z + 16
end

function SWAB_DebugContaminationPanel:onClickReInitBuildingButton(_button)
    if getPlayer():getSquare() and getPlayer():getSquare():getBuilding() then
        local buildingModDataId = SWAB_Config.getBuildingModDataId(getPlayer():getSquare():getBuilding():getDef())
        if ModData.exists(buildingModDataId) then
            ModData.remove(buildingModDataId)
        end
    end
end

function SWAB_DebugContaminationPanel:onClickDecontaminateRoomButton(_button)
    if getPlayer():getSquare() and getPlayer():getSquare():getRoom() then
        local squares = getPlayer():getSquare():getRoom():getSquares()
        for squareIndex = 0, squares:size() - 1 do
            local square = squares:get(squareIndex)
            squareModData = square:getModData()
            if squareModData and squareModData[SWAB_Config.squareExposureModDataId] then
                squareModData[SWAB_Config.squareExposureModDataId] = 0
            end
        end
    end
end

function SWAB_DebugContaminationPanel:onClickContaminateRoomButton(_button)
    if getPlayer():getSquare() and getPlayer():getSquare():getRoom() then
        local squares = getPlayer():getSquare():getRoom():getSquares()
        for squareIndex = 0, squares:size() - 1 do
            local square = squares:get(squareIndex)
            squareModData = square:getModData()
            if squareModData and squareModData[SWAB_Config.squareExposureModDataId] then
                squareModData[SWAB_Config.squareExposureModDataId] = 7
            end
        end
    end
end

function SWAB_DebugContaminationPanel:onClickDecontaminatePlayerButton(_button)
    local modData = getPlayer():getModData()[SWAB_Config.playerModDataId]
    modData.respiratoryAbsorption = 0
end


function SWAB_DebugContaminationPanel:onClickCloseButton(_button)
    self:setVisible(false)
    self:removeFromUIManager()
end

--************************************************************************--
--** SWAB_DebugContaminationPanel:new
--**
--************************************************************************--
function SWAB_DebugContaminationPanel:new(_x, _y, _width, _height, _player)
    local o = {}
    _x = getCore():getScreenWidth() / 2 - (_width / 2)
    _y = getCore():getScreenHeight() / 2 - (_height / 2)
    o = ISPanel:new(_x, _y, _width, _height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = _width
    o.height = _height
    o.player = _player
    o.moveWithMouse = true
    SWAB_DebugContaminationPanel.instance = o
    return o
end

function SWAB_DebugContaminationPanel.openPanel(_player, _context, _worldObjects, _test)
	_context:addOption("Debug Contamination", _player, SWAB_DebugContaminationPanel.OnOpenPanel)
end
Events.OnPreFillWorldObjectContextMenu.Add(SWAB_DebugContaminationPanel.openPanel)