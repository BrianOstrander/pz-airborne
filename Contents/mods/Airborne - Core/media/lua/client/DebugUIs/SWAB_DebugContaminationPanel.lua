require "SWAB_Config"

SWAB_DebugContaminationPanel = ISPanel:derive("SWAB_DebugContaminationPanel")
SWAB_DebugContaminationPanel.instance = nil

SWAB_DebugContaminationPanel.buttonBeginY = 180
SWAB_DebugContaminationPanel.buttonPaddingBottom = 4
SWAB_DebugContaminationPanel.buttonWidth = 100
SWAB_DebugContaminationPanel.buttonHeight = PZMath.max(25, getTextManager():getFontHeight(UIFont.Small) + 1 * 2)

function SWAB_DebugContaminationPanel.OnOpenPanel()
    if SWAB_DebugContaminationPanel.instance == nil then
        SWAB_DebugContaminationPanel.instance = SWAB_DebugContaminationPanel:new(
            50,
            300,
            310,
            SWAB_DebugContaminationPanel.buttonBeginY + ((SWAB_DebugContaminationPanel.buttonHeight + SWAB_DebugContaminationPanel.buttonPaddingBottom) * 3),
            getPlayer()
        )
        SWAB_DebugContaminationPanel.instance:initialise()
    end

    SWAB_DebugContaminationPanel.instance:addToUIManager()
    SWAB_DebugContaminationPanel.instance:setVisible(true)

    return SWAB_DebugContaminationPanel.instance
end

function SWAB_DebugContaminationPanel:initialise()
    ISPanel.initialise(self)

    -- Button Creation
    self:createButton(
        "Con. Room",
        "CON_ROOM",
        SWAB_DebugContaminationPanel.onClickContaminateRoomButton
    )
    
    self:createButton(
        "Decon. Room",
        "DECON_ROOM",
        SWAB_DebugContaminationPanel.onClickDecontaminateRoomButton
    )
    
    self:createButton(
        "Sickness +",
        "INC_SICK",
        SWAB_DebugContaminationPanel.onClickIncreaseSicknessButton
    )
    
    self:createButton(
        "Decon. Player",
        "DECON_PLAYER",
        SWAB_DebugContaminationPanel.onClickDecontaminatePlayerButton
    )

    self:createButton(
        "ReInit Building",
        "REINIT_BUILDING",
        SWAB_DebugContaminationPanel.onClickReInitBuildingButton
    )

    self:createButton(
        "Close",
        "CLOSE",
        SWAB_DebugContaminationPanel.onClickCloseButton
    )
end

function SWAB_DebugContaminationPanel:createButton(_name, _id, _onClick)
    local buttonX = 10
    local buttonY = SWAB_DebugContaminationPanel.buttonBeginY

    if not self.buttonListInitialized then
        self.buttonListInitialized = true
        self.buttonCount = 1
    else
        self.buttonCount = self.buttonCount + 1
    end

    local row = nil

    if self.buttonCount % 2 == 0 then
        -- We're in the right column
        buttonX = buttonX + SWAB_DebugContaminationPanel.buttonWidth + 10
        row = self.buttonCount / 2
    else
        row = (self.buttonCount + 1) / 2
    end

    row = row - 1

    buttonY = buttonY + (row * (SWAB_DebugContaminationPanel.buttonHeight + SWAB_DebugContaminationPanel.buttonPaddingBottom))

    local button = ISButton:new(
        buttonX,
        buttonY,
        SWAB_DebugContaminationPanel.buttonWidth,
        SWAB_DebugContaminationPanel.buttonHeight,
        _name,
        self,
        _onClick
    )
    button.internal = _id
    button.anchorTop = false
    button.anchorBottom = true
    self[_id.."_ENTRY"] = button
    
    button:initialise()
    button:instantiate()
    button.borderColor = {r=1, g=1, b=1, a=0.1}
    self:addChild(button)
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
    local lastTick = "None"
    local squareExposure = nil
    local isRoomAsleep = nil

    if getPlayer() and getPlayer():getSquare() and getPlayer():getSquare():getRoom() then
        buildingModDataId = SWAB_Config.getBuildingModDataId(getPlayer():getSquare():getBuilding():getDef())
        roomModDataId = SWAB_Config.getRoomModDataId(getPlayer():getSquare():getRoom():getRoomDef())
        lastTick = getPlayer():getSquare():getModData().swab_last_tick
        squareExposure = getPlayer():getSquare():getModData().swab_square_exposure
        if ModData.exists(buildingModDataId) then
            local rooms = getPlayer():getSquare():getBuilding():getDef():getRooms()
            for i = 0, rooms:size() - 1 do
                if rooms:get(i) == getPlayer():getSquare():getRoom():getRoomDef() then
                    local roomDatas = ModData.get(buildingModDataId).roomDatas
                    if roomDatas and i <= #roomDatas then
                        isRoomAsleep = 0 < roomDatas[i].skipUpdatesRemaining
                    end
                end
            end
        end
    end

    local playerModData = getPlayer():getModData().swab_player
    
    z = self:drawField("Position", string.format("%d, %d, %d", getPlayer():getX(), getPlayer():getY(), getPlayer():getZ()), x, z)
    z = self:drawField("Building ModData ID", buildingModDataId, x, z)
    z = self:drawField("Room ModData ID", roomModDataId, x, z)

    z = self:drawField("Last Tick", lastTick, x, z)
    z = self:drawField("Is Room Asleep", isRoomAsleep, x, z)
    z = self:drawFloat("Squa. Exposure", squareExposure, x, z)
    z = self:drawFloat("Resp. Exposure", playerModData.respiratoryExposure, x, z)
    -- z = self:drawField("Resp. Exposure Level", playerModData.respiratoryExposureLevel, x, z)
    -- z = self:drawField("Resp. Absorption Level", playerModData.respiratoryAbsorptionLevel, x, z)
    -- z = self:drawFloat("Resp. Absorption Rate", playerModData.respiratoryAbsorptionRate, x, z)
    -- z = self:drawFloat("Resp. Absorption", playerModData.respiratoryAbsorption, x, z)
    -- z = self:drawFloat("Endurance Maximum", playerModData.enduranceMaximum, x, z)
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
            if squareModData and squareModData.swab_square_exposure then
                squareModData.swab_square_exposure = 0
            end
        end
    end
end

function SWAB_DebugContaminationPanel:onClickIncreaseSicknessButton(_button)
    local modData = getPlayer():getModData().swab_player
    if modData.respiratorySicknessLevel + 1 <= SWAB_Config.respiratorySicknessLevelMaximum then
        modData.respiratorySicknessLevel = modData.respiratorySicknessLevel + 1
        modData.respiratoryAbsorption = SWAB_Config.GetRespiratorySicknessEffects(modData.respiratorySicknessLevel).absorptionMinimum
    else
        modData.respiratorySicknessLevel = 0
        modData.respiratoryAbsorption = 0
    end
end

function SWAB_DebugContaminationPanel:onClickContaminateRoomButton(_button)
    if getPlayer():getSquare() and getPlayer():getSquare():getRoom() then
        local squares = getPlayer():getSquare():getRoom():getSquares()
        for squareIndex = 0, squares:size() - 1 do
            local square = squares:get(squareIndex)
            squareModData = square:getModData()
            if squareModData and squareModData.swab_square_exposure then
                squareModData.swab_square_exposure = 7
            end
        end
    end
end

function SWAB_DebugContaminationPanel:onClickDecontaminatePlayerButton(_button)
    local modData = getPlayer():getModData().swab_player
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